#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

usage() {
  cat <<'EOF'
Usage:
  Tools/Release/audit_app_bundle_artifacts.sh /path/to/NightBreath.app

Checks a built app bundle for files that must not ship in release builds:
  ESC-50 / public dataset content
  personal/public sample folders
  local training/offline-evaluation output
  bundled audio files
  Python/sklearn training artifacts

Set APP_BUNDLE_PATH instead of passing an argument if preferred.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

BUNDLE_PATH="${1:-${APP_BUNDLE_PATH:-}}"
if [[ -z "$BUNDLE_PATH" ]]; then
  usage >&2
  exit 2
fi

if [[ ! -d "$BUNDLE_PATH" ]]; then
  echo "error: app bundle not found: $BUNDLE_PATH" >&2
  exit 1
fi

blocked_entries=()

record_blocked() {
  local path="$1"
  local reason="$2"
  blocked_entries+=("$path"$'\t'"$reason")
}

while IFS= read -r -d '' path; do
  rel_path="${path#$BUNDLE_PATH/}"
  lower_rel="$(printf '%s' "$rel_path" | tr '[:upper:]' '[:lower:]')"

  case "$lower_rel" in
    *esc-50*|*esc50*)
      record_blocked "$rel_path" "ESC-50 content or manifest must not ship in the app bundle"
      ;;
    datasets/*|*/datasets/*|samples/personal/*|*/samples/personal/*|samples/public/*|*/samples/public/*)
      record_blocked "$rel_path" "dataset/sample folders must not ship in the app bundle"
      ;;
    tools/offlineevaluation/output/*|*/tools/offlineevaluation/output/*|tools/training/output/*|*/tools/training/output/*)
      record_blocked "$rel_path" "local evaluation/training output must not ship in the app bundle"
      ;;
    *offline_evaluation*|*tuning_report*|*snore_evaluation*|*export_feedback_manifest*)
      record_blocked "$rel_path" "local detector/training evidence output must not ship in the app bundle"
      ;;
    *.wav|*.caf|*.m4a|*.mp3|*.flac|*.ogg|*.aac|*.aif|*.aiff)
      record_blocked "$rel_path" "bundled audio files require a separate release/legal review and are blocked by default"
      ;;
    *.pkl|*.joblib|*.onnx|*.pt|*.pth|*.tflite)
      record_blocked "$rel_path" "training/runtime model artifact is not an approved app bundle resource"
      ;;
  esac
done < <(find "$BUNDLE_PATH" -print0)

if (( ${#blocked_entries[@]} > 0 )); then
  cat >&2 <<'EOF'
error: blocked dataset/audio/training artifacts were found in the app bundle.

Release builds must not include ESC-50, personal/public audio samples, local
evaluation output, or training artifacts.

Blocked bundle paths:
EOF
  printf '  %s\n' "${blocked_entries[@]}" >&2
  exit 1
fi

cat <<EOF
App bundle artifact audit passed.

Bundle:
  ${BUNDLE_PATH#$ROOT_DIR/}
EOF
