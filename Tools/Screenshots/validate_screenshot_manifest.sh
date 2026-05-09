#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MANIFEST="$REPO_ROOT/Docs/Screenshots/screenshot_status.tsv"
DOCS_TO_CHECK=(
  "$REPO_ROOT/Docs/UI_GALLERY.md"
  "$REPO_ROOT/Docs/UI_SCREEN_MAP.md"
)
EXPECTED_HEADER=$'id\tgroup\tview_or_surface\tscenario\traw_source\treview_asset\tstatus\trelease_surface\tnotes'
ALLOWED_STATUSES="screenshot pending|captured, quality review pending|internal-only, quality review pending|blocked, recapture required|release-approved"

fail() {
  echo "error: $*" >&2
  exit 1
}

for tool in awk grep sort mktemp; do
  command -v "$tool" >/dev/null 2>&1 || fail "$tool is required."
done

[[ -f "$MANIFEST" ]] || fail "Missing Docs/Screenshots/screenshot_status.tsv"

manifest_paths_file="$(mktemp)"
doc_paths_file="$(mktemp)"
trap 'rm -f "$manifest_paths_file" "$doc_paths_file"' EXIT

awk -F '\t' \
  -v expected_header="$EXPECTED_HEADER" \
  -v allowed_statuses="$ALLOWED_STATUSES" '
BEGIN {
  split(allowed_statuses, allowed, "|")
  for (allowed_index in allowed) {
    allowed_status[allowed[allowed_index]] = 1
  }
}
NR == 1 {
  if ($0 != expected_header) {
    printf("error: unexpected screenshot_status.tsv header.\nexpected: %s\nactual:   %s\n", expected_header, $0) > "/dev/stderr"
    exit 1
  }
  next
}
NF != 9 {
  printf("error: line %d has %d columns; expected 9.\n", NR, NF) > "/dev/stderr"
  exit 1
}
{
  id = $1
  group = $2
  raw_source = $5
  review_asset = $6
  status = $7
  release_surface = $8
  row_count += 1
  status_count[status] += 1

  if (!(status in allowed_status)) {
    printf("error: line %d has unsupported status: %s\n", NR, status) > "/dev/stderr"
    exit 1
  }
  if (status == "screenshot pending" && review_asset != "") {
    printf("error: pending row %s should not point at a review asset before capture.\n", id) > "/dev/stderr"
    exit 1
  }
  if (status != "screenshot pending" && (raw_source == "" || review_asset == "")) {
    printf("error: non-pending row %s must include raw_source and review_asset.\n", id) > "/dev/stderr"
    exit 1
  }
  if (status == "release-approved" && (group == "Debug" || release_surface == "DEBUG only")) {
    printf("error: DEBUG-only row %s cannot be release-approved.\n", id) > "/dev/stderr"
    exit 1
  }
}
END {
  if (NR == 0 || row_count < 30) {
    printf("error: screenshot_status.tsv should track at least 30 screenshot candidates.\n") > "/dev/stderr"
    exit 1
  }

  print "Screenshot manifest schema/status check passed."
  print "Rows: " row_count
  for (status in status_count) {
    print "  " status ": " status_count[status]
  }
}
' "$MANIFEST"

awk -F '\t' 'NR > 1 && $7 != "screenshot pending" { print $5; print $6 }' "$MANIFEST" | while IFS= read -r path; do
  [[ -n "$path" ]] || continue
  [[ -f "$REPO_ROOT/$path" ]] || fail "Manifest references missing file: $path"
done

awk -F '\t' 'NR > 1 { if ($5 != "") print $5; if ($6 != "") print $6 }' "$MANIFEST" | sort -u > "$manifest_paths_file"

grep -Eoh 'Docs/Screenshots/[^`|)\] ]+\.png' "${DOCS_TO_CHECK[@]}" | sort -u > "$doc_paths_file" || true

while IFS= read -r path; do
  [[ -n "$path" ]] || continue
  grep -Fxq "$path" "$manifest_paths_file" || fail "$path is referenced in UI docs but missing from screenshot_status.tsv"
done < "$doc_paths_file"

cat <<EOF
Screenshot manifest validation passed.

Checked:
  Docs/Screenshots/screenshot_status.tsv
  Docs/UI_GALLERY.md
  Docs/UI_SCREEN_MAP.md

Reminder:
  README representative screenshots may render as documentation preview while quality review is pending.
  App Store/export/marketing screenshots still require release-approved, non-DEBUG assets.
EOF
