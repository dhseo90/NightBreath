#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

scan_paths=(
  README.md
  Docs
  SleepSoundApp
)

patterns=(
  'official[[:space:]-]+(Apple|HealthKit|Fitdays|Fitdays\+|Omron)[[:space:]-]+(partner|partnership|integration|certified|endorsed|sponsored)'
  '(Apple|HealthKit|Fitdays|Fitdays\+|Omron)[[:space:]-]+official[[:space:]-]+(partner|partnership|integration|certified|endorsed|sponsored)'
  'endorsed[[:space:]]+by[[:space:]]+(Apple|HealthKit|Fitdays|Fitdays\+|Omron)'
  'sponsored[[:space:]]+by[[:space:]]+(Apple|HealthKit|Fitdays|Fitdays\+|Omron)'
  'affiliated[[:space:]]+with[[:space:]]+(Apple|HealthKit|Fitdays|Fitdays\+|Omron)'
  'partnership[[:space:]]+with[[:space:]]+(Apple|HealthKit|Fitdays|Fitdays\+|Omron)'
  '(Apple|HealthKit|Fitdays|Fitdays\+|Omron)[[:space:]]+certified'
  '공식[[:space:]]*(연동|제휴|파트너|인증)[^[:space:]]{0,30}(Apple|HealthKit|Fitdays|Fitdays\+|Omron)'
  '(Apple|HealthKit|Fitdays|Fitdays\+|Omron)[^[:space:]]{0,30}공식[[:space:]]*(연동|제휴|파트너|인증)'
  '(Apple|HealthKit|Fitdays|Fitdays\+|Omron)[^[:space:]]{0,30}(제휴|인증|스폰서|후원)'
  '(제휴|인증|스폰서|후원)[^[:space:]]{0,30}(Apple|HealthKit|Fitdays|Fitdays\+|Omron)'
)

matches=()
for pattern in "${patterns[@]}"; do
  while IFS= read -r line; do
    matches+=("$line")
  done < <(grep -RInE "$pattern" "${scan_paths[@]}" 2>/dev/null || true)
done

if (( ${#matches[@]} > 0 )); then
  cat >&2 <<'EOF'
error: possible trademark, sponsorship, certification, or affiliation wording was found.

NightBreath may mention Apple, HealthKit, Fitdays, and Omron descriptively, but
release-facing copy must not imply endorsement, sponsorship, certification, or
official partnership.

Matches:
EOF
  printf '  %s\n' "${matches[@]}" >&2
  exit 1
fi

cat <<'EOF'
Trademark/affiliation copy audit passed.

Checked release-facing docs and app source for official, certified, endorsed,
sponsored, affiliated, and partnership-style wording around Apple, HealthKit,
Fitdays, and Omron.
EOF
