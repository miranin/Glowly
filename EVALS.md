# Glowly — Evaluations

Automated evaluation of the AI pipeline against a golden dataset, with an A/B
model experiment. Run with:

```bash
cd backend && source .venv/bin/activate
python evals/eval_runner.py                 # all suites
python evals/eval_runner.py --ab-test \
  --model-a claude-haiku-4-5-20251001 \
  --model-b claude-sonnet-4-6               # A/B experiment
```

Every run is traced in LangSmith (when `LANGCHAIN_API_KEY` is set).

---

## 1. Golden dataset — 41 labelled examples

`backend/evals/golden_dataset.json`

| Suite | Examples | What it tests |
|---|---|---|
| Classification | 25 | brand, category, application zone, confidence calibration |
| Recommendations | 8 | routine relevance for a user profile (heuristics + LLM-judge) |
| Ingredient analysis | 8 | conflict/synergy detection, SPF warnings |

**Why these examples:** they span easy cases (clear CeraVe/The Ordinary labels),
**niche brands** (Glossier, SK-II, Abib), **multi-language packaging**, and
deliberate **edge cases** — ambiguous categories, body vs face products, and
known ingredient conflicts (retinol + BPO, vitamin C + copper peptides).

---

## 2. Metrics

We measure **two** metric families (requirement: ≥2):

1. **Classification accuracy** — weighted exact-match score per example:
   category 0.4, brand 0.2, zone 0.2, confidence-calibration 0.2. Pass ≥ 0.6.
2. **LLM-as-judge relevance** — for recommendations, Claude Haiku scores routine
   appropriateness 1–10 against the user profile, blended with heuristic checks
   (required categories present, harmful combos absent).

Plus **confidence calibration** (does the model say "low confidence" exactly when
it should?) and **latency** per call.

**What these metrics do NOT show:** real-world OCR robustness on blurry/angled
photos (the classification suite feeds text, not images, for determinism), and
subjective recommendation quality beyond the judge's rubric.

---

## 3. A/B Experiment — Haiku 4.5 vs Sonnet 4.6 (classification)

**Hypothesis:** the cheaper, faster **Haiku** is good enough for the *text*
classification/reasoning step, so we can reserve expensive **Sonnet** only for
the *vision* step where multimodal quality actually matters.

**Setup:** identical prompt (`_CLASSIFICATION_TEMPLATE`), 25 classification
examples, same temperature/max_tokens, run back-to-back.

| Metric | Haiku 4.5 (A) | Sonnet 4.6 (B) | Winner |
|---|---|---|---|
| Pass rate | **92%** (23/25) | **96%** (24/25) | B (+1 example) |
| Avg score | 0.888 | 0.888 | Tie |
| Avg latency | 9,793 ms | 9,864 ms | ~Tie |
| Relative cost | **~1×** | ~8–10× | A |

**Result & decision:** Haiku matches Sonnet's average score and trails pass-rate
by a single example — at roughly **1/8th the cost**. So we **adopted a split
strategy**: Sonnet for the vision call (multimodal accuracy is worth it), Haiku
for all text generation (recommendations, ingredient analysis, LLM-judge). This
is exactly how the production code is wired (`claude_vision_model` vs
`claude_chat_model`).

---

## 4. Edge cases — what breaks the system today

The eval surfaced a precise, useful failure mode:

- **`cls_024` (L'Occitane Shea Butter Hand Cream)** fails on **both** models.
- **`cls_017` (Glossier Boy Brow)** fails on Haiku.

Root cause is **not** the model — it's our **category taxonomy**. The golden
labels expect `hand_cream` and `brow_product`, which aren't in our enum, so the
models correctly read the product but can't emit the expected category. This
tells us the next improvement is **expanding the category taxonomy**, not
changing models — a conclusion we'd have missed without evals.

Other known breakers: heavily stylized/foreign-only labels lower confidence
(correctly routed to human review), and products absent from INCIDecoder fall
back to vision-only ingredients (graceful, but no full INCI list).

---

## 5. Reproducing

```bash
# full suite (classification + recommendations + ingredient analysis)
python evals/eval_runner.py --suite all

# single suite
python evals/eval_runner.py --suite classification

# the A/B experiment in §3
python evals/eval_runner.py --ab-test \
  --model-a claude-haiku-4-5-20251001 --model-b claude-sonnet-4-6
```

The runner prints per-example pass/fail + score + latency, a suite summary, and
(with `LANGCHAIN_API_KEY`) uploads results to LangSmith. CI can gate on the built-in
"overall pass rate ≥ 60%" exit code.
