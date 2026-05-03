#!/usr/bin/env python3
"""Dataset loading utilities for the local snore detector pipeline."""

from __future__ import annotations

import copy
import csv
import json
import math
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

from audio_features import FEATURE_COLUMNS, safe_float


POSITIVE_LABEL = "snore"
NEGATIVE_LABELS = {
    "bruxismLike",
    "gaspLike",
    "silence",
    "unknown",
    "environmentalNoise",
    "movementLike",
    "coughLike",
    "sleepTalkLike",
}
KNOWN_LABELS = {POSITIVE_LABEL, *NEGATIVE_LABELS}

DEFAULT_CONFIG: dict[str, Any] = {
    "dataset": {
        "input_dir": "../../Samples/Personal",
        "feature_columns": FEATURE_COLUMNS,
    },
    "training": {
        "min_total_samples": 40,
        "min_positive_samples": 20,
        "min_negative_samples": 20,
        "test_size": 0.25,
        "random_state": 42,
        "class_weight": "balanced",
        "threshold": 0.5,
    },
    "output": {
        "directory": "output",
        "model_filename": "snore_model.pkl",
        "evaluation_json_filename": "snore_evaluation.json",
        "evaluation_markdown_filename": "snore_evaluation.md",
        "feature_export_filename": "snore_features.csv",
    },
}


@dataclass(frozen=True)
class SampleRecord:
    sample_id: str
    label: str
    target: int
    features: dict[str, float]
    audio_path: str
    source_path: str
    notes: str = ""
    captured_at: str = ""
    label_confidence: float = 1.0
    training_action: str = ""

    @property
    def display_name(self) -> str:
        if self.audio_path:
            return Path(self.audio_path).name
        return self.sample_id


class DatasetError(Exception):
    """Base class for friendly dataset errors."""


class NoSamplesFound(DatasetError):
    """Raised when no metadata or feature records can be loaded."""


class InsufficientDataError(DatasetError):
    """Raised when the dataset is too small or too imbalanced for training."""


def project_root() -> Path:
    return Path(__file__).resolve().parents[2]


def training_root() -> Path:
    return Path(__file__).resolve().parent


def resolve_path(path_value: str | Path, base_dir: Path | None = None) -> Path:
    path = Path(path_value)
    if path.is_absolute():
        return path
    cwd_candidate = Path.cwd().joinpath(path)
    if cwd_candidate.exists():
        return cwd_candidate.resolve()
    return (base_dir or training_root()).joinpath(path).resolve()


def load_config(path: str | Path | None) -> dict[str, Any]:
    config = copy.deepcopy(DEFAULT_CONFIG)
    if path is None:
        return config

    config_path = Path(path)
    if not config_path.exists():
        return config

    try:
        import yaml  # type: ignore
    except ImportError:
        print(
            "PyYAML이 없어 config 파일을 건너뜁니다. 기본 설정으로 계속합니다.",
            file=sys.stderr,
        )
        return config

    with config_path.open("r", encoding="utf-8") as handle:
        loaded = yaml.safe_load(handle) or {}

    if not isinstance(loaded, dict):
        raise DatasetError(f"config 형식이 올바르지 않습니다: {config_path}")

    return _deep_merge(config, loaded)


def load_samples(
    input_dir: str | Path | None = None,
    metadata_path: str | Path | None = None,
    manifest_path: str | Path | None = None,
) -> list[SampleRecord]:
    if manifest_path is not None:
        manifest_file = _resolve_manifest_path(manifest_path)
        records = _load_manifest_file(manifest_file)
        deduped = _dedupe(records)
        if not deduped:
            raise NoSamplesFound(
                "manifest는 찾았지만 학습 가능한 snore/non-snore segment feature record가 없습니다.\n"
                "expectedLabels와 features/duration 값을 확인하거나 feature metadata를 사용해 주세요."
            )
        return deduped

    if input_dir is None:
        raise NoSamplesFound("샘플 폴더 또는 manifest path가 지정되지 않았습니다.")

    root = Path(input_dir).expanduser().resolve()
    if not root.exists():
        raise NoSamplesFound(
            f"샘플 폴더를 찾을 수 없습니다: {root}\n"
            "DEBUG 샘플 수집 화면에서 짧은 샘플을 만들거나, metadata.csv/json을 준비해 주세요."
        )

    paths = [_resolve_metadata_path(root, metadata_path)] if metadata_path else _discover_metadata_paths(root)
    if not paths:
        raise NoSamplesFound(
            f"읽을 metadata 파일이 없습니다: {root}\n"
            "지원 형식: metadata.csv, metadata.json, *.metadata.json, *.features.csv"
        )

    records: list[SampleRecord] = []
    for path in paths:
        records.extend(_load_metadata_file(path, root))

    deduped = _dedupe(records)
    if not deduped:
        raise NoSamplesFound(
            "metadata는 찾았지만 학습 가능한 snore/non-snore feature record가 없습니다.\n"
            "label과 rms/energy/zeroCrossingRate 등의 feature column을 확인해 주세요."
        )

    return deduped


def build_feature_matrix(
    records: Iterable[SampleRecord],
    feature_columns: list[str] | None = None,
) -> tuple[list[list[float]], list[int], list[str]]:
    columns = feature_columns or FEATURE_COLUMNS
    x: list[list[float]] = []
    y: list[int] = []

    for record in records:
        x.append([_finite_feature(record.features.get(column, 0.0)) for column in columns])
        y.append(record.target)

    return x, y, columns


def class_counts(records: Iterable[SampleRecord]) -> dict[str, int]:
    total = 0
    positive = 0
    negative = 0
    for record in records:
        total += 1
        if record.target == 1:
            positive += 1
        else:
            negative += 1

    return {"total": total, "positive": positive, "negative": negative}


def validate_for_training(
    records: list[SampleRecord],
    min_total: int,
    min_positive: int,
    min_negative: int,
) -> None:
    counts = class_counts(records)
    missing: list[str] = []

    if counts["total"] < min_total:
        missing.append(f"전체 샘플 {min_total}개 이상 필요, 현재 {counts['total']}개")
    if counts["positive"] < min_positive:
        missing.append(f"snore positive {min_positive}개 이상 필요, 현재 {counts['positive']}개")
    if counts["negative"] < min_negative:
        missing.append(f"non-snore negative {min_negative}개 이상 필요, 현재 {counts['negative']}개")

    if missing:
        raise InsufficientDataError(
            "코골기 detector 학습을 시작하기에는 데이터가 부족합니다.\n"
            + "\n".join(f"- {line}" for line in missing)
            + "\nDEBUG 샘플 수집 화면에서 짧은 snore/non-snore 샘플을 더 모아 주세요."
        )


def target_for_label(label: str) -> int | None:
    normalized = str(label).strip()
    if normalized == POSITIVE_LABEL:
        return 1
    if normalized in NEGATIVE_LABELS:
        return 0
    return None


def _discover_metadata_paths(root: Path) -> list[Path]:
    aggregate_paths = [root / "metadata.csv", root / "metadata.json"]
    aggregate_paths = [path for path in aggregate_paths if path.exists()]
    if aggregate_paths:
        return _unique_paths(aggregate_paths)

    metadata_jsons = sorted(root.glob("*.metadata.json"))
    if metadata_jsons:
        return _unique_paths(metadata_jsons)

    return _unique_paths(sorted(root.glob("*.features.csv")))


def _resolve_metadata_path(root: Path, metadata_path: str | Path | None) -> Path:
    if metadata_path is None:
        raise NoSamplesFound("metadata path가 지정되지 않았습니다.")

    path = Path(metadata_path)
    if not path.is_absolute():
        path = root / path
    path = path.resolve()

    if not path.exists():
        raise NoSamplesFound(f"metadata 파일을 찾을 수 없습니다: {path}")
    return path


def _resolve_manifest_path(manifest_path: str | Path) -> Path:
    path = Path(manifest_path).expanduser()
    if not path.is_absolute():
        cwd_candidate = Path.cwd().joinpath(path)
        path = cwd_candidate if cwd_candidate.exists() else training_root() / path
    path = path.resolve()

    if not path.exists():
        raise NoSamplesFound(
            f"manifest 파일을 찾을 수 없습니다: {path}\n"
            "공개/개인 오디오 파일은 직접 준비하고, manifest에는 로컬 경로와 feature summary만 기록해 주세요."
        )
    return path


def _load_manifest_file(path: Path) -> list[SampleRecord]:
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)

    if isinstance(data, dict):
        dataset_name = str(data.get("datasetName") or path.stem)
        feedback_rows = _feedback_rows(data)
        if feedback_rows is not None:
            return _load_feedback_manifest_records(feedback_rows, source_path=path)
        segments = data.get("segments") if isinstance(data.get("segments"), list) else []
    elif isinstance(data, list):
        dataset_name = path.stem
        segments = data
    else:
        segments = []
        dataset_name = path.stem

    records: list[SampleRecord] = []
    for row_index, segment in enumerate(segments):
        if not isinstance(segment, dict):
            continue
        record = _parse_manifest_segment(
            segment,
            dataset_name=dataset_name,
            source_path=path,
            row_index=row_index,
        )
        if record is not None:
            records.append(record)
    return records


def _feedback_rows(data: dict[str, Any]) -> list[dict[str, Any]] | None:
    for key in ("records", "feedback", "items"):
        value = data.get(key)
        if not isinstance(value, list):
            continue
        rows = [row for row in value if isinstance(row, dict)]
        if any("selectedFeedback" in row and "eventType" in row for row in rows):
            return rows
    return None


def _load_feedback_manifest_records(rows: list[dict[str, Any]], source_path: Path) -> list[SampleRecord]:
    records: list[SampleRecord] = []
    for row_index, row in enumerate(rows):
        record = _parse_feedback_manifest_record(row, source_path=source_path, row_index=row_index)
        if record is not None:
            records.append(record)
    return records


def _load_metadata_file(path: Path, root: Path) -> list[SampleRecord]:
    suffix = "".join(path.suffixes[-2:]) if path.name.endswith(".metadata.json") else path.suffix
    if suffix == ".csv":
        rows = _read_csv(path)
    elif suffix in {".json", ".metadata.json"}:
        rows = _read_json(path)
    else:
        raise DatasetError(f"지원하지 않는 metadata 형식입니다: {path}")

    records: list[SampleRecord] = []
    for row_index, row in enumerate(rows):
        record = _parse_row(row, root=root, source_path=path, row_index=row_index)
        if record is not None:
            records.append(record)
    return records


def _read_csv(path: Path) -> list[dict[str, Any]]:
    with path.open("r", encoding="utf-8", newline="") as handle:
        return [dict(row) for row in csv.DictReader(handle)]


def _read_json(path: Path) -> list[dict[str, Any]]:
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)

    if isinstance(data, list):
        return [row for row in data if isinstance(row, dict)]
    if isinstance(data, dict):
        for key in ("samples", "records", "items"):
            value = data.get(key)
            if isinstance(value, list):
                return [row for row in value if isinstance(row, dict)]
        return [data]
    return []


def _parse_row(
    row: dict[str, Any],
    root: Path,
    source_path: Path,
    row_index: int,
) -> SampleRecord | None:
    features_block = row.get("features") if isinstance(row.get("features"), dict) else {}
    label = str(_first_value(row, features_block, "label", "eventType") or "").strip()
    target = target_for_label(label)
    if target is None:
        return None

    features = {
        column: _feature_value(row, features_block, column)
        for column in FEATURE_COLUMNS
    }

    sample_id = str(
        _first_value(row, features_block, "sampleId", "sample_id", "id")
        or f"{source_path.stem}-{row_index}"
    )
    audio_name = str(_first_value(row, features_block, *_audio_path_keys()) or "")
    audio_path = _resolve_audio_path(audio_name, root)
    notes = str(_first_value(row, features_block, "notes", "memo") or "")
    captured_at = str(_first_value(row, features_block, "capturedAt", "timestamp", "captured_at") or "")

    return SampleRecord(
        sample_id=sample_id,
        label=label,
        target=target,
        features=features,
        audio_path=audio_path,
        source_path=str(source_path),
        notes=notes,
        captured_at=captured_at,
    )


def _parse_manifest_segment(
    segment: dict[str, Any],
    dataset_name: str,
    source_path: Path,
    row_index: int,
) -> SampleRecord | None:
    features_block = _manifest_features_block(segment)
    label = _manifest_target_label(segment)
    if label is None:
        return None

    target = target_for_label(label)
    if target is None:
        return None

    features = {
        column: _feature_value(segment, features_block, column)
        for column in FEATURE_COLUMNS
    }

    if "duration" in features and features["duration"] <= 0:
        features["duration"] = _finite_feature(segment.get("segmentDurationSeconds"))

    sample_id = str(
        _first_value(segment, features_block, "fileId", "sampleId", "sample_id", "id")
        or f"{dataset_name}-{row_index}"
    )
    audio_name = str(_first_value(segment, features_block, "localFilePath", *_audio_path_keys()) or "")
    audio_path = _resolve_audio_path(audio_name, source_path.parent)
    notes = str(_first_value(segment, features_block, "notes", "confidenceNote") or "")

    return SampleRecord(
        sample_id=sample_id,
        label=label,
        target=target,
        features=features,
        audio_path=audio_path,
        source_path=str(source_path),
        notes=notes,
        captured_at=str(segment.get("capturedAt") or ""),
        label_confidence=_clamped_confidence(segment.get("labelConfidence"), default=1.0),
        training_action=str(segment.get("trainingAction") or ""),
    )


def _parse_feedback_manifest_record(
    row: dict[str, Any],
    source_path: Path,
    row_index: int,
) -> SampleRecord | None:
    label = _feedback_target_label(row)
    if label is None:
        return None

    target = target_for_label(label)
    if target is None:
        return None

    features_block = _manifest_features_block(row)
    features = {
        column: _feature_value(row, features_block, column)
        for column in FEATURE_COLUMNS
    }
    if "duration" in features and features["duration"] <= 0:
        features["duration"] = _finite_feature(row.get("segmentDurationSeconds"))

    sample_id = str(
        _first_value(row, features_block, "fileId", "feedbackId", "eventId", "sampleId", "id")
        or f"{source_path.stem}-{row_index}"
    )
    audio_name = str(
        _first_value(row, features_block, "localFilePath", "audioSamplePath", *_audio_path_keys()) or ""
    )
    audio_path = _resolve_audio_path(audio_name, source_path.parent)
    selected_feedback = str(row.get("selectedFeedback") or "")
    training_action = str(row.get("trainingAction") or _feedback_training_action(row))
    notes = "; ".join(
        value
        for value in [
            str(row.get("notes") or ""),
            f"feedback={selected_feedback}" if selected_feedback else "",
            f"trainingAction={training_action}" if training_action else "",
        ]
        if value
    )

    return SampleRecord(
        sample_id=sample_id,
        label=label,
        target=target,
        features=features,
        audio_path=audio_path,
        source_path=str(source_path),
        notes=notes,
        captured_at=str(row.get("createdAt") or ""),
        label_confidence=_clamped_confidence(row.get("labelConfidence"), default=_feedback_default_confidence(row)),
        training_action=training_action,
    )


def _manifest_features_block(segment: dict[str, Any]) -> dict[str, Any]:
    for key in ("features", "featureSummary", "feature_summary"):
        value = segment.get(key)
        if isinstance(value, dict):
            return value
    return {}


def _manifest_target_label(segment: dict[str, Any]) -> str | None:
    explicit_label = str(segment.get("label") or "").strip()
    if target_for_label(explicit_label) is not None:
        return explicit_label

    labels = segment.get("expectedLabels")
    if not isinstance(labels, list):
        return None

    normalized = [str(label).strip() for label in labels if str(label).strip()]
    if POSITIVE_LABEL in normalized:
        return POSITIVE_LABEL

    for label in normalized:
        if label in NEGATIVE_LABELS:
            return label
    return None


def _feedback_target_label(row: dict[str, Any]) -> str | None:
    selected = str(row.get("selectedFeedback") or "").strip()
    if selected == "unsure":
        return None

    corrected = str(row.get("correctedLabel") or "").strip()
    event_type = str(row.get("eventType") or "").strip()

    if selected == "correct":
        if target_for_label(event_type) is not None:
            return event_type
        return _first_targetable_expected_label(row)

    if selected == "incorrect":
        if target_for_label(corrected) is not None:
            return corrected
        if event_type == POSITIVE_LABEL:
            return "unknown"
        return _first_targetable_expected_label(row) or "unknown"

    return _first_targetable_expected_label(row)


def _first_targetable_expected_label(row: dict[str, Any]) -> str | None:
    labels = row.get("expectedLabels")
    if not isinstance(labels, list):
        return None
    for label in labels:
        normalized = str(label).strip()
        if target_for_label(normalized) is not None:
            return normalized
    return None


def _feedback_training_action(row: dict[str, Any]) -> str:
    selected = str(row.get("selectedFeedback") or "").strip()
    if selected == "correct":
        return "positive" if str(row.get("eventType") or "") == POSITIVE_LABEL else "negative"
    if selected == "incorrect" and str(row.get("correctedLabel") or "").strip():
        return "correctedLabel"
    if selected == "incorrect":
        return "negative"
    return "excludedUnsure"


def _feedback_default_confidence(row: dict[str, Any]) -> float:
    selected = str(row.get("selectedFeedback") or "").strip()
    if selected == "correct":
        return 1.0
    if selected == "incorrect" and str(row.get("correctedLabel") or "").strip():
        return 0.9
    if selected == "incorrect":
        return 0.8
    return 0.2


def _feature_value(row: dict[str, Any], features_block: dict[str, Any], column: str) -> float:
    snake_case = _camel_to_snake(column)
    keys = [column, snake_case]
    if column == "duration":
        keys.extend(
            [
                "segmentDurationSeconds",
                "segment_duration_seconds",
                "audioSnippetDuration",
                "audio_duration",
            ]
        )
    value = _first_value(row, features_block, *keys)
    return _finite_feature(value)


def _first_value(
    row: dict[str, Any],
    features_block: dict[str, Any],
    *keys: str,
) -> Any:
    for key in keys:
        if key in row and row[key] not in (None, ""):
            return row[key]
        if key in features_block and features_block[key] not in (None, ""):
            return features_block[key]
    return None


def _finite_feature(value: Any) -> float:
    result = safe_float(value)
    if not math.isfinite(result):
        return 0.0
    return result


def _clamped_confidence(value: Any, default: float) -> float:
    if value in (None, ""):
        result = default
    else:
        result = safe_float(value)
    if not math.isfinite(result):
        result = default
    return max(0.0, min(1.0, result))


def _resolve_audio_path(audio_name: str, root: Path) -> str:
    if not audio_name:
        return ""
    path = Path(audio_name)
    if path.is_absolute():
        return str(path)
    return str((root / path).resolve())


def _audio_path_keys() -> tuple[str, ...]:
    return ("audioFileName", "fileName", "audio_path", "path")


def _dedupe(records: list[SampleRecord]) -> list[SampleRecord]:
    seen: set[tuple[str, str, str]] = set()
    deduped: list[SampleRecord] = []
    for record in records:
        key = (record.sample_id, record.label, record.source_path)
        if key in seen:
            continue
        seen.add(key)
        deduped.append(record)
    return deduped


def _unique_paths(paths: list[Path]) -> list[Path]:
    seen: set[Path] = set()
    result: list[Path] = []
    for path in paths:
        resolved = path.resolve()
        if resolved in seen:
            continue
        seen.add(resolved)
        result.append(resolved)
    return result


def _deep_merge(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    result = copy.deepcopy(base)
    for key, value in override.items():
        if isinstance(value, dict) and isinstance(result.get(key), dict):
            result[key] = _deep_merge(result[key], value)
        else:
            result[key] = value
    return result


def _camel_to_snake(value: str) -> str:
    output: list[str] = []
    for character in value:
        if character.isupper() and output:
            output.append("_")
        output.append(character.lower())
    return "".join(output)
