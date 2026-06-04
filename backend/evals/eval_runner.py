"""
Glowly AI Evaluation Pipeline

Runs automated evals against the golden dataset using LangSmith.

What we evaluate:
  1. Classification Accuracy  — brand, category, application_zone exact match
  2. Confidence Calibration   — confidence score vs expected threshold
  3. Ingredient Detection     — are key ingredients in the detected list?
  4. Recommendation Relevance — LLM-as-judge: do recommendations fit the profile?
  5. Ingredient Conflict Detection — does the model catch known conflicts?

Usage:
    # Run all evals
    python evals/eval_runner.py

    # Run only classification
    python evals/eval_runner.py --suite classification

    # A/B test two model configs
    python evals/eval_runner.py --ab-test --model-a claude-haiku-4-5-20251001 --model-b claude-sonnet-4-6

Environment:
    ANTHROPIC_API_KEY   — required
    LANGCHAIN_API_KEY   — required for LangSmith logging
    LANGCHAIN_PROJECT   — e.g. "glowly-evals"
"""

import argparse
import asyncio
import json
import os
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

# Add backend root to path when running as script
sys.path.insert(0, str(Path(__file__).parent.parent))

from config import configure_langsmith, settings
from services.vision_service import _parse_product_json

configure_langsmith()

DATASET_PATH = Path(__file__).parent / "golden_dataset.json"


# ─── Result types ─────────────────────────────────────────────────────────────

@dataclass
class EvalResult:
    example_id: str
    suite: str
    passed: bool
    score: float          # 0.0 – 1.0
    details: dict = field(default_factory=dict)
    latency_ms: float = 0.0
    error: str | None = None


@dataclass
class EvalSummary:
    suite: str
    total: int
    passed: int
    failed: int
    avg_score: float
    avg_latency_ms: float
    results: list[EvalResult]

    @property
    def pass_rate(self) -> float:
        return self.passed / self.total if self.total else 0.0


# ─── Evaluator functions ──────────────────────────────────────────────────────

def _normalize(s: str) -> str:
    return s.lower().strip()


def eval_classification(example: dict, model_output: dict) -> EvalResult:
    """
    Evaluates product classification accuracy against golden labels.

    Scoring:
      - brand match:    0.2 pts  (fuzzy: model output contains expected brand)
      - category match: 0.4 pts  (exact)
      - zone match:     0.2 pts  (exact)
      - confidence ok:  0.2 pts  (above min or below max as expected)
    """
    expected = example["expected"]
    ex_id = example["id"]
    score = 0.0
    details: dict[str, Any] = {}

    # Brand
    expected_brand = _normalize(expected.get("brand", ""))
    got_brand = _normalize(model_output.get("brand", ""))
    brand_ok = expected_brand in got_brand or got_brand in expected_brand
    if brand_ok or not expected_brand:  # empty expected = any brand acceptable
        score += 0.2
    details["brand"] = {"expected": expected_brand, "got": got_brand, "pass": brand_ok}

    # Category
    expected_cat = _normalize(expected.get("category", ""))
    got_cat = _normalize(model_output.get("category", ""))
    cat_ok = expected_cat == got_cat
    if cat_ok:
        score += 0.4
    details["category"] = {"expected": expected_cat, "got": got_cat, "pass": cat_ok}

    # Application zone (if expected)
    if "application_zone" in expected:
        expected_zone = _normalize(expected["application_zone"])
        got_zone = _normalize(model_output.get("application_zone", ""))
        zone_ok = expected_zone == got_zone
        if zone_ok:
            score += 0.2
        details["zone"] = {"expected": expected_zone, "got": got_zone, "pass": zone_ok}
    else:
        score += 0.2  # no zone requirement — award by default

    # Confidence calibration
    got_confidence = float(model_output.get("confidence", 0.0))
    if "confidence_min" in expected:
        conf_ok = got_confidence >= expected["confidence_min"]
    elif "confidence_max" in expected:
        conf_ok = got_confidence <= expected["confidence_max"]
    else:
        conf_ok = True
    if conf_ok:
        score += 0.2
    details["confidence"] = {
        "got": got_confidence,
        "requirement": expected.get("confidence_min", expected.get("confidence_max", "none")),
        "pass": conf_ok,
    }

    # needs_confirmation
    if "needs_confirmation" in expected:
        nc_ok = bool(model_output.get("needs_confirmation")) == expected["needs_confirmation"]
        details["needs_confirmation"] = {"expected": expected["needs_confirmation"], "got": model_output.get("needs_confirmation"), "pass": nc_ok}
        if not nc_ok:
            score = max(0.0, score - 0.1)

    return EvalResult(
        example_id=ex_id,
        suite="classification",
        passed=score >= 0.6,
        score=score,
        details=details,
    )


async def eval_recommendation(example: dict, llm_judge: bool = True) -> EvalResult:
    """
    Evaluates recommendation relevance using heuristics + optional LLM-as-judge.
    """
    import anthropic

    expected = example["expected_recommendations"]
    ex_id = example["id"]
    user_profile = example["user_profile"]
    existing = example.get("existing_products", [])

    # Call the recommend_routine MCP tool
    from services.mcp_tools import _recommend_routine
    start = time.time()
    result = await _recommend_routine({
        "skin_type": user_profile["skin_type"],
        "skin_conditions": user_profile.get("skin_conditions", []),
        "beauty_goals": user_profile.get("beauty_goals", []),
        "existing_categories": existing,
        "experience_level": user_profile.get("experience_level", "beginner"),
    })
    latency_ms = (time.time() - start) * 1000

    routine_text = json.dumps(result)
    score = 0.0
    details: dict[str, Any] = {}

    # Heuristic: check required categories mentioned
    required_cats = expected.get("required_categories", [])
    cats_found = [c for c in required_cats if c.lower() in routine_text.lower()]
    cat_score = len(cats_found) / len(required_cats) if required_cats else 1.0
    score += cat_score * 0.3
    details["required_categories"] = {"required": required_cats, "found": cats_found, "score": cat_score}

    # Heuristic: check required ingredients mentioned
    must_mention = expected.get("must_mention_ingredients", []) or expected.get("must_mention", [])
    if must_mention:
        found_ingredients = [i for i in must_mention if i.lower() in routine_text.lower()]
        ing_score = len(found_ingredients) / len(must_mention)
        score += ing_score * 0.3
        details["must_mention"] = {"required": must_mention, "found": found_ingredients, "score": ing_score}
    else:
        score += 0.3  # no requirement, award by default

    # Heuristic: check nothing bad is recommended
    must_not = expected.get("must_not_recommend_categories", []) or expected.get("must_not_mention", [])
    if must_not:
        bad_found = [b for b in must_not if b.lower() in routine_text.lower()]
        no_bad_score = 1.0 - (len(bad_found) / len(must_not))
        score += no_bad_score * 0.2
        details["must_not"] = {"required_absent": must_not, "found": bad_found, "score": no_bad_score}
    else:
        score += 0.2

    # LLM-as-judge for overall relevance
    if llm_judge and settings.anthropic_api_key:
        try:
            client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)
            judge_prompt = f"""Rate this skincare routine recommendation on a scale of 1-10.

User profile: {json.dumps(user_profile, indent=2)}

Generated routine: {routine_text[:1500]}

Scoring criteria:
- Is it appropriate for the user's skin type?
- Does it address their skin conditions and goals?
- Is the layering order correct?
- Are the recommendations safe (no harmful combinations)?
- Is the advice specific and actionable?

Return only a JSON object: {{"score": 7, "reasoning": "one sentence"}}"""

            response = await client.messages.create(
                model=settings.claude_chat_model,
                max_tokens=200,
                messages=[{"role": "user", "content": judge_prompt}],
            )
            raw = response.content[0].text
            judge_data = json.loads(raw.strip())
            llm_score = judge_data.get("score", 5) / 10.0
            score += llm_score * 0.2
            details["llm_judge"] = judge_data
        except Exception as exc:
            score += 0.1  # partial credit on LLM judge failure
            details["llm_judge_error"] = str(exc)
    else:
        score += 0.2  # skip LLM judge

    return EvalResult(
        example_id=ex_id,
        suite="recommendations",
        passed=score >= 0.6,
        score=score,
        details=details,
        latency_ms=latency_ms,
    )


async def eval_ingredient_conflict(example: dict) -> EvalResult:
    """
    Tests whether the model correctly identifies ingredient conflicts
    or synergies for known combinations.
    """
    from services.mcp_tools import _analyze_ingredients

    ex_id = example["id"]
    expected = example["expected"]
    ingredients = example["ingredients"]
    skin_type = example.get("skin_type", "normal")

    start = time.time()
    result = await _analyze_ingredients({
        "ingredients": ingredients,
        "skin_type": skin_type,
    })
    latency_ms = (time.time() - start) * 1000

    result_text = json.dumps(result).lower()
    score = 0.0
    details: dict[str, Any] = {}

    # Conflict detection
    if expected.get("must_identify_conflict"):
        conflict_words = expected.get("conflict_keywords", ["conflict", "avoid", "irritation"])
        found = any(w in result_text for w in conflict_words)
        score += 0.5 if found else 0.0
        details["conflict_detected"] = found
    else:
        score += 0.5  # no conflict expected — award half
        details["conflict_not_required"] = True

    # Synergy detection
    if expected.get("must_identify_synergy"):
        synergy_words = expected.get("synergy_keywords", ["synergy", "work well", "compatible"])
        found = any(w in result_text for w in synergy_words)
        score += 0.3 if found else 0.0
        details["synergy_detected"] = found
    else:
        score += 0.3
        details["synergy_not_required"] = True

    # SPF mention for photosensitizing ingredients
    if expected.get("must_mention_spf"):
        spf_found = "spf" in result_text or "sun" in result_text
        score += 0.2 if spf_found else 0.0
        details["spf_mentioned"] = spf_found
    else:
        score += 0.2

    return EvalResult(
        example_id=ex_id,
        suite="ingredient_analysis",
        passed=score >= 0.5,
        score=score,
        details=details,
        latency_ms=latency_ms,
    )


# ─── Mock classification runner (uses vision service parser) ──────────────────

async def run_classification_eval(dataset: dict, model_override: str | None = None) -> EvalSummary:
    """
    Classification eval: feeds pre-computed vision_description + ocr_text through
    the product_classification step (bypasses actual image) for fast, deterministic testing.
    """
    import anthropic
    from services.vision_service import _CLASSIFICATION_TEMPLATE

    examples = dataset["classification_examples"]
    results: list[EvalResult] = []
    client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)
    model = model_override or settings.claude_chat_model

    for ex in examples:
        start = time.time()
        try:
            prompt = _CLASSIFICATION_TEMPLATE.format(
                vision=ex["vision_description"],
                ocr=ex["ocr_text"],
            )
            response = await client.messages.create(
                model=model,
                max_tokens=1024,
                messages=[{"role": "user", "content": prompt}],
            )
            raw = response.content[0].text
            parsed = _parse_product_json(raw)
            model_output = parsed.model_dump()

            result = eval_classification(ex, model_output)
            result.latency_ms = (time.time() - start) * 1000

        except Exception as exc:
            result = EvalResult(
                example_id=ex["id"],
                suite="classification",
                passed=False,
                score=0.0,
                error=str(exc),
                latency_ms=(time.time() - start) * 1000,
            )

        results.append(result)
        status_icon = "✅" if result.passed else "❌"
        print(f"  {status_icon} [{ex['id']}] score={result.score:.2f}  latency={result.latency_ms:.0f}ms")

    return _make_summary("classification", results)


# ─── LangSmith integration ────────────────────────────────────────────────────

def log_to_langsmith(summary: EvalSummary, experiment_name: str) -> None:
    """
    Logs eval results to LangSmith as a dataset + experiment.
    Requires LANGCHAIN_API_KEY to be set.
    """
    if not settings.langchain_api_key:
        print("  [LangSmith] LANGCHAIN_API_KEY not set — skipping upload")
        return

    try:
        from langsmith import Client

        client = Client()
        dataset_name = f"glowly-{summary.suite}-golden"

        # Create or get dataset
        try:
            dataset = client.create_dataset(
                dataset_name=dataset_name,
                description=f"Glowly {summary.suite} golden dataset",
            )
        except Exception:
            dataset = client.read_dataset(dataset_name=dataset_name)

        # Log each result as a run
        project = f"{settings.langchain_project}-evals"
        for result in summary.results:
            client.create_run(
                project_name=project,
                name=f"{experiment_name}/{result.example_id}",
                run_type="evaluator",
                inputs={"example_id": result.example_id},
                outputs={"score": result.score, "details": result.details},
                extra={"passed": result.passed, "latency_ms": result.latency_ms},
            )

        print(
            f"  [LangSmith] Logged {len(summary.results)} results to "
            f"project '{project}'"
        )
    except Exception as exc:
        print(f"  [LangSmith] Upload failed: {exc}")


# ─── Helpers ──────────────────────────────────────────────────────────────────

def _make_summary(suite: str, results: list[EvalResult]) -> EvalSummary:
    passed = sum(1 for r in results if r.passed)
    avg_score = sum(r.score for r in results) / len(results) if results else 0.0
    avg_latency = sum(r.latency_ms for r in results) / len(results) if results else 0.0
    return EvalSummary(
        suite=suite,
        total=len(results),
        passed=passed,
        failed=len(results) - passed,
        avg_score=avg_score,
        avg_latency_ms=avg_latency,
        results=results,
    )


def print_summary(summary: EvalSummary) -> None:
    bar = "=" * 60
    print(f"\n{bar}")
    print(f"  Suite     : {summary.suite}")
    print(f"  Total     : {summary.total}")
    print(f"  Passed    : {summary.passed}  ({summary.pass_rate:.0%})")
    print(f"  Failed    : {summary.failed}")
    print(f"  Avg Score : {summary.avg_score:.3f}")
    print(f"  Avg Latency: {summary.avg_latency_ms:.0f} ms")
    print(f"{bar}\n")


# ─── A/B testing ──────────────────────────────────────────────────────────────

async def run_ab_test(dataset: dict, model_a: str, model_b: str) -> None:
    """
    Runs classification eval twice — once per model — and compares results.
    """
    print(f"\n{'='*60}")
    print(f"A/B Test: {model_a} vs {model_b}")
    print(f"{'='*60}\n")

    print(f"Model A: {model_a}")
    summary_a = await run_classification_eval(dataset, model_override=model_a)

    print(f"\nModel B: {model_b}")
    summary_b = await run_classification_eval(dataset, model_override=model_b)

    print("\n── A/B Comparison ──────────────────────────────────────")
    print(f"{'Metric':<25} {'Model A':>15} {'Model B':>15} {'Winner':>10}")
    print("─" * 65)
    metrics = [
        ("Pass Rate", summary_a.pass_rate, summary_b.pass_rate, True),
        ("Avg Score", summary_a.avg_score, summary_b.avg_score, True),
        ("Avg Latency (ms)", summary_a.avg_latency_ms, summary_b.avg_latency_ms, False),
    ]
    for name, val_a, val_b, higher_is_better in metrics:
        if higher_is_better:
            winner = "A" if val_a > val_b else ("B" if val_b > val_a else "Tie")
        else:
            winner = "A" if val_a < val_b else ("B" if val_b < val_a else "Tie")
        print(f"{name:<25} {val_a:>15.3f} {val_b:>15.3f} {winner:>10}")

    # Log both to LangSmith
    log_to_langsmith(summary_a, f"ab-model-a-{model_a}")
    log_to_langsmith(summary_b, f"ab-model-b-{model_b}")


# ─── Main ─────────────────────────────────────────────────────────────────────

async def main(args: argparse.Namespace) -> None:
    if not settings.anthropic_api_key:
        print("❌ ANTHROPIC_API_KEY not set. Cannot run evals.")
        sys.exit(1)

    # Initialize RAG (needed for recommendation and ingredient evals)
    from services.rag_service import rag_service
    rag_service.initialize()

    with open(DATASET_PATH) as f:
        dataset = json.load(f)

    experiment_name = f"glowly-eval-{int(time.time())}"
    print(f"\nExperiment: {experiment_name}")

    if args.ab_test:
        await run_ab_test(dataset, args.model_a, args.model_b)
        return

    summaries: list[EvalSummary] = []

    if args.suite in ("all", "classification"):
        print("\n── Classification Evaluation ─────────────────────────────")
        summary = await run_classification_eval(dataset)
        print_summary(summary)
        log_to_langsmith(summary, experiment_name)
        summaries.append(summary)

    if args.suite in ("all", "recommendations"):
        print("\n── Recommendation Evaluation ─────────────────────────────")
        rec_results: list[EvalResult] = []
        for ex in dataset["recommendation_examples"]:
            result = await eval_recommendation(ex, llm_judge=args.llm_judge)
            icon = "✅" if result.passed else "❌"
            print(f"  {icon} [{ex['id']}] score={result.score:.2f}")
            rec_results.append(result)
        summary = _make_summary("recommendations", rec_results)
        print_summary(summary)
        log_to_langsmith(summary, experiment_name)
        summaries.append(summary)

    if args.suite in ("all", "ingredients"):
        print("\n── Ingredient Conflict Evaluation ────────────────────────")
        ing_results: list[EvalResult] = []
        for ex in dataset["ingredient_analysis_examples"]:
            result = await eval_ingredient_conflict(ex)
            icon = "✅" if result.passed else "❌"
            print(f"  {icon} [{ex['id']}] score={result.score:.2f}")
            ing_results.append(result)
        summary = _make_summary("ingredient_analysis", ing_results)
        print_summary(summary)
        log_to_langsmith(summary, experiment_name)
        summaries.append(summary)

    # Overall summary
    if summaries:
        total_passed = sum(s.passed for s in summaries)
        total_examples = sum(s.total for s in summaries)
        overall_score = sum(s.avg_score for s in summaries) / len(summaries)
        print(f"\n{'═'*60}")
        print(f"  OVERALL RESULT")
        print(f"  Pass rate : {total_passed}/{total_examples} ({total_passed/total_examples:.0%})")
        print(f"  Avg Score : {overall_score:.3f}")
        print(f"{'═'*60}\n")

        # Exit 1 if overall pass rate < 60%
        if total_passed / total_examples < 0.6:
            print("⚠️  Pass rate below 60% threshold.")
            sys.exit(1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Glowly AI Evaluation Runner")
    parser.add_argument(
        "--suite",
        choices=["all", "classification", "recommendations", "ingredients"],
        default="all",
        help="Which eval suite to run",
    )
    parser.add_argument(
        "--llm-judge",
        action="store_true",
        default=True,
        help="Use LLM-as-judge for recommendation evals",
    )
    parser.add_argument(
        "--ab-test",
        action="store_true",
        default=False,
        help="Run A/B test between two models",
    )
    parser.add_argument(
        "--model-a",
        default="claude-haiku-4-5-20251001",
        help="Model A for A/B testing",
    )
    parser.add_argument(
        "--model-b",
        default="claude-sonnet-4-6",
        help="Model B for A/B testing",
    )
    args = parser.parse_args()
    asyncio.run(main(args))
