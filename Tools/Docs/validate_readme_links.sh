#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

README_FILES=(
  "README.md"
  "Docs/Architecture/README.md"
  "Docs/Health/README.md"
  "Docs/Privacy/README.md"
  "Docs/Product/README.md"
  "Docs/QA/README.md"
  "Docs/Release/README.md"
  "Docs/Screenshots/README.md"
  "Docs/UI/README.md"
)

ROOT_SUB_READMES=(
  "Docs/Product/README.md"
  "Docs/UI/README.md"
  "Docs/Architecture/README.md"
  "Docs/Privacy/README.md"
  "Docs/Health/README.md"
  "Docs/QA/README.md"
  "Docs/Release/README.md"
)

failures=0

require_file() {
  local relative_path="$1"
  if [[ ! -f "$ROOT_DIR/$relative_path" ]]; then
    printf 'error: missing README file: %s\n' "$relative_path" >&2
    failures=1
  fi
}

is_external_target() {
  local target="$1"
  case "$target" in
    ""|\#*|http://*|https://*|mailto:*|tel:*|sms:*|ftp://*)
      return 0
      ;;
    *://*)
      return 0
      ;;
  esac
  return 1
}

extract_markdown_targets() {
  local file_path="$1"
  perl -ne 'while (/!?\[[^\]\n]*\]\(([^)\n]+)\)/g) { print "$1\n" }' "$file_path"
}

normalize_target() {
  local target="$1"
  target="${target%$'\r'}"

  if [[ "$target" == \<*\> ]]; then
    target="${target#<}"
    target="${target%%>*}"
  else
    target="${target%%[[:space:]]*}"
  fi

  target="${target%%#*}"
  printf '%s\n' "$target"
}

for readme in "${README_FILES[@]}"; do
  require_file "$readme"
done

for sub_readme in "${ROOT_SUB_READMES[@]}"; do
  if ! grep -Fq "($sub_readme)" "$ROOT_DIR/README.md"; then
    printf 'error: root README does not link required sub README: %s\n' "$sub_readme" >&2
    failures=1
  fi
done

for readme in "${README_FILES[@]}"; do
  readme_path="$ROOT_DIR/$readme"
  [[ -f "$readme_path" ]] || continue

  readme_dir="$(dirname "$readme")"
  while IFS= read -r raw_target; do
    if is_external_target "$raw_target"; then
      continue
    fi

    target="$(normalize_target "$raw_target")"
    if is_external_target "$target"; then
      continue
    fi

    if [[ -z "$target" ]]; then
      continue
    fi

    if [[ "$target" = /* ]]; then
      resolved_path="$ROOT_DIR${target}"
    elif [[ "$readme_dir" == "." ]]; then
      resolved_path="$ROOT_DIR/$target"
    else
      resolved_path="$ROOT_DIR/$readme_dir/$target"
    fi

    if [[ ! -e "$resolved_path" ]]; then
      printf 'error: %s links missing target: %s\n' "$readme" "$raw_target" >&2
      failures=1
    fi
  done < <(extract_markdown_targets "$readme_path")
done

if (( failures != 0 )); then
  exit 1
fi

printf 'README link validation passed for %d files.\n' "${#README_FILES[@]}"
