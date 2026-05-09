#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

Tools/Release/audit_tracked_artifacts.sh
Tools/Training/validate_coreml_integration_gate.sh
Tools/Training/validate_model_provenance_gate.sh
Tools/Training/test_model_provenance_gate_negative.sh
Tools/Release/audit_trademark_copy.sh
Tools/Release/audit_public_repo_privacy.sh
Tools/UI/validate_navigation_chrome.sh

/usr/bin/xcrun swift test \
  --filter ReleaseReadiness \
  --filter AppStoreReadiness \
  --filter UIGalleryDocumentation \
  --filter SimulatorQAScenario \
  --filter PrivacyCopySafety \
  --filter HealthKitReadOnlyPolicy \
  --no-parallel
