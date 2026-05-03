#!/usr/bin/env python3
"""Train the first local snore vs non-snore baseline detector."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

from dataset import (
    DatasetError,
    InsufficientDataError,
    NEGATIVE_LABELS,
    POSITIVE_LABEL,
    build_feature_matrix,
    class_counts,
    load_config,
    load_samples,
    resolve_path,
    training_root,
    validate_for_training,
)


def main() -> int:
    parser = argparse.ArgumentParser(description="Train a local snore detector baseline.")
    parser.add_argument("--config", default=str(training_root() / "config" / "snore_detector.yaml"))
    parser.add_argument("--input", help="Samples/Personal style folder containing metadata.")
    parser.add_argument("--metadata", help="Optional metadata.csv/json path inside --input.")
    parser.add_argument("--manifest", help="Optional dataset manifest JSON path.")
    parser.add_argument("--output-dir", help="Directory for trained model and metrics.")
    args = parser.parse_args()

    try:
        config = load_config(args.config)
        manifest_path = resolve_path(args.manifest, training_root()) if args.manifest else None
        input_dir = (
            resolve_path(args.input or config["dataset"]["input_dir"], training_root())
            if manifest_path is None or args.input
            else None
        )
        output_dir = resolve_path(args.output_dir or config["output"]["directory"], training_root())

        records = load_samples(
            input_dir=input_dir,
            metadata_path=args.metadata,
            manifest_path=manifest_path,
        )
        validate_for_training(
            records,
            min_total=int(config["training"]["min_total_samples"]),
            min_positive=int(config["training"]["min_positive_samples"]),
            min_negative=int(config["training"]["min_negative_samples"]),
        )
    except (DatasetError, InsufficientDataError) as error:
        print(f"Training skipped: {error}", file=sys.stderr)
        return 2

    try:
        deps = _load_training_dependencies()
    except RuntimeError as error:
        print(f"Training skipped: {error}", file=sys.stderr)
        return 2

    x, y, feature_columns = build_feature_matrix(records, config["dataset"]["feature_columns"])
    np = deps["np"]
    joblib = deps["joblib"]
    LogisticRegression = deps["LogisticRegression"]
    Pipeline = deps["Pipeline"]
    StandardScaler = deps["StandardScaler"]
    train_test_split = deps["train_test_split"]
    accuracy_score = deps["accuracy_score"]
    precision_score = deps["precision_score"]
    recall_score = deps["recall_score"]
    f1_score = deps["f1_score"]
    confusion_matrix = deps["confusion_matrix"]

    x_array = np.asarray(x, dtype=float)
    y_array = np.asarray(y, dtype=int)
    test_size = float(config["training"]["test_size"])
    random_state = int(config["training"]["random_state"])
    class_weight = config["training"].get("class_weight") or None
    threshold = float(config["training"]["threshold"])

    x_train, x_test, y_train, y_test = train_test_split(
        x_array,
        y_array,
        test_size=test_size,
        random_state=random_state,
        stratify=y_array,
    )

    model = Pipeline(
        steps=[
            ("scaler", StandardScaler()),
            (
                "classifier",
                LogisticRegression(
                    max_iter=1_000,
                    class_weight=class_weight,
                    random_state=random_state,
                ),
            ),
        ]
    )
    model.fit(x_train, y_train)

    probabilities = model.predict_proba(x_test)[:, 1]
    predictions = (probabilities >= threshold).astype(int)
    metrics = {
        "modelVersion": "Snore ML v0",
        "trainedAt": datetime.now(timezone.utc).isoformat(),
        "sampleCounts": class_counts(records),
        "trainSampleCount": int(len(y_train)),
        "validationSampleCount": int(len(y_test)),
        "featureColumns": feature_columns,
        "positiveLabel": POSITIVE_LABEL,
        "negativeLabels": sorted(NEGATIVE_LABELS),
        "threshold": threshold,
        "accuracy": float(accuracy_score(y_test, predictions)),
        "precision": float(precision_score(y_test, predictions, zero_division=0)),
        "recall": float(recall_score(y_test, predictions, zero_division=0)),
        "f1": float(f1_score(y_test, predictions, zero_division=0)),
        "confusionMatrix": confusion_matrix(y_test, predictions, labels=[0, 1]).tolist(),
    }

    output_dir.mkdir(parents=True, exist_ok=True)
    model_path = output_dir / config["output"]["model_filename"]
    metrics_path = output_dir / (
        config["output"].get("evaluation_json_filename")
        or config["output"].get("metrics_filename")
        or "snore_evaluation.json"
    )
    report_path = output_dir / config["output"].get(
        "evaluation_markdown_filename",
        "snore_evaluation.md",
    )
    bundle = {
        "model": model,
        "feature_columns": feature_columns,
        "threshold": threshold,
        "positive_label": POSITIVE_LABEL,
        "negative_labels": sorted(NEGATIVE_LABELS),
        "model_version": metrics["modelVersion"],
        "trained_at": metrics["trainedAt"],
        "config": config,
    }
    joblib.dump(bundle, model_path)
    metrics_path.write_text(json.dumps(metrics, ensure_ascii=False, indent=2), encoding="utf-8")
    report_path.write_text(_make_evaluation_markdown(metrics), encoding="utf-8")

    print(f"Trained snore detector with {len(records)} samples.")
    print(f"Model: {model_path}")
    print(f"Evaluation JSON: {metrics_path}")
    print(f"Evaluation report: {report_path}")
    print(
        "Validation: "
        f"accuracy={metrics['accuracy']:.3f} "
        f"precision={metrics['precision']:.3f} "
        f"recall={metrics['recall']:.3f} "
        f"f1={metrics['f1']:.3f}"
    )
    return 0


def _make_evaluation_markdown(metrics: dict[str, object]) -> str:
    counts = metrics.get("sampleCounts", {})
    if not isinstance(counts, dict):
        counts = {}

    confusion = metrics.get("confusionMatrix", [[0, 0], [0, 0]])

    return "\n".join(
        [
            "# Snore ML v0 Evaluation",
            "",
            "이 report는 snore vs non-snore detector 개발용 baseline 요약입니다. 의료적 정확도나 진단 성능을 의미하지 않습니다.",
            "",
            "## Dataset",
            "",
            f"- total samples: {counts.get('total', 0)}",
            f"- snore positive: {counts.get('positive', 0)}",
            f"- non-snore negative: {counts.get('negative', 0)}",
            f"- train samples: {metrics.get('trainSampleCount', 0)}",
            f"- validation samples: {metrics.get('validationSampleCount', 0)}",
            "",
            "## Metrics",
            "",
            f"- threshold: {_format_metric(metrics.get('threshold'))}",
            f"- accuracy: {_format_metric(metrics.get('accuracy'))}",
            f"- precision: {_format_metric(metrics.get('precision'))}",
            f"- recall: {_format_metric(metrics.get('recall'))}",
            f"- f1: {_format_metric(metrics.get('f1'))}",
            "",
            "## Confusion Matrix",
            "",
            "`[[true non-snore predicted non-snore, true non-snore predicted snore], [true snore predicted non-snore, true snore predicted snore]]`",
            "",
            f"```json\n{json.dumps(confusion, ensure_ascii=False)}\n```",
            "",
            "## Next Checks",
            "",
            "- false-positive-like 후보는 Offline Evaluation baseline report와 함께 확인합니다.",
            "- false-negative-like 후보는 snore expected segment에서 final snore event가 없는 경우를 우선 검토합니다.",
            "- 실제 iPhone threshold는 별도 기기 테스트와 함께 보수적으로 확인합니다.",
            "",
        ]
    )


def _format_metric(value: object) -> str:
    try:
        number = float(value)  # type: ignore[arg-type]
    except (TypeError, ValueError):
        return "0.000"
    return f"{number:.3f}"


def _load_training_dependencies() -> dict[str, object]:
    try:
        import joblib
        import numpy as np
        from sklearn.linear_model import LogisticRegression
        from sklearn.metrics import accuracy_score, confusion_matrix, f1_score, precision_score, recall_score
        from sklearn.model_selection import train_test_split
        from sklearn.pipeline import Pipeline
        from sklearn.preprocessing import StandardScaler
    except ImportError as error:
        raise RuntimeError(
            "필요한 Python package가 없습니다. "
            "Tools/Training에서 `python3 -m pip install -r requirements.txt`를 실행해 주세요."
        ) from error

    return {
        "joblib": joblib,
        "np": np,
        "LogisticRegression": LogisticRegression,
        "accuracy_score": accuracy_score,
        "precision_score": precision_score,
        "recall_score": recall_score,
        "f1_score": f1_score,
        "confusion_matrix": confusion_matrix,
        "train_test_split": train_test_split,
        "Pipeline": Pipeline,
        "StandardScaler": StandardScaler,
    }


if __name__ == "__main__":
    raise SystemExit(main())
