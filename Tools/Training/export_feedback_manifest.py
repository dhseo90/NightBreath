#!/usr/bin/env python3
"""Export NightBreath local event feedback metadata for offline training."""

from __future__ import annotations

import argparse
import csv
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

POSITIVE_LABEL = "snore"
NEGATIVE_LABELS = {
    "bruxismLike",
    "silence",
    "unknown",
    "environmentalNoise",
    "movementLike",
    "coughLike",
    "sleepTalkLike",
}


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Export local NightBreath event feedback metadata without copying audio files."
    )
    parser.add_argument(
        "--feedback-store",
        default=str(
            Path.home()
            / "Library"
            / "Application Support"
            / "NightBreath"
            / "sleep-event-feedback.json"
        ),
        help="Path to sleep-event-feedback.json copied from the app container.",
    )
    parser.add_argument(
        "--output-dir",
        default="output",
        help="Gitignored output directory. Defaults to Tools/Training/output.",
    )
    args = parser.parse_args()

    store_path = Path(args.feedback_store).expanduser()
    output_dir = Path(args.output_dir).expanduser()
    if not output_dir.is_absolute():
        output_dir = Path(__file__).resolve().parent / output_dir

    feedbacks = load_feedbacks(store_path)
    records = [make_record(feedback) for feedback in feedbacks]

    output_dir.mkdir(parents=True, exist_ok=True)
    json_path = output_dir / "export_feedback_manifest.json"
    csv_path = output_dir / "export_feedback_manifest.csv"

    manifest = {
        "datasetName": "NightBreath Local Event Feedback",
        "datasetLicenseNote": "Local user feedback metadata only. Audio files are not included.",
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "records": records,
    }
    json_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True), encoding="utf-8")
    write_csv(csv_path, records)

    print("Feedback manifest export complete")
    print(f"records: {len(records)}")
    print(f"json: {json_path}")
    print(f"csv: {csv_path}")
    print("audio files are not copied; audioSamplePath/localFilePath are local references only")
    return 0


def load_feedbacks(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        raise SystemExit(
            f"Feedback store not found: {path}\n"
            "Copy sleep-event-feedback.json from the app container or pass --feedback-store."
        )

    data = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(data, dict) and isinstance(data.get("feedbackByEventID"), dict):
        return [row for row in data["feedbackByEventID"].values() if isinstance(row, dict)]
    if isinstance(data, list):
        return [row for row in data if isinstance(row, dict)]
    raise SystemExit(f"Unsupported feedback store format: {path}")


def make_record(feedback: dict[str, Any]) -> dict[str, Any]:
    selected = normalize_feedback(str(feedback.get("selectedFeedback") or "unsure"))
    event_type = str(feedback.get("eventType") or "unknown")
    corrected_label = str(feedback.get("correctedLabel") or "")
    expected, negative, confidence, action = training_labels(selected, event_type, corrected_label)
    audio_sample_id = str(feedback.get("audioSampleId") or "")
    has_audio_sample = bool(feedback.get("hasAudioSample")) and bool(audio_sample_id)

    return {
        "feedbackId": str(feedback.get("id") or ""),
        "fileId": audio_sample_id or f"feedback-{feedback.get('eventId', '')}",
        "eventId": str(feedback.get("eventId") or ""),
        "sessionId": str(feedback.get("sessionId") or ""),
        "eventType": event_type,
        "selectedFeedback": selected,
        "correctedLabel": corrected_label or None,
        "expectedLabels": expected,
        "negativeLabels": negative,
        "labelConfidence": confidence,
        "trainingAction": action,
        "localFilePath": audio_sample_id if has_audio_sample else "",
        "audioSamplePath": audio_sample_id if has_audio_sample else None,
        "hasAudioSample": has_audio_sample,
        "audioSampleId": audio_sample_id or None,
        "segmentStartSeconds": 0,
        "segmentDurationSeconds": 0,
        "createdAt": str(feedback.get("createdAt") or ""),
        "notes": str(feedback.get("note") or ""),
    }


def normalize_feedback(value: str) -> str:
    if value == "soundsLikeBruxism":
        return "correct"
    if value == "notBruxism":
        return "incorrect"
    if value in {"correct", "incorrect", "unsure"}:
        return value
    return "unsure"


def training_labels(
    selected: str,
    event_type: str,
    corrected_label: str,
) -> tuple[list[str], list[str], float, str]:
    if selected == "correct":
        return [event_type], [], 1.0, "positive" if event_type == POSITIVE_LABEL else "negative"
    if selected == "incorrect" and corrected_label:
        return [corrected_label], negative_labels(event_type), 0.9, "correctedLabel"
    if selected == "incorrect":
        return ["unknown"], negative_labels(event_type), 0.8, "negative"
    return [], [], 0.2, "excludedUnsure"


def negative_labels(event_type: str) -> list[str]:
    if event_type == POSITIVE_LABEL or event_type in NEGATIVE_LABELS:
        return [event_type]
    return []


def write_csv(path: Path, records: list[dict[str, Any]]) -> None:
    fieldnames = [
        "feedbackId",
        "fileId",
        "eventId",
        "sessionId",
        "eventType",
        "selectedFeedback",
        "correctedLabel",
        "expectedLabels",
        "negativeLabels",
        "labelConfidence",
        "trainingAction",
        "localFilePath",
        "hasAudioSample",
        "audioSampleId",
        "segmentStartSeconds",
        "segmentDurationSeconds",
        "createdAt",
        "notes",
    ]
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for record in records:
            row = dict(record)
            row["expectedLabels"] = "|".join(record["expectedLabels"])
            row["negativeLabels"] = "|".join(record["negativeLabels"])
            writer.writerow({key: row.get(key) for key in fieldnames})


if __name__ == "__main__":
    raise SystemExit(main())
