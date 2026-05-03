#!/usr/bin/env python3
"""Convert the local snore baseline model to Core ML.

This script expects the joblib bundle produced by train_snore_detector.py.
It does not download datasets, upload audio, or add the generated model to the
Xcode target automatically.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


from audio_features import FEATURE_COLUMNS


def training_root() -> Path:
    return Path(__file__).resolve().parent


def repo_root() -> Path:
    return training_root().parents[1]


def main() -> int:
    parser = argparse.ArgumentParser(description="Convert Snore ML v0 snore_model.pkl to Core ML.")
    parser.add_argument(
        "--input",
        default=str(training_root() / "output" / "snore_model.pkl"),
        help="Path to the trained joblib bundle.",
    )
    parser.add_argument(
        "--output",
        default=str(repo_root() / "Models" / "CoreML" / "SnoreDetector.mlmodel"),
        help="Destination .mlmodel or .mlpackage path.",
    )
    args = parser.parse_args()

    input_path = Path(args.input).expanduser().resolve()
    output_path = Path(args.output).expanduser().resolve()

    if not input_path.exists():
        print(
            "Core ML conversion skipped: trained model file was not found.\n"
            f"Expected: {input_path}\n"
            "Run `python3 train_snore_detector.py --manifest <path>` or prepare local metadata first.",
            file=sys.stderr,
        )
        return 2

    try:
        deps = load_dependencies()
    except RuntimeError as error:
        print(f"Core ML conversion skipped: {error}", file=sys.stderr)
        return 2

    joblib = deps["joblib"]
    ct = deps["coremltools"]

    try:
        bundle = joblib.load(input_path)
    except Exception as error:  # noqa: BLE001
        print(f"Core ML conversion failed: could not read {input_path}: {error}", file=sys.stderr)
        return 2

    estimator = bundle.get("model") if isinstance(bundle, dict) else bundle
    feature_columns = bundle.get("feature_columns", FEATURE_COLUMNS) if isinstance(bundle, dict) else FEATURE_COLUMNS
    threshold = bundle.get("threshold", 0.5) if isinstance(bundle, dict) else 0.5
    model_version = bundle.get("model_version", "Snore ML v0") if isinstance(bundle, dict) else "Snore ML v0"

    missing_columns = [name for name in FEATURE_COLUMNS if name not in feature_columns]
    if missing_columns:
        print(
            "Core ML conversion failed: trained bundle is missing expected feature columns: "
            + ", ".join(missing_columns),
            file=sys.stderr,
        )
        return 2

    try:
        input_features = [(name, ct.models.datatypes.Double()) for name in feature_columns]
        coreml_model = ct.converters.sklearn.convert(
            estimator,
            input_features=input_features,
            output_feature_names=["classLabel", "classProbability"],
        )
    except Exception as error:  # noqa: BLE001
        print(f"Core ML conversion failed: {error}", file=sys.stderr)
        return 2

    coreml_model.short_description = "NightBreath Snore ML v0 local snore vs non-snore baseline."
    coreml_model.author = "NightBreath local training pipeline"
    coreml_model.license = "Private local model"
    coreml_model.user_defined_metadata.update(
        {
            "nightbreath_detector": "snore",
            "model_version": str(model_version),
            "positive_label": "snore",
            "negative_label": "non_snore",
            "numeric_label_mapping": "1=snore, 0=non_snore",
            "threshold": str(threshold),
            "feature_columns": ",".join(feature_columns),
        }
    )

    output_path.parent.mkdir(parents=True, exist_ok=True)

    try:
        coreml_model.save(output_path)
    except Exception as error:  # noqa: BLE001
        print(f"Core ML conversion failed: could not save {output_path}: {error}", file=sys.stderr)
        return 2

    print(f"Core ML model written to: {output_path}")
    print("Add this model to the Xcode target when you are ready to test the Core ML backend.")
    return 0


def load_dependencies() -> dict[str, object]:
    try:
        import coremltools as ct
        import joblib
    except ImportError as error:
        raise RuntimeError(
            "필요한 Python package가 없습니다. "
            "`python3 -m pip install -r Tools/Training/requirements.txt`를 실행해 주세요."
        ) from error

    return {
        "coremltools": ct,
        "joblib": joblib,
    }


if __name__ == "__main__":
    raise SystemExit(main())
