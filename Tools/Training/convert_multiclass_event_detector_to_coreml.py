#!/usr/bin/env python3
"""Placeholder Core ML conversion entry point for the multiclass event classifier."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


def training_root() -> Path:
    return Path(__file__).resolve().parent


def repo_root() -> Path:
    return training_root().parents[1]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Prepare Core ML conversion for the local multiclass event classifier."
    )
    parser.add_argument(
        "--input",
        default=str(training_root() / "output" / "multiclass_event_model.pkl"),
        help="Path to the trained multiclass joblib bundle.",
    )
    parser.add_argument(
        "--output",
        default=str(repo_root() / "Models" / "CoreML" / "SleepEventClassifier.mlmodel"),
        help="Destination .mlmodel or .mlpackage path.",
    )
    args = parser.parse_args()

    input_path = Path(args.input).expanduser().resolve()
    output_path = Path(args.output).expanduser().resolve()

    if not input_path.exists():
        print(
            "Core ML conversion skipped: multiclass model file was not found.\n"
            f"Expected: {input_path}\n"
            "Run `python3 train_multiclass_event_detector.py --manifest <path>` after enough reviewed samples exist.",
            file=sys.stderr,
        )
        return 2

    print(
        "Core ML conversion placeholder: multiclass model bundle exists, but conversion is intentionally gated "
        "until label quality, class balance, and app-side output mapping are reviewed."
    )
    print(f"Input model: {input_path}")
    print(f"Planned output: {output_path}")
    print("No model file was written.")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
