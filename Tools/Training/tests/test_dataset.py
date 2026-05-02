#!/usr/bin/env python3

from __future__ import annotations

import csv
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
            self.assertEqual(len(x[0]), len(columns))

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
                validate_for_training(records, min_total=20, min_positive=5, min_negative=5)

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
            },
            {
                "sampleId": "sample-noise",
                "label": "environmentalNoise",
                "audioFileName": "sample-noise.caf",
                "rms": "0.16",
                "energy": "0.0256",
                "zeroCrossingRate": "0.42",
                "spectralCentroid": "2500",
                "lowBandEnergy": "0.10",
                "midBandEnergy": "0.35",
                "highBandEnergy": "0.55",
            },
        ]

        with path.open("w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(rows)


if __name__ == "__main__":
    unittest.main()
