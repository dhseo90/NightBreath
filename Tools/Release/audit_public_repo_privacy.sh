#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -n "${NIGHTBREATH_REPO_ROOT:-}" ]]; then
  ROOT_DIR="$(cd "$NIGHTBREATH_REPO_ROOT" && pwd)"
else
  ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi
cd "$ROOT_DIR"

matches=()

record_matches() {
  local label="$1"
  local pattern="$2"

  while IFS= read -r line; do
    matches+=("$label"$'\t'"$line")
  done < <(git grep -nI -E -- "$pattern" -- . 2>/dev/null || true)
}

record_matches "AWS access key" '(AKIA|ASIA)[0-9A-Z]{16}'
record_matches "Google API key" 'AIza[0-9A-Za-z_-]{35}'
record_matches "GitHub token" 'gh[pousr]_[A-Za-z0-9_]{20,}'
record_matches "Slack token" 'xox[baprs]-[A-Za-z0-9-]{20,}'
record_matches "private key block" '-----BEGIN [A-Z ]*PRIVATE KEY-----'
record_matches "personal absolute path" '/(Users|private/var|var/folders)/[A-Za-z0-9._%+-]+'
record_matches "file URI" 'file:///(Users|private|var|Volumes)/'
record_matches "email address" '[A-Za-z0-9._%+-]+@[A-Za-z][A-Za-z0-9.-]*\.[A-Za-z]{2,}'
record_matches "device identifier in command" '(platform=iOS[^`"]*id=|--device )[A-Fa-f0-9-]{20,}'

if (( ${#matches[@]} > 0 )); then
  cat >&2 <<'EOF'
error: possible public-repo secret, personal path, email, or device identifier was found.

This scan is intentionally conservative. If a match is a synthetic fixture or
documentation example, either rewrite it to a clearly fake value or narrow this
gate with an explicit allowlist and rationale.

Matches:
EOF
  printf '  %s\n' "${matches[@]}" >&2
  exit 1
fi

NIGHTBREATH_REPO_ROOT="$ROOT_DIR" "$SCRIPT_DIR/audit_tracked_artifacts.sh" >/dev/null

cat <<'EOF'
Public repository privacy audit passed.

Checked tracked repository text for:
  common cloud/API tokens
  private key blocks
  personal absolute paths and file URIs
  email addresses
  UDID-like device identifiers
  blocked dataset/audio/model/output artifacts
EOF
