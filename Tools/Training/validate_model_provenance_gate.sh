#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -n "${NIGHTBREATH_REPO_ROOT:-}" ]]; then
  REPO_ROOT="$(cd "$NIGHTBREATH_REPO_ROOT" && pwd)"
else
  REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi
CHECKLIST="$REPO_ROOT/Docs/MODEL_PROVENANCE_CHECKLIST.md"
MANIFEST="$REPO_ROOT/Models/CoreML/model_provenance.tsv"
MODEL_ROOTS=(
  "$REPO_ROOT/Models/CoreML"
  "$REPO_ROOT/SleepSoundApp"
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

model_artifacts=()
for root in "${MODEL_ROOTS[@]}"; do
  [[ -d "$root" ]] || continue
  while IFS= read -r -d '' path; do
    model_artifacts+=("${path#$REPO_ROOT/}")
  done < <(find "$root" \( -name '*.mlmodel' -o -name '*.mlmodelc' -o -name '*.mlpackage' \) -print0)
done

require_file "$CHECKLIST"
require_text "$CHECKLIST" "model_provenance.tsv"
require_text "$CHECKLIST" "ESC-50"
require_text "$CHECKLIST" "NonCommercial"
require_text "$CHECKLIST" "approved"

if (( ${#model_artifacts[@]} == 0 )); then
  cat <<'EOF'
Model provenance gate passed.

Current expected state:
  no Core ML model artifacts are present
  provenance checklist is documented
  model_provenance.tsv is required before any model artifact is committed
EOF
  exit 0
fi

require_file "$MANIFEST"

expected_header=$'artifact_path\tmodel_name\tversion\ttraining_data_summary\ttraining_data_license\tcommercial_use_status\tpersonal_data_status\tevaluation_evidence\treview_status\treviewer\treview_date\tnotes'
actual_header="$(head -n 1 "$MANIFEST")"
[[ "$actual_header" == "$expected_header" ]] || fail "Models/CoreML/model_provenance.tsv has an unexpected header"

for artifact in "${model_artifacts[@]}"; do
  matched=0

  while IFS=$'\t' read -r artifact_path model_name version training_data_summary training_data_license commercial_use_status personal_data_status evaluation_evidence review_status reviewer review_date notes; do
    [[ "$artifact_path" == "artifact_path" ]] && continue
    [[ "$artifact_path" == "$artifact" ]] || continue
    matched=1

    [[ -n "$model_name" ]] || fail "$artifact is missing model_name in provenance manifest"
    [[ -n "$version" ]] || fail "$artifact is missing version in provenance manifest"
    [[ -n "$training_data_summary" ]] || fail "$artifact is missing training_data_summary in provenance manifest"
    [[ -n "$training_data_license" ]] || fail "$artifact is missing training_data_license in provenance manifest"
    [[ -n "$commercial_use_status" ]] || fail "$artifact is missing commercial_use_status in provenance manifest"
    [[ -n "$personal_data_status" ]] || fail "$artifact is missing personal_data_status in provenance manifest"
    [[ -n "$evaluation_evidence" ]] || fail "$artifact is missing evaluation_evidence in provenance manifest"
    [[ "$review_status" == "approved" ]] || fail "$artifact must have review_status=approved before git/app target use"
    [[ -n "$reviewer" ]] || fail "$artifact is missing reviewer in provenance manifest"
    [[ -n "$review_date" ]] || fail "$artifact is missing review_date in provenance manifest"

    license_lower="$(printf '%s' "$training_data_license" | tr '[:upper:]' '[:lower:]')"
    commercial_lower="$(printf '%s' "$commercial_use_status" | tr '[:upper:]' '[:lower:]')"
    if [[ "$license_lower" == *"esc-50"* || "$license_lower" == *"cc by-nc"* || "$license_lower" == *"noncommercial"* ]]; then
      if [[ "$commercial_lower" != *"legal-reviewed"* && "$commercial_lower" != *"not-for-commercial-release"* ]]; then
        fail "$artifact uses ESC-50/NonCommercial data but commercial_use_status is not legal-reviewed or not-for-commercial-release"
      fi
    fi
  done < "$MANIFEST"

  (( matched == 1 )) || fail "$artifact is missing from Models/CoreML/model_provenance.tsv"
done

cat <<'EOF'
Model provenance gate passed.

Checked:
  Core ML model artifact provenance rows
  approved review status
  ESC-50 / NonCommercial commercial-use handling
EOF
