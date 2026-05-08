#!/usr/bin/env python3
"""Small tabular audio feature helpers for local snore detector training.

This module intentionally avoids network calls and does not persist raw audio.
The iOS app already exports these summary features, but the helpers are useful
for synthetic tests and future local-only experiments.
"""

from __future__ import annotations

import math
from dataclasses import asdict, dataclass
from typing import Iterable


FEATURE_COLUMNS = [
    "rms",
    "energy",
    "zeroCrossingRate",
    "spectralCentroid",
    "lowBandEnergy",
    "midBandEnergy",
    "highBandEnergy",
    "duration",
]


@dataclass(frozen=True)
class LogMelSpectrogramSpec:
    """Document the future local-only spectrogram input contract.

    This is intentionally a schema placeholder. The current training scripts
    still use FEATURE_COLUMNS above, and this spec must not be treated as an
    enabled model input until a reviewed log-mel extractor is added.
    """

    schema_version: str = "log_mel_v0_placeholder"
    status: str = "placeholder"
    sample_rate: int = 16_000
    window_size_ms: float = 25.0
    hop_size_ms: float = 10.0
    frame_count: int = 300
    mel_bin_count: int = 64
    min_frequency_hz: float = 50.0
    max_frequency_hz: float = 8_000.0
    power_floor_db: float = -80.0
    normalization: str = "per_sample_log_power_0_1_placeholder"
    purpose: str = "future local-only Core ML input contract"

    @property
    def input_shape(self) -> list[int]:
        return [self.frame_count, self.mel_bin_count]

    def to_metadata(self) -> dict[str, object]:
        metadata = asdict(self)
        metadata["input_shape"] = self.input_shape
        metadata["stores_raw_audio"] = False
        metadata["requires_network"] = False
        return metadata


DEFAULT_LOG_MEL_SPEC = LogMelSpectrogramSpec()


def safe_float(value: object, default: float = 0.0) -> float:
    try:
        result = float(value)
    except (TypeError, ValueError):
        return default

    if not math.isfinite(result):
        return default
    return result


def clamp(value: float, lower: float = 0.0, upper: float = 1.0) -> float:
    value = safe_float(value)
    return min(max(value, lower), upper)


def extract_basic_features(
    samples: Iterable[float],
    sample_rate: float,
    max_spectral_samples: int = 2048,
) -> dict[str, float]:
    """Extract the MVP feature set from PCM-like samples.

    This is a lightweight local helper, not the production iPhone analyzer. It
    uses a tiny naive DFT window for centroid and band-energy estimates so that
    synthetic tests can run without numpy.
    """

    sample_list = [safe_float(sample) for sample in samples]
    if not sample_list:
        return {name: 0.0 for name in FEATURE_COLUMNS}

    sample_rate = max(safe_float(sample_rate, 16_000.0), 1.0)
    duration = len(sample_list) / sample_rate
    square_sum = sum(sample * sample for sample in sample_list)
    energy = square_sum / len(sample_list)
    rms = math.sqrt(energy)

    crossings = 0
    previous = sample_list[0]
    for sample in sample_list[1:]:
        if (previous < 0 <= sample) or (previous >= 0 > sample):
            crossings += 1
        previous = sample

    zero_crossing_rate = crossings / max(1, len(sample_list) - 1)

    spectral_window = sample_list[:max_spectral_samples]
    spectral_centroid, low_band, mid_band, high_band = _spectral_summary(
        spectral_window,
        sample_rate,
    )

    return {
        "rms": clamp(rms),
        "energy": max(0.0, safe_float(energy)),
        "zeroCrossingRate": clamp(zero_crossing_rate),
        "spectralCentroid": max(0.0, safe_float(spectral_centroid)),
        "lowBandEnergy": clamp(low_band),
        "midBandEnergy": clamp(mid_band),
        "highBandEnergy": clamp(high_band),
        "duration": max(0.0, safe_float(duration)),
    }


def log_mel_placeholder_metadata(
    spec: LogMelSpectrogramSpec = DEFAULT_LOG_MEL_SPEC,
) -> dict[str, object]:
    """Return commit-safe metadata for the future log-mel path."""

    return spec.to_metadata()


def build_log_mel_placeholder_tensor(
    spec: LogMelSpectrogramSpec = DEFAULT_LOG_MEL_SPEC,
    fill: float = 0.0,
) -> list[list[float]]:
    """Build a shape-only tensor for tests and documentation examples.

    The tensor does not encode audio and must not be used for model training.
    It exists so shape consumers can be tested without adding personal audio or
    enabling a not-yet-reviewed extractor.
    """

    value = clamp(fill)
    return [[value for _ in range(spec.mel_bin_count)] for _ in range(spec.frame_count)]


def extract_log_mel_spectrogram(*_: object, **__: object) -> list[list[float]]:
    """Placeholder for a future local-only log-mel feature path.

    The first snore detector is intentionally feature-table based. A later
    iteration can implement this function and train a model that consumes a
    spectrogram-like tensor before Core ML conversion.
    """

    raise NotImplementedError(
        "log-mel spectrogram extraction is intentionally disabled. "
        "Use log_mel_placeholder_metadata() for the reviewed placeholder schema."
    )


def _spectral_summary(samples: list[float], sample_rate: float) -> tuple[float, float, float, float]:
    if len(samples) < 8:
        return 0.0, 0.0, 0.0, 0.0

    n = len(samples)
    nyquist = sample_rate / 2.0
    max_bin = min(n // 2, 512)
    weighted_sum = 0.0
    magnitude_sum = 0.0
    low_sum = 0.0
    mid_sum = 0.0
    high_sum = 0.0

    for bin_index in range(1, max_bin):
        real = 0.0
        imaginary = 0.0
        for sample_index, sample in enumerate(samples):
            angle = 2.0 * math.pi * bin_index * sample_index / n
            real += sample * math.cos(angle)
            imaginary -= sample * math.sin(angle)

        magnitude = math.sqrt(real * real + imaginary * imaginary)
        frequency = bin_index * sample_rate / n
        weighted_sum += frequency * magnitude
        magnitude_sum += magnitude

        if frequency < 300.0:
            low_sum += magnitude
        elif frequency < 2_000.0:
            mid_sum += magnitude
        elif frequency <= nyquist:
            high_sum += magnitude

    if magnitude_sum <= 0:
        return 0.0, 0.0, 0.0, 0.0

    return (
        weighted_sum / magnitude_sum,
        low_sum / magnitude_sum,
        mid_sum / magnitude_sum,
        high_sum / magnitude_sum,
    )
