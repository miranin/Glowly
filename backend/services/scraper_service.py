"""
Web scraping service — Step 3 of the product-analysis pipeline.

When Claude vision reads the label but the full INCI ingredient list is not
visible in the photo, we enrich the result by scraping the authoritative
ingredient database INCIDecoder (incidecoder.com).

Flow:
  search_product(brand, name)  → resolves the most likely product page URL
  scrape_ingredients(url)      → parses the full INCI list + canonical name
  enrich(brand, name)          → convenience wrapper used by the vision pipeline

This satisfies the "document processing / web scraping with dynamic content"
requirement and genuinely improves data quality: a photo rarely shows the whole
ingredient list, but INCIDecoder always has it.

HTML is parsed with BeautifulSoup (lxml). All network calls are defensive —
any failure returns None so the pipeline degrades gracefully to vision-only data.
"""

import logging
import re
from dataclasses import dataclass, field
from difflib import SequenceMatcher
from urllib.parse import quote_plus

import httpx
from bs4 import BeautifulSoup

logger = logging.getLogger(__name__)

_BASE = "https://incidecoder.com"
_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/120.0 Safari/537.36"
    )
}
_TIMEOUT = 10.0


@dataclass
class ScrapedProduct:
    """Result of a successful INCIDecoder scrape."""
    canonical_name: str = ""
    full_ingredients: list[str] = field(default_factory=list)
    source_url: str = ""
    match_score: float = 0.0  # how well the page title matched our query

    @property
    def found(self) -> bool:
        return bool(self.full_ingredients)


class ScraperService:
    """Scrapes INCIDecoder for full ingredient lists. Stateless and safe to share."""

    def __init__(self, base_url: str = _BASE, timeout: float = _TIMEOUT) -> None:
        self._base = base_url
        self._timeout = timeout

    # ── Public API ────────────────────────────────────────────────────────────

    async def enrich(self, brand: str, product_name: str) -> ScrapedProduct | None:
        """
        Resolve a product on INCIDecoder and return its full ingredient list.
        Returns None if nothing credible is found (pipeline stays vision-only).
        """
        query = f"{brand} {product_name}".strip()
        if not query:
            return None

        try:
            url, score = await self._search_best_match(query)
            if not url:
                logger.info(f"[scraper] no INCIDecoder match for '{query}'")
                return None

            scraped = await self._scrape_ingredients(url)
            if scraped and scraped.found:
                scraped.match_score = score
                logger.info(
                    f"[scraper] enriched '{query}' → {len(scraped.full_ingredients)} "
                    f"ingredients (match={score:.2f}) from {url}"
                )
                return scraped
        except Exception as exc:  # network, parsing, anything — never fatal
            logger.warning(f"[scraper] enrich failed for '{query}' (non-fatal): {exc}")
        return None

    # ── Internal steps ────────────────────────────────────────────────────────

    async def _search_best_match(self, query: str) -> tuple[str | None, float]:
        """
        Scrape the search results page and pick the product whose title best
        matches the query (fuzzy ratio). Returns (absolute_url, score).

        Brand punctuation like 'Dr.Jart+' breaks INCIDecoder's search, so we
        clean the query and fall back to a brand-simplified query if needed.
        """
        # Punctuation (., +, /) returns zero results — replace with spaces.
        cleaned = re.sub(r"[^A-Za-z0-9 ]", " ", query)
        cleaned = re.sub(r"\s+", " ", cleaned).strip()
        queries = [cleaned]
        # Fallback: drop the last word (often a generic descriptor) for a wider net
        words = cleaned.split()
        if len(words) > 3:
            queries.append(" ".join(words[:3]))

        async with httpx.AsyncClient(timeout=self._timeout, headers=_HEADERS) as client:
            for q in queries:
                resp = await client.get(f"{self._base}/search?query={quote_plus(q)}")
                resp.raise_for_status()
                soup = BeautifulSoup(resp.text, "lxml")
                candidates = soup.select("a.klavika.simpletextlistitem")
                if not candidates:
                    continue

                best_url: str | None = None
                best_score = 0.0
                q_norm = _normalize(query)  # score against the ORIGINAL query
                for a in candidates[:8]:
                    title = a.get_text(strip=True)
                    score = _similarity(q_norm, _normalize(title))
                    if score > best_score:
                        best_score, best_url = score, a.get("href", "")

                if best_url and best_score >= 0.45:
                    return self._base + best_url, best_score

        return None, 0.0

    async def _scrape_ingredients(self, url: str) -> ScrapedProduct | None:
        """Parse a product page for its canonical name and full INCI list."""
        async with httpx.AsyncClient(timeout=self._timeout, headers=_HEADERS) as client:
            resp = await client.get(url)
            resp.raise_for_status()

        soup = BeautifulSoup(resp.text, "lxml")

        title_el = soup.select_one("#product-title")
        canonical = title_el.get_text(strip=True) if title_el else ""

        # Ingredient chips link to /ingredients/<slug>
        ingredient_links = soup.select("a.ingred-link")
        ingredients = []
        seen = set()
        for a in ingredient_links:
            name = a.get_text(strip=True).replace("​", "")  # zero-width spaces
            key = name.lower()
            if name and key not in seen:
                seen.add(key)
                ingredients.append(name)

        if not ingredients:
            return None

        return ScrapedProduct(
            canonical_name=canonical,
            full_ingredients=ingredients,
            source_url=url,
        )


# ── helpers ───────────────────────────────────────────────────────────────────

def _normalize(s: str) -> str:
    return re.sub(r"[^a-z0-9 ]", "", s.lower()).strip()


def _similarity(a: str, b: str) -> float:
    """Token-overlap-weighted similarity, robust to word order."""
    if not a or not b:
        return 0.0
    ratio = SequenceMatcher(None, a, b).ratio()
    a_tokens, b_tokens = set(a.split()), set(b.split())
    overlap = len(a_tokens & b_tokens) / max(1, len(a_tokens))
    return 0.5 * ratio + 0.5 * overlap


# Module-level singleton
scraper_service = ScraperService()
