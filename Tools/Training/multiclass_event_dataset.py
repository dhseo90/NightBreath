#!/usr/bin/env python3
"""Shared helpers for the local multiclass event classifier pipeline."""

from __future__ import annotations

import copy
import json
import math
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

from audio_features import FEATURE_COLUMNS
from dataset import DatasetError, SampleRecord, load_samples, training_root

MULTICLASS_LABELS = [
    "snore",
    "bruxismLike",
    "gaspLike",
    "coughLike",
    "movementLike",
    "environmentalNoise",
    "sleepTalkLike",
    "unknown",
    "silence",
]

DEFAULT_MULTICLASS_CONFIG: dict[str, Any] = {
    "dataset": {
        "input_dir": "../../Samples/Personal",
        "feature_columns": FEATURE_COLUMNS,
    },
    "labels": {
        "classes": MULTICLASS_LABELS,
        "unknown_label": "unknown",
    },
    "training": {
        "min_total_samples": 180,
        "min_samples_per_class": 20,
        "recommended_samples_per_class": 100,
        "exclude_underrepresented_labels": False,
        "imbalance_warning_ratio": 4.0,
        "test_size": 0.25,
        "random_state": 42,
        "class_weight": "balanced",
    },
    "output": {
        "directory": "output",
        "model_filename": "multiclass_event_model.pkl",
        "evaluation_json_filename": "multiclass_event_evaluation.json",
        "evaluation_markdown_filename": "multiclass_event_evaluation.md",
        "label_counts_filename": "multiclass_event_label_counts.json",
    },
}


@dataclass(frozen=True)
class MulticlassDatasetSummary:
    labels: list[str]
    counts: dict[str, int]
    total_samples: int
    trainable_labels: list[str]
    skipped_labels: list[str]
    warnings: list[str]
    is_trainable: bool
    stop_reason: str = ""


class MulticlassDataGuardError(DatasetError):
    """Raised when multiclass training should not start."""


def load_multiclass_config(path: str | Path | None) -> dict[str, Any]:
    config = copy.deepcopy(DEFAULT_MULTICLASS_CONFIG)
    if path is None:
        return config

    config_path = Path(path)
    if not config_path.exists():
        return config

    try:
        import yaml  # type: ignore
    except ImportError:
        return config

    with config_path.open("r", encoding="utf-8") as handle:
        loaded = yaml.safe_load(handle) or {}

    if not isinstance(loaded, dict):
        raise DatasetError(f"config 형식이 올바르지 않습니다: {config_path}")

    return deep_merge(config, loaded)


def load_multiclass_samples(
    input_dir: str | Path | None = None,
    metadata_path: str | Path | None = None,
    manifest_path: str | Path | None = None,
    labels: Iterable[str] = MULTICLASS_LABELS,
) -> list[SampleRecord]:
    allowed = set(labels)
    records = load_samples(input_dir=input_dir, metadata_path=metadata_path, manifest_path=manifest_path)
    return [record for record in records if record.label in allowed]


def summarize_records(
    records: Iterable[SampleRecord],
    labels: Iterable[str] = MULTICLASS_LABELS,
    min_total_samples: int = 180,
    min_samples_per_class: int = 20,
    exclude_underrepresented_labels: bool = False,
    imbalance_warning_ratio: float = 4.0,
) -> MulticlassDatasetSummary:
    labels = list(labels)
    counts = label_counts(records, labels)
    total = sum(counts.values())
    underrepresented = [label for label in labels if counts.get(label, 0) < min_samples_per_class]
    warnings = class_count_warnings(counts, min_samples_per_class)
    warnings.extend(class_imbalance_warnings(counts, imbalance_warning_ratio))

    trainable_labels = [label for label in labels if counts.get(label, 0) >= min_samples_per_class]
    skipped_labels = underrepresented if exclude_underrepresented_labels else []
    stop_reason = ""

    if total < min_total_samples:
        stop_reason = f"전체 sample {min_total_samples}개 이상 필요, 현재 {total}개"
    elif exclude_underrepresented_labels and len(trainable_labels) < 2:
        stop_reason = "학습 가능한 label이 2개 미만입니다."
    elif not exclude_underrepresented_labels and underrepresented:
        stop_reason = "최소 sample 수 미달 label이 있어 학습을 시작하지 않습니다: " + ", ".join(underrepresented)

    return MulticlassDatasetSummary(
        labels=labels,
        counts=counts,
        total_samples=total,
        trainable_labels=trainable_labels if exclude_underrepresented_labels else labels,
        skipped_labels=skipped_labels,
        warnings=warnings,
        is_trainable=stop_reason == "",
        stop_reason=stop_reason,
    )


def records_for_training(
    records: list[SampleRecord],
    summary: MulticlassDatasetSummary,
    exclude_underrepresented_labels: bool,
) -> list[SampleRecord]:
    if not exclude_underrepresented_labels:
        return [record for record in records if record.label in set(summary.labels)]

    trainable = set(summary.trainable_labels)
    return [record for record in records if record.label in trainable]


def label_counts(records: Iterable[SampleRecord], labels: Iterable[str] = MULTICLASS_LABELS) -> dict[str, int]:
    counts = {label: 0 for label in labels}
    for record in records:
        if record.label in counts:
            counts[record.label] += 1
    return counts


def class_count_warnings(counts: dict[str, int], min_samples_per_class: int) -> list[str]:
    return [
        f"{label}: sample {min_samples_per_class}개 이상 권장, 현재 {count}개"
        for label, count in counts.items()
        if count < min_samples_per_class
    ]


def class_imbalance_warnings(counts: dict[str, int], ratio: float = 4.0) -> list[str]:
    nonzero = [count for count in counts.values() if count > 0]
    if len(nonzero) < 2:
        return []

    smallest = min(nonzero)
    largest = max(nonzero)
    if smallest <= 0 or not math.isfinite(ratio) or ratio <= 1:
        return []
    if largest / smallest < ratio:
        return []
    return [f"class imbalance warning: max/min sample ratio {largest / smallest:.1f}x"]


def label_indices(labels: Iterable[str]) -> dict[str, int]:
    return {label: index for index, label in enumerate(labels)}


def encode_labels(records: Iterable[SampleRecord], labels: Iterable[str]) -> list[int]:
    indices = label_indices(labels)
    return [indices[record.label] for record in records]


def write_label_counts(path: Path, summary: MulticlassDatasetSummary) -> None:
    payload = {
        "labels": summary.labels,
        "counts": summary.counts,
        "totalSamples": summary.total_samples,
        "trainableLabels": summary.trainable_labels,
        "skippedLabels": summary.skipped_labels,
        "warnings": summary.warnings,
        "isTrainable": summary.is_trainable,
        "stopReason": summary.stop_reason,
    }
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True), encoding="utf-8")


def resolve_training_path(path_value: str | Path | None, fallback: str | Path | None = None) -> Path | None:
    value = path_value if path_value is not None else fallback
    if value is None:
        return None
    path = Path(value).expanduser()
    if path.is_absolute():
        return path.resolve()
    if path_value is not None:
        return Path.cwd().joinpath(path).resolve()
    return training_root().joinpath(path).resolve()


def deep_merge(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    result = copy.deepcopy(base)
    for key, value in override.items():
        if isinstance(value, dict) and isinstance(result.get(key), dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = value
    return result
