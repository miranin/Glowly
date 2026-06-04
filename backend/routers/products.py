"""
Products router.

POST /api/products/analyze-image  — main AI pipeline (multipart image upload)
GET  /api/products                — list user's products
POST /api/products                — manually create product
GET  /api/products/{id}           — single product
PUT  /api/products/{id}           — update (used after human_confirmation)
DELETE /api/products/{id}         — delete

Also exposes the canonical academic route:
POST /analyze-product             — alias for /api/products/analyze-image
POST /users/profile               — save/update user profile
"""

import logging
from datetime import datetime

from fastapi import APIRouter, File, HTTPException, UploadFile, status
from sqlalchemy import select

from database.models import Product, UserProfile
from routers.deps import CurrentUser, DB
from schemas.product import (
    AnalyzeProductResponse,
    AnalyzedProduct,
    ProductCategory,
    ProductCreate,
    ProductResponse,
    ProductUpdate,
)
from schemas.auth import UserProfileRequest, UserProfileResponse
from services.langgraph_agent import run_analysis_workflow

logger = logging.getLogger(__name__)

router = APIRouter(tags=["products"])

# Max upload size: 10 MB
MAX_IMAGE_BYTES = 10 * 1024 * 1024

ALLOWED_MIME_TYPES = {
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
    "image/heic",
}

# Media types Claude vision accepts
_CLAUDE_MEDIA_TYPES = {"image/jpeg", "image/png", "image/gif", "image/webp"}


def _sniff_media_type(data: bytes, fallback: str = "image/jpeg") -> str:
    """
    Determine the real image media type from magic bytes.
    iOS multipart uploads send 'application/octet-stream', so the declared
    Content-Type is unreliable — inspect the actual bytes instead.
    """
    if len(data) < 12:
        return fallback
    if data[:3] == b"\xff\xd8\xff":
        return "image/jpeg"
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        return "image/png"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "image/webp"
    if data[:4] in (b"GIF8",):
        return "image/gif"
    # HEIC/HEIF — Claude can't read these; the iOS app converts to JPEG before
    # upload, so this is a safety net only.
    if data[4:8] == b"ftyp":
        return fallback
    return fallback


# ─── helpers ──────────────────────────────────────────────────────────────────

def _db_product_to_response(p: Product) -> ProductResponse:
    return ProductResponse(
        id=p.id,
        user_id=p.user_id,
        name=p.name,
        brand=p.brand,
        category=p.category,
        application_zone=p.application_zone,
        ingredients=p.ingredients or "",
        ingredients_list=p.ingredients_list or [],
        how_to_use=p.how_to_use or "",
        benefits=p.benefits or [],
        warnings=p.warnings or [],
        notes=p.notes or "",
        barcode=p.barcode,
        is_sensitive_safe=p.is_sensitive_safe,
        is_acne_safe=p.is_acne_safe,
        is_active=p.is_active,
        ai_confidence=p.ai_confidence,
        needs_confirmation=p.needs_confirmation,
        purchase_date=p.purchase_date,
        created_at=p.created_at,
        updated_at=p.updated_at,
    )


def _get_profile_dict(profile: UserProfile | None) -> dict:
    if profile is None:
        return {}
    return {
        "skin_type": profile.skin_type or "",
        "skin_conditions": profile.skin_conditions or [],
        "allergies": profile.allergies or [],
        "beauty_goals": profile.beauty_goals or [],
        "experience_level": profile.experience_level or "",
        "makeup_frequency": profile.makeup_frequency or "",
    }


# ─── Image analysis (main AI pipeline) ────────────────────────────────────────

async def _run_analysis(
    file: UploadFile,
    current_user,
    db,
) -> AnalyzeProductResponse:
    """Shared implementation for both /api/products/analyze-image and /analyze-product."""
    content_type = file.content_type or "image/jpeg"
    if content_type not in ALLOWED_MIME_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"Unsupported image type: {content_type}. Allowed: {ALLOWED_MIME_TYPES}",
        )

    image_bytes = await file.read()
    if len(image_bytes) > MAX_IMAGE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Image too large. Maximum 10 MB.",
        )

    # Load user profile for context injection
    result = await db.execute(
        select(UserProfile).where(UserProfile.user_id == current_user.id)
    )
    profile = result.scalar_one_or_none()
    user_profile_dict = _get_profile_dict(profile)

    logger.info(
        f"Starting analysis pipeline for user={current_user.id}, "
        f"image_size={len(image_bytes)} bytes"
    )

    # Run LangGraph workflow
    final_state = await run_analysis_workflow(
        image_bytes=image_bytes,
        media_type=content_type,
        user_id=current_user.id,
        user_profile=user_profile_dict,
    )

    if final_state.get("error"):
        logger.error(f"Workflow error: {final_state['error']}")

    product_data = final_state.get("analyzed_product") or {}
    analyzed = _dict_to_analyzed_product(product_data)
    recommendations = final_state.get("recommendations", [])
    steps = final_state.get("workflow_steps", [])

    saved_product_response = None

    # Auto-save if confidence is sufficient
    if not analyzed.needs_confirmation and analyzed.product_name:
        db_product = Product(
            user_id=current_user.id,
            name=analyzed.product_name,
            brand=analyzed.brand,
            category=analyzed.category.value,
            application_zone=analyzed.application_zone.value,
            ingredients=analyzed.ingredients_raw,
            ingredients_list=analyzed.ingredients,
            how_to_use=analyzed.how_to_use,
            benefits=analyzed.benefits,
            warnings=analyzed.warnings,
            is_sensitive_safe=analyzed.is_sensitive_safe,
            is_acne_safe=analyzed.is_acne_safe,
            ai_confidence=analyzed.confidence,
            needs_confirmation=False,
            ai_raw_description=analyzed.ai_raw_description,
        )
        db.add(db_product)
        await db.commit()
        await db.refresh(db_product)
        saved_product_response = _db_product_to_response(db_product)
        logger.info(f"Auto-saved product '{analyzed.product_name}' for user {current_user.id}")
    elif analyzed.needs_confirmation:
        # Save as pending-confirmation placeholder
        db_product = Product(
            user_id=current_user.id,
            name=analyzed.product_name or "Unknown Product",
            brand=analyzed.brand or "Unknown Brand",
            category=analyzed.category.value,
            application_zone=analyzed.application_zone.value,
            ingredients=analyzed.ingredients_raw,
            ingredients_list=analyzed.ingredients,
            ai_confidence=analyzed.confidence,
            needs_confirmation=True,
            ai_raw_description=analyzed.ai_raw_description,
            is_active=False,   # not shown until confirmed
        )
        db.add(db_product)
        await db.commit()
        await db.refresh(db_product)
        saved_product_response = _db_product_to_response(db_product)

    return AnalyzeProductResponse(
        analyzed_product=analyzed,
        saved_product=saved_product_response,
        recommendations=recommendations,
        workflow_steps=steps,
    )


def _dict_to_analyzed_product(d: dict) -> AnalyzedProduct:
    if not d:
        return AnalyzedProduct(confidence=0.0, needs_confirmation=True)
    try:
        cat_val = d.get("category", "other")
        cat = ProductCategory(cat_val) if cat_val in ProductCategory._value2member_map_ else ProductCategory.other
    except Exception:
        cat = ProductCategory.other

    from schemas.product import ApplicationZone
    try:
        zone_val = d.get("application_zone", "face")
        zone = ApplicationZone(zone_val) if zone_val in ApplicationZone._value2member_map_ else ApplicationZone.face
    except Exception:
        zone = ApplicationZone.face

    return AnalyzedProduct(
        brand=d.get("brand", ""),
        product_name=d.get("product_name", ""),
        category=cat,
        application_zone=zone,
        product_description=d.get("product_description", ""),
        key_ingredients=d.get("key_ingredients", []),
        ingredients=d.get("ingredients", []),
        ingredients_raw=d.get("ingredients_raw", ""),
        skin_types=d.get("skin_types", []),
        detected_concerns=d.get("detected_concerns", []),
        usage_time=d.get("usage_time", "both"),
        how_to_use=d.get("how_to_use", ""),
        benefits=d.get("benefits", []),
        warnings=d.get("warnings", []),
        is_sensitive_safe=d.get("is_sensitive_safe", False),
        is_acne_safe=d.get("is_acne_safe", True),
        confidence=d.get("confidence", 0.0),
        needs_confirmation=d.get("needs_confirmation", True),
        reasoning=d.get("reasoning", ""),
        ocr_text=d.get("ocr_text", ""),
        ai_raw_description=d.get("ai_raw_description", ""),
    )


# ─── Routes ───────────────────────────────────────────────────────────────────

@router.post("/api/products/analyze", response_model=AnalyzedProduct)
async def analyze_product_public(
    file: UploadFile = File(...),
) -> AnalyzedProduct:
    """
    Public endpoint — no auth required. Returns AI analysis without saving to DB.
    Used by iOS for the image → confirmation flow. The iOS app saves the product
    locally after user confirms the pre-filled form.
    Accepts multipart/form-data with field name 'file'.
    """
    from services.vision_service import vision_service as vs

    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Empty file")
    if len(image_bytes) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=413, detail="Image too large (max 10 MB)")

    # iOS multipart sends 'application/octet-stream'; determine the real type
    # from the bytes instead of trusting the declared Content-Type.
    media_type = _sniff_media_type(image_bytes, fallback="image/jpeg")
    if media_type not in _CLAUDE_MEDIA_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"Unsupported image format (detected: {media_type}). Use JPEG or PNG.",
        )

    logger.info(
        f"Public analyze: image_size={len(image_bytes)} bytes, "
        f"declared={file.content_type}, sniffed={media_type}"
    )
    try:
        _, _, product = await vs.analyze_image(image_bytes, media_type=media_type)
    except Exception as exc:
        # Surface common misconfigurations with actionable messages
        name = type(exc).__name__
        if name == "AuthenticationError":
            logger.error("Anthropic API key invalid or missing — set ANTHROPIC_API_KEY in backend/.env")
            raise HTTPException(
                status_code=503,
                detail="AI service unavailable: invalid or missing ANTHROPIC_API_KEY on the server.",
            )
        logger.error(f"Public analyze failed: {name}: {exc}")
        raise HTTPException(status_code=502, detail=f"Analysis failed: {name}")
    return product


@router.post("/api/products/analyze-image", response_model=AnalyzeProductResponse)
async def analyze_product_image(
    file: UploadFile = File(...),
    current_user: CurrentUser = None,
    db: DB = None,
) -> AnalyzeProductResponse:
    """
    Authenticated endpoint: image → AI analysis → auto-save → recommendations.
    Accepts multipart/form-data with field name 'file'.
    """
    return await _run_analysis(file, current_user, db)


@router.post("/analyze-product", response_model=AnalyzeProductResponse)
async def analyze_product_academic(
    file: UploadFile = File(...),
    current_user: CurrentUser = None,
    db: DB = None,
) -> AnalyzeProductResponse:
    """Academic-requirement alias for /api/products/analyze-image."""
    return await _run_analysis(file, current_user, db)


@router.get("/api/products", response_model=list[ProductResponse])
async def list_products(
    current_user: CurrentUser,
    db: DB,
    active_only: bool = True,
) -> list[ProductResponse]:
    """Returns all products in the user's cosmetic bag."""
    query = select(Product).where(Product.user_id == current_user.id)
    if active_only:
        query = query.where(Product.is_active == True)
    result = await db.execute(query.order_by(Product.created_at.desc()))
    products = result.scalars().all()
    return [_db_product_to_response(p) for p in products]


@router.post("/api/products", response_model=ProductResponse, status_code=201)
async def create_product(
    body: ProductCreate,
    current_user: CurrentUser,
    db: DB,
) -> ProductResponse:
    """Manually create a product (no AI — user fills in the form)."""
    product = Product(
        user_id=current_user.id,
        name=body.name,
        brand=body.brand,
        category=body.category.value,
        application_zone=body.application_zone.value,
        ingredients=body.ingredients,
        ingredients_list=body.ingredients_list,
        how_to_use=body.how_to_use,
        benefits=body.benefits,
        warnings=body.warnings,
        notes=body.notes,
        barcode=body.barcode,
        is_sensitive_safe=body.is_sensitive_safe,
        is_acne_safe=body.is_acne_safe,
        ai_confidence=body.ai_confidence,
        purchase_date=body.purchase_date,
    )
    db.add(product)
    await db.commit()
    await db.refresh(product)
    return _db_product_to_response(product)


@router.get("/api/products/{product_id}", response_model=ProductResponse)
async def get_product(
    product_id: str,
    current_user: CurrentUser,
    db: DB,
) -> ProductResponse:
    result = await db.execute(
        select(Product).where(Product.id == product_id, Product.user_id == current_user.id)
    )
    product = result.scalar_one_or_none()
    if product is None:
        raise HTTPException(404, "Product not found")
    return _db_product_to_response(product)


@router.put("/api/products/{product_id}", response_model=ProductResponse)
async def update_product(
    product_id: str,
    body: ProductUpdate,
    current_user: CurrentUser,
    db: DB,
) -> ProductResponse:
    """
    Used by iOS when the user confirms/corrects an AI analysis result
    (human_confirmation branch). Sets needs_confirmation=False and is_active=True.
    """
    result = await db.execute(
        select(Product).where(Product.id == product_id, Product.user_id == current_user.id)
    )
    product = result.scalar_one_or_none()
    if product is None:
        raise HTTPException(404, "Product not found")

    update_data = body.model_dump(exclude_none=True)
    for field, value in update_data.items():
        if hasattr(product, field):
            if isinstance(value, ProductCategory):
                setattr(product, field, value.value)
            else:
                setattr(product, field, value)

    # If being confirmed, activate it
    if product.needs_confirmation:
        product.needs_confirmation = False
        product.is_active = True

    await db.commit()
    await db.refresh(product)
    return _db_product_to_response(product)


@router.delete("/api/products/{product_id}", status_code=204)
async def delete_product(
    product_id: str,
    current_user: CurrentUser,
    db: DB,
) -> None:
    result = await db.execute(
        select(Product).where(Product.id == product_id, Product.user_id == current_user.id)
    )
    product = result.scalar_one_or_none()
    if product is None:
        raise HTTPException(404, "Product not found")
    await db.delete(product)
    await db.commit()


# ─── User profile ─────────────────────────────────────────────────────────────

@router.post("/users/profile", response_model=UserProfileResponse)
async def upsert_user_profile(
    body: UserProfileRequest,
    current_user: CurrentUser,
    db: DB,
) -> UserProfileResponse:
    """
    Create or update the user's skin profile.
    Called after the iOS onboarding flow completes.
    """
    result = await db.execute(
        select(UserProfile).where(UserProfile.user_id == current_user.id)
    )
    profile = result.scalar_one_or_none()

    if profile is None:
        profile = UserProfile(user_id=current_user.id)
        db.add(profile)

    for field, value in body.model_dump().items():
        if hasattr(profile, field):
            setattr(profile, field, value)

    await db.commit()
    await db.refresh(profile)

    return UserProfileResponse(
        id=profile.id,
        user_id=profile.user_id,
        age_range=profile.age_range,
        sex=profile.sex,
        skin_type=profile.skin_type,
        skin_tone=profile.skin_tone,
        skin_conditions=profile.skin_conditions or [],
        allergies=profile.allergies or [],
        sensitivities=profile.sensitivities or [],
        experience_level=profile.experience_level,
        beauty_goals=profile.beauty_goals or [],
        preferred_brands=profile.preferred_brands or [],
        makeup_frequency=profile.makeup_frequency,
        skincare_routine_complexity=profile.skincare_routine_complexity,
        has_completed_onboarding=profile.has_completed_onboarding,
    )


@router.get("/users/profile", response_model=UserProfileResponse)
async def get_user_profile(current_user: CurrentUser, db: DB) -> UserProfileResponse:
    result = await db.execute(
        select(UserProfile).where(UserProfile.user_id == current_user.id)
    )
    profile = result.scalar_one_or_none()
    if profile is None:
        raise HTTPException(404, "Profile not found. Complete onboarding first.")
    return UserProfileResponse(
        id=profile.id,
        user_id=profile.user_id,
        age_range=profile.age_range,
        sex=profile.sex,
        skin_type=profile.skin_type,
        skin_tone=profile.skin_tone,
        skin_conditions=profile.skin_conditions or [],
        allergies=profile.allergies or [],
        sensitivities=profile.sensitivities or [],
        experience_level=profile.experience_level,
        beauty_goals=profile.beauty_goals or [],
        preferred_brands=profile.preferred_brands or [],
        makeup_frequency=profile.makeup_frequency,
        skincare_routine_complexity=profile.skincare_routine_complexity,
        has_completed_onboarding=profile.has_completed_onboarding,
    )
