# Release Readiness Evidence

이 문서는 NightBreath / 밤숨의 release 준비 evidence를 한 장으로 묶은 요약입니다. 기준일은 2026-05-09이며, 실기기 전용 항목은 자동 완료로 처리하지 않습니다.

## Screenshot Evidence

| 범위 | 상태 | evidence | 다음 액션 |
| --- | --- | --- | --- |
| README 대표 8장 | docs-preview-only | `Docs/Screenshots/screenshot_status.tsv`는 `captured, quality review pending`, `Docs/Screenshots/screenshot_visual_review.tsv`는 `docs-preview-only`로 유지 | README 문서 preview로만 사용, `release-approved` 승격 안 함 |
| App Store 후보 8장 | simulator `release-approved` | raw/review crop contact sheet, `Docs/Screenshots/app_store_export_visual_review.tsv`, `REQUIRE_APP_STORE_RELEASE_APPROVED=1` hard gate | App Store Connect upload 화면에서 순서/crop/locale 최종 확인 |
| Health/Fitdays gallery 11장 | UI Gallery 전용 `release-approved` | Health/Fitdays crop visual QA와 `screenshot_status.tsv` evidence | README/App Store 대표 이미지로는 사용하지 않음 |
| Edge/Privacy/Support 11장 | UI Gallery 전용 `release-approved` | EdgeStates 7장, Privacy/Support 4장 visual QA와 `screenshot_status.tsv` evidence | DEBUG 화면은 계속 격리 |
| DEBUG observability | internal-only | `Docs/Screenshots/Debug/` 후보는 `internal-only, quality review pending` | release-facing 문서에 렌더링하지 않음 |
| Sleep recording | UI Gallery 전용 `release-approved` | `sleep-recording` 재캡처 crop과 `screenshot_visual_review.tsv` visual QA evidence | README/App Store 대표 이미지로는 사용하지 않음 |

## App Store Copy Evidence

| 항목 | 상태 | evidence |
| --- | --- | --- |
| ko-KR metadata | reviewed locally | `Docs/APP_STORE_PRODUCT_PAGE_COPY.md`의 subtitle, promotional text, keywords가 초안 제한 안에 있음 |
| en-US metadata | reviewed locally | secondary locale copy가 local-first privacy와 wellness 범위를 유지함 |
| Screenshot headline | aligned | App Store 후보 8장 headline이 `ScreenshotScenario`와 product page screenshot order에 연결됨 |
| App Store Connect upload preview | manual pending | Codex 환경에서 로그인된 App Store Connect upload 화면을 확인하지 않았음 |

## Automated Gates

| Gate | 목적 |
| --- | --- |
| `Tools/Docs/validate_readme_links.sh` | 루트 README와 주요 sub README 링크 검증 |
| `Tools/Screenshots/validate_screenshot_manifest.sh` | screenshot status schema, 파일 존재, 문서 참조 검증 |
| `Tools/Screenshots/validate_app_store_export_manifest.sh` | App Store Connect size export manifest와 visual evidence 검증 |
| `REQUIRE_APP_STORE_RELEASE_APPROVED=1 Tools/Screenshots/validate_app_store_release_approval.sh` | App Store 후보 8장 전체 세트 승인 evidence 검증 |
| `Tools/UI/validate_navigation_chrome.sh` | tab/back 정책과 주요 flow/screenshot scenario 진입점 smoke 검증 |
| `Tools/Release/audit_release_copy.sh` | release-facing 문서 copy, 개인정보, HealthKit read-only, screenshot gate regression 검증 |

## Manual Pending

- 실제 iPhone foreground/background/overnight QA
- 실제 HealthKit 권한 조합과 데이터 없음/일부 허용 상태 확인
- 실제 Fitdays export/share 노출 확인
- App Store Connect upload 화면에서 screenshot 순서, 잘림, locale copy 최종 preview
- TestFlight 내부 테스트와 private evidence 기록

## Decision

현재 simulator-first evidence 기준으로 App Store screenshot 후보 8장, Health/Fitdays gallery, Sleep recording gallery, Edge/Privacy/Support gallery는 각각 정해진 범위 안에서 승인 상태입니다. README 대표 8장은 프로젝트 소개용 문서 preview로 유지하며, App Store 제출 후보나 UI Gallery 승인 이미지로 승격하지 않습니다.
