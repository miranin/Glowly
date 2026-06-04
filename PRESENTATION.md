# Glowly — Defense Presentation (10 slides)

Structure required by the brief: проблема → решение → демо → архитектура →
метрики → выводы. Speaker notes under each slide. ~7 min talk, leaves 3 min buffer.

---

## Slide 1 — Title
**Glowly — AI beauty assistant**
Photograph any skincare product → instant structured product intelligence.
*Your name · Final LLM Project*

> "Glowly turns a single phone photo of a skincare product into structured,
> science-grounded information — in about 15 seconds."

---

## Slide 2 — Problem
- People own 10–30 skincare products and **don't know** what's in them, what they
  conflict with, or how to use them together.
- Reading INCI lists is unreadable; Googling each product is slow.
- **User:** anyone building a skincare routine who wants to understand their shelf.

> "The pain: your bathroom shelf is a black box. You can't tell what conflicts
> with what, or whether a product even fits your skin."

---

## Slide 3 — Solution
One photo → the app returns: **brand, exact product, category, full ingredient
list, active ingredients with their roles, skin-type fit, concerns it targets,
how to use, safety flags** — editable, then saved to your collection.

> "Point your camera at the tube. That's the entire interaction."

---

## Slide 4 — Live Demo
*(Switch to phone. Scan the Dr.Jart+.)*
Narrate during the ~15s: "reading label → identifying brand → scraping the full
ingredient list → structuring." Then show the filled confirmation screen.

**Backup if Wi-Fi fails:** screenshots of the result + `curl` output.

> "Brand: Dr.Jart+ — correctly, not a keyword guess. Category: cleanser. 61
> ingredients pulled from INCIDecoder. Actives with their roles. All from one photo."

---

## Slide 5 — Architecture (the diagram)
Show the diagram from [ARCHITECTURE.md](ARCHITECTURE.md). Trace one request:
iOS upload → FastAPI → **LangGraph** → Vision (Sonnet) → cache → scraper → response.

> "One photo flows through a LangGraph state machine. Each step is a node;
> low-confidence results branch to human review instead of guessing."

---

## Slide 6 — The 5-step AI pipeline
1. **Vision** — Claude Sonnet 4.6, single multimodal call (OCR + brand ID + JSON)
2. **Vector cache** — Qdrant, cosine ≥ 0.88 → instant repeat scans
3. **Web scraping** — INCIDecoder for the full INCI list
4. **Embed & store** — self-populating product DB
5. **Structured response** — strict Pydantic → camelCase → Swift

> "I collapsed three lossy calls into one. That single change fixed our worst bug —
> a Dr.Jart+ tube being labelled 'Mac'."

---

## Slide 7 — Required modules (proof)
- **LangGraph** workflow with conditional branch + human-in-the-loop
- **Custom MCP server** — 3 tools: analyze_ingredients, categorize_product, recommend_routine
- **Custom Skill** — `cosmetic-advisor` with SKILL.md + triggers
- **RAG** — Qdrant + all-MiniLM-L6-v2, 63-doc knowledge base
- **Web scraping** — INCIDecoder (dynamic HTML)
- **Multimodality** — vision OCR is the core feature
- **LangSmith** tracing on every LLM call

> "Every mandatory module is load-bearing, not bolted on."

---

## Slide 8 — Metrics & A/B
**Golden dataset: 41 examples.** Classification accuracy + LLM-as-judge.

**A/B — Haiku vs Sonnet (classification):**
| | Haiku | Sonnet |
|---|---|---|
| Pass rate | 92% | 96% |
| Avg score | 0.888 | 0.888 |
| Cost | 1× | ~8× |

**Decision:** Sonnet for vision, Haiku for text — same quality, 1/8 the cost.

> "Evals also showed our failures are missing *categories* (hand cream, brow), not
> model errors — so the next fix is taxonomy, not a bigger model. We'd have missed
> that without measuring."

---

## Slide 9 — Engineering decisions / trade-offs
- **One combined vision call** vs 3 — accuracy + cost, fixed misID.
- **Public `/analyze` endpoint inline** vs full LangGraph — simpler client path.
- **Cache-first + scrape-fallback** — fast, cheap, degrades gracefully.
- **Confidence threshold 0.75** — honest uncertainty → human review.
- **Cost:** ~1–3¢ per fresh scan; cached scans ≈ free.

> "Each choice is a deliberate trade-off between quality, latency and cost."

---

## Slide 10 — Conclusion & next steps
- Working multimodal pipeline: **vision + RAG + scraping + LangGraph**, observable
  in LangSmith, measured by evals.
- **Next:** expand category taxonomy (from evals), real web-scrape ranking,
  model fallback, on-device routine recommendations.

> "Glowly is a complete, measured LLM product — not a demo. One photo in,
> structured product intelligence out."

---

### Q&A cheat-sheet
- **Why LangGraph?** stateful + conditional branching + human-in-the-loop; simpler
  than CrewAI for a deterministic pipeline, more controllable than a raw agent loop.
- **Why Claude?** best structured-output adherence + multimodal OCR in testing.
- **Cost per request?** ~1–3¢ fresh, ≈0 cached.
- **If Sonnet is down?** isolated behind `VisionService` → swap to Haiku vision, flag low-confidence.
- **Biggest unconfirmed hypothesis?** that we'd need a fine-tuned classifier — evals
  showed prompt-engineered Sonnet/Haiku already hit 92–96%, so we didn't.
