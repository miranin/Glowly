"""
Custom MCP (Model Context Protocol) server tools.

Three tools exposed as a JSON-RPC-compatible FastAPI router:

  1. analyze_ingredients  — given a list of ingredients, return compatibility,
                            conflicts, benefits, and skin-type guidance
  2. categorize_product   — classify a product by name + description into the
                            Glowly taxonomy and suggest application zone
  3. recommend_routine    — given a user profile + existing product categories,
                            build a personalized routine with missing steps

Each tool's input/output schema is also served at GET /api/mcp/tools
for Claude's tool_use API and for academic inspection.
"""

import logging
from typing import Any

import anthropic

from config import settings
from services.rag_service import rag_service

logger = logging.getLogger(__name__)

# ─── Tool manifests (MCP tool_use schema format) ─────────────────────────────

TOOL_MANIFESTS = [
    {
        "name": "analyze_ingredients",
        "description": (
            "Analyze a list of cosmetic ingredients. Returns: ingredient benefits, "
            "known conflicts with other common ingredients, skin type suitability, "
            "and safety notes (pregnancy, sensitivity). "
            "Uses RAG retrieval against a curated cosmetic knowledge base."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "ingredients": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "List of ingredient names to analyze",
                },
                "skin_type": {
                    "type": "string",
                    "description": "User's skin type (dry, oily, combination, sensitive, normal)",
                },
                "skin_conditions": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "Optional list of skin conditions (acne, redness, etc.)",
                },
            },
            "required": ["ingredients"],
        },
    },
    {
        "name": "categorize_product",
        "description": (
            "Classify a cosmetic product into the Glowly taxonomy given its name, "
            "brand, and optional description. Returns: category, application_zone, "
            "confidence score, and alternative category suggestions."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "product_name": {
                    "type": "string",
                    "description": "Name of the product",
                },
                "brand": {
                    "type": "string",
                    "description": "Brand name",
                },
                "description": {
                    "type": "string",
                    "description": "Optional product description or visible text",
                },
            },
            "required": ["product_name"],
        },
    },
    {
        "name": "recommend_routine",
        "description": (
            "Generate a personalized skincare routine based on the user's profile "
            "and their existing product categories. Returns: AM routine steps, "
            "PM routine steps, missing essential products, and ingredient conflicts "
            "to avoid in the current collection."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "skin_type": {
                    "type": "string",
                    "description": "User's skin type",
                },
                "skin_conditions": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "List of skin conditions",
                },
                "beauty_goals": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "User's beauty goals",
                },
                "existing_categories": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "Categories of products already in the user's bag",
                },
                "experience_level": {
                    "type": "string",
                    "description": "beginner | intermediate | advanced | professional",
                },
            },
            "required": ["skin_type"],
        },
    },
]


# ─── Tool implementations ─────────────────────────────────────────────────────

async def execute_tool(tool_name: str, tool_input: dict[str, Any]) -> dict[str, Any]:
    """
    Dispatch tool execution by name.
    Raises ValueError for unknown tools.
    """
    dispatch = {
        "analyze_ingredients": _analyze_ingredients,
        "categorize_product": _categorize_product,
        "recommend_routine": _recommend_routine,
    }

    handler = dispatch.get(tool_name)
    if handler is None:
        raise ValueError(f"Unknown MCP tool: '{tool_name}'. Available: {list(dispatch)}")

    return await handler(tool_input)


# ─── Tool 1: analyze_ingredients ─────────────────────────────────────────────

async def _analyze_ingredients(inp: dict) -> dict:
    """
    RAG retrieval + LLM synthesis for ingredient analysis.
    """
    ingredients = inp.get("ingredients", [])
    skin_type = inp.get("skin_type", "")
    skin_conditions = inp.get("skin_conditions", [])

    if not ingredients:
        return {"error": "No ingredients provided", "results": []}

    # 1. RAG retrieval
    docs = rag_service.retrieve_for_ingredients(ingredients, skin_type)
    rag_context = "\n\n".join(
        f"**{d['title']}**: {d['content'][:400]}" for d in docs
    )

    # 2. LLM synthesis
    prompt = f"""Analyze these cosmetic ingredients for a user with {skin_type or 'unspecified'} skin type
and conditions: {', '.join(skin_conditions) or 'none'}.

Ingredients to analyze: {', '.join(ingredients)}

Knowledge base context:
{rag_context}

Provide a structured analysis including:
1. What each key ingredient does
2. Conflicts between these ingredients
3. Skin type suitability
4. Safety notes (pregnancy, sensitivity, sun exposure)
5. Recommended usage order

Format as JSON with keys: analysis (list), conflicts (list), suitability_score (0-10), notes (string)"""

    client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)
    response = await client.messages.create(
        model=settings.claude_chat_model,
        max_tokens=1500,
        messages=[{"role": "user", "content": prompt}],
    )

    raw = response.content[0].text

    import json, re
    match = re.search(r"```(?:json)?\s*([\s\S]*?)```", raw)
    json_str = (match.group(1) if match else raw).strip()
    try:
        result = json.loads(json_str)
    except Exception:
        result = {"raw_analysis": raw}

    return {
        "ingredients_analyzed": ingredients,
        "skin_type": skin_type,
        "rag_documents_used": [d["title"] for d in docs],
        **result,
    }


# ─── Tool 2: categorize_product ──────────────────────────────────────────────

_CATEGORY_PROMPT = """Classify this cosmetic product into the correct category.

Product Name: {name}
Brand: {brand}
Description: {description}

Available categories: foundation, concealer, powder, blush, bronzer, highlighter,
eyeshadow, eyeliner, mascara, lipstick, lip_gloss, lip_liner, primer, setting_spray,
cleanser, toner, moisturizer, serum, sunscreen, mask, exfoliant, eye_cream, other

Available application zones: face, eyes, lips, cheeks, body, hair, hands, feet, nails, neck, decolletage

Return JSON with exactly these keys:
{{
  "category": "string",
  "application_zone": "string",
  "confidence": 0.0-1.0,
  "alternative_categories": ["second_best", "third_best"],
  "reasoning": "one-sentence explanation"
}}"""


async def _categorize_product(inp: dict) -> dict:
    product_name = inp.get("product_name", "")
    brand = inp.get("brand", "")
    description = inp.get("description", "")

    client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)
    prompt = _CATEGORY_PROMPT.format(
        name=product_name,
        brand=brand or "Unknown",
        description=description or "No description provided",
    )

    response = await client.messages.create(
        model=settings.claude_chat_model,
        max_tokens=512,
        messages=[{"role": "user", "content": prompt}],
    )

    raw = response.content[0].text

    import json, re
    match = re.search(r"```(?:json)?\s*([\s\S]*?)```", raw)
    json_str = (match.group(1) if match else raw).strip()
    try:
        result = json.loads(json_str)
    except Exception:
        result = {"raw": raw, "confidence": 0.0}

    return {"product_name": product_name, "brand": brand, **result}


# ─── Tool 3: recommend_routine ────────────────────────────────────────────────

_ROUTINE_PROMPT = """Build a complete skincare routine for this user.

User Profile:
- Skin Type: {skin_type}
- Skin Conditions: {conditions}
- Beauty Goals: {goals}
- Experience Level: {experience}

Products already in their bag (categories): {existing}

Retrieved knowledge about their skin type:
{rag_context}

Generate a personalized routine. Identify:
1. What they already have and where it fits
2. What's missing from an optimal routine for their profile
3. Ingredient conflicts to watch for in their collection
4. Order of application for AM and PM

Return JSON:
{{
  "am_routine": [{{"step": 1, "category": "cleanser", "action": "gentle foam cleanser", "reason": "..."}}],
  "pm_routine": [{{"step": 1, "category": "cleanser", "action": "...", "reason": "..."}}],
  "missing_products": [{{"category": "...", "why_important": "...", "priority": "high|medium|low"}}],
  "ingredient_conflicts": [{{"ingredient_a": "...", "ingredient_b": "...", "advice": "..."}}],
  "routine_tips": ["tip1", "tip2"]
}}"""


async def _recommend_routine(inp: dict) -> dict:
    skin_type = inp.get("skin_type", "normal")
    conditions = inp.get("skin_conditions", [])
    goals = inp.get("beauty_goals", [])
    existing = inp.get("existing_categories", [])
    experience = inp.get("experience_level", "beginner")

    # RAG retrieval
    user_profile = {
        "skin_type": skin_type,
        "skin_conditions": conditions,
        "beauty_goals": goals,
    }
    rag_context = rag_service.build_recommendation_context(
        user_profile=user_profile,
        existing_categories=existing,
    )

    prompt = _ROUTINE_PROMPT.format(
        skin_type=skin_type,
        conditions=", ".join(conditions) or "none",
        goals=", ".join(goals) or "general skincare",
        experience=experience,
        existing=", ".join(existing) if existing else "none yet",
        rag_context=rag_context[:2000],
    )

    client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)
    response = await client.messages.create(
        model=settings.claude_chat_model,
        max_tokens=2048,
        messages=[{"role": "user", "content": prompt}],
    )

    raw = response.content[0].text

    import json, re
    match = re.search(r"```(?:json)?\s*([\s\S]*?)```", raw)
    json_str = (match.group(1) if match else raw).strip()
    try:
        result = json.loads(json_str)
    except Exception:
        result = {"raw_routine": raw}

    return {
        "user_profile_summary": f"{skin_type} skin, {', '.join(conditions) or 'no conditions'}",
        **result,
    }
