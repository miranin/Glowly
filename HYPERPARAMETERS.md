# Glowly — Model & Hyperparameter Choices

Documented, experiment-backed rationale for every model and tuning decision.

---

## 1. LLM selection

| Role | Model | Why this one |
|---|---|---|
| **Vision / extraction** | Claude **Sonnet 4.6** | Best multimodal OCR + structured-JSON adherence we tested; reads Korean/French/multi-language labels and reasons about brand from packaging design. The accuracy here defines product quality, so it's worth the cost. |
| **Text generation** (recommendations, ingredient analysis, LLM-judge) | Claude **Haiku 4.5** | Our A/B test (see [EVALS.md](EVALS.md) §3) showed Haiku matches Sonnet's avg score on text classification at ~1/8 the cost and similar latency. |
| **Embeddings** | `all-MiniLM-L6-v2` (local, 384-dim) | No API key, runs locally, fast, self-contained for academic submission. |

**Cost / latency / quality balance:** a fresh scan = 1 Sonnet vision call
(~$0.01–0.03, 15–20s) + optionally 1 scrape (free). Repeat scans hit the vector
cache (≈ free). Text tasks use Haiku to keep cost down. This is the explicit
trade-off: **pay for quality only at the vision step**, economize everywhere else.

**Fallback strategy (roadmap):** on Sonnet unavailability/budget cap, the vision
call can degrade to Haiku vision (lower accuracy, flagged low-confidence → human
review). The provider is isolated behind `VisionService`, so swapping is one line.

---

## 2. Hyperparameters

Set in [`backend/config.py`](backend/config.py) and per call site.

| Parameter | Value | Justification |
|---|---|---|
| `max_tokens` (vision) | **1800** | Enough for the full structured JSON (description, 5 ingredients-with-roles, benefits, warnings, how-to-use). Measured: real responses are 900–1500 tokens; 1800 gives headroom without truncation. |
| `max_tokens` (recommendations) | 2048 | Routines with per-step reasoning run long. |
| `max_tokens` (ingredient analysis) | 1500 | Conflict/synergy explanations are medium-length. |
| `max_tokens` (LLM-judge) | 200 | Judge returns only `{score, reasoning}`. |
| `temperature` | **default (1.0), not overridden** | Extraction is constrained by a strict JSON schema + explicit rules, so output is effectively deterministic in shape. Lowering temperature gave no measurable accuracy gain in spot tests but reduced the quality of natural-language descriptions/recommendations, so we kept the default. |
| `confidence_threshold` | **0.75** | Below this, the LangGraph workflow routes to human confirmation. Chosen from the calibration examples: clear labels score ≥0.9, partial ~0.6 — 0.75 cleanly separates "trust" from "ask the user". |
| Product-cache cosine threshold | **0.88** | High enough that only the *same* product matches; below it we always re-analyze. |
| Scraper fuzzy-match threshold | **0.45** | Empirically avoids attaching a wrong INCIDecoder product while tolerating name variation ("Cleansing Foam" vs "Micro Foam Cleanser"). |
| RAG `top_k` | 5 (+2 for recs) | Enough context without diluting the prompt. |

---

## 3. Prompt evolution (headline)

- **v1:** three sequential calls — vision description → OCR → classify. Lossy
  between steps; a Dr.Jart+ tube came back as **"Mac"** (keyword match).
- **v2 (current):** **single combined multimodal call** — OCR + visual brand ID +
  structured JSON at once, with explicit brand-identity rules ("Dr.Jart+ has a red
  cross; never output 'Mac' just because 'mac' appears in another word") and a
  category-disambiguation guide. Fixed the misidentification and cut latency/cost.

See the full prompts in [`backend/services/vision_service.py`](backend/services/vision_service.py).
