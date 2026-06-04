"""
Glowly Product Analysis Engine — multimodal vision service.

Pipeline (follows user-specified system prompt architecture):
  Step 1  Extract product identity via Claude vision (OCR + visual reasoning)
  Step 2  Search vector DB (product cache) — return immediately on cache HIT (≥ 0.88)
  Step 3  Web enrichment  [stub — not implemented in MVP; Claude knowledge used instead]
  Step 4  Store result in vector DB product cache for future instant lookups
  Step 5  Return structured AnalyzedProduct to caller

All LangSmith tracing is automatic via LANGCHAIN_TRACING_V2 env var.
"""

import base64
import json
import logging
import re
from typing import Any

import anthropic

from config import settings
from schemas.product import AnalyzedProduct, ApplicationZone, ProductCategory

logger = logging.getLogger(__name__)

_client: anthropic.AsyncAnthropic | None = None


def _get_client() -> anthropic.AsyncAnthropic:
    global _client
    if _client is None:
        _client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)
    return _client


# ─── System prompt ────────────────────────────────────────────────────────────

_SYSTEM = """\
You are Glowly's AI product analysis engine. Your job is to identify beauty/skincare
products from photos and return structured, detailed product information to users.

You have encyclopedic knowledge of global beauty brands (drugstore to luxury):
La Roche-Posay, CeraVe, Dr.Jart+, COSRX, Laneige, The Ordinary, Drunk Elephant,
Charlotte Tilbury, MAC, Fenty Beauty, NARS, L'Oréal, Maybelline, Neutrogena,
Cetaphil, Olay, Bioré, SK-II, Tatcha, Paula's Choice, Supergoop!, EltaMD, and many more.

You know brand visual identities:
- Dr.Jart+ = red cross logo on white tube/pump
- La Roche-Posay = gold lettering, clinical white
- CeraVe = blue/white pump with "CeraVe" wordmark
- The Ordinary = minimal black text on white/clear
- COSRX = clean Korean minimalist, often beige/white
- Charlotte Tilbury = gold/dark luxe packaging
- MAC = sleek black with "M·A·C" logo

You also know INCI ingredient names, their roles, and skin compatibility.
You read packaging in English, French, Korean, Japanese, Russian, German, Spanish, Chinese.

RULES (follow strictly):
- NEVER hallucinate product details. Read what is actually on the label.
- Brand: read the logo text carefully. 'Dr.Jart+' has a red + sign. 'MAC' is all caps.
  NEVER set brand='Mac' just because 'mac' appears somewhere in OCR text.
- key_ingredients: list each active ingredient WITH its function.
  Format: "Ingredient Name — what it does for skin"
- confidence: 0.95 = clearly readable full label; 0.7 = partially readable;
  0.4 = blurry/obscured; 0.1 = not a cosmetic product at all.
- If not a cosmetic: set confidence=0.05, category='other', brand and product_name empty.
- Respond ONLY with valid JSON. No markdown fences. No text before or after.\
"""

# ─── Combined analysis prompt ─────────────────────────────────────────────────

_COMBINED_PROMPT = """\
Analyze this cosmetic product image. Work through these steps mentally, then output only the JSON:

STEP 1 — TEXT EXTRACTION
Read every text element visible on the packaging, from most prominent to smallest:
brand logo, product line name, product type descriptor, volume/size, key claims,
ingredient highlights, directions, warnings.

STEP 2 — VISUAL IDENTITY
If text is partially obscured or in another language, use visual cues:
logo shape, color scheme, packaging design language to confirm the brand.
Korean brands (Dr.Jart+, COSRX, Laneige) → minimalist packaging.
French pharmacy brands (La Roche-Posay, Bioderma, Avène) → clinical white.
Luxury brands (Charlotte Tilbury, Tatcha) → gold/black.

STEP 3 — INGREDIENT & USAGE ENRICHMENT
For recognized products, use your knowledge to fill in likely key ingredients and
skin suitability — but clearly flag inferred vs. directly readable items in reasoning.
Never invent specific percentages. Provide ingredient ROLES (what each does).

CATEGORY DISAMBIGUATION (pick the single most precise category):
- cleanser: foaming/gel/cream/oil/balm that you rinse off to wash the face
- toner: thin watery liquid applied after cleansing to rebalance/prep skin
- essence: lightweight hydrating liquid (often Korean), thicker than toner, before serum
- serum: concentrated active treatment (vitamin C, retinol, niacinamide, peptides)
- moisturizer: cream/lotion/gel that seals hydration (the last leave-on step)
- eye_cream: small jar/tube specifically for the eye area
- oil: facial oil (rosehip, squalane, marula) — leave-on, oily texture
- exfoliant: AHA/BHA/PHA chemical or physical scrub that removes dead skin
- spot_treatment: small targeted acne/blemish product (BPO, salicylic spot gel)
- mist: spray/face mist in a fine-spray bottle
- sunscreen: SPF / UV protection (look for "SPF", "PA+++", "sunscreen", "UV")
- mask: sheet mask, wash-off mask, sleeping mask, clay mask
- lip_care: lip balm, lip mask, lip treatment
If genuinely ambiguous, choose the category implied by the product's primary FUNCTION.

Return ONLY this JSON object:
{
  "brand": "Exact brand name from logo. E.g. 'Dr.Jart+' not 'Dr Jart'. Empty string only if truly unreadable.",
  "product_name": "Product name WITHOUT brand prefix. E.g. 'Dermaclear Microfoam Cleansing Foam'. Use packaging text.",
  "category": "Exactly one of: cleanser | toner | serum | moisturizer | sunscreen | exfoliant | eye_cream | mask | lip_care | spot_treatment | mist | essence | oil | foundation | concealer | powder | blush | bronzer | highlighter | eyeshadow | eyeliner | mascara | lipstick | lip_gloss | lip_liner | primer | setting_spray | other",
  "application_zone": "Exactly one of: face | eyes | lips | body | hair | hands | nails",
  "product_description": "3-5 sentences: what this product is, what it does, and who it is best suited for. Be specific and ingredient-focused.",
  "key_ingredients": [
    "Ingredient Name — its specific role and benefit for skin. E.g. 'Niacinamide — brightening, minimizes pores, regulates sebum'",
    "Another Ingredient — its role"
  ],
  "ingredients_raw": "Full INCI ingredient list exactly as printed on packaging. Empty string if not readable.",
  "skin_types": ["Applicable from: oily | dry | combination | sensitive | normal | all | acne_prone | mature"],
  "detected_concerns": ["Skin concerns addressed from: acne | aging | dryness | hyperpigmentation | pores | redness | sensitivity | brightening | firmness | dark_circles"],
  "usage_time": "morning | night | both",
  "how_to_use": "Step-by-step application instructions. Use packaging text if visible, otherwise provide standard instructions for this product type.",
  "benefits": ["3-5 specific benefits based on visible claims or product knowledge. Be concrete."],
  "warnings": ["Safety cautions from packaging or typical for this ingredient profile. E.g. 'Avoid eye contact', 'Use SPF during day if using AHAs'"],
  "is_sensitive_safe": true or false,
  "is_acne_safe": true or false,
  "confidence": 0.0 to 1.0,
  "reasoning": "1-2 sentences: how you identified the brand and product, what was directly readable vs. inferred from product knowledge."
}"""

# Text-only classification prompt — used by the evaluation harness (and as a
# fallback path). Takes a vision description + OCR text instead of an image, so
# the golden-dataset evals run deterministically and cheaply without images.
_CLASSIFICATION_TEMPLATE = """You are classifying a cosmetic product from a text description and OCR'd label text.

VISION DESCRIPTION:
{vision}

OCR TEXT FROM LABEL:
{ocr}

Based on the above, return ONLY this JSON (no markdown, no extra text):
{{
  "brand": "Exact brand name. Empty string if unknown.",
  "product_name": "Product name without brand prefix.",
  "category": "Exactly one of: cleanser | toner | serum | moisturizer | sunscreen | exfoliant | eye_cream | mask | lip_care | spot_treatment | mist | essence | oil | foundation | concealer | powder | blush | bronzer | highlighter | eyeshadow | eyeliner | mascara | lipstick | lip_gloss | lip_liner | primer | setting_spray | other",
  "application_zone": "Exactly one of: face | eyes | lips | body | hair | hands | nails",
  "key_ingredients": ["Ingredient — role"],
  "skin_types": ["oily | dry | combination | sensitive | normal | all | acne_prone | mature"],
  "detected_concerns": ["acne | aging | dryness | hyperpigmentation | pores | redness | sensitivity | brightening | firmness | dark_circles"],
  "is_sensitive_safe": true or false,
  "is_acne_safe": true or false,
  "confidence": 0.0 to 1.0,
  "reasoning": "1 sentence on how you classified it."
}}

Rules:
- Read the brand carefully from the OCR text. Never keyword-match (e.g. don't output 'Mac' just because 'mac' appears in another word).
- If the text clearly isn't a cosmetic product, set confidence=0.05 and category='other'.
- confidence reflects how clear the label text is: full clear label ≥ 0.9, partial ~0.6, barely readable ≤ 0.4."""


# ─── Main service ─────────────────────────────────────────────────────────────

class VisionService:
    """
    Product analysis pipeline:
      1. Extract product identity via Claude claude-sonnet-4-6 vision
      2. Search Qdrant product cache (skip Claude if cache hit ≥ 0.88)
      3. [Web scraping — future, not MVP]
      4. Store result in product cache
      5. Return AnalyzedProduct
    """

    async def analyze_image(
        self,
        image_data: bytes,
        media_type: str = "image/jpeg",
    ) -> tuple[str, str, AnalyzedProduct]:
        """
        Full pipeline. Returns (vision_description, ocr_text, structured_product).
        Tuple shape kept for LangGraph node compatibility.
        """
        # ── Step 1: Claude vision analysis ───────────────────────────────────
        image_b64 = base64.standard_b64encode(image_data).decode("utf-8")
        product = await self._claude_analysis(image_b64, media_type)

        # ── Step 2: Check product cache AFTER we have brand + name ───────────
        #    If we get a very high-confidence cached result, enrich/override low-conf fields
        if product.brand or product.product_name:
            cache_hit = self._check_product_cache(product.brand, product.product_name)
            if cache_hit:
                product = _merge_with_cache(product, cache_hit)

        # ── Step 3: Web enrichment — scrape full INCI list if not on the label ─
        #    Only when we have a confident identity but the photo didn't show the
        #    full ingredient list. Skips the network call when already complete.
        if (
            product.confidence >= 0.55
            and (product.brand or product.product_name)
            and len(product.ingredients_raw) < 40  # label list not captured
        ):
            await self._web_enrich(product)

        # ── Step 4: Store in product cache (if confidence good enough) ────────
        if product.confidence >= 0.6 and (product.brand or product.product_name):
            self._store_in_cache(product)

        vision_description = product.reasoning
        ocr_text = product.ingredients_raw or ""
        return vision_description, ocr_text, product

    # ─── Private methods ──────────────────────────────────────────────────────

    async def _claude_analysis(self, image_b64: str, media_type: str) -> AnalyzedProduct:
        """Single-pass Claude call: vision + OCR + classification."""
        client = _get_client()
        response = await client.messages.create(
            model=settings.claude_vision_model,
            max_tokens=1800,
            system=_SYSTEM,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": media_type,
                                "data": image_b64,
                            },
                        },
                        {"type": "text", "text": _COMBINED_PROMPT},
                    ],
                }
            ],
        )
        raw = response.content[0].text
        return _parse_product_json(raw)

    async def _web_enrich(self, product: AnalyzedProduct) -> None:
        """
        Step 3: scrape INCIDecoder for the full ingredient list and merge it in.
        Mutates `product` in place. Non-fatal — leaves vision data untouched on failure.
        """
        try:
            from services.scraper_service import scraper_service
            scraped = await scraper_service.enrich(product.brand, product.product_name)
            if scraped and scraped.found:
                product.ingredients_raw = ", ".join(scraped.full_ingredients)
                product.ocr_text = product.ingredients_raw
                product.source_url = scraped.source_url
                product.data_source = "web"
                # Confidence in the product *identity* is unchanged, but a verified
                # ingredient list is a strong positive signal.
                product.confidence = min(1.0, product.confidence + 0.03)
        except Exception as exc:
            logger.debug(f"[vision] web enrich skipped: {exc}")

    def _check_product_cache(self, brand: str, product_name: str) -> dict | None:
        """Search Qdrant product cache. Returns payload dict or None."""
        try:
            from services.rag_service import rag_service
            query = f"{brand} {product_name}".strip()
            return rag_service.search_product_cache(query)
        except Exception as exc:
            logger.debug(f"[vision] product cache lookup skipped: {exc}")
            return None

    def _store_in_cache(self, product: AnalyzedProduct) -> None:
        """Serialize AnalyzedProduct and store in Qdrant product cache."""
        try:
            from services.rag_service import rag_service
            rag_service.store_product_in_cache(product.model_dump(mode="json"))
        except Exception as exc:
            logger.debug(f"[vision] product cache store skipped: {exc}")


def _merge_with_cache(
    fresh: AnalyzedProduct, cached: dict[str, Any]
) -> AnalyzedProduct:
    """
    Merge fresh Claude analysis with cached data.
    Fresh data wins for confidence and brand/name (OCR is authoritative).
    Cached data fills in empty fields (ingredients, description, etc.).
    """
    def pick(fresh_val, cached_val):
        if fresh_val:
            return fresh_val
        return cached_val or fresh_val

    cached_confidence = cached.get("confidence", 0.0)
    # Only use cached data if cache entry itself was high-confidence
    if cached_confidence < 0.7:
        return fresh

    logger.info(
        f"[vision] enriching from product cache: "
        f"'{cached.get('brand')} {cached.get('product_name')}'"
    )

    raw_cat = cached.get("category", "other")
    try:
        cached_category = ProductCategory(raw_cat)
    except ValueError:
        cached_category = fresh.category

    raw_zone = cached.get("application_zone", "face")
    try:
        cached_zone = ApplicationZone(raw_zone)
    except ValueError:
        cached_zone = fresh.application_zone

    return AnalyzedProduct(
        brand=pick(fresh.brand, cached.get("brand", "")),
        product_name=pick(fresh.product_name, cached.get("product_name", "")),
        category=fresh.category if fresh.category != ProductCategory.other else cached_category,
        application_zone=fresh.application_zone if fresh.application_zone != ApplicationZone.face else cached_zone,
        product_description=pick(fresh.product_description, cached.get("product_description", "")),
        key_ingredients=fresh.key_ingredients or cached.get("key_ingredients", []),
        ingredients=fresh.ingredients or cached.get("ingredients", []),
        ingredients_raw=pick(fresh.ingredients_raw, cached.get("ingredients_raw", "")),
        skin_types=fresh.skin_types or cached.get("skin_types", []),
        detected_concerns=fresh.detected_concerns or cached.get("detected_concerns", []),
        usage_time=fresh.usage_time,
        how_to_use=pick(fresh.how_to_use, cached.get("how_to_use", "")),
        benefits=fresh.benefits or cached.get("benefits", []),
        warnings=fresh.warnings or cached.get("warnings", []),
        is_sensitive_safe=fresh.is_sensitive_safe,
        is_acne_safe=fresh.is_acne_safe,
        confidence=max(fresh.confidence, cached_confidence * 0.9),
        needs_confirmation=fresh.needs_confirmation,
        reasoning=fresh.reasoning + " ⓘ Loaded from Glowly database." if cached else fresh.reasoning,
        ocr_text=fresh.ocr_text or cached.get("ocr_text", ""),
        ai_raw_description=fresh.ai_raw_description or cached.get("ai_raw_description", ""),
    )


def _parse_product_json(raw: str) -> AnalyzedProduct:
    """Parse JSON from model output, handle edge cases gracefully."""
    match = re.search(r"```(?:json)?\s*([\s\S]*?)```", raw)
    json_str = match.group(1).strip() if match else raw.strip()

    obj_match = re.search(r"\{[\s\S]*\}", json_str)
    if obj_match:
        json_str = obj_match.group(0)

    try:
        data: dict[str, Any] = json.loads(json_str)
    except json.JSONDecodeError:
        logger.warning("Failed to parse vision JSON; returning low-confidence fallback.")
        return AnalyzedProduct(confidence=0.1, needs_confirmation=True)

    raw_cat = data.get("category", "other").lower().replace(" ", "_").replace("-", "_")
    try:
        category = ProductCategory(raw_cat)
    except ValueError:
        category = ProductCategory.other

    raw_zone = data.get("application_zone", "face").lower()
    try:
        zone = ApplicationZone(raw_zone)
    except ValueError:
        zone = ApplicationZone.face

    confidence = max(0.0, min(1.0, float(data.get("confidence", 0.5))))

    # key_ingredients: accept both ["Ingredient — role"] strings and {"name":..,"role":..} dicts
    raw_ingredients = data.get("key_ingredients", [])
    key_ingredients: list[str] = []
    for item in raw_ingredients:
        if isinstance(item, dict):
            name = item.get("name", "")
            role = item.get("role", "")
            key_ingredients.append(f"{name} — {role}" if role else name)
        elif isinstance(item, str):
            key_ingredients.append(item)

    return AnalyzedProduct(
        brand=data.get("brand", ""),
        product_name=data.get("product_name", ""),
        category=category,
        application_zone=zone,
        product_description=data.get("product_description", ""),
        key_ingredients=key_ingredients,
        ingredients=key_ingredients,
        ingredients_raw=data.get("ingredients_raw", ""),
        skin_types=data.get("skin_types", []),
        detected_concerns=data.get("detected_concerns", []),
        usage_time=data.get("usage_time", "both"),
        how_to_use=data.get("how_to_use", ""),
        benefits=data.get("benefits", []),
        warnings=data.get("warnings", []),
        is_sensitive_safe=bool(data.get("is_sensitive_safe", False)),
        is_acne_safe=bool(data.get("is_acne_safe", True)),
        confidence=confidence,
        needs_confirmation=confidence < settings.confidence_threshold,
        reasoning=data.get("reasoning", ""),
        ocr_text=data.get("ingredients_raw", ""),
        ai_raw_description=data.get("product_description", ""),
    )


# Module-level singleton
vision_service = VisionService()
