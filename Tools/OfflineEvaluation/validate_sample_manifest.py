#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MANIFEST = REPO_ROOT / "Tools" / "OfflineEvaluation" / "sample_manifest.example.json"
AUDIO_EXTENSIONS = {".wav", ".caf", ".m4a", ".mp3", ".aiff", ".aif", ".flac"}
ALLOWED_LABELS = {
    "snore",
    "bruxismLike",
    "breathingPauseSuspected",
    "gaspLike",
    "coughLike",
    "sleepTalkLike",
    "movementLike",
    "environmentalNoise",
    "awakeningSuspected",
    "unknown",
    "silence",
}
ALLOWED_RECORDING_TYPES = {"publicDataset", "personalDebugSample", "synthetic"}
REQUIRED_SEGMENT_FIELDS = {
    "fileId",
    "localFilePath",
    "recordingType",
    "segmentStartSeconds",
    "segmentDurationSeconds",
    "expectedLabels",
}
FEATURE_KEYS = {
    "rms",
    "energy",
    "zeroCrossingRate",
    "spectralCentroid",
    "lowBandEnergy",
    "midBandEnergy",
    "highBandEnergy",
    "duration",
}
GITIGNORED_AUDIO_ROOTS = [
    REPO_ROOT / "Datasets",
    REPO_ROOT / "Samples" / "Personal",
    REPO_ROOT / "Samples" / "Public",
]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate a NightBreath Offline Evaluation sample manifest without loading audio."
    )
    parser.add_argument("--manifest", default=str(DEFAULT_MANIFEST), help="Manifest JSON path.")
    parser.add_argument(
        "--require-files",
        action="store_true",
        help="Fail when localFilePath targets do not exist. Default only reports missing files.",
    )
    parser.add_argument(
        "--max-segment-seconds",
        type=float,
        default=float(os.environ.get("OFFLINE_MANIFEST_MAX_SEGMENT_SECONDS", "30")),
        help="Maximum segment duration accepted by this local gate.",
    )
    args = parser.parse_args()

    manifest_path = Path(args.manifest).expanduser().resolve()
    errors: list[str] = []
    warnings: list[str] = []

    if not manifest_path.is_file():
        print(f"error: manifest not found: {manifest_path}", file=sys.stderr)
        return 1

    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        print(f"error: manifest is not valid JSON: {error}", file=sys.stderr)
        return 1

    if not isinstance(manifest, dict):
        print("error: manifest root must be a JSON object.", file=sys.stderr)
        return 1

    dataset_name = manifest.get("datasetName")
    license_note = manifest.get("datasetLicenseNote")
    segments = manifest.get("segments")

    if not isinstance(dataset_name, str) or not dataset_name.strip():
        errors.append("datasetName is required.")
    if not isinstance(license_note, str) or not license_note.strip():
        warnings.append("datasetLicenseNote is missing; license/source review should be recorded.")
    if not isinstance(segments, list):
        errors.append("segments must be an array.")
        segments = []

    missing_files = 0
    labels_seen: set[str] = set()

    for index, segment in enumerate(segments):
        prefix = f"segments[{index}]"
        if not isinstance(segment, dict):
            errors.append(f"{prefix} must be an object.")
            continue

        missing_fields = sorted(field for field in REQUIRED_SEGMENT_FIELDS if field not in segment)
        if missing_fields:
            errors.append(f"{prefix} is missing required fields: {', '.join(missing_fields)}")

        file_id = segment.get("fileId")
        if not isinstance(file_id, str) or not file_id.strip():
            errors.append(f"{prefix}.fileId must be a non-empty string.")

        recording_type = segment.get("recordingType")
        if recording_type not in ALLOWED_RECORDING_TYPES:
            errors.append(f"{prefix}.recordingType is unsupported: {recording_type}")

        duration = segment.get("segmentDurationSeconds")
        if not isinstance(duration, (int, float)) or duration <= 0:
            errors.append(f"{prefix}.segmentDurationSeconds must be greater than 0.")
        elif duration > args.max_segment_seconds:
            errors.append(
                f"{prefix}.segmentDurationSeconds is {duration}; keep debug/replay samples at or below "
                f"{args.max_segment_seconds:g} seconds for this gate."
            )

        path_value = segment.get("localFilePath")
        if isinstance(path_value, str) and path_value.strip():
            resolved_audio_path = resolve_audio_path(manifest_path.parent, path_value)
            validate_audio_path(
                prefix=prefix,
                path_value=path_value,
                resolved_path=resolved_audio_path,
                require_files=args.require_files,
                errors=errors,
                warnings=warnings,
            )
            if not resolved_audio_path.exists():
                missing_files += 1
        else:
            errors.append(f"{prefix}.localFilePath must be a non-empty string.")

        for label_field in ("expectedLabels", "negativeLabels"):
            labels = segment.get(label_field, [])
            if label_field == "expectedLabels" and not isinstance(labels, list):
                errors.append(f"{prefix}.{label_field} must be an array.")
                continue
            if not isinstance(labels, list):
                errors.append(f"{prefix}.{label_field} must be an array when provided.")
                continue
            if label_field == "expectedLabels" and not labels:
                errors.append(f"{prefix}.expectedLabels should include at least one detector label.")
            for label in labels:
                if label not in ALLOWED_LABELS:
                    errors.append(f"{prefix}.{label_field} has unsupported label: {label}")
                else:
                    labels_seen.add(label)

        features = segment.get("features")
        if features is not None:
            if not isinstance(features, dict):
                errors.append(f"{prefix}.features must be an object when provided.")
            else:
                unknown_features = sorted(set(features.keys()) - FEATURE_KEYS)
                if unknown_features:
                    warnings.append(f"{prefix}.features has unknown keys: {', '.join(unknown_features)}")

        notes = " ".join(
            str(segment.get(field, "")) for field in ("confidenceNote", "notes") if segment.get(field)
        ).lower()
        if "transcript" in notes or "speech-to-text" in notes:
            errors.append(f"{prefix} notes should not include or request speech transcription.")

    if errors:
        print("Offline manifest validation failed.", file=sys.stderr)
        for error in errors:
            print(f"error: {error}", file=sys.stderr)
        for warning in warnings:
            print(f"warning: {warning}", file=sys.stderr)
        return 1

    print("Offline manifest validation passed.")
    print(f"Manifest: {manifest_path.relative_to(REPO_ROOT) if is_within(manifest_path, REPO_ROOT) else manifest_path}")
    print(f"Segments: {len(segments)}")
    print(f"Missing local files: {missing_files}")
    print(f"Labels: {', '.join(sorted(labels_seen)) if labels_seen else 'none'}")
    for warning in warnings:
        print(f"warning: {warning}")
    return 0


def resolve_audio_path(manifest_directory: Path, path_value: str) -> Path:
    path = Path(path_value).expanduser()
    if path.is_absolute():
        return path.resolve(strict=False)
    return (manifest_directory / path).resolve(strict=False)


def validate_audio_path(
    *,
    prefix: str,
    path_value: str,
    resolved_path: Path,
    require_files: bool,
    errors: list[str],
    warnings: list[str],
) -> None:
    suffix = resolved_path.suffix.lower()
    if suffix not in AUDIO_EXTENSIONS:
        warnings.append(f"{prefix}.localFilePath does not look like an audio segment: {path_value}")
    if require_files and not resolved_path.exists():
        errors.append(f"{prefix}.localFilePath does not exist: {path_value}")
    if suffix in AUDIO_EXTENSIONS and is_within(resolved_path, REPO_ROOT):
        if not any(is_within(resolved_path, root) for root in GITIGNORED_AUDIO_ROOTS):
            errors.append(
                f"{prefix}.localFilePath points inside the repo outside Datasets/ or Samples/: {path_value}"
            )
        if git_tracks(resolved_path):
            errors.append(f"{prefix}.localFilePath points at a git-tracked audio file: {path_value}")


def is_within(path: Path, root: Path) -> bool:
    try:
        path.resolve(strict=False).relative_to(root.resolve(strict=False))
        return True
    except ValueError:
        return False


def git_tracks(path: Path) -> bool:
    if not is_within(path, REPO_ROOT):
        return False
    relative = path.resolve(strict=False).relative_to(REPO_ROOT.resolve(strict=False))
    result = subprocess.run(
        ["git", "ls-files", "--error-unmatch", str(relative)],
        cwd=REPO_ROOT,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return result.returncode == 0


if __name__ == "__main__":
    raise SystemExit(main())
