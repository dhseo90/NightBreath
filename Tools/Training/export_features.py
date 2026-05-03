#!/usr/bin/env python3
"""Export normalized snore detector feature rows to CSV."""

from __future__ import annotations

import argparse
import csv
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


def main() -> int:
    parser = argparse.ArgumentParser(description="Export local snore detector features.")
    parser.add_argument("--config", default=str(training_root() / "config" / "snore_detector.yaml"))
    parser.add_argument("--input", help="Samples/Personal style folder containing metadata.")
    parser.add_argument("--metadata", help="Optional metadata.csv/json path inside --input.")
    parser.add_argument("--manifest", help="Optional dataset manifest JSON path.")
    parser.add_argument("--output", help="Output CSV path.")
    args = parser.parse_args()

    try:
        config = load_config(args.config)
        manifest_path = resolve_path(args.manifest, training_root()) if args.manifest else None
        input_dir = (
            resolve_path(args.input or config["dataset"]["input_dir"], training_root())
            if manifest_path is None or args.input
            else None
        )
        output_path = resolve_path(
            args.output
            or str(Path(config["output"]["directory"]) / config["output"]["feature_export_filename"]),
            training_root(),
        )

        records = load_samples(
            input_dir=input_dir,
            metadata_path=args.metadata,
            manifest_path=manifest_path,
        )
        _, _, feature_columns = build_feature_matrix(records, config["dataset"]["feature_columns"])
        write_feature_csv(records, feature_columns, output_path)

        print(f"Exported {len(records)} feature rows to {output_path}")
        return 0
    except DatasetError as error:
        print(f"Feature export skipped: {error}", file=sys.stderr)
        return 2


def write_feature_csv(records, feature_columns: list[str], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = [
        "sampleId",
        "label",
        "target",
        "audioPath",
        "sourcePath",
        *feature_columns,
    ]

    with output_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for record in records:
            row = {
                "sampleId": record.sample_id,
                "label": record.label,
                "target": record.target,
                "audioPath": record.audio_path,
                "sourcePath": record.source_path,
            }
            for column in feature_columns:
                row[column] = record.features.get(column, 0.0)
            writer.writerow(row)


if __name__ == "__main__":
    raise SystemExit(main())
