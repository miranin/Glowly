"""
Glowly AI Backend — FastAPI application entry point.

Start with:
    uvicorn main:app --reload --host 0.0.0.0 --port 8080

Architecture overview:
  - FastAPI handles HTTP routing with async SQLAlchemy
  - LangGraph orchestrates the multimodal AI pipeline
  - Qdrant stores cosmetic knowledge embeddings (RAG)
  - LangSmith traces every LLM call automatically via env vars
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from config import configure_langsmith, settings
from database.db import init_db
from routers.auth import router as auth_router
from routers.products import router as products_router
from routers.ai import router as ai_router
from routers.mcp import router as mcp_router
from services.rag_service import rag_service

# ─── Logging ──────────────────────────────────────────────────────────────────

logging.basicConfig(
    level=logging.DEBUG if not settings.is_production else logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
)
logger = logging.getLogger("glowly")


# ─── Lifespan (startup / shutdown) ────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Runs once at startup and once at shutdown.
    - Pushes LangSmith env vars so all LangChain calls are traced
    - Creates DB tables (dev mode)
    - Seeds the Qdrant knowledge base
    """
    logger.info("─" * 60)
    logger.info("Starting Glowly AI Backend")
    logger.info(f"  Environment : {settings.app_env}")
    logger.info(f"  Database    : {settings.database_url.split('@')[-1]}")
    logger.info(f"  Vision model: {settings.claude_vision_model}")
    logger.info(f"  Chat model  : {settings.claude_chat_model}")
    logger.info(f"  Qdrant      : {'memory' if settings.qdrant_use_memory else f'{settings.qdrant_host}:{settings.qdrant_port}'}")

    # LangSmith tracing
    configure_langsmith()
    if settings.langchain_api_key:
        logger.info(f"  LangSmith   : tracing enabled → project '{settings.langchain_project}'")
    else:
        logger.warning("  LangSmith   : LANGCHAIN_API_KEY not set — tracing disabled")

    # Database
    await init_db()
    logger.info("  Database    : tables ready")

    # RAG knowledge base
    rag_service.initialize()
    logger.info("  RAG         : Qdrant collection seeded")

    logger.info("─" * 60)
    logger.info("Server ready.")

    yield  # ← application runs here

    logger.info("Shutting down Glowly AI Backend")


# ─── App factory ──────────────────────────────────────────────────────────────

app = FastAPI(
    title="Glowly AI Backend",
    description=(
        "AI-powered cosmetic assistant backend.\n\n"
        "**Key capabilities:**\n"
        "- Multimodal product image analysis (LangGraph + Claude claude-sonnet-4-6)\n"
        "- RAG-powered skincare recommendations (Qdrant + sentence-transformers)\n"
        "- Custom MCP server with 3 tools\n"
        "- LangSmith tracing on all LLM calls\n"
        "- JWT authentication matching iOS AuthManager expectations\n\n"
        "**iOS integration:** set `NetworkConfiguration.baseURL` to this server's URL."
    ),
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# ─── CORS (allow iOS simulator + any dev frontend) ────────────────────────────

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if not settings.is_production else ["https://glowly.app"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Routers ──────────────────────────────────────────────────────────────────

app.include_router(auth_router)
app.include_router(products_router)
app.include_router(ai_router)
app.include_router(mcp_router)


# ─── Health check ─────────────────────────────────────────────────────────────

@app.get("/health", tags=["system"])
async def health() -> dict:
    return {
        "status": "ok",
        "environment": settings.app_env,
        "rag_initialized": rag_service._initialized,
        "models": {
            "vision": settings.claude_vision_model,
            "chat": settings.claude_chat_model,
        },
    }


@app.get("/", tags=["system"])
async def root() -> dict:
    return {
        "name": "Glowly AI Backend",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health",
    }


# ─── Global exception handler ─────────────────────────────────────────────────

@app.exception_handler(Exception)
async def global_exception_handler(request, exc: Exception):
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error", "type": type(exc).__name__},
    )
