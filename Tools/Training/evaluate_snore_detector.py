#!/usr/bin/env python3
"""Evaluate the local snore detector baseline."""

from __future__ import annotations

import argparse
import sys
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
    parser.add_argument("--model", help="Path to the trained .joblib model bundle.")
    parser.add_argument("--threshold", type=float, help="Decision threshold override.")
    args = parser.parse_args()

    try:
        config = load_config(args.config)
        input_dir = resolve_path(args.input or config["dataset"]["input_dir"], training_root())
        model_path = resolve_path(
            args.model
            or str(Path(config["output"]["directory"]) / config["output"]["model_filename"]),
            training_root(),
        )

        if not model_path.exists():
            print(f"Evaluation skipped: trained model not found: {model_path}", file=sys.stderr)
            return 2

        records = load_samples(input_dir=input_dir, metadata_path=args.metadata)
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

    print(f"Model: {model_path}")
    print(f"Samples: {len(records)}")
    print(f"Threshold: {threshold:.2f}")
    print(f"accuracy:  {accuracy_score(y_array, predictions):.3f}")
    print(f"precision: {precision_score(y_array, predictions, zero_division=0):.3f}")
    print(f"recall:    {recall_score(y_array, predictions, zero_division=0):.3f}")
    print(f"F1:        {f1_score(y_array, predictions, zero_division=0):.3f}")
    print("confusion matrix [non-snore, snore]:")
    print(confusion_matrix(y_array, predictions, labels=[0, 1]))

    print("\nthreshold precision/recall:")
    for candidate_threshold in THRESHOLDS:
        candidate_predictions = (probabilities >= candidate_threshold).astype(int)
        precision = precision_score(y_array, candidate_predictions, zero_division=0)
        recall = recall_score(y_array, candidate_predictions, zero_division=0)
        print(f"- {candidate_threshold:.2f}: precision={precision:.3f}, recall={recall:.3f}")

    false_positives = _mistakes(records, y_array, predictions, probabilities, expected=0, predicted=1)
    false_negatives = _mistakes(records, y_array, predictions, probabilities, expected=1, predicted=0)

    _print_mistakes("false positive samples", false_positives)
    _print_mistakes("false negative samples", false_negatives)
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
