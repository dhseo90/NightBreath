#!/usr/bin/env python3

from __future__ import annotations

import sys
import unittest
from pathlib import Path

TRAINING_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TRAINING_ROOT))

from dataset import SampleRecord  # noqa: E402
from multiclass_event_dataset import (  # noqa: E402
    MULTICLASS_LABELS,
    class_count_warnings,
    class_imbalance_warnings,
    label_counts,
    summarize_records,
)


class MulticlassEventDatasetTests(unittest.TestCase):
    def test_multiclass_label_counts_include_target_labels(self) -> None:
        records = [
            make_record("snore"),
            make_record("coughLike"),
            make_record("gaspLike"),
            make_record("environmentalNoise"),
        ]

        counts = label_counts(records, MULTICLASS_LABELS)

        self.assertEqual(counts["snore"], 1)
        self.assertEqual(counts["coughLike"], 1)
        self.assertEqual(counts["gaspLike"], 1)
        self.assertEqual(counts["environmentalNoise"], 1)
        self.assertEqual(counts["silence"], 0)

    def test_class_count_warning_for_underrepresented_labels(self) -> None:
        counts = {label: 0 for label in MULTICLASS_LABELS}
        counts["snore"] = 3

        warnings = class_count_warnings(counts, min_samples_per_class=5)

        self.assertTrue(any("snore" in warning for warning in warnings))
        self.assertTrue(any("silence" in warning for warning in warnings))

    def test_no_data_training_guard(self) -> None:
        summary = summarize_records([], min_total_samples=10, min_samples_per_class=2)

        self.assertFalse(summary.is_trainable)
        self.assertIn("전체 sample", summary.stop_reason)

    def test_class_imbalance_warning(self) -> None:
        counts = {label: 0 for label in MULTICLASS_LABELS}
        counts["snore"] = 40
        counts["coughLike"] = 5

        warnings = class_imbalance_warnings(counts, ratio=4.0)

        self.assertTrue(any("imbalance" in warning for warning in warnings))

    def test_excluding_underrepresented_labels_can_leave_trainable_subset(self) -> None:
        records = [make_record("snore", index) for index in range(5)]
        records.extend(make_record("coughLike", index) for index in range(5))
        records.append(make_record("gaspLike", 1))

        summary = summarize_records(
            records,
            labels=["snore", "coughLike", "gaspLike"],
            min_total_samples=10,
            min_samples_per_class=5,
            exclude_underrepresented_labels=True,
        )

        self.assertTrue(summary.is_trainable)
        self.assertEqual(summary.trainable_labels, ["snore", "coughLike"])
        self.assertEqual(summary.skipped_labels, ["gaspLike"])


def make_record(label: str, index: int = 0) -> SampleRecord:
    return SampleRecord(
        sample_id=f"{label}-{index}",
        label=label,
        target=1 if label == "snore" else 0,
        features={},
        audio_path="",
        source_path="unit",
    )


if __name__ == "__main__":
    unittest.main()
