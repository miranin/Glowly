"""
Product schemas — mirrors iOS Product model + adds AI analysis fields.
"""

from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field
from pydantic.alias_generators import to_camel


class _CamelModel(BaseModel):
    model_config = {"alias_generator": to_camel, "populate_by_name": True}


# ─── Category enum (English keys ↔ iOS Russian display values) ───────────────

class ProductCategory(str, Enum):
    foundation = "foundation"
    concealer = "concealer"
    powder = "powder"
    blush = "blush"
    bronzer = "bronzer"
    highlighter = "highlighter"
    eyeshadow = "eyeshadow"
    eyeliner = "eyeliner"
    mascara = "mascara"
    lipstick = "lipstick"
    lip_gloss = "lip_gloss"
    lip_liner = "lip_liner"
    primer = "primer"
    setting_spray = "setting_spray"
    cleanser = "cleanser"
    toner = "toner"
    moisturizer = "moisturizer"
    serum = "serum"
    sunscreen = "sunscreen"
    mask = "mask"
    exfoliant = "exfoliant"
    eye_cream = "eye_cream"
    other = "other"


class ApplicationZone(str, Enum):
    face = "face"
    eyes = "eyes"
    lips = "lips"
    cheeks = "cheeks"
    body = "body"
    hair = "hair"
    hands = "hands"
    feet = "feet"
    nails = "nails"
    neck = "neck"
    decolletage = "decolletage"


# ─── AI analysis result ───────────────────────────────────────────────────────

class AnalyzedProduct(_CamelModel):
    """
    Structured output returned by the vision pipeline.
    This is what the iOS app receives in the /analyze-product response.
    """
    brand: str = ""
    product_name: str = ""
    category: ProductCategory = ProductCategory.other
    application_zone: ApplicationZone = ApplicationZone.face

    # Rich descriptive fields
    product_description: str = ""
    key_ingredients: list[str] = []
    ingredients: list[str] = []
    ingredients_raw: str = ""
    skin_types: list[str] = []
    detected_concerns: list[str] = []
    usage_time: str = "both"

    # Usage guidance
    how_to_use: str = ""
    benefits: list[str] = []
    warnings: list[str] = []

    # Safety flags
    is_sensitive_safe: bool = False
    is_acne_safe: bool = True

    # Confidence
    confidence: float = Field(0.0, ge=0.0, le=1.0)
    needs_confirmation: bool = False
    reasoning: str = ""

    # Provenance (Step 3 web enrichment)
    data_source: str = "vision"   # "vision" | "web" | "cache"
    source_url: str = ""

    # Raw outputs preserved for debugging
    ocr_text: str = ""
    ai_raw_description: str = ""


class ProductCreate(_CamelModel):
    name: str
    brand: str
    category: ProductCategory
    application_zone: ApplicationZone = ApplicationZone.face
    ingredients: str = ""
    ingredients_list: list[str] = []
    how_to_use: str = ""
    benefits: list[str] = []
    warnings: list[str] = []
    notes: str = ""
    barcode: str | None = None
    is_sensitive_safe: bool = False
    is_acne_safe: bool = True
    purchase_date: datetime | None = None
    ai_confidence: float = 0.0


class ProductUpdate(_CamelModel):
    name: str | None = None
    brand: str | None = None
    category: ProductCategory | None = None
    application_zone: ApplicationZone | None = None
    ingredients: str | None = None
    ingredients_list: list[str] | None = None
    how_to_use: str | None = None
    benefits: list[str] | None = None
    warnings: list[str] | None = None
    notes: str | None = None
    is_active: bool | None = None
    is_sensitive_safe: bool | None = None
    is_acne_safe: bool | None = None


class ProductResponse(_CamelModel):
    id: str
    user_id: str
    name: str
    brand: str
    category: str
    application_zone: str | None = None
    ingredients: str = ""
    ingredients_list: list[str] = []
    how_to_use: str = ""
    benefits: list[str] = []
    warnings: list[str] = []
    notes: str = ""
    barcode: str | None = None
    is_sensitive_safe: bool = False
    is_acne_safe: bool = True
    is_active: bool = True
    ai_confidence: float = 0.0
    needs_confirmation: bool = False
    purchase_date: datetime | None = None
    created_at: datetime
    updated_at: datetime


# ─── Analysis pipeline response ───────────────────────────────────────────────

class AnalyzeProductResponse(_CamelModel):
    """Full response from POST /analyze-product including saved product + recs."""
    analyzed_product: AnalyzedProduct
    saved_product: ProductResponse | None = None      # None if needs_confirmation
    recommendations: list[dict] = []
    workflow_steps: list[str] = []                    # for LangSmith debugging UI
