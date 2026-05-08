#!/usr/bin/env python3

from __future__ import annotations

import sys
import unittest
from pathlib import Path

TRAINING_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TRAINING_ROOT))

from audio_features import (  # noqa: E402
    DEFAULT_LOG_MEL_SPEC,
    build_log_mel_placeholder_tensor,
    extract_log_mel_spectrogram,
    log_mel_placeholder_metadata,
)


class AudioFeaturePlaceholderTests(unittest.TestCase):
    def test_log_mel_placeholder_metadata_is_commit_safe(self) -> None:
        metadata = log_mel_placeholder_metadata()

        self.assertEqual(metadata["schema_version"], "log_mel_v0_placeholder")
        self.assertEqual(metadata["status"], "placeholder")
        self.assertEqual(metadata["sample_rate"], 16_000)
        self.assertEqual(metadata["input_shape"], [300, 64])
        self.assertFalse(metadata["stores_raw_audio"])
        self.assertFalse(metadata["requires_network"])
        self.assertNotIn("localFilePath", metadata)
        self.assertNotIn("audioFileName", metadata)

    def test_log_mel_placeholder_tensor_is_shape_only(self) -> None:
        tensor = build_log_mel_placeholder_tensor(fill=0.25)

        self.assertEqual(len(tensor), DEFAULT_LOG_MEL_SPEC.frame_count)
        self.assertEqual(len(tensor[0]), DEFAULT_LOG_MEL_SPEC.mel_bin_count)
        self.assertEqual(tensor[0][0], 0.25)
        self.assertEqual(tensor[-1][-1], 0.25)

    def test_log_mel_extraction_remains_disabled(self) -> None:
        with self.assertRaises(NotImplementedError) as context:
            extract_log_mel_spectrogram([0.0, 0.1, -0.1], sample_rate=16_000)

        self.assertIn("intentionally disabled", str(context.exception))


if __name__ == "__main__":
    unittest.main()
