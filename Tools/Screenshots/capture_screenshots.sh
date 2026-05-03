#!/usr/bin/env bash
set -euo pipefail

OUTPUT_PATH="${1:-}"
APPEARANCE="${2:-}"

if [[ -z "$OUTPUT_PATH" ]]; then
  echo "Usage: Tools/Screenshots/capture_screenshots.sh <output-path.png> [light|dark]" >&2
  echo "Example: Tools/Screenshots/capture_screenshots.sh Docs/Screenshots/README/home-dashboard.png light" >&2
  exit 64
fi

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun was not found. Install Xcode command line tools and try again." >&2
  exit 69
fi

echo "Available simulators:"
xcrun simctl list devices available

if ! xcrun simctl list devices booted | grep -q "(Booted)"; then
  echo "No booted simulator found." >&2
  echo "Boot a simulator first, then run the app in DEBUG configuration." >&2
  echo "Example: xcrun simctl boot 'iPhone 17'" >&2
  exit 65
fi

case "$APPEARANCE" in
  "")
    ;;
  light|dark)
    echo "Setting simulator appearance to $APPEARANCE"
    xcrun simctl ui booted appearance "$APPEARANCE"
    ;;
  *)
    echo "Unknown appearance '$APPEARANCE'. Use light or dark." >&2
    exit 64
    ;;
esac

mkdir -p "$(dirname "$OUTPUT_PATH")"

echo "Before capture:"
echo "1. Run the app in DEBUG configuration."
echo "2. Open Settings > Developer > Simulator QA / Screenshot Scenario."
echo "3. Select and apply the desired Screenshot preset."
echo "4. Open the target screen."
echo "5. Return here and press Enter."
read -r _

if xcrun simctl io booted screenshot "$OUTPUT_PATH"; then
  echo "Saved screenshot: $OUTPUT_PATH"
else
  echo "Failed to capture screenshot." >&2
  echo "Confirm that a simulator is booted and the app is visible." >&2
  exit 70
fi
