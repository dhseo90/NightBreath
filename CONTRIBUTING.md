# Contributing

NightBreath / 밤숨 is a local-first wellness project for sleep sound reports and
personal daily rhythm reports. Contributions should preserve the product's
privacy, licensing, and non-diagnostic boundaries.

## Scope

Good contributions usually fit one of these areas:

- SwiftUI app UI and accessibility improvements
- Sleep sound report, Daily Rhythm, and dashboard logic
- HealthKit read-only display flows
- Fitdays local file/import parsing with synthetic fixtures
- Local-only detector, screenshot, QA, and release tooling
- Documentation that clarifies privacy, licensing, or release readiness

Do not add:

- server upload, cloud processing, account login, ads, or external analytics
- HealthKit write/delete/custom type behavior
- Fitdays server/API integration, private API usage, or UI scraping
- medical diagnosis, disease determination, or treatment recommendations
- personal health exports, real audio recordings, or private local paths

## Data and Fixtures

Use synthetic fixtures only. Do not commit personal CSV/export files, real audio,
device-specific logs, dataset downloads, model artifacts, or generated local
outputs. Public dataset content keeps its upstream license and must not be
treated as Apache-2.0 NightBreath-owned material.

## Licensing

NightBreath is mixed-license when third-party dataset content is present.
Project-owned code, tests, tools, docs, and app assets are Apache-2.0 unless a
file or notice says otherwise. ESC-50 and other third-party materials keep their
upstream licenses. See `LICENSE`, `NOTICE.md`, `THIRD_PARTY_NOTICES.md`, and
`Docs/LICENSING.md`.

## Pull Request Checklist

Before proposing a change:

- Run focused tests for the changed area when possible.
- Run `Tools/Release/audit_release_copy.sh` for release-facing copy, privacy, or
  public repository changes.
- Keep README and sub-README links valid.
- Keep screenshots based on mock/synthetic data.
- Update `Docs/DEPENDENCIES.md` when dependencies, action versions, dataset
  handling, or model artifact policy changes.

## UI and Copy

UI text should be Korean-first in the app and should describe findings as
wellness/reference information. Prefer phrases like "의심 소리", "참고용 보기",
"read-only", and "온디바이스". Avoid wording that sounds like diagnosis,
treatment guidance, certified integration, or automatic cloud sync.
