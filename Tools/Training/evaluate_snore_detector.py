#!/usr/bin/env python3
"""Evaluate the local snore detector baseline."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

from dataset import (
    DatasetError,
    build_feature_matrix,
    load_config,
    load_samples,
    resolve_path,
    training_root,
)


THRESHOLDS = [0.30, 0.40, 0.50, 0.60, 0.70]


def main() -> int:
    parser = argparse.ArgumentParser(description="Evaluate a local snore detector baseline.")
    parser.add_argument("--config", default=str(training_root() / "config" / "snore_detector.yaml"))
    parser.add_argument("--input", help="Samples/Personal style folder containing metadata.")
    parser.add_argument("--metadata", help="Optional metadata.csv/json path inside --input.")
    parser.add_argument("--manifest", help="Optional dataset manifest JSON path.")
    parser.add_argument("--model", help="Path to the trained .joblib model bundle.")
    parser.add_argument("--output-dir", help="Optional directory for snore_evaluation.json/md.")
    parser.add_argument("--threshold", type=float, help="Decision threshold override.")
    args = parser.parse_args()

    try:
        config = load_config(args.config)
        manifest_path = resolve_path(args.manifest, training_root()) if args.manifest else None
        input_dir = (
            resolve_path(args.input or config["dataset"]["input_dir"], training_root())
            if manifest_path is None or args.input
            else None
        )
        model_path = resolve_path(
            args.model
            or str(Path(config["output"]["directory"]) / config["output"]["model_filename"]),
            training_root(),
        )
        output_dir = (
            resolve_path(args.output_dir, training_root())
            if args.output_dir
            else None
        )

        if not model_path.exists():
            print(f"Evaluation skipped: trained model not found: {model_path}", file=sys.stderr)
            return 2

        records = load_samples(
            input_dir=input_dir,
            metadata_path=args.metadata,
            manifest_path=manifest_path,
        )
    except DatasetError as error:
        print(f"Evaluation skipped: {error}", file=sys.stderr)
        return 2

    try:
        deps = _load_evaluation_dependencies()
    except RuntimeError as error:
        print(f"Evaluation skipped: {error}", file=sys.stderr)
        return 2

    joblib = deps["joblib"]
    np = deps["np"]
    accuracy_score = deps["accuracy_score"]
    precision_score = deps["precision_score"]
    recall_score = deps["recall_score"]
    f1_score = deps["f1_score"]
    confusion_matrix = deps["confusion_matrix"]

    bundle = joblib.load(model_path)
    model = bundle["model"]
    feature_columns = bundle.get("feature_columns") or config["dataset"]["feature_columns"]
    threshold = float(args.threshold if args.threshold is not None else bundle.get("threshold", 0.5))

    x, y, _ = build_feature_matrix(records, feature_columns)
    x_array = np.asarray(x, dtype=float)
    y_array = np.asarray(y, dtype=int)
    probabilities = model.predict_proba(x_array)[:, 1]
    predictions = (probabilities >= threshold).astype(int)
    threshold_summaries = []
    for candidate_threshold in THRESHOLDS:
        candidate_predictions = (probabilities >= candidate_threshold).astype(int)
        threshold_summaries.append(
            {
                "threshold": candidate_threshold,
                "precision": float(precision_score(y_array, candidate_predictions, zero_division=0)),
                "recall": float(recall_score(y_array, candidate_predictions, zero_division=0)),
            }
        )

    evaluation = {
        "modelVersion": bundle.get("model_version", "Snore ML v0") if isinstance(bundle, dict) else "Snore ML v0",
        "evaluatedAt": datetime.now(timezone.utc).isoformat(),
        "sampleCount": len(records),
        "threshold": threshold,
        "featureColumns": feature_columns,
        "accuracy": float(accuracy_score(y_array, predictions)),
        "precision": float(precision_score(y_array, predictions, zero_division=0)),
        "recall": float(recall_score(y_array, predictions, zero_division=0)),
        "f1": float(f1_score(y_array, predictions, zero_division=0)),
        "confusionMatrix": confusion_matrix(y_array, predictions, labels=[0, 1]).tolist(),
        "thresholdSummaries": threshold_summaries,
    }

    print(f"Model: {model_path}")
    print(f"Samples: {len(records)}")
    print(f"Threshold: {threshold:.2f}")
    print(f"accuracy:  {evaluation['accuracy']:.3f}")
    print(f"precision: {evaluation['precision']:.3f}")
    print(f"recall:    {evaluation['recall']:.3f}")
    print(f"F1:        {evaluation['f1']:.3f}")
    print("confusion matrix [non-snore, snore]:")
    print(evaluation["confusionMatrix"])

    print("\nthreshold precision/recall:")
    for summary in threshold_summaries:
        print(
            f"- {summary['threshold']:.2f}: "
            f"precision={summary['precision']:.3f}, recall={summary['recall']:.3f}"
        )

    false_positives = _mistakes(records, y_array, predictions, probabilities, expected=0, predicted=1)
    false_negatives = _mistakes(records, y_array, predictions, probabilities, expected=1, predicted=0)

    _print_mistakes("false positive samples", false_positives)
    _print_mistakes("false negative samples", false_negatives)

    if output_dir is not None:
        output_dir.mkdir(parents=True, exist_ok=True)
        json_path = output_dir / config["output"].get(
            "evaluation_json_filename",
            "snore_evaluation.json",
        )
        markdown_path = output_dir / config["output"].get(
            "evaluation_markdown_filename",
            "snore_evaluation.md",
        )
        json_path.write_text(json.dumps(evaluation, ensure_ascii=False, indent=2), encoding="utf-8")
        markdown_path.write_text(_make_evaluation_markdown(evaluation), encoding="utf-8")
        print(f"\nEvaluation JSON: {json_path}")
        print(f"Evaluation report: {markdown_path}")
    return 0


def _mistakes(records, y_true, y_pred, probabilities, expected: int, predicted: int):
    mistakes = []
    for record, truth, prediction, probability in zip(records, y_true, y_pred, probabilities):
        if int(truth) == expected and int(prediction) == predicted:
            mistakes.append((record, float(probability)))
    return mistakes


def _print_mistakes(title: str, mistakes) -> None:
    print(f"\n{title}:")
    if not mistakes:
        print("- none")
        return

    for record, probability in mistakes:
        print(
            f"- {record.sample_id} label={record.label} "
            f"p_snore={probability:.3f} file={record.display_name}"
        )


def _make_evaluation_markdown(evaluation: dict[str, object]) -> str:
    return "\n".join(
        [
            "# Snore ML v0 Evaluation",
            "",
            "이 report는 snore vs non-snore detector 개발용 평가 요약입니다. 의료적 정확도나 진단 성능을 의미하지 않습니다.",
            "",
            f"- samples: {evaluation.get('sampleCount', 0)}",
            f"- threshold: {_format_metric(evaluation.get('threshold'))}",
            f"- accuracy: {_format_metric(evaluation.get('accuracy'))}",
            f"- precision: {_format_metric(evaluation.get('precision'))}",
            f"- recall: {_format_metric(evaluation.get('recall'))}",
            f"- f1: {_format_metric(evaluation.get('f1'))}",
            "",
            "## Confusion Matrix",
            "",
            f"```json\n{json.dumps(evaluation.get('confusionMatrix', []), ensure_ascii=False)}\n```",
            "",
        ]
    )


def _format_metric(value: object) -> str:
    try:
        number = float(value)  # type: ignore[arg-type]
    except (TypeError, ValueError):
        return "0.000"
    return f"{number:.3f}"


def _load_evaluation_dependencies() -> dict[str, object]:
    try:
        import joblib
        import numpy as np
        from sklearn.metrics import accuracy_score, confusion_matrix, f1_score, precision_score, recall_score
    except ImportError as error:
        raise RuntimeError(
            "필요한 Python package가 없습니다. "
            "Tools/Training에서 `python3 -m pip install -r requirements.txt`를 실행해 주세요."
        ) from error

    return {
        "joblib": joblib,
        "np": np,
        "accuracy_score": accuracy_score,
        "precision_score": precision_score,
        "recall_score": recall_score,
        "f1_score": f1_score,
        "confusion_matrix": confusion_matrix,
    }


if __name__ == "__main__":
    raise SystemExit(main())
