#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

fail() {
  echo "error: $*" >&2
  exit 1
}

require_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "Missing required file: $path"
}

require_text() {
  local path="$1"
  local needle="$2"
  grep -Fq -- "$needle" "$path" || fail "$path is missing required text: $needle"
}

require_file "Docs/DEPENDENCIES.md"
require_file "Docs/LICENSING.md"
require_file "THIRD_PARTY_NOTICES.md"
require_file "Tools/Training/requirements.txt"
require_file ".github/workflows/release-guardrails.yml"
require_file "Package.swift"

if grep -Fq "package(url:" Package.swift; then
  fail "Package.swift declares an external Swift package but Docs/DEPENDENCIES.md says none"
fi

if grep -Fq "XCRemoteSwiftPackageReference" SleepSoundApp.xcodeproj/project.pbxproj; then
  fail "Xcode project declares a remote Swift package but Docs/DEPENDENCIES.md says none"
fi

require_text "Docs/DEPENDENCIES.md" "| External Swift package | none |"
require_text "Docs/DEPENDENCIES.md" "| CocoaPods / Carthage | 사용하지 않음 |"
require_text "Docs/DEPENDENCIES.md" "| Vendored third-party source | 없음 |"
require_text "Docs/DEPENDENCIES.md" "| Public dataset | ESC-50을 포함 배포하는 경우 upstream CC license 유지 |"
require_text "Docs/DEPENDENCIES.md" "\`actions/checkout\` | \`v6\`"
require_text ".github/workflows/release-guardrails.yml" "actions/checkout@v6"

while IFS= read -r requirement; do
  [[ -n "$requirement" ]] || continue
  package="${requirement%%>=*}"
  version="${requirement#*>=}"
  [[ "$package" != "$requirement" ]] || fail "Unsupported requirement format: $requirement"
  require_text "Docs/DEPENDENCIES.md" "\`$package\` | \`>=$version\`"
  require_text "THIRD_PARTY_NOTICES.md" "\`$package\` | \`>=$version\`"
done < "Tools/Training/requirements.txt"

for path in LICENSE Docs/LICENSING.md THIRD_PARTY_NOTICES.md Docs/DEPENDENCIES.md; do
  require_text "$path" "ESC-50"
  require_text "$path" "Apache-2.0"
done

require_text "LICENSE" "CC-BY-NC-3.0"
require_text "Docs/LICENSING.md" "CC BY-NC 3.0"
require_text "THIRD_PARTY_NOTICES.md" "Creative Commons Attribution-NonCommercial 3.0"

cat <<'EOF'
Dependency inventory validation passed.

Checked:
  Swift package dependency absence
  Python training requirements in dependency docs and notices
  GitHub Actions checkout version
  ESC-50 and mixed-license boundary docs
EOF
