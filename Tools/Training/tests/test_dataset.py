#!/usr/bin/env python3

from __future__ import annotations

import csv
import json
import sys
import tempfile
import unittest
from pathlib import Path

TRAINING_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TRAINING_ROOT))

from dataset import (  # noqa: E402
    InsufficientDataError,
    NoSamplesFound,
    build_feature_matrix,
    load_samples,
    validate_for_training,
)


class DatasetLoaderTests(unittest.TestCase):
    def test_loads_metadata_csv_and_maps_snore_target(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            metadata = root / "metadata.csv"
            self._write_metadata(metadata)

            records = load_samples(root)
            x, y, columns = build_feature_matrix(records)

            self.assertEqual(len(records), 2)
            self.assertEqual(y, [1, 0])
            self.assertEqual(columns[0], "rms")
            self.assertEqual(columns[-1], "duration")
            self.assertEqual(len(x[0]), len(columns))
            self.assertEqual(records[1].label, "silence")

    def test_loads_manifest_segments_and_maps_expected_labels(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            manifest = root / "manifest.json"
            manifest.write_text(
                json.dumps(
                    {
                        "datasetName": "unit-manifest",
                        "segments": [
                            {
                                "fileId": "snore-1",
                                "localFilePath": "snore.wav",
                                "segmentDurationSeconds": 2,
                                "expectedLabels": ["snore"],
                                "features": {
                                    "rms": 0.2,
                                    "energy": 0.04,
                                    "zeroCrossingRate": 0.08,
                                    "spectralCentroid": 220,
                                    "lowBandEnergy": 0.75,
                                    "midBandEnergy": 0.20,
                                    "highBandEnergy": 0.05,
                                },
                            },
                            {
                                "fileId": "quiet-1",
                                "localFilePath": "quiet.wav",
                                "segmentDurationSeconds": 3,
                                "expectedLabels": ["silence"],
                                "features": {
                                    "rms": 0.01,
                                    "energy": 0.0001,
                                    "zeroCrossingRate": 0.02,
                                    "spectralCentroid": 80,
                                    "lowBandEnergy": 0.30,
                                    "midBandEnergy": 0.10,
                                    "highBandEnergy": 0.05,
                                },
                            },
                        ],
                    }
                ),
                encoding="utf-8",
            )

            records = load_samples(manifest_path=manifest)
            x, y, columns = build_feature_matrix(records)

            self.assertEqual(len(records), 2)
            self.assertEqual(y, [1, 0])
            self.assertEqual(records[1].label, "silence")
            self.assertEqual(columns[-1], "duration")
            self.assertEqual(x[0][-1], 2)
            self.assertEqual(x[1][-1], 3)

    def test_empty_folder_raises_friendly_error(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            with self.assertRaises(NoSamplesFound) as context:
                load_samples(temp_dir)

            self.assertIn("metadata", str(context.exception))

    def test_insufficient_data_has_actionable_message(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            metadata = root / "metadata.csv"
            self._write_metadata(metadata)
            records = load_samples(root)

            with self.assertRaises(InsufficientDataError) as context:
                validate_for_training(records, min_total=40, min_positive=20, min_negative=20)

            self.assertIn("데이터가 부족", str(context.exception))
            self.assertIn("snore", str(context.exception))

    @staticmethod
    def _write_metadata(path: Path) -> None:
        fieldnames = [
            "sampleId",
            "label",
            "audioFileName",
            "rms",
            "energy",
            "zeroCrossingRate",
            "spectralCentroid",
            "lowBandEnergy",
            "midBandEnergy",
            "highBandEnergy",
            "duration",
        ]
        rows = [
            {
                "sampleId": "sample-snore",
                "label": "snore",
                "audioFileName": "sample-snore.caf",
                "rms": "0.20",
                "energy": "0.04",
                "zeroCrossingRate": "0.08",
                "spectralCentroid": "220",
                "lowBandEnergy": "0.75",
                "midBandEnergy": "0.20",
                "highBandEnergy": "0.05",
                "duration": "2",
            },
            {
                "sampleId": "sample-noise",
                "label": "silence",
                "audioFileName": "sample-noise.caf",
                "rms": "0.16",
                "energy": "0.0256",
                "zeroCrossingRate": "0.42",
                "spectralCentroid": "2500",
                "lowBandEnergy": "0.10",
                "midBandEnergy": "0.35",
                "highBandEnergy": "0.55",
                "duration": "2",
            },
        ]

        with path.open("w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(rows)


if __name__ == "__main__":
    unittest.main()
