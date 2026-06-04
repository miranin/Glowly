"""
RAG (Retrieval-Augmented Generation) service using Qdrant.

Architecture:
  - Embedding model: sentence-transformers/all-MiniLM-L6-v2 (local, no API key)
    OR openai text-embedding-3-small if OPENAI_API_KEY is set.
  - Vector store: Qdrant (in-memory for dev, persistent for prod)
  - Knowledge base: data/knowledge_base.json (ingredients, routines, products, guides)

Usage:
  results = await rag_service.retrieve("retinol and acne prone skin", top_k=3)
  context = await rag_service.build_context_for_recommendation(user_profile, ingredients)
"""

import json
import logging
import os
from pathlib import Path
from typing import Any

from qdrant_client import QdrantClient
from qdrant_client.models import (
    Distance,
    FieldCondition,
    Filter,
    MatchAny,
    PointStruct,
    VectorParams,
)

from config import settings

logger = logging.getLogger(__name__)

VECTOR_DIM = 384   # all-MiniLM-L6-v2 output dimension
KB_PATH = Path(__file__).parent.parent / "data" / "knowledge_base.json"
PRODUCT_CACHE_COLLECTION = "glowly_product_cache"
PRODUCT_CACHE_SIMILARITY_THRESHOLD = 0.88


# ─── Embedding function (local, no API key required) ──────────────────────────

class EmbeddingService:
    """
    Wraps sentence-transformers for local embeddings.
    Falls back to OpenAI if OPENAI_API_KEY is set and the model is faster needed.
    Using local model keeps the project self-contained for academic submission.
    """

    def __init__(self) -> None:
        self._model = None
        self._openai_client = None
        # Only use OpenAI if key is present and not a placeholder
        key = settings.openai_api_key
        self._use_openai = bool(key) and key.startswith("sk-") and len(key) > 20

    def _load_local_model(self):
        if self._model is None:
            from sentence_transformers import SentenceTransformer
            logger.info("Loading sentence-transformers/all-MiniLM-L6-v2 …")
            self._model = SentenceTransformer("all-MiniLM-L6-v2")
        return self._model

    def embed(self, texts: list[str]) -> list[list[float]]:
        """Synchronous embedding (Qdrant client is synchronous too)."""
        if self._use_openai:
            return self._embed_openai(texts)
        model = self._load_local_model()
        embeddings = model.encode(texts, normalize_embeddings=True)
        return [e.tolist() for e in embeddings]

    def _embed_openai(self, texts: list[str]) -> list[list[float]]:
        if self._openai_client is None:
            from openai import OpenAI
            self._openai_client = OpenAI(api_key=settings.openai_api_key)
        response = self._openai_client.embeddings.create(
            input=texts,
            model=settings.openai_embedding_model,
        )
        return [item.embedding for item in response.data]

    def embed_one(self, text: str) -> list[float]:
        return self.embed([text])[0]


embedding_service = EmbeddingService()


# ─── Qdrant client factory ────────────────────────────────────────────────────

def _make_qdrant_client() -> QdrantClient:
    if settings.qdrant_use_memory:
        logger.info("Qdrant: using in-memory mode (dev)")
        return QdrantClient(":memory:")
    logger.info(f"Qdrant: connecting to {settings.qdrant_host}:{settings.qdrant_port}")
    return QdrantClient(host=settings.qdrant_host, port=settings.qdrant_port)


# ─── RAG Service ─────────────────────────────────────────────────────────────

class RAGService:
    """
    Manages the Qdrant collection and exposes retrieval methods used by
    the LangGraph recommendation node and the /recommendations endpoint.
    """

    def __init__(self) -> None:
        self.client: QdrantClient | None = None
        self.collection = settings.qdrant_collection
        self._initialized = False

    def initialize(self) -> None:
        """Called once at application startup."""
        if self._initialized:
            return
        self.client = _make_qdrant_client()
        self._ensure_collection()
        self._ensure_product_cache_collection()
        self._seed_knowledge_base()
        self._initialized = True
        logger.info(f"RAG service ready. Collection: '{self.collection}'")

    def _ensure_collection(self) -> None:
        existing = [c.name for c in self.client.get_collections().collections]
        if self.collection not in existing:
            dim = VECTOR_DIM if not settings.openai_api_key else 1536
            self.client.create_collection(
                collection_name=self.collection,
                vectors_config=VectorParams(size=dim, distance=Distance.COSINE),
            )
            logger.info(f"Created Qdrant collection '{self.collection}' (dim={dim})")

    def _ensure_product_cache_collection(self) -> None:
        existing = [c.name for c in self.client.get_collections().collections]
        if PRODUCT_CACHE_COLLECTION not in existing:
            dim = VECTOR_DIM if not settings.openai_api_key else 1536
            self.client.create_collection(
                collection_name=PRODUCT_CACHE_COLLECTION,
                vectors_config=VectorParams(size=dim, distance=Distance.COSINE),
            )
            logger.info(f"Created product cache collection '{PRODUCT_CACHE_COLLECTION}'")

    def _seed_knowledge_base(self) -> None:
        """
        Load knowledge_base.json and upsert all documents.
        Idempotent — if vectors already exist, Qdrant upserts silently.
        """
        if not KB_PATH.exists():
            logger.warning(f"Knowledge base not found at {KB_PATH}")
            return

        with open(KB_PATH, "r", encoding="utf-8") as f:
            docs: list[dict] = json.load(f)

        points: list[PointStruct] = []
        texts = [f"{d['title']}. {d['content']}" for d in docs]
        vectors = embedding_service.embed(texts)

        for i, (doc, vec) in enumerate(zip(docs, vectors)):
            points.append(
                PointStruct(
                    id=i,
                    vector=vec,
                    payload={
                        "doc_id": doc["id"],
                        "type": doc["type"],
                        "title": doc["title"],
                        "content": doc["content"],
                        "tags": doc.get("tags", []),
                        "skin_types": doc.get("skin_types", []),
                        "conflicts": doc.get("conflicts", []),
                        "synergies": doc.get("synergies", []),
                        "category": doc.get("category", ""),
                    },
                )
            )

        self.client.upsert(collection_name=self.collection, points=points)
        logger.info(f"Seeded {len(points)} documents into Qdrant")

    # ─── Public API ───────────────────────────────────────────────────────────

    def retrieve(
        self,
        query: str,
        top_k: int | None = None,
        doc_types: list[str] | None = None,
    ) -> list[dict[str, Any]]:
        """
        Semantic search over the knowledge base.

        Args:
            query: natural-language query
            top_k: number of results (default: settings.rag_top_k)
            doc_types: filter by type ("ingredient", "routine", "product", etc.)

        Returns:
            List of payload dicts sorted by score descending.
        """
        if not self._initialized or self.client is None:
            raise RuntimeError("RAGService not initialized. Call .initialize() first.")

        k = top_k or settings.rag_top_k
        query_vec = embedding_service.embed_one(query)

        search_filter: Filter | None = None
        if doc_types:
            search_filter = Filter(
                must=[FieldCondition(key="type", match=MatchAny(any=doc_types))]
            )

        results = self.client.query_points(
            collection_name=self.collection,
            query=query_vec,
            limit=k,
            query_filter=search_filter,
            with_payload=True,
        ).points

        return [
            {"score": r.score, **r.payload}
            for r in results
        ]

    def retrieve_for_ingredients(
        self,
        ingredients: list[str],
        skin_type: str = "",
    ) -> list[dict[str, Any]]:
        """
        Find ingredient compatibility info and routine guidance for a product's
        ingredient list. Used by the recommendation generation node.
        """
        if not ingredients and not skin_type:
            return []

        query_parts = []
        if ingredients:
            query_parts.append(f"ingredients: {', '.join(ingredients[:10])}")
        if skin_type:
            query_parts.append(f"skin type: {skin_type}")
        query = ". ".join(query_parts)

        return self.retrieve(query, top_k=5, doc_types=["ingredient", "conflict", "recommendation"])

    def build_recommendation_context(
        self,
        user_profile: dict,
        product_ingredients: list[str] | None = None,
        existing_categories: list[str] | None = None,
    ) -> str:
        """
        Assembles a rich context string for the LLM recommendation prompt.

        Returns formatted context ready for injection into a system prompt.
        """
        skin_type = user_profile.get("skin_type", "")
        conditions = user_profile.get("skin_conditions", [])
        goals = user_profile.get("beauty_goals", [])

        # Build query from profile
        query_parts = []
        if skin_type:
            query_parts.append(f"{skin_type} skin")
        if conditions:
            query_parts.append(f"conditions: {', '.join(conditions)}")
        if goals:
            query_parts.append(f"goals: {', '.join(goals)}")
        if product_ingredients:
            query_parts.append(f"ingredients: {', '.join(product_ingredients[:8])}")

        query = ". ".join(query_parts) or "skincare routine recommendations"

        docs = self.retrieve(
            query,
            top_k=settings.rag_top_k + 2,
            doc_types=["ingredient", "routine", "recommendation", "conflict"],
        )

        context_lines = ["# Retrieved Knowledge Base Context\n"]
        for i, doc in enumerate(docs, 1):
            context_lines.append(
                f"## [{i}] {doc['title']} (relevance: {doc['score']:.2f})\n{doc['content']}\n"
            )

        return "\n".join(context_lines)


    # ─── Product cache (Step 2 & 4 from analysis pipeline) ──────────────────

    def search_product_cache(
        self, query: str, threshold: float = PRODUCT_CACHE_SIMILARITY_THRESHOLD
    ) -> dict[str, Any] | None:
        """
        Search the product cache by semantic similarity.
        Returns the cached product payload if similarity ≥ threshold, else None.
        Call this BEFORE running the full Claude vision analysis.
        """
        if not self._initialized or self.client is None:
            return None
        try:
            query_vec = embedding_service.embed_one(query)
            results = self.client.query_points(
                collection_name=PRODUCT_CACHE_COLLECTION,
                query=query_vec,
                limit=1,
                with_payload=True,
            ).points
            if results and results[0].score >= threshold:
                hit = results[0]
                logger.info(
                    f"[product_cache] HIT: '{hit.payload.get('product_name')}' "
                    f"(score={hit.score:.3f})"
                )
                return hit.payload
        except Exception as exc:
            logger.warning(f"[product_cache] search failed (non-fatal): {exc}")
        return None

    def store_product_in_cache(self, product: dict[str, Any]) -> None:
        """
        Embed and store a fully analyzed product in the product cache.
        Called after a successful Claude analysis so future identical scans are instant.
        Uses brand + product_name + category as the search key.
        """
        if not self._initialized or self.client is None:
            return
        try:
            brand = product.get("brand", "")
            name = product.get("product_name", "")
            category = product.get("category", "")
            # category may be a ProductCategory enum from model_dump(); use its value
            category = getattr(category, "value", category)
            if not brand and not name:
                return  # Don't cache empty results

            search_key = f"{brand} {name} {category}".strip()
            vec = embedding_service.embed_one(search_key)

            # Use hash of search_key as point ID for deduplication
            point_id = abs(hash(search_key.lower())) % (10**12)

            self.client.upsert(
                collection_name=PRODUCT_CACHE_COLLECTION,
                points=[
                    PointStruct(
                        id=point_id,
                        vector=vec,
                        payload={**product, "_cache_key": search_key},
                    )
                ],
            )
            logger.info(f"[product_cache] Stored: '{search_key}'")
        except Exception as exc:
            logger.warning(f"[product_cache] store failed (non-fatal): {exc}")


# Module-level singleton — initialized once in main.py lifespan
rag_service = RAGService()
