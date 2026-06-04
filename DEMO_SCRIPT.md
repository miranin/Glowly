# Glowly — Demo Script (AI Pipeline)

**Format:** ~7–9 min live demo + architecture walkthrough
**Goal:** show a working multimodal AI product-analysis pipeline and explain how it's built.

---

## 0. Hook (30 sec)

> "Glowly is an AI beauty assistant. The core feature: you photograph any skincare product, and in about 15 seconds the app identifies the exact product, reads its label, and returns a structured breakdown — brand, category, active ingredients with their roles, skin-type fit, concerns it targets, how to use it, and safety flags.
>
> The interesting part isn't the UI — it's the AI pipeline behind that one photo. That's what I'll walk through."

---

## 1. Live Demo (90 sec) — *do this first, while the server is running*

**Before you start:** backend running on your Mac, phone on the same Wi-Fi.

1. Open the app → **+** tab → **Сделать фото / галерея**.
2. Pick the **Dr.Jart+ Dermaclear** photo.
3. **Narrate the loading state** (it takes ~15s — fill the silence):
   > "Right now the image is going to my backend. Claude's vision model is reading the label — OCR plus visual brand recognition — and at the same time structuring everything into JSON. Notice the staged progress: reading label → identifying brand → analyzing composition."
4. Confirmation screen appears. **Point at the fields:**
   > "Brand: Dr.Jart+ — correctly, not a fuzzy keyword match. Category: cleanser. Here are the **active ingredients with their roles** — Centella Asiatica for soothing, Panthenol for conditioning. Skin types, concerns it targets, how to use, safety flags — all extracted from a single photo."
5. **Save it** → open the product → show the full detail sheet with description + ingredient cards.

**Optional wow moment — scan the same product again:**
> "Watch the logs — this second scan was served from my vector database in milliseconds. The first time we analyze a product, we cache it; identical scans never hit the model again."

---

## 2. The AI Pipeline — *the main section (3–4 min)*

> "When that photo arrives at `POST /api/products/analyze`, it runs through a 5-step pipeline."

### Step 1 — Multimodal extraction (Claude Sonnet 4.6 vision)
> "One single Claude vision call does three things at once: OCR of every text element, visual brand identification — logo shape, packaging colour language — and structured JSON extraction. I deliberately collapsed what used to be three separate calls into **one combined pass**, because the model sees the actual pixels at extraction time. No information is lost between an OCR step and a separate reasoning step. It's faster, cheaper, and more accurate.
>
> The prompt is heavily engineered: it knows brand visual identities — Dr.Jart+ has a red cross, MAC is all-caps — and it has an explicit rule *not* to keyword-match 'mac' to MAC. That single rule fixed our biggest early failure, where a Dr.Jart+ tube was being labelled 'Mac'."

### Step 2 — Vector DB cache lookup (Qdrant, cosine ≥ 0.88)
> "Before trusting a fresh result, I embed the extracted product name and search a Qdrant vector collection of previously-analyzed products. If cosine similarity is **0.88 or higher**, it's the same product — I enrich from cache. This is what makes repeat scans instant and keeps model cost down."

### Step 3 — Web enrichment *(roadmap)*
> "Step three is web enrichment — scraping the brand site or INCI Decoder for the full ingredient list. It's stubbed in the current MVP; Claude's product knowledge covers the common cases, so I prioritized the closed loop first."

### Step 4 — Embed & store
> "Every successful analysis with decent confidence is embedded and written back into the vector DB. The system gets faster and cheaper the more it's used — it's a self-populating product knowledge base."

### Step 5 — Structured response
> "The result comes back as a strict Pydantic schema — 20-plus typed fields — serialized as camelCase so the iOS app decodes it directly into Swift models. No free-text parsing on the client."

---

## 3. Orchestration & Reliability — *(90 sec)*

> "The pipeline isn't just a function call — it's a **LangGraph state machine**."

- **Nodes:** image_analysis → confidence_check → *conditional branch* → save **or** human-confirmation → recommendation generation.
- **Confidence-based branching:** every analysis returns a `confidence` 0–1. Above the threshold it auto-saves; below it, the graph routes to a **human-confirmation** path — that's the "Проверьте данные" screen you saw. The model is honest about uncertainty instead of guessing.
- **RAG for recommendations:** a separate node retrieves from a **63-document knowledge base** (ingredients, conflicts, routines, guides) embedded with `all-MiniLM-L6-v2`, and feeds that context to Claude Haiku to generate personalized routine advice grounded in real skincare science — not hallucinated.
- **Observability:** every LLM call is traced in **LangSmith** automatically, so I can inspect any step of any run.
- **Evaluation:** I built a **golden dataset of 41 labelled examples** (25 classification, 8 recommendation, 8 ingredient-analysis) to measure accuracy as I tune prompts.
- **Custom MCP server:** 3 tools — `analyze_ingredients`, `categorize_product`, `recommend_routine` — exposing the pipeline's capabilities as callable tools.

---

## 4. Tech Stack (rapid-fire, 30 sec)

| Layer | Choice | Why |
|-------|--------|-----|
| Vision / reasoning | **Claude Sonnet 4.6** | best multimodal OCR + structured output |
| Recommendations | **Claude Haiku 4.5** | fast + cheap for text generation |
| Embeddings | **all-MiniLM-L6-v2** (local, 384-dim) | no API key, self-contained |
| Vector DB | **Qdrant** | RAG knowledge base + product cache |
| Orchestration | **LangGraph** | stateful, branching, retry-able |
| Tracing | **LangSmith** | full pipeline observability |
| API | **FastAPI** (async) | typed Pydantic I/O |
| Client | **SwiftUI** (iOS 18) | MVVM, protocol-based DI |

---

## 5. Q&A Prep — anticipated questions

**"Why one Claude call instead of a dedicated OCR model + classifier?"**
> Tesseract-style OCR loses context — it gives you characters, not meaning. A multimodal model reads the text *and* reasons about the brand from packaging design simultaneously. Fewer moving parts, higher accuracy, and it handles multi-language labels (Korean, French) out of the box.

**"What if the model is wrong?"**
> Two guards: a confidence score that routes low-confidence results to human review, and the entire confirmation screen is editable before saving. The human is always in the loop on uncertain cases.

**"How do you stop it hallucinating ingredients?"**
> The prompt forbids inventing percentages and asks it to flag inferred vs. directly-read items. Recommendations are RAG-grounded against a curated knowledge base, not free generation.

**"Does the cache ever serve a wrong product?"**
> The 0.88 cosine threshold is deliberately high. Below it, we always fall back to a fresh model call. Fresh OCR is authoritative for brand/name; the cache only fills in supporting detail.

**"Cost?"**
> ~1–3 cents per fresh scan; cached scans are effectively free. The vector DB makes the system cheaper over time.

---

## 6. One-line closer

> "So Glowly turns a single phone photo into structured, science-grounded product intelligence — using a multimodal Claude pipeline orchestrated by LangGraph, grounded by a Qdrant vector database, and observable end-to-end in LangSmith."

---

### Demo-day checklist
- [ ] Backend running: `cd backend && source .venv/bin/activate && uvicorn main:app --host 0.0.0.0 --port 8080`
- [ ] Phone + Mac on **same Wi-Fi**; `NetworkConfiguration.development.baseURL` = Mac's current IP
- [ ] `curl http://<mac-ip>:8080/health` returns `status: ok`
- [ ] One product pre-scanned so you can show an instant **cache hit**
- [ ] LangSmith dashboard open in a browser tab (optional, strong visual)
- [ ] Rotate the API key if you shared it anywhere
