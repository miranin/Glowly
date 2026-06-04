"""
AI / Chat router.

POST /api/ai/chat              — proxies iOS AIService through backend (hides API key)
GET  /api/ai/recommendations   — RAG-powered personalized product recommendations
POST /recommendations          — academic alias for GET /api/ai/recommendations
"""

import logging

import anthropic
from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from config import settings
from database.models import ChatMessage, Product, UserProfile
from routers.deps import CurrentUser, DB
from schemas.ai import (
    ChatRequest,
    ChatResponse,
    RecommendationItem,
    RecommendationsResponse,
)
from services.rag_service import rag_service

logger = logging.getLogger(__name__)
router = APIRouter(tags=["ai"])

_BEAUTY_SYSTEM = """You are an expert AI beauty and skincare assistant for Glowly.
You help users understand their cosmetic products, build personalized routines,
and make informed skincare decisions based on their unique profile.

Guidelines:
- Always personalize advice to the user's skin type, conditions, and goals
- Reference their specific products when relevant
- Warn about harmful ingredient combinations
- Be encouraging and practical
- Respond in the same language as the user's message (English, Russian, or Kazakh)
- Keep responses concise and actionable"""


@router.post("/api/ai/chat", response_model=ChatResponse)
async def chat(
    body: ChatRequest,
    current_user: CurrentUser,
    db: DB,
) -> ChatResponse:
    """
    Proxies AI chat requests through the backend.
    iOS AIService sends its messages here instead of calling Claude directly,
    which keeps the API key server-side and allows conversation history storage.
    """
    if not settings.anthropic_api_key:
        raise HTTPException(503, "AI service not configured (missing ANTHROPIC_API_KEY)")

    # Load user profile for context
    result = await db.execute(
        select(UserProfile).where(UserProfile.user_id == current_user.id)
    )
    profile = result.scalar_one_or_none()

    # Build system prompt with user context
    system = _BEAUTY_SYSTEM
    if profile:
        system += f"\n\nUser Profile:\n{profile.ai_context_string}"

    # Convert iOS AIMessage format to Anthropic format
    # Filter out "system" role messages (Claude API doesn't accept them in messages array)
    api_messages = [
        {"role": m.role, "content": m.content}
        for m in body.messages
        if m.role in ("user", "assistant")
    ]

    if not api_messages:
        raise HTTPException(400, "No valid messages provided")

    try:
        client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)
        response = await client.messages.create(
            model=settings.claude_chat_model,
            max_tokens=2048,
            system=system,
            messages=api_messages,
        )

        content = response.content[0].text

        # Persist messages to DB for history
        user_msg = body.messages[-1]
        if user_msg.role == "user":
            db.add(ChatMessage(
                user_id=current_user.id,
                role="user",
                content=user_msg.content,
            ))
        db.add(ChatMessage(
            user_id=current_user.id,
            role="assistant",
            content=content,
        ))
        await db.commit()

        return ChatResponse(
            content=content,
            model=settings.claude_chat_model,
            usage={
                "input_tokens": response.usage.input_tokens,
                "output_tokens": response.usage.output_tokens,
            },
        )

    except anthropic.APIError as exc:
        logger.error(f"Claude API error: {exc}")
        raise HTTPException(502, f"AI service error: {exc.message}")


@router.get("/api/ai/recommendations", response_model=RecommendationsResponse)
async def get_recommendations(
    current_user: CurrentUser,
    db: DB,
) -> RecommendationsResponse:
    """
    RAG-powered recommendations based on user profile + existing product bag.
    Replaces the static ProductRecommendationEngine on iOS.
    """
    # Get profile
    result = await db.execute(
        select(UserProfile).where(UserProfile.user_id == current_user.id)
    )
    profile = result.scalar_one_or_none()
    if profile is None:
        return RecommendationsResponse(
            recommendations=[],
            profile_summary="No profile set up yet.",
            missing_routine_steps=["Complete onboarding to get personalized recommendations"],
        )

    # Get existing product categories
    prod_result = await db.execute(
        select(Product).where(
            Product.user_id == current_user.id,
            Product.is_active == True,
        )
    )
    products = prod_result.scalars().all()
    existing_categories = list({p.category for p in products})
    existing_ingredients = []
    for p in products[:5]:  # use first 5 products for ingredient context
        existing_ingredients.extend(p.ingredients_list or [])

    user_profile_dict = {
        "skin_type": profile.skin_type or "",
        "skin_conditions": profile.skin_conditions or [],
        "allergies": profile.allergies or [],
        "beauty_goals": profile.beauty_goals or [],
        "experience_level": profile.experience_level or "",
    }

    # RAG retrieval
    rag_context = rag_service.build_recommendation_context(
        user_profile=user_profile_dict,
        product_ingredients=existing_ingredients[:20],
        existing_categories=existing_categories,
    )

    # LLM-powered recommendation generation
    skin_type = profile.skin_type or "normal"
    conditions = ", ".join(profile.skin_conditions or []) or "none"
    goals = ", ".join(profile.beauty_goals or []) or "general skincare"

    prompt = f"""Based on this user's profile and their current product collection,
generate 5 personalized product recommendations.

User:
- Skin type: {skin_type}
- Conditions: {conditions}
- Goals: {goals}
- Experience: {profile.experience_level or 'beginner'}
- Existing product categories: {', '.join(existing_categories) or 'none yet'}

{rag_context[:2000]}

Generate 5 recommendations as a JSON array. Each object must have:
- product_name, brand, category, reason, priority (1-10), ingredient_synergy (array)

Also add after the array:
- "missing_steps": array of routine steps they are missing
- "profile_summary": one sentence about their skin profile

Return as: {{"recommendations": [...], "missing_steps": [...], "profile_summary": "..."}}"""

    try:
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
        data = json.loads(json_str)

        recs = [
            RecommendationItem(
                product_name=r.get("product_name", ""),
                brand=r.get("brand", "Various"),
                category=r.get("category", "other"),
                reason=r.get("reason", ""),
                priority=r.get("priority", 5),
                ingredient_synergy=r.get("ingredient_synergy", []),
            )
            for r in data.get("recommendations", [])
        ]

        return RecommendationsResponse(
            recommendations=recs,
            profile_summary=data.get("profile_summary", ""),
            missing_routine_steps=data.get("missing_steps", []),
        )

    except Exception as exc:
        logger.error(f"Recommendations generation failed: {exc}")
        # Return empty rather than 500
        return RecommendationsResponse(
            recommendations=[],
            profile_summary=f"{skin_type} skin profile",
            missing_routine_steps=[],
        )


@router.post("/recommendations", response_model=RecommendationsResponse)
async def recommendations_post(
    current_user: CurrentUser,
    db: DB,
) -> RecommendationsResponse:
    """Academic-requirement alias — POST /recommendations."""
    return await get_recommendations(current_user, db)
