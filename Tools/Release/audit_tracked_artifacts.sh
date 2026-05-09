#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -n "${NIGHTBREATH_REPO_ROOT:-}" ]]; then
  ROOT_DIR="$(cd "$NIGHTBREATH_REPO_ROOT" && pwd)"
else
  ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi
cd "$ROOT_DIR"

blocked_entries=()

record_blocked() {
  local path="$1"
  local reason="$2"
  blocked_entries+=("$path"$'\t'"$reason")
}

while IFS= read -r -d '' path; do
  lower_path="$(printf '%s' "$path" | tr '[:upper:]' '[:lower:]')"

  case "$path" in
    Datasets/*)
      record_blocked "$path" "dataset content must stay outside git"
      ;;
    Samples/Personal/*)
      record_blocked "$path" "personal sample content must stay outside git"
      ;;
    Samples/Public/*)
      record_blocked "$path" "public audio sample content must stay outside git unless a separate license gate is approved"
      ;;
    Tools/FeatureLab/output/*|Tools/Training/output/*|Tools/DatasetReplay/output/*|Tools/OfflineEvaluation/output/*)
      record_blocked "$path" "generated local output must stay outside git"
      ;;
    .device-data/*)
      record_blocked "$path" "device-local data must stay outside git"
      ;;
  esac

  case "$lower_path" in
    *.wav|*.caf|*.m4a|*.mp3|*.flac|*.ogg|*.aac|*.aif|*.aiff)
      record_blocked "$path" "audio file artifact must stay outside git"
      ;;
    *.mlmodel|*.mlmodelc|*.mlmodelc/*|*.mlpackage|*.mlpackage/*|*.onnx|*.pt|*.pth|*.tflite|*.pkl|*.joblib)
      record_blocked "$path" "model/training artifact requires provenance review before git"
      ;;
  esac
done < <(git ls-files -z)

if (( ${#blocked_entries[@]} > 0 )); then
  cat >&2 <<'EOF'
error: git-tracked local dataset, audio, model, or generated artifacts were found.

These files are intentionally blocked for privacy, licensing, and release safety.
Keep personal/public audio, ESC-50, training outputs, offline evaluation outputs,
and model artifacts outside git unless a dedicated provenance/legal gate is added.

Blocked paths:
EOF
  printf '  %s\n' "${blocked_entries[@]}" >&2
  exit 1
fi

cat <<'EOF'
Tracked artifact audit passed.

Checked git-tracked paths for:
  Datasets/
  Samples/Personal/
  Samples/Public/
  Tools/*/output/
  .device-data/
  audio files
  model/training artifacts
EOF
