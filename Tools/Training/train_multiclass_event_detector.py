#!/usr/bin/env python3
"""Train a local multiclass sleep sound event classifier when enough data exists."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

from dataset import DatasetError, build_feature_matrix, training_root
from multiclass_event_dataset import (
    MULTICLASS_LABELS,
    encode_labels,
    load_multiclass_config,
    load_multiclass_samples,
    records_for_training,
    resolve_training_path,
    summarize_records,
    write_label_counts,
)


def main() -> int:
    parser = argparse.ArgumentParser(description="Train a local multiclass event classifier baseline.")
    parser.add_argument("--config", default=str(training_root() / "config" / "multiclass_event_detector.yaml"))
    parser.add_argument("--input", help="Samples/Personal style folder containing metadata.")
    parser.add_argument("--metadata", help="Optional metadata.csv/json path inside --input.")
    parser.add_argument("--manifest", help="Optional dataset or feedback export manifest JSON path.")
    parser.add_argument("--output-dir", help="Directory for trained model and metrics.")
    args = parser.parse_args()

    try:
        config = load_multiclass_config(args.config)
        labels = list(config.get("labels", {}).get("classes") or MULTICLASS_LABELS)
        manifest_path = resolve_training_path(args.manifest)
        input_dir = (
            resolve_training_path(args.input, config["dataset"]["input_dir"])
            if manifest_path is None or args.input
            else None
        )
        output_dir = resolve_training_path(args.output_dir, config["output"]["directory"]) or training_root() / "output"

        records = load_multiclass_samples(
            input_dir=input_dir,
            metadata_path=args.metadata,
            manifest_path=manifest_path,
            labels=labels,
        )
        summary = summarize_records(
            records,
            labels=labels,
            min_total_samples=int(config["training"]["min_total_samples"]),
            min_samples_per_class=int(config["training"]["min_samples_per_class"]),
            exclude_underrepresented_labels=bool(config["training"].get("exclude_underrepresented_labels", False)),
            imbalance_warning_ratio=float(config["training"].get("imbalance_warning_ratio", 4.0)),
        )
        output_dir.mkdir(parents=True, exist_ok=True)
        write_label_counts(output_dir / config["output"]["label_counts_filename"], summary)
        _print_summary(summary)

        if not summary.is_trainable:
            print(f"Training skipped: {summary.stop_reason}", file=sys.stderr)
            return 2

        train_records = records_for_training(
            records,
            summary,
            exclude_underrepresented_labels=bool(config["training"].get("exclude_underrepresented_labels", False)),
        )
    except DatasetError as error:
        print(f"Training skipped: {error}", file=sys.stderr)
        return 2

    try:
        deps = _load_training_dependencies()
    except RuntimeError as error:
        print(f"Training skipped: {error}", file=sys.stderr)
        return 2

    np = deps["np"]
    joblib = deps["joblib"]
    LogisticRegression = deps["LogisticRegression"]
    Pipeline = deps["Pipeline"]
    StandardScaler = deps["StandardScaler"]
    train_test_split = deps["train_test_split"]
    classification_report = deps["classification_report"]
    confusion_matrix = deps["confusion_matrix"]

    labels_for_training = summary.trainable_labels
    x, _, feature_columns = build_feature_matrix(train_records, config["dataset"]["feature_columns"])
    y = encode_labels(train_records, labels_for_training)
    x_array = np.asarray(x, dtype=float)
    y_array = np.asarray(y, dtype=int)

    x_train, x_validation, y_train, y_validation = train_test_split(
        x_array,
        y_array,
        test_size=float(config["training"]["test_size"]),
        random_state=int(config["training"]["random_state"]),
        stratify=y_array,
    )

    model = Pipeline(
        steps=[
            ("scaler", StandardScaler()),
            (
                "classifier",
                LogisticRegression(
                    max_iter=1_000,
                    class_weight=config["training"].get("class_weight") or None,
                    random_state=int(config["training"]["random_state"]),
                ),
            ),
        ]
    )
    model.fit(x_train, y_train)
    predictions = model.predict(x_validation)

    metrics = {
        "modelVersion": "Multiclass Event Classifier v0",
        "trainedAt": datetime.now(timezone.utc).isoformat(),
        "labels": labels_for_training,
        "sampleCounts": summary.counts,
        "warnings": summary.warnings,
        "featureColumns": feature_columns,
        "trainSampleCount": int(len(y_train)),
        "validationSampleCount": int(len(y_validation)),
        "classificationReport": classification_report(
            y_validation,
            predictions,
            labels=list(range(len(labels_for_training))),
            target_names=labels_for_training,
            zero_division=0,
            output_dict=True,
        ),
        "confusionMatrix": confusion_matrix(
            y_validation,
            predictions,
            labels=list(range(len(labels_for_training))),
        ).tolist(),
    }

    model_path = output_dir / config["output"]["model_filename"]
    metrics_path = output_dir / config["output"]["evaluation_json_filename"]
    report_path = output_dir / config["output"]["evaluation_markdown_filename"]
    bundle = {
        "model": model,
        "feature_columns": feature_columns,
        "labels": labels_for_training,
        "model_version": metrics["modelVersion"],
        "trained_at": metrics["trainedAt"],
        "config": config,
    }
    joblib.dump(bundle, model_path)
    metrics_path.write_text(json.dumps(metrics, ensure_ascii=False, indent=2), encoding="utf-8")
    report_path.write_text(_make_training_markdown(metrics), encoding="utf-8")

    print(f"Trained multiclass event classifier with {len(train_records)} samples.")
    print(f"Model: {model_path}")
    print(f"Evaluation JSON: {metrics_path}")
    print(f"Evaluation report: {report_path}")
    return 0


def _print_summary(summary) -> None:
    print("label sample counts:")
    for label in summary.labels:
        print(f"- {label}: {summary.counts.get(label, 0)}")
    if summary.warnings:
        print("warnings:")
        for warning in summary.warnings:
            print(f"- {warning}")


def _make_training_markdown(metrics: dict[str, object]) -> str:
    counts = metrics.get("sampleCounts", {})
    labels = metrics.get("labels", [])
    return "\n".join(
        [
            "# Multiclass Event Classifier v0",
            "",
            "이 report는 수면 소리 이벤트 classifier 개발용 요약입니다. 의료적 정확도나 진단 성능을 의미하지 않습니다.",
            "",
            "## Labels",
            "",
            *[f"- {label}: {counts.get(label, 0) if isinstance(counts, dict) else 0}" for label in labels],
            "",
            "## Confusion Matrix",
            "",
            f"```json\n{json.dumps(metrics.get('confusionMatrix', []), ensure_ascii=False)}\n```",
            "",
        ]
    )


def _load_training_dependencies() -> dict[str, object]:
    try:
        import joblib
        import numpy as np
        from sklearn.linear_model import LogisticRegression
        from sklearn.metrics import classification_report, confusion_matrix
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
        "classification_report": classification_report,
        "confusion_matrix": confusion_matrix,
        "train_test_split": train_test_split,
        "Pipeline": Pipeline,
        "StandardScaler": StandardScaler,
    }


if __name__ == "__main__":
    raise SystemExit(main())
