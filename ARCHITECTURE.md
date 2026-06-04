# Glowly — Architecture

AI-powered beauty assistant. A user photographs a skincare product; the system
identifies it, reads its label, enriches it with a verified ingredient list, and
returns structured, science-grounded product intelligence.

This document walks the full system and traces a single request end-to-end.

---

## 1. System overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          iOS App (SwiftUI, MVVM)                           │
│  Camera / Gallery → multipart upload → ProductConfirmationView (editable)  │
└───────────────────────────────┬────────────────────────────────────────────┘
                                 │  POST /api/products/analyze  (image bytes)
                                 ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                         FastAPI Backend (async)                            │
│                                                                            │
│   Router  ──►  LangGraph Workflow  ──►  Services                           │
│                                                                            │
│   ┌─────────────────────────── LangGraph state machine ───────────────┐   │
│   │  image_analysis → ocr → classification → confidence_check          │   │
│   │                                  │                                 │   │
│   │                     ┌────────────┴───────────┐                     │   │
│   │              confidence<τ                 confidence≥τ             │   │
│   │                     ▼                          ▼                   │   │
│   │            human_confirmation            save_product              │   │
│   │                     │                          ▼                   │   │
│   │                     │              recommendation_generation       │   │
│   │                     └──────────────┬───────────┘                   │   │
│   │                                   END                              │   │
│   └────────────────────────────────────────────────────────────────────┘  │
│                                                                            │
│   Services:                                                                │
│     • VisionService    — Claude Sonnet 4.6 single-pass vision (OCR+JSON)    │
│     • ScraperService   — INCIDecoder web scraping (full INCI list)         │
│     • RAGService       — Qdrant retrieval + product cache                  │
│     • mcp_tools        — 3 callable tools (analyze/categorize/recommend)   │
└───────┬───────────────────────┬────────────────────────┬───────────────────┘
        │                       │                        │
        ▼                       ▼                        ▼
  Anthropic API           Qdrant (vectors)         incidecoder.com
  (Claude Sonnet/Haiku)   • knowledge_base (63)    (HTML scrape)
                          • product_cache
        │
        ▼
  LangSmith (tracing of every LLM call)
```

---

## 2. Request lifecycle — one photo, traced end-to-end

**User taps "scan" on a Dr.Jart+ Dermaclear photo.**

1. **iOS** (`CameraUploadView`) compresses the image to JPEG (~0.85 quality) and
   uploads it as `multipart/form-data` to `POST /api/products/analyze`
   ([NetworkService.upload](Glowly/Core/Network/Services/NetworkService.swift)).
   The session allows up to 90s because the AI call is long.

2. **Router** (`routers/products.py::analyze_product_public`) reads the bytes,
   **sniffs the real media type from magic bytes** (iOS sends
   `application/octet-stream`), and calls `VisionService.analyze_image`.

3. **Step 1 — Vision** (`VisionService._claude_analysis`): a **single** Claude
   Sonnet 4.6 multimodal call does OCR + visual brand recognition + structured
   JSON extraction at once. Output is parsed into a strict `AnalyzedProduct`
   Pydantic model. → *brand: Dr.Jart+, category: cleanser, confidence: 0.88.*

4. **Step 2 — Cache lookup** (`RAGService.search_product_cache`): the product
   name is embedded and matched against the Qdrant `product_cache` collection.
   On a cosine hit ≥ **0.88**, cached fields enrich the result and the response
   is tagged *"Loaded from Glowly database"*.

5. **Step 3 — Web enrichment** (`ScraperService.enrich`): if the photo didn't
   capture the full ingredient list, we scrape **INCIDecoder** for the canonical
   product and its **full INCI list** (fuzzy-matched, ≥0.45 similarity). →
   *61 ingredients, `data_source: web`, `source_url` recorded.*

6. **Step 4 — Store** (`RAGService.store_product_in_cache`): the enriched result
   is embedded and written back to the product cache, so the next identical scan
   is instant.

7. **Step 5 — Response**: the `AnalyzedProduct` (20+ typed fields) is serialized
   as **camelCase** and returned. iOS decodes it directly into Swift and
   pre-fills the editable confirmation screen.

8. **Confidence branch** (full pipeline / `langgraph_agent.py`): if confidence is
   below the threshold (`settings.confidence_threshold = 0.75`), the graph routes
   to **human_confirmation** — the "Проверьте данные" review screen — instead of
   auto-saving. Above it, it proceeds to `save_product` →
   `recommendation_generation` (RAG-grounded routine advice).

Every LLM call in this path is automatically traced in **LangSmith**.

---

## 3. Components — what's independent, what's coupled

| Component | Responsibility | Swappable? |
|---|---|---|
| `VisionService` | image → structured product (Claude) | Model swappable via `settings.claude_vision_model`; provider behind one method |
| `ScraperService` | brand+name → full INCI list | Fully independent; source site isolated to one class |
| `RAGService` | embeddings + Qdrant (KB + cache) | Embedding model + vector DB swappable; only `embed()` / `query_points()` touched |
| `mcp_tools` | analyze_ingredients / categorize_product / recommend_routine | Independent, exposed via MCP router |
| `langgraph_agent` | orchestration + branching | Nodes are pure `state → dict` functions, individually replaceable |
| iOS `NetworkService` | transport + (de)serialization | Protocol-based DI; `APIEndpoint` decouples calls from URLs |

**Deliberate coupling:** the vision pipeline calls cache + scraper inline (not as
separate graph nodes) so the **public, auth-free** `/analyze` endpoint stays a
single fast call for the iOS confirmation flow. The full LangGraph workflow
(with branching + recommendations) backs the authenticated `/analyze-image`
endpoint. This split trades a little duplication for a much simpler client path.

---

## 4. Model choices (see [HYPERPARAMETERS.md](HYPERPARAMETERS.md) for the full rationale)

| Role | Model | Why |
|---|---|---|
| Vision / extraction | **Claude Sonnet 4.6** | best multimodal OCR + structured JSON; reads multi-language labels |
| Recommendations / judge | **Claude Haiku 4.5** | 8–10× cheaper & faster; quality sufficient for text generation |
| Embeddings | **all-MiniLM-L6-v2** (local, 384-dim) | no API key, self-contained, fast |
| Vector DB | **Qdrant** (in-memory dev) | one engine for both RAG and the product cache |

---

## 5. Data stores

- **Qdrant `glowly_knowledge` (63 docs):** ingredients, conflicts, routines,
  product knowledge, guides — the RAG knowledge base for recommendations.
- **Qdrant `glowly_product_cache`:** previously analyzed products, keyed by
  `brand + name + category` embedding; powers instant repeat scans.
- **SQLite (`glowly.db`):** users, profiles, saved products (auth flow).
- **iOS UserDefaults:** local product store on device.

---

## 6. Reliability & observability

- **Confidence-based branching** routes uncertain results to human review.
- **Graceful degradation:** cache miss → fresh analysis; scrape failure →
  vision-only data; every external call is wrapped and non-fatal.
- **Clear failure surfaces:** invalid API key → `503`; bad image → `415` with a
  sniffed-type message; the iOS client shows actionable errors, never a silent
  empty form.
- **LangSmith** traces every LLM call; **golden-dataset evals** (`evals/`) and an
  **A/B harness** measure quality on each change (see [EVALS.md](EVALS.md)).

---

## 7. Repo map

```
backend/
  main.py                     FastAPI app + lifespan (RAG seed, LangSmith)
  config.py                   settings, model IDs, hyperparameters
  routers/   products.py      /analyze (public), /analyze-image (full pipeline)
             mcp.py           MCP server: /api/mcp/tools, /api/mcp/execute
             auth.py, ai.py
  services/  vision_service.py    Step 1+2+3+4 orchestration
             scraper_service.py   INCIDecoder scraping (Step 3)
             rag_service.py       Qdrant: retrieval + product cache
             langgraph_agent.py   LangGraph state machine
             mcp_tools.py         3 MCP tools
  evals/     eval_runner.py       golden-dataset evals + A/B harness
             golden_dataset.json  41 labelled examples
  skills/cosmetic-advisor/SKILL.md   Claude Skill
  data/knowledge_base.json    63 RAG documents

Glowly/ (iOS, SwiftUI)
  Core/Network/               NetworkService, endpoints, configuration
  Views/AddProduct/           camera, analyzing, confirmation screens
  Modules/Products/           Product model + store
```
