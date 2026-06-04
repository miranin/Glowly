"""
LangGraph multi-step workflow for cosmetic product analysis.

Graph topology (with conditional branching):

  START
    │
    ▼
  image_analysis_node          ← Claude claude-sonnet-4-6 vision (Pass 1: description)
    │
    ▼
  ocr_extraction_node          ← Claude claude-sonnet-4-6 vision (Pass 2: text OCR)
    │
    ▼
  product_classification_node  ← Claude haiku (structured JSON extraction)
    │
    ▼
  confidence_check_node        ← Branching point (pure function, no LLM)
    │
    ├─── confidence < threshold ──→  human_confirmation_node  ──→  END
    │                                (returns partial result, awaits user)
    │
    └─── confidence ≥ threshold ──→  save_product_node
                                       │
                                       ▼
                                     recommendation_generation_node  ← RAG + LLM
                                       │
                                       ▼
                                      END

State type: CosmeticAnalysisState (TypedDict with all fields)
All LangSmith traces are automatic via LANGCHAIN_TRACING_V2 env var.
"""

import logging
from typing import Annotated, Any, Optional, TypedDict

import anthropic
from langchain_anthropic import ChatAnthropic
from langchain_core.messages import HumanMessage, SystemMessage
from langgraph.graph import END, StateGraph

from config import settings
from schemas.product import AnalyzedProduct, ApplicationZone, ProductCategory
from services.rag_service import rag_service
from services.vision_service import vision_service

logger = logging.getLogger(__name__)


# ─── State definition ────────────────────────────────────────────────────────

class CosmeticAnalysisState(TypedDict):
    """
    Typed state passed between all nodes in the graph.
    Each node receives the full state and returns a partial update dict.
    """
    # ── Inputs ──────────────────────────────────────────────────────────────
    image_bytes: bytes                          # raw uploaded image
    media_type: str                             # "image/jpeg" | "image/png"
    user_id: str
    user_profile: dict                          # from UserProfile.ai_context_string

    # ── Node outputs (populated as graph executes) ───────────────────────────
    vision_description: str                     # image_analysis_node
    ocr_text: str                               # ocr_extraction_node
    analyzed_product: Optional[dict]            # product_classification_node (serialized AnalyzedProduct)
    confidence: float                           # extracted for routing

    # ── Conditional branch flag ──────────────────────────────────────────────
    needs_confirmation: bool                    # confidence_check_node

    # ── Downstream ───────────────────────────────────────────────────────────
    rag_context: str                            # retrieved knowledge
    recommendations: list[dict]                 # recommendation_generation_node
    workflow_steps: list[str]                   # audit trail of nodes executed
    error: Optional[str]                        # set if any node fails


# ─── LLM clients ─────────────────────────────────────────────────────────────

def _vision_llm() -> ChatAnthropic:
    return ChatAnthropic(
        model=settings.claude_vision_model,
        anthropic_api_key=settings.anthropic_api_key,
        max_tokens=1024,
    )


def _chat_llm() -> ChatAnthropic:
    return ChatAnthropic(
        model=settings.claude_chat_model,
        anthropic_api_key=settings.anthropic_api_key,
        max_tokens=2048,
    )


# ─── Node 1: Image Analysis ──────────────────────────────────────────────────

async def image_analysis_node(state: CosmeticAnalysisState) -> dict:
    """
    Combined single-pass analysis via the improved VisionService.
    Replaces the old 3-pass approach: one Claude call extracts OCR +
    visual reasoning + structured JSON simultaneously.
    """
    steps = list(state.get("workflow_steps", []))
    steps.append("image_analysis")
    logger.info("[node] image_analysis (combined single-pass) started")

    try:
        vision_description, ocr_text, product = await vision_service.analyze_image(
            state["image_bytes"],
            media_type=state.get("media_type", "image/jpeg"),
        )
        product_dict = product.model_dump()
        logger.info(
            f"[node] image_analysis complete: brand='{product.brand}' "
            f"product='{product.product_name}' confidence={product.confidence:.2f}"
        )
        return {
            "vision_description": vision_description,
            "ocr_text": ocr_text,
            "analyzed_product": product_dict,
            "confidence": product.confidence,
            "needs_confirmation": product.needs_confirmation,
            "workflow_steps": steps,
            "error": None,
        }

    except Exception as exc:
        logger.error(f"[node] image_analysis failed: {exc}")
        return {
            "vision_description": "",
            "ocr_text": "",
            "analyzed_product": None,
            "confidence": 0.0,
            "needs_confirmation": True,
            "workflow_steps": steps,
            "error": f"image_analysis: {exc}",
        }


# ─── Node 2: OCR Extraction (pass-through — combined in Node 1) ──────────────

async def ocr_extraction_node(state: CosmeticAnalysisState) -> dict:
    """
    Node 1 already performed combined analysis including OCR.
    This node is kept for graph topology compatibility but is now a pass-through.
    """
    steps = list(state.get("workflow_steps", []))
    steps.append("ocr_extraction")
    logger.info("[node] ocr_extraction (pass-through) complete")
    return {"workflow_steps": steps}


# ─── Node 3: Product Classification (pass-through — combined in Node 1) ───────

async def product_classification_node(state: CosmeticAnalysisState) -> dict:
    """
    Node 1 already extracted structured product data.
    This node is kept for graph topology compatibility but is now a pass-through.
    If analyzed_product is somehow missing, returns a low-confidence sentinel.
    """
    steps = list(state.get("workflow_steps", []))
    steps.append("product_classification")
    logger.info("[node] product_classification (pass-through) complete")

    if state.get("analyzed_product"):
        return {"workflow_steps": steps}

    logger.warning("[node] product_classification: no analyzed_product in state — returning fallback")
    return {
        "analyzed_product": {},
        "confidence": 0.0,
        "needs_confirmation": True,
        "workflow_steps": steps,
        "error": "product_classification: no analyzed_product produced by image_analysis",
    }


# ─── Node 4: Confidence Check (branching node) ───────────────────────────────

def confidence_check_node(state: CosmeticAnalysisState) -> dict:
    """
    Pure function — no LLM call. Sets the needs_confirmation flag that drives
    the conditional edge routing.
    """
    steps = list(state.get("workflow_steps", []))
    steps.append("confidence_check")

    confidence = state.get("confidence", 0.0)
    needs = confidence < settings.confidence_threshold
    logger.info(
        f"[node] confidence_check: {confidence:.2f} vs threshold "
        f"{settings.confidence_threshold} → needs_confirmation={needs}"
    )
    return {"needs_confirmation": needs, "workflow_steps": steps}


def _should_confirm(state: CosmeticAnalysisState) -> str:
    """
    Edge router — maps state to next node name.
    Returns "confirm" or "save".
    """
    return "confirm" if state.get("needs_confirmation", False) else "save"


# ─── Node 5a: Human Confirmation ─────────────────────────────────────────────

async def human_confirmation_node(state: CosmeticAnalysisState) -> dict:
    """
    Low-confidence branch: returns partial result to the iOS client so the user
    can manually review and correct the extracted fields before saving.
    The workflow terminates here; the iOS app re-submits via PATCH /products/{id}.
    """
    steps = list(state.get("workflow_steps", []))
    steps.append("human_confirmation")
    logger.info("[node] human_confirmation — routing to user review")

    product = state.get("analyzed_product", {})
    if product:
        product["needs_confirmation"] = True

    return {
        "analyzed_product": product,
        "recommendations": [],
        "workflow_steps": steps,
    }


# ─── Node 5b: Save Product ────────────────────────────────────────────────────

async def save_product_node(state: CosmeticAnalysisState) -> dict:
    """
    High-confidence branch: marks the product as auto-saved.
    Actual DB persistence is done in the router after the graph returns,
    so this node focuses on state finalization.
    """
    steps = list(state.get("workflow_steps", []))
    steps.append("save_product")
    logger.info("[node] save_product — product auto-approved for saving")

    product = state.get("analyzed_product", {})
    if product:
        product["needs_confirmation"] = False

    return {"analyzed_product": product, "workflow_steps": steps}


# ─── Node 6: Recommendation Generation ───────────────────────────────────────

_RECOMMENDATION_SYSTEM = """You are a professional skincare advisor. Based on the user's profile and
the detected product ingredients, generate personalized skincare recommendations.
Be specific, practical, and science-backed. Respond in the user's language."""

_RECOMMENDATION_TEMPLATE = """User Profile:
{user_profile}

Detected Product:
Brand: {brand}
Category: {category}
Ingredients: {ingredients}

Retrieved Knowledge Base:
{rag_context}

Generate 3-5 personalized product recommendations that would complement this product and the user's profile.
For each recommendation provide:
- product_name: specific product name or type
- brand: brand name (if recommending specific product) or "Various"
- category: product category
- reason: why this product helps THIS user specifically (reference their skin type/conditions)
- priority: 1-10 (10 = most essential)
- ingredient_synergy: ingredients that work well together with the detected product

Respond with a JSON array of recommendation objects only. No other text."""


async def recommendation_generation_node(state: CosmeticAnalysisState) -> dict:
    """
    RAG-powered recommendation engine:
    1. Retrieves relevant knowledge chunks from Qdrant
    2. Combines with user profile context
    3. Calls Claude to generate personalized recommendations
    """
    steps = list(state.get("workflow_steps", []))
    steps.append("recommendation_generation")
    logger.info("[node] recommendation_generation started")

    try:
        product = state.get("analyzed_product", {})
        user_profile = state.get("user_profile", {})
        ingredients = product.get("ingredients", [])

        # Step 1: RAG retrieval
        rag_context = rag_service.build_recommendation_context(
            user_profile=user_profile,
            product_ingredients=ingredients,
        )

        # Step 2: Build prompt
        skin_type = user_profile.get("skin_type", "not specified")
        conditions = ", ".join(user_profile.get("skin_conditions", []) or [])
        goals = ", ".join(user_profile.get("beauty_goals", []) or [])

        profile_str = (
            f"Skin type: {skin_type}\n"
            f"Skin conditions: {conditions or 'none'}\n"
            f"Beauty goals: {goals or 'not specified'}\n"
            f"Allergies: {', '.join(user_profile.get('allergies', []) or [])}"
        )

        prompt = _RECOMMENDATION_TEMPLATE.format(
            user_profile=profile_str,
            brand=product.get("brand", "Unknown"),
            category=product.get("category", "other"),
            ingredients=", ".join(ingredients[:15]) if ingredients else "not detected",
            rag_context=rag_context,
        )

        client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)
        response = await client.messages.create(
            model=settings.claude_chat_model,
            max_tokens=2048,
            system=_RECOMMENDATION_SYSTEM,
            messages=[{"role": "user", "content": prompt}],
        )

        raw = response.content[0].text
        recommendations = _parse_recommendations(raw)

        logger.info(f"[node] recommendation_generation: {len(recommendations)} recommendations")
        return {
            "rag_context": rag_context,
            "recommendations": recommendations,
            "workflow_steps": steps,
        }

    except Exception as exc:
        logger.error(f"[node] recommendation_generation failed: {exc}")
        return {
            "rag_context": "",
            "recommendations": [],
            "workflow_steps": steps,
            "error": str(exc),
        }


def _parse_recommendations(raw: str) -> list[dict]:
    """Extract JSON array from recommendation LLM output."""
    import json
    import re

    match = re.search(r"```(?:json)?\s*([\s\S]*?)```", raw)
    json_str = match.group(1) if match else raw

    # Also handle case where output starts/ends with array directly
    json_str = json_str.strip()
    if not json_str.startswith("["):
        # Find first [ and last ]
        start = json_str.find("[")
        end = json_str.rfind("]")
        if start != -1 and end != -1:
            json_str = json_str[start : end + 1]

    try:
        data = json.loads(json_str)
        if isinstance(data, list):
            return data
        return []
    except json.JSONDecodeError:
        logger.warning("Could not parse recommendations JSON")
        return []


# ─── Graph assembly ───────────────────────────────────────────────────────────

def build_workflow() -> Any:
    """
    Assembles and compiles the LangGraph StateGraph.
    The compiled graph is a callable: await graph.ainvoke(initial_state).
    """
    graph = StateGraph(CosmeticAnalysisState)

    # Add nodes
    graph.add_node("image_analysis", image_analysis_node)
    graph.add_node("ocr_extraction", ocr_extraction_node)
    graph.add_node("product_classification", product_classification_node)
    graph.add_node("confidence_check", confidence_check_node)
    graph.add_node("human_confirmation", human_confirmation_node)
    graph.add_node("save_product", save_product_node)
    graph.add_node("recommendation_generation", recommendation_generation_node)

    # Linear edges (no branching)
    graph.set_entry_point("image_analysis")
    graph.add_edge("image_analysis", "ocr_extraction")
    graph.add_edge("ocr_extraction", "product_classification")
    graph.add_edge("product_classification", "confidence_check")

    # ── Conditional branching at confidence_check ──────────────────────────
    graph.add_conditional_edges(
        "confidence_check",
        _should_confirm,
        {
            "confirm": "human_confirmation",  # low confidence → user reviews
            "save": "save_product",            # high confidence → auto-save
        },
    )

    # Both save paths eventually terminate
    graph.add_edge("human_confirmation", END)
    graph.add_edge("save_product", "recommendation_generation")
    graph.add_edge("recommendation_generation", END)

    return graph.compile()


# Module-level compiled graph — created once at startup
cosmetic_workflow = build_workflow()


# ─── Convenience runner ───────────────────────────────────────────────────────

async def run_analysis_workflow(
    image_bytes: bytes,
    media_type: str,
    user_id: str,
    user_profile: dict,
) -> CosmeticAnalysisState:
    """
    Public entry point used by the /analyze-product router.
    Returns the final state after all nodes have executed.
    """
    initial_state: CosmeticAnalysisState = {
        "image_bytes": image_bytes,
        "media_type": media_type,
        "user_id": user_id,
        "user_profile": user_profile,
        "vision_description": "",
        "ocr_text": "",
        "analyzed_product": None,
        "confidence": 0.0,
        "needs_confirmation": False,
        "rag_context": "",
        "recommendations": [],
        "workflow_steps": [],
        "error": None,
    }

    config = {
        "configurable": {
            "thread_id": f"analysis-{user_id}",
        },
        # LangSmith run metadata
        "metadata": {
            "user_id": user_id,
            "flow_type": "cosmetic_analysis",
        },
        "tags": ["cosmetic-analysis", "production" if settings.is_production else "dev"],
        "run_name": f"CosmeticAnalysis-{user_id[:8]}",
    }

    result: CosmeticAnalysisState = await cosmetic_workflow.ainvoke(initial_state, config=config)
    return result
