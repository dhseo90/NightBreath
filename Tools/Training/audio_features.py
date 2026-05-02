#!/usr/bin/env python3
"""Small tabular audio feature helpers for local snore detector training.

This module intentionally avoids network calls and does not persist raw audio.
The iOS app already exports these summary features, but the helpers are useful
for synthetic tests and future local-only experiments.
"""

from __future__ import annotations

import math
from typing import Iterable


FEATURE_COLUMNS = [
    "rms",
    "energy",
    "zeroCrossingRate",
    "spectralCentroid",
    "lowBandEnergy",
    "midBandEnergy",
    "highBandEnergy",
]


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
    }


def extract_log_mel_spectrogram(*_: object, **__: object) -> list[list[float]]:
    """Placeholder for a future local-only log-mel feature path.

    The first snore detector is intentionally feature-table based. A later
    iteration can implement this function and train a model that consumes a
    spectrogram-like tensor before Core ML conversion.
    """

    raise NotImplementedError(
        "log-mel spectrogram extraction is intentionally left for a later Core ML training step"
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
