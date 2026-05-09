# App Store Connect Local Preview Evidence

이 문서는 실제 App Store Connect upload 화면에 로그인하지 않고 진행한 로컬/시뮬레이터 대체 QA 결과입니다. 실제 ASC upload preview 확인을 완료한 것으로 보지 않으며, 실제 화면 확인 결과는 `Docs/Release/RELEASE_READINESS_EVIDENCE.md`의 `App Store Connect Manual Preview Result Entry`에 별도로 입력합니다.

## Run Summary

| 항목 | 값 |
| --- | --- |
| run date | 2026-05-09 |
| reviewer | Codex local substitute |
| ASC authenticated screen | not run |
| substitute scope | export manifest, size별 PNG dimensions, App Store release hard gate, product page copy/order |
| screenshot source set | `Docs/Screenshots/AppStore/export/` regenerated from raw |
| result | local substitute pass; ASC manual preview pending |

## Commands

```sh
Tools/Screenshots/validate_app_store_export_manifest.sh
REQUIRE_APP_STORE_RELEASE_APPROVED=1 Tools/Screenshots/validate_app_store_release_approval.sh
Tools/Docs/validate_readme_links.sh
git diff --check
```

## Local Result Matrix

| Check | Local result | Evidence |
| --- | --- | --- |
| export manifest/dimensions | pass | `Docs/Screenshots/AppStore/export/manifest.tsv`, 88 rows |
| size visual evidence | pass | `Docs/Screenshots/app_store_export_visual_review.tsv`, 11 release-approved size rows |
| App Store screenshot set | pass | 8 App Store rows are `release-approved` in `Docs/Screenshots/screenshot_status.tsv` |
| screenshot order | pass | `Docs/APP_STORE_PRODUCT_PAGE_COPY.md` and `Docs/APP_STORE_CONNECT_PREVIEW_QA.md` use the same 8-slot order |
| copy/crop/privacy/export hard gate | pass | `REQUIRE_APP_STORE_RELEASE_APPROVED=1 Tools/Screenshots/validate_app_store_release_approval.sh` |
| ASC upload preview | not run | Requires authenticated App Store Connect screen |

## Slot Evidence

| Slot | Expected file | Local order result | Local export/crop result | ASC status |
| --- | --- | --- | --- | --- |
| 1 | `01_home_dashboard_light.png` | pass | pass | not run |
| 2 | `02_sleep_report_light.png` | pass | pass | not run |
| 3 | `03_sleep_timeline_light.png` | pass | pass | not run |
| 4 | `04_daily_rhythm_report_light.png` | pass | pass | not run |
| 5 | `05_daily_health_card_light.png` | pass | pass | not run |
| 6 | `06_health_metrics_overview_light.png` | pass | pass | not run |
| 7 | `07_privacy_settings_light.png` | pass | pass | not run |
| 8 | `08_zero_event_report_light.png` | pass | pass | not run |

## Remaining Manual Gate

- App Store Connect upload 화면에서 실제 preview 순서, 잘림, locale copy를 확인해야 합니다.
- 실제 ASC 화면 확인 전에는 release decision을 `continue`로 바꾸지 않습니다.
- Release evidence decision remains `hold until ASC manual preview`.
- 계정 이메일, 개인 이름, 실제 사용자 데이터, 실제 local path는 release-facing 문서에 기록하지 않습니다.
