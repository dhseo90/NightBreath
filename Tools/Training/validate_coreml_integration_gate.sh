#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_FILE="$REPO_ROOT/SleepSoundApp.xcodeproj/project.pbxproj"
INTEGRATION_GUIDE="$REPO_ROOT/Docs/CORE_ML_MODEL_INTEGRATION.md"
SNORE_GUIDE="$REPO_ROOT/Docs/SNORE_ML_V0.md"
TRAINING_GUIDE="$REPO_ROOT/Tools/Training/README.md"
MODEL_ROOTS=(
  "$REPO_ROOT/SleepSoundApp"
  "$REPO_ROOT/Models"
)
KNOWN_MODEL_REFERENCES=(
  "SnoreDetector.mlmodel"
  "SnoreDetector.mlmodelc"
  "SnoreDetector.mlpackage"
  "SleepEventClassifier.mlmodel"
  "SleepEventClassifier.mlmodelc"
  "SleepEventClassifier.mlpackage"
)

fail() {
  echo "error: $*" >&2
  exit 1
}

require_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "Missing required file: ${path#$REPO_ROOT/}"
}

require_text() {
  local path="$1"
  local needle="$2"
  grep -Fq -- "$needle" "$path" || fail "${path#$REPO_ROOT/} is missing required text: $needle"
}

require_file "$PROJECT_FILE"
require_file "$INTEGRATION_GUIDE"
require_file "$SNORE_GUIDE"
require_file "$TRAINING_GUIDE"

model_artifacts=()
for root in "${MODEL_ROOTS[@]}"; do
  [[ -d "$root" ]] || continue
  while IFS= read -r -d '' path; do
    model_artifacts+=("${path#$REPO_ROOT/}")
  done < <(find "$root" \( -name '*.mlmodel' -o -name '*.mlmodelc' -o -name '*.mlpackage' \) -print0)
done

if (( ${#model_artifacts[@]} > 0 )); then
  printf 'error: Core ML model artifacts are present before the integration gate is complete:\n' >&2
  printf '  %s\n' "${model_artifacts[@]}" >&2
  exit 1
fi

for reference in "${KNOWN_MODEL_REFERENCES[@]}"; do
  if grep -Fq -- "$reference" "$PROJECT_FILE"; then
    fail "Xcode project already references $reference. Run the full Core ML integration gate before adding target resources."
  fi
done

require_text "$INTEGRATION_GUIDE" "실제 모델 artifact는 아직 앱 target에 포함하지 않습니다."
require_text "$INTEGRATION_GUIDE" "modelInstalled == false"
require_text "$INTEGRATION_GUIDE" "rule-based fallback"
require_text "$INTEGRATION_GUIDE" "--backends ruleBased,coreML,hybrid"
require_text "$INTEGRATION_GUIDE" "전체 밤 원본 오디오 저장 기능을 추가하지 않습니다."
require_text "$INTEGRATION_GUIDE" "서버 업로드, 클라우드 처리, 외부 API 호출, 외부 분석 SDK를 추가하지 않습니다."
require_text "$SNORE_GUIDE" "Docs/CORE_ML_MODEL_INTEGRATION.md"
require_text "$TRAINING_GUIDE" "Docs/CORE_ML_MODEL_INTEGRATION.md"
require_text "$TRAINING_GUIDE" '앱 target에 `.mlmodel`을 자동으로 추가하지 않습니다.'

cat <<EOF
Core ML integration gate passed.

Checked:
  SleepSoundApp.xcodeproj/project.pbxproj
  SleepSoundApp/
  Models/
  Docs/CORE_ML_MODEL_INTEGRATION.md
  Docs/SNORE_ML_V0.md
  Tools/Training/README.md

Current expected state:
  no .mlmodel, .mlmodelc, or .mlpackage artifacts are committed
  no Core ML model resource is added to the app target
  hybrid detector remains safe to fall back to rule-based detection
EOF
