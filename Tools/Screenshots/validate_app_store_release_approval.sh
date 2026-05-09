#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MANIFEST="$REPO_ROOT/Docs/Screenshots/screenshot_status.tsv"
REQUIRE_APPROVED="${REQUIRE_APP_STORE_RELEASE_APPROVED:-0}"

EXPECTED_HEADER=$'id\tgroup\tview_or_surface\tscenario\traw_source\treview_asset\tstatus\trelease_surface\tnotes'
REQUIRED_IDS=(
  "appstore-home"
  "appstore-sleep-report"
  "appstore-timeline"
  "appstore-rhythm"
  "appstore-card"
  "appstore-health"
  "appstore-privacy"
  "appstore-zero-event"
)
REQUIRED_CHECKLIST_TERMS=(
  "copy"
  "crop"
  "privacy"
  "export"
)

fail() {
  echo "error: $*" >&2
  exit 1
}

[[ -f "$MANIFEST" ]] || fail "Missing Docs/Screenshots/screenshot_status.tsv"

header="$(sed -n '1p' "$MANIFEST")"
[[ "$header" == "$EXPECTED_HEADER" ]] || fail "Unexpected screenshot_status.tsv header."

release_approved_count=0
blocked_count=0

for id in "${REQUIRED_IDS[@]}"; do
  row="$(
    awk -F '\t' -v target_id="$id" '
      NR > 1 && $1 == target_id && $2 == "App Store" {
        print
        found = 1
        exit
      }
      END {
        if (!found) {
          exit 1
        }
      }
    ' "$MANIFEST"
  )" || fail "Missing App Store screenshot row: $id"

  IFS=$'\t' read -r row_id group view_or_surface scenario raw_source review_asset status release_surface notes <<< "$row"

  [[ -n "$raw_source" ]] || fail "$id must keep a raw source path."
  [[ -n "$review_asset" ]] || fail "$id must keep a review crop path."
  [[ -f "$REPO_ROOT/$raw_source" ]] || fail "$id raw source does not exist: $raw_source"
  [[ -f "$REPO_ROOT/$review_asset" ]] || fail "$id review crop does not exist: $review_asset"

  case "$status" in
    "release-approved")
      release_approved_count=$((release_approved_count + 1))
      [[ "$notes" == *"approved:"* ]] || fail "$id release-approved notes must include approved: evidence."
      [[ "$notes" == *"checklist:"* ]] || fail "$id release-approved notes must include checklist: evidence."
      for term in "${REQUIRED_CHECKLIST_TERMS[@]}"; do
        [[ "$notes" == *"$term"* ]] || fail "$id release-approved checklist must mention $term."
      done
      ;;
    "blocked, recapture required")
      blocked_count=$((blocked_count + 1))
      ;;
    *)
      fail "$id has unsupported App Store approval status: $status"
      ;;
  esac
done

if [[ "$release_approved_count" -gt 0 && "$release_approved_count" -ne "${#REQUIRED_IDS[@]}" ]]; then
  fail "App Store screenshots must be promoted as a complete set of 8; found $release_approved_count release-approved."
fi

if [[ "$REQUIRE_APPROVED" == "1" && "$release_approved_count" -ne "${#REQUIRED_IDS[@]}" ]]; then
  fail "REQUIRE_APP_STORE_RELEASE_APPROVED=1 requires all 8 App Store screenshots to be release-approved."
fi

cat <<EOF
App Store screenshot release approval validation passed.

App Store rows: ${#REQUIRED_IDS[@]}
release-approved: $release_approved_count
blocked, recapture required: $blocked_count

Gate behavior:
  - No partial promotion is allowed.
  - release-approved rows require approved: and checklist: notes.
  - checklist must mention copy, crop, privacy, and export.
EOF
