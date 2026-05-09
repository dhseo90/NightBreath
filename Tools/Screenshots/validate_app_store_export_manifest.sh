#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EXPORT_DIR="${APP_STORE_EXPORT_DIR:-$REPO_ROOT/Docs/Screenshots/AppStore/export}"
MANIFEST="$EXPORT_DIR/manifest.tsv"
VISUAL_REVIEW="$REPO_ROOT/Docs/Screenshots/app_store_export_visual_review.tsv"
EXPECTED_HEADER=$'size_label\twidth\theight\tfit_mode\tinput\toutput'
EXPECTED_VISUAL_REVIEW_HEADER=$'size_label\twidth\theight\tfit_mode\texported_pngs\treviewed_on\treviewer\tdecision\tevidence\tnext_action'
EXPECTED_SCREENSHOT_COUNT=8
EXPECTED_SIZE_COUNT=11

fail() {
  echo "error: $*" >&2
  exit 1
}

[[ -f "$MANIFEST" ]] || fail "Missing App Store export manifest: ${MANIFEST#$REPO_ROOT/}"
[[ -f "$VISUAL_REVIEW" ]] || fail "Missing App Store export visual review TSV: ${VISUAL_REVIEW#$REPO_ROOT/}"

if ! command -v sips >/dev/null 2>&1; then
  fail "sips is required to verify exported PNG dimensions."
fi

header="$(sed -n '1p' "$MANIFEST")"
[[ "$header" == "$EXPECTED_HEADER" ]] || fail "Unexpected App Store export manifest header."

visual_review_header="$(sed -n '1p' "$VISUAL_REVIEW")"
[[ "$visual_review_header" == "$EXPECTED_VISUAL_REVIEW_HEADER" ]] || fail "Unexpected App Store export visual review header."

row_count="$(awk 'NR > 1 { count++ } END { print count + 0 }' "$MANIFEST")"
expected_count=$((EXPECTED_SCREENSHOT_COUNT * EXPECTED_SIZE_COUNT))
[[ "$row_count" -eq "$expected_count" ]] || fail "Expected $expected_count export rows, found $row_count."

visual_review_count="$(awk 'NR > 1 { count++ } END { print count + 0 }' "$VISUAL_REVIEW")"
[[ "$visual_review_count" -eq "$EXPECTED_SIZE_COUNT" ]] || fail "Expected $EXPECTED_SIZE_COUNT visual review rows, found $visual_review_count."

while IFS=$'\t' read -r size_label width height fit_mode input output; do
  [[ -n "$size_label" ]] || fail "Empty size label in manifest."
  [[ -n "$width" && -n "$height" ]] || fail "$size_label has missing dimensions."
  [[ "$fit_mode" == "contain" || "$fit_mode" == "cover" || "$fit_mode" == "stretch" ]] || fail "$output has invalid fit mode: $fit_mode"
  [[ -f "$REPO_ROOT/$input" ]] || fail "Missing export source: $input"
  [[ -f "$REPO_ROOT/$output" ]] || fail "Missing exported PNG: $output"
  [[ -s "$REPO_ROOT/$output" ]] || fail "Exported PNG is empty: $output"

  actual_width="$(sips -g pixelWidth "$REPO_ROOT/$output" 2>/dev/null | awk '/pixelWidth/ { print $2 }')"
  actual_height="$(sips -g pixelHeight "$REPO_ROOT/$output" 2>/dev/null | awk '/pixelHeight/ { print $2 }')"

  [[ "$actual_width" == "$width" ]] || fail "$output width mismatch: expected $width, got $actual_width"
  [[ "$actual_height" == "$height" ]] || fail "$output height mismatch: expected $height, got $actual_height"
done < <(awk 'NR > 1 { print }' "$MANIFEST")

while IFS=$'\t' read -r size_label width height fit_mode exported_pngs reviewed_on reviewer decision evidence next_action; do
  [[ "$exported_pngs" == "$EXPECTED_SCREENSHOT_COUNT" ]] || fail "$size_label visual review must cover $EXPECTED_SCREENSHOT_COUNT PNGs."
  [[ "$decision" == "release-approved" ]] || fail "$size_label visual review is not release-approved: $decision"
  [[ "$evidence" == *"manifest/dimension QA passed"* ]] || fail "$size_label visual review must cite manifest/dimension QA evidence."
  [[ -n "$next_action" ]] || fail "$size_label visual review must include next action."
done < <(awk 'NR > 1 { print }' "$VISUAL_REVIEW")

cat <<EOF
App Store export manifest validation passed.

Manifest:
  ${MANIFEST#$REPO_ROOT/}

Rows:
  $row_count

Visual review rows:
  $visual_review_count

Expected:
  $EXPECTED_SCREENSHOT_COUNT screenshots x $EXPECTED_SIZE_COUNT sizes = $expected_count PNGs
EOF
