#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GATE="$REPO_ROOT/Tools/Release/audit_public_repo_privacy.sh"
TMP_REPO="$(mktemp -d "${TMPDIR:-/tmp}/nightbreath-public-privacy.XXXXXX")"
OUT_FILE="$(mktemp "${TMPDIR:-/tmp}/nightbreath-public-privacy-output.XXXXXX")"
trap 'rm -rf "$TMP_REPO"; rm -f "$OUT_FILE"' EXIT

reset_repo() {
  rm -rf "$TMP_REPO"
  mkdir -p "$TMP_REPO"
  git -C "$TMP_REPO" init -q
}

track_file() {
  local path="$1"
  local content="$2"
  mkdir -p "$TMP_REPO/$(dirname "$path")"
  printf '%s\n' "$content" > "$TMP_REPO/$path"
  git -C "$TMP_REPO" add "$path"
}

expect_fail() {
  local label="$1"
  if NIGHTBREATH_REPO_ROOT="$TMP_REPO" "$GATE" >"$OUT_FILE" 2>&1; then
    echo "error: expected public repo privacy audit to fail: $label" >&2
    cat "$OUT_FILE" >&2
    exit 1
  fi
}

expect_pass() {
  local label="$1"
  if ! NIGHTBREATH_REPO_ROOT="$TMP_REPO" "$GATE" >"$OUT_FILE" 2>&1; then
    echo "error: expected public repo privacy audit to pass: $label" >&2
    cat "$OUT_FILE" >&2
    exit 1
  fi
}

reset_repo
track_file "Docs/fixture.txt" "$(printf '%s%s' AKIA 0123456789ABCDEF)"
expect_fail "cloud token"

reset_repo
track_file "Docs/fixture.txt" "$(printf '/%s/%s/Desktop/private.csv' Users developer)"
expect_fail "personal absolute path"

reset_repo
track_file "Docs/fixture.txt" "$(printf '%s@%s.%s' person example com)"
expect_fail "email address"

reset_repo
track_file "Samples/Public/snore.wav" "synthetic placeholder"
expect_fail "tracked audio artifact"

reset_repo
track_file "Models/CoreML/Fake.mlmodel" "synthetic placeholder"
expect_fail "tracked model artifact"

reset_repo
track_file "Docs/fixture.txt" "synthetic public-repo-safe fixture"
expect_pass "safe synthetic fixture"

cat <<'EOF'
Public repository privacy negative test passed.

Checked blocked examples:
  cloud token
  personal absolute path
  email address
  tracked audio artifact
  tracked model artifact
  safe synthetic fixture pass
EOF
