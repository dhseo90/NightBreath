#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

Tools/UI/validate_navigation_chrome.sh

/usr/bin/xcrun swift test \
  --filter ReleaseReadiness \
  --filter AppStoreReadiness \
  --filter UIGalleryDocumentation \
  --filter SimulatorQAScenario \
  --filter PrivacyCopySafety \
  --filter HealthKitReadOnlyPolicy \
  --no-parallel
