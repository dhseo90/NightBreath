#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_REPO="$(mktemp -d "${TMPDIR:-/tmp}/nightbreath-model-provenance.XXXXXX")"
trap 'rm -rf "$TMP_REPO"' EXIT

mkdir -p "$TMP_REPO/Docs" "$TMP_REPO/Models/CoreML" "$TMP_REPO/SleepSoundApp"

cat > "$TMP_REPO/Docs/MODEL_PROVENANCE_CHECKLIST.md" <<'EOF'
# Model Provenance Checklist

model_provenance.tsv
ESC-50
NonCommercial
approved
EOF

touch "$TMP_REPO/Models/CoreML/Fake.mlmodel"

HEADER=$'artifact_path\tmodel_name\tversion\ttraining_data_summary\ttraining_data_license\tcommercial_use_status\tpersonal_data_status\tevaluation_evidence\treview_status\treviewer\treview_date\tnotes'
GATE="$REPO_ROOT/Tools/Training/validate_model_provenance_gate.sh"

expect_fail() {
  local label="$1"
  if NIGHTBREATH_REPO_ROOT="$TMP_REPO" "$GATE" >/tmp/nightbreath-model-provenance.out 2>&1; then
    echo "error: expected model provenance gate to fail: $label" >&2
    cat /tmp/nightbreath-model-provenance.out >&2
    exit 1
  fi
}

expect_pass() {
  local label="$1"
  if ! NIGHTBREATH_REPO_ROOT="$TMP_REPO" "$GATE" >/tmp/nightbreath-model-provenance.out 2>&1; then
    echo "error: expected model provenance gate to pass: $label" >&2
    cat /tmp/nightbreath-model-provenance.out >&2
    exit 1
  fi
}

expect_fail "model artifact without provenance manifest"

{
  printf '%s\n' "$HEADER"
  printf 'Models/CoreML/Fake.mlmodel\tFakeModel\tv0\tsynthetic samples\tApache-2.0\tcommercial-release-candidate\tno personal data\tDocs/EVIDENCE.md\tpending\tQA\t2026-05-09\tnegative test\n'
} > "$TMP_REPO/Models/CoreML/model_provenance.tsv"

expect_fail "pending review_status"

{
  printf '%s\n' "$HEADER"
  printf 'Models/CoreML/Fake.mlmodel\tFakeModel\tv0\tESC-50 local QA sweep\tESC-50 CC BY-NC 3.0\tcommercial-release-candidate\tno personal data\tDocs/EVIDENCE.md\tapproved\tQA\t2026-05-09\tnegative test\n'
} > "$TMP_REPO/Models/CoreML/model_provenance.tsv"

expect_fail "NonCommercial data without commercial status"

{
  printf '%s\n' "$HEADER"
  printf 'Models/CoreML/Fake.mlmodel\tFakeModel\tv0\tESC-50 local QA sweep\tESC-50 CC BY-NC 3.0\tnot-for-commercial-release\tno personal data\tDocs/EVIDENCE.md\tapproved\tQA\t2026-05-09\tnegative test\n'
} > "$TMP_REPO/Models/CoreML/model_provenance.tsv"

expect_pass "approved non-commercial model provenance"

cat <<'EOF'
Model provenance negative test passed.

Checked:
  missing manifest fails
  pending review_status fails
  ESC-50 / NonCommercial commercial-use ambiguity fails
  approved not-for-commercial-release provenance passes
EOF
