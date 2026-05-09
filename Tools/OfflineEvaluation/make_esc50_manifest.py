#!/usr/bin/env python3
"""Build a NightBreath Offline Evaluation manifest from an ESC-50 checkout.

The script never downloads audio. The default workflow keeps ESC-50 outside
git-tracked source or in an ignored local dataset directory. If ESC-50 is
intentionally distributed with the repository, keep the upstream CC BY-NC 3.0
license and clip attribution notices; NightBreath does not relicense ESC-50
under Apache-2.0.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
from pathlib import Path
from typing import Iterable


DEFAULT_NEGATIVE_CATEGORIES = (
    "breathing",
    "coughing",
    "sneezing",
    "crying_baby",
    "laughing",
    "brushing_teeth",
    "drinking_sipping",
    "clock_tick",
    "vacuum_cleaner",
    "rain",
    "wind",
)


def main() -> int:
    args = parse_args()
    esc50_root = args.esc50_root.expanduser().resolve()
    metadata_path = esc50_root / "meta" / "esc50.csv"
    audio_root = esc50_root / "audio"

    if not metadata_path.exists():
        raise SystemExit(f"ESC-50 metadata not found: {metadata_path}")
    if not audio_root.exists():
        raise SystemExit(f"ESC-50 audio directory not found: {audio_root}")

    negative_categories = {
        category.strip()
        for category in args.negative_categories.split(",")
        if category.strip()
    }
    output_path = args.output.expanduser().resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)

    segments = make_segments(
        metadata_path=metadata_path,
        audio_root=audio_root,
        output_directory=output_path.parent,
        negative_categories=negative_categories,
        max_snore=args.max_snore,
        max_negative_per_category=args.max_negative_per_category,
        absolute_paths=args.absolute_paths,
    )

    manifest = {
        "datasetName": "esc50-public-snore-smoke-qa",
        "datasetLicenseNote": (
            "ESC-50 is a public environmental sound dataset distributed for "
            "research/non-commercial use under CC-BY-NC-3.0, with ESC-10 "
            "clips under CC-BY-3.0. Keep upstream license and attribution "
            "notices with any distribution that includes ESC-50 files."
        ),
        "segments": segments,
    }

    with output_path.open("w", encoding="utf-8") as file:
        json.dump(manifest, file, ensure_ascii=False, indent=2)
        file.write("\n")

    print(f"wrote manifest: {output_path}")
    print(f"segments: {len(segments)}")
    print(f"snore positives: {sum(1 for segment in segments if segment['expectedLabels'] == ['snore'])}")
    print(f"negative guards: {sum(1 for segment in segments if segment['expectedLabels'] == ['unknown'])}")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create a local Offline Evaluation manifest from ESC-50 metadata."
    )
    parser.add_argument(
        "--esc50-root",
        type=Path,
        required=True,
        help="Local ESC-50 root containing meta/esc50.csv and audio/*.wav.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("Tools/OfflineEvaluation/output/esc50_manifest.json"),
        help="Manifest JSON output path. Keep this in an ignored output directory.",
    )
    parser.add_argument(
        "--max-snore",
        type=int,
        default=40,
        help="Maximum snoring clips to include. ESC-50 has 40.",
    )
    parser.add_argument(
        "--max-negative-per-category",
        type=int,
        default=5,
        help="Maximum negative guard clips per selected non-snoring category.",
    )
    parser.add_argument(
        "--negative-categories",
        default=",".join(DEFAULT_NEGATIVE_CATEGORIES),
        help="Comma-separated ESC-50 categories to use as no-snore guards.",
    )
    parser.add_argument(
        "--absolute-paths",
        action="store_true",
        help="Write absolute localFilePath values instead of paths relative to the output manifest.",
    )
    return parser.parse_args()


def make_segments(
    metadata_path: Path,
    audio_root: Path,
    output_directory: Path,
    negative_categories: set[str],
    max_snore: int,
    max_negative_per_category: int,
    absolute_paths: bool,
) -> list[dict[str, object]]:
    rows = read_esc50_rows(metadata_path)
    rows.sort(key=lambda row: (row["category"], int(row["fold"]), row["filename"]))

    segments: list[dict[str, object]] = []
    snore_count = 0
    negative_counts: dict[str, int] = {}

    for row in rows:
        category = row["category"]
        audio_path = audio_root / row["filename"]
        if category == "snoring":
            if snore_count >= max(0, max_snore):
                continue
            segments.append(
                make_segment(
                    row=row,
                    audio_path=audio_path,
                    output_directory=output_directory,
                    expected_labels=["snore"],
                    negative_labels=["environmentalNoise", "coughLike", "sleepTalkLike"],
                    absolute_paths=absolute_paths,
                )
            )
            snore_count += 1
        elif category in negative_categories:
            current_count = negative_counts.get(category, 0)
            if current_count >= max(0, max_negative_per_category):
                continue
            segments.append(
                make_segment(
                    row=row,
                    audio_path=audio_path,
                    output_directory=output_directory,
                    expected_labels=["unknown"],
                    negative_labels=["snore"],
                    absolute_paths=absolute_paths,
                )
            )
            negative_counts[category] = current_count + 1

    return segments


def read_esc50_rows(metadata_path: Path) -> list[dict[str, str]]:
    with metadata_path.open("r", encoding="utf-8", newline="") as file:
        reader = csv.DictReader(file)
        required_columns = {"filename", "fold", "category"}
        missing_columns = required_columns.difference(reader.fieldnames or [])
        if missing_columns:
            missing = ", ".join(sorted(missing_columns))
            raise SystemExit(f"ESC-50 metadata missing required columns: {missing}")
        return [normalize_row(row) for row in reader]


def normalize_row(row: dict[str, str]) -> dict[str, str]:
    return {
        "filename": row.get("filename", "").strip(),
        "fold": row.get("fold", "0").strip() or "0",
        "category": row.get("category", "").strip(),
        "target": row.get("target", "").strip(),
        "esc10": row.get("esc10", "").strip(),
        "src_file": row.get("src_file", "").strip(),
        "take": row.get("take", "").strip(),
    }


def make_segment(
    row: dict[str, str],
    audio_path: Path,
    output_directory: Path,
    expected_labels: list[str],
    negative_labels: list[str],
    absolute_paths: bool,
) -> dict[str, object]:
    file_id = f"esc50-{Path(row['filename']).stem}"
    local_file_path = str(audio_path.resolve()) if absolute_paths else relative_path(audio_path, output_directory)
    return {
        "fileId": file_id,
        "localFilePath": local_file_path,
        "subjectId": "public-esc50",
        "recordingType": "publicDataset",
        "microphoneType": "ambient",
        "segmentStartSeconds": 0,
        "segmentDurationSeconds": 5,
        "expectedLabels": expected_labels,
        "negativeLabels": negative_labels,
        "confidenceNote": (
            "ESC-50 category label mapped for detector smoke QA. "
            "Use as development evidence, not medical validation."
        ),
        "notes": (
            f"ESC-50 category={row['category']} fold={row['fold']} "
            f"target={row['target']} src_file={row['src_file']} take={row['take']}"
        ),
    }


def relative_path(path: Path, base_directory: Path) -> str:
    return os.path.relpath(path.resolve(), base_directory.resolve())


if __name__ == "__main__":
    raise SystemExit(main())
