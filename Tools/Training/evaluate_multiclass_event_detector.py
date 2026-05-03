#!/usr/bin/env python3
"""Evaluate a local multiclass event classifier for detector development."""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

from dataset import DatasetError, build_feature_matrix, training_root
from multiclass_event_dataset import (
    MULTICLASS_LABELS,
    label_counts,
    load_multiclass_config,
    load_multiclass_samples,
    resolve_training_path,
)


def main() -> int:
    parser = argparse.ArgumentParser(description="Evaluate a local multiclass event classifier.")
    parser.add_argument("--config", default=str(training_root() / "config" / "multiclass_event_detector.yaml"))
    parser.add_argument("--input", help="Samples/Personal style folder containing metadata.")
    parser.add_argument("--metadata", help="Optional metadata.csv/json path inside --input.")
    parser.add_argument("--manifest", help="Optional dataset or feedback export manifest JSON path.")
    parser.add_argument("--model", help="Path to trained multiclass model bundle.")
    parser.add_argument("--output-dir", help="Optional directory for evaluation JSON/markdown.")
    args = parser.parse_args()

    try:
        config = load_multiclass_config(args.config)
        labels = list(config.get("labels", {}).get("classes") or MULTICLASS_LABELS)
        model_path = resolve_training_path(
            args.model,
            Path(config["output"]["directory"]) / config["output"]["model_filename"],
        )
        if model_path is None or not model_path.exists():
            print(f"Evaluation skipped: trained multiclass model not found: {model_path}", file=sys.stderr)
            return 2

        manifest_path = resolve_training_path(args.manifest)
        input_dir = (
            resolve_training_path(args.input, config["dataset"]["input_dir"])
            if manifest_path is None or args.input
            else None
        )
        records = load_multiclass_samples(
            input_dir=input_dir,
            metadata_path=args.metadata,
            manifest_path=manifest_path,
            labels=labels,
        )
        if not records:
            print("Evaluation skipped: no multiclass samples found.", file=sys.stderr)
            return 2
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
    classification_report = deps["classification_report"]
    confusion_matrix = deps["confusion_matrix"]

    bundle = joblib.load(model_path)
    model = bundle["model"]
    trained_labels = list(bundle.get("labels") or labels)
    feature_columns = bundle.get("feature_columns") or config["dataset"]["feature_columns"]

    records = [record for record in records if record.label in set(trained_labels)]
    x, _, _ = build_feature_matrix(records, feature_columns)
    y_true = [trained_labels.index(record.label) for record in records]
    x_array = np.asarray(x, dtype=float)
    y_array = np.asarray(y_true, dtype=int)
    predictions = model.predict(x_array)
    probabilities = _safe_probabilities(model, x_array)

    evaluation = {
        "modelVersion": bundle.get("model_version", "Multiclass Event Classifier v0"),
        "evaluatedAt": datetime.now(timezone.utc).isoformat(),
        "sampleCount": len(records),
        "labels": trained_labels,
        "sampleCounts": label_counts(records, trained_labels),
        "classificationReport": classification_report(
            y_array,
            predictions,
            labels=list(range(len(trained_labels))),
            target_names=trained_labels,
            zero_division=0,
            output_dict=True,
        ),
        "confusionMatrix": confusion_matrix(
            y_array,
            predictions,
            labels=list(range(len(trained_labels))),
        ).tolist(),
        "falsePositiveLikeCases": false_positive_like_cases(records, y_array, predictions, probabilities, trained_labels),
        "falseNegativeLikeCases": false_negative_like_cases(records, y_array, predictions, probabilities, trained_labels),
        "confidenceDistribution": confidence_distribution(probabilities),
    }

    _print_evaluation(evaluation)

    output_dir = resolve_training_path(args.output_dir) if args.output_dir else None
    if output_dir is not None:
        output_dir.mkdir(parents=True, exist_ok=True)
        json_path = output_dir / config["output"]["evaluation_json_filename"]
        markdown_path = output_dir / config["output"]["evaluation_markdown_filename"]
        json_path.write_text(json.dumps(evaluation, ensure_ascii=False, indent=2), encoding="utf-8")
        markdown_path.write_text(_make_markdown(evaluation), encoding="utf-8")
        print(f"Evaluation JSON: {json_path}")
        print(f"Evaluation report: {markdown_path}")
    return 0


def false_positive_like_cases(records, y_true, y_pred, probabilities, labels):
    cases = []
    for record, truth, prediction, probability in zip(records, y_true, y_pred, max_confidences(probabilities)):
        if int(truth) != int(prediction):
            cases.append(
                {
                    "sampleId": record.sample_id,
                    "expectedLabel": labels[int(truth)],
                    "predictedLabel": labels[int(prediction)],
                    "confidence": probability,
                    "file": record.display_name,
                }
            )
    return cases


def false_negative_like_cases(records, y_true, y_pred, probabilities, labels):
    missed_by_label = []
    for record, truth, prediction, probability in zip(records, y_true, y_pred, max_confidences(probabilities)):
        if int(truth) != int(prediction):
            missed_by_label.append(
                {
                    "sampleId": record.sample_id,
                    "expectedLabel": labels[int(truth)],
                    "predictedLabel": labels[int(prediction)],
                    "confidence": probability,
                    "file": record.display_name,
                }
            )
    return missed_by_label


def confidence_distribution(probabilities) -> dict[str, int]:
    buckets: Counter[str] = Counter()
    for confidence in max_confidences(probabilities):
        if confidence < 0.40:
            buckets["0.00-0.39"] += 1
        elif confidence < 0.60:
            buckets["0.40-0.59"] += 1
        elif confidence < 0.80:
            buckets["0.60-0.79"] += 1
        else:
            buckets["0.80-1.00"] += 1
    return dict(buckets)


def max_confidences(probabilities):
    if probabilities is None:
        return []
    return [float(max(row)) for row in probabilities]


def _safe_probabilities(model, x_array):
    if hasattr(model, "predict_proba"):
        return model.predict_proba(x_array)
    predictions = model.predict(x_array)
    buckets = defaultdict(list)
    for prediction in predictions:
        buckets[int(prediction)].append(1.0)
    return [[1.0] for _ in predictions]


def _print_evaluation(evaluation: dict[str, object]) -> None:
    print("Multiclass event evaluation complete")
    print(f"samples: {evaluation.get('sampleCount', 0)}")
    print("label sample counts:")
    sample_counts = evaluation.get("sampleCounts", {})
    if isinstance(sample_counts, dict):
        for label, count in sample_counts.items():
            print(f"- {label}: {count}")
    print("confidence distribution:")
    distribution = evaluation.get("confidenceDistribution", {})
    if isinstance(distribution, dict):
        for bucket, count in sorted(distribution.items()):
            print(f"- {bucket}: {count}")


def _make_markdown(evaluation: dict[str, object]) -> str:
    return "\n".join(
        [
            "# Multiclass Event Classifier Evaluation",
            "",
            "이 report는 detector 개발용 비교 자료입니다. 의료적 정확도나 진단 성능을 의미하지 않습니다.",
            "",
            f"- samples: {evaluation.get('sampleCount', 0)}",
            f"- false-positive-like cases: {len(evaluation.get('falsePositiveLikeCases', []))}",
            f"- false-negative-like cases: {len(evaluation.get('falseNegativeLikeCases', []))}",
            "",
            "## Confusion Matrix",
            "",
            f"```json\n{json.dumps(evaluation.get('confusionMatrix', []), ensure_ascii=False)}\n```",
            "",
        ]
    )


def _load_evaluation_dependencies() -> dict[str, object]:
    try:
        import joblib
        import numpy as np
        from sklearn.metrics import classification_report, confusion_matrix
    except ImportError as error:
        raise RuntimeError(
            "필요한 Python package가 없습니다. "
            "Tools/Training에서 `python3 -m pip install -r requirements.txt`를 실행해 주세요."
        ) from error

    return {
        "joblib": joblib,
        "np": np,
        "classification_report": classification_report,
        "confusion_matrix": confusion_matrix,
    }


if __name__ == "__main__":
    raise SystemExit(main())
