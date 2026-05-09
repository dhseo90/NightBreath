# Release Readiness Evidence

이 문서는 NightBreath / 밤숨의 release 준비 evidence를 한 장으로 묶은 요약입니다. 기준일은 2026-05-09이며, 실기기 전용 항목은 자동 완료로 처리하지 않습니다.

## Screenshot Evidence

| 범위 | 상태 | evidence | 다음 액션 |
| --- | --- | --- | --- |
| README 대표 8장 | docs-preview-only | `Docs/Screenshots/screenshot_status.tsv`는 `captured, quality review pending`, `Docs/Screenshots/screenshot_visual_review.tsv`는 `docs-preview-only`로 유지 | README 문서 preview로만 사용, `release-approved` 승격 안 함 |
| App Store 후보 8장 | simulator `release-approved` | raw/review crop contact sheet, `Docs/Screenshots/app_store_export_visual_review.tsv`, `REQUIRE_APP_STORE_RELEASE_APPROVED=1` hard gate | App Store Connect upload 화면에서 순서/crop/locale 최종 확인 |
| Health/Fitdays gallery 11장 | UI Gallery 전용 `release-approved` | Health/Fitdays crop visual QA와 `screenshot_status.tsv` evidence | README/App Store 대표 이미지로는 사용하지 않음 |
| Direct detail gallery 4장 | UI Gallery 전용 `release-approved` | Trend, morning/evening check-in, Daily Health Card export visual QA와 `screenshot_status.tsv` evidence | README/App Store 대표 이미지로는 사용하지 않음 |
| Edge/Privacy/Support 11장 | UI Gallery 전용 `release-approved` | EdgeStates 7장, Privacy/Support 4장 visual QA와 `screenshot_status.tsv` evidence | DEBUG 화면은 계속 격리 |
| DEBUG observability | internal-only | `Docs/Screenshots/Debug/` 후보는 `internal-only, quality review pending` | release-facing 문서에 렌더링하지 않음 |
| Sleep recording | UI Gallery 전용 `release-approved` | `sleep-recording` 재캡처 crop과 `screenshot_visual_review.tsv` visual QA evidence | README/App Store 대표 이미지로는 사용하지 않음 |

## App Store Copy Evidence

| 항목 | 상태 | evidence |
| --- | --- | --- |
| ko-KR metadata | reviewed locally | `Docs/APP_STORE_PRODUCT_PAGE_COPY.md`의 subtitle, promotional text, keywords가 초안 제한 안에 있음 |
| en-US metadata | reviewed locally | secondary locale copy가 local-first privacy와 wellness 범위를 유지함 |
| Screenshot headline | aligned | App Store 후보 8장 headline이 `ScreenshotScenario`와 product page screenshot order에 연결됨 |
| App Store Connect upload preview | local substitute passed; ASC manual pending | `Docs/APP_STORE_CONNECT_LOCAL_PREVIEW_EVIDENCE.md`에서 export/order/copy 대체 QA 통과. Codex 환경에서 로그인된 App Store Connect upload 화면은 확인하지 않았음 |

## Submission Candidate Local Recheck

| 항목 | 상태 | evidence |
| --- | --- | --- |
| version/build | local recheck passed; ASC build selection pending | `Docs/APP_STORE_SUBMISSION_LOCAL_RECHECK.md`에서 `MARKETING_VERSION` 1.0, `CURRENT_PROJECT_VERSION` 1, Info.plist mapping 확인 |
| release note | local recheck passed; ASC locale entry pending | ko-KR/en-US What's New 후보를 `Docs/APP_STORE_PRODUCT_PAGE_COPY.md`와 local recheck 문서에 정리 |
| product metadata | local recheck passed; ASC field preview pending | ko-KR/en-US app name, subtitle, promotional text, keywords 후보 정합성 확인 |
| bundle/app record | manual pending | local bundle identifier는 `com.local.NightBreath`; ASC app record와 bundle identifier 선택은 실제 제출 전 필요 |

## App Store Connect Manual Preview Result Entry

아래 표는 실제 App Store Connect upload preview를 확인한 뒤 수동으로 채웁니다. 계정 이메일, 개인 이름, 실제 사용자 데이터, 실제 local path는 기록하지 않습니다. 상세 절차는 `Docs/APP_STORE_CONNECT_PREVIEW_QA.md`를 기준으로 합니다.

| 항목 | 값 |
| --- | --- |
| ASC preview QA date | not run; local substitute 2026-05-09 |
| reviewer role | Codex local substitute |
| locale checked | ko-KR / en-US docs checked; ASC not run |
| TestFlight/App Store candidate build | not selected |
| screenshot source set | `Docs/Screenshots/AppStore/export/` regenerated from raw |
| order result | local substitute pass; ASC not run |
| crop result | local substitute pass; ASC not run |
| locale copy result | local substitute pass; ASC not run |
| sensitive data result | local substitute pass; ASC not run |
| HealthKit/server/cloud wording result | local substitute pass; ASC not run |
| evidence note id | `Docs/APP_STORE_CONNECT_LOCAL_PREVIEW_EVIDENCE.md`; private note pending |
| blocker issue id | none from local substitute |
| release decision | hold until ASC manual preview |

| Slot | Expected file | ASC order | Crop/headline result | Notes |
| --- | --- | --- | --- | --- |
| 1 | `01_home_dashboard_light.png` | local substitute pass; ASC not run | local substitute pass; ASC not run | export/order evidence only |
| 2 | `02_sleep_report_light.png` | local substitute pass; ASC not run | local substitute pass; ASC not run | export/order evidence only |
| 3 | `03_sleep_timeline_light.png` | local substitute pass; ASC not run | local substitute pass; ASC not run | export/order evidence only |
| 4 | `04_daily_rhythm_report_light.png` | local substitute pass; ASC not run | local substitute pass; ASC not run | export/order evidence only |
| 5 | `05_daily_health_card_light.png` | local substitute pass; ASC not run | local substitute pass; ASC not run | export/order evidence only |
| 6 | `06_health_metrics_overview_light.png` | local substitute pass; ASC not run | local substitute pass; ASC not run | export/order evidence only |
| 7 | `07_privacy_settings_light.png` | local substitute pass; ASC not run | local substitute pass; ASC not run | export/order evidence only |
| 8 | `08_zero_event_report_light.png` | local substitute pass; ASC not run | local substitute pass; ASC not run | export/order evidence only |

## Automated Gates

| Gate | 목적 |
| --- | --- |
| `Tools/Docs/validate_readme_links.sh` | 루트 README와 주요 sub README 링크 검증 |
| `Tools/Screenshots/validate_screenshot_manifest.sh` | screenshot status schema, 파일 존재, 문서 참조 검증 |
| `Tools/Screenshots/validate_app_store_export_manifest.sh` | App Store Connect size export manifest와 visual evidence 검증 |
| `REQUIRE_APP_STORE_RELEASE_APPROVED=1 Tools/Screenshots/validate_app_store_release_approval.sh` | App Store 후보 8장 전체 세트 승인 evidence 검증 |
| `Tools/UI/validate_navigation_chrome.sh` | tab/back 정책과 주요 flow/screenshot scenario 진입점 smoke 검증 |
| `Tools/Release/audit_release_copy.sh` | release-facing 문서 copy, 개인정보, HealthKit read-only, screenshot gate regression 검증 |
| `Tools/Release/audit_tracked_artifacts.sh` | Git tracked ESC-50/audio/model/output artifact 차단 |
| `Tools/Release/audit_app_bundle_artifacts.sh` | built `.app` bundle 내 ESC-50/audio/output/training artifact 차단 |
| `Tools/Training/validate_model_provenance_gate.sh` | model artifact 추가 전 provenance manifest와 ESC-50/NonCommercial 상태 확인 |
| `Tools/Training/test_model_provenance_gate_negative.sh` | model provenance gate의 fail/pass negative case 검증 |
| `Tools/Release/audit_trademark_copy.sh` | Apple/HealthKit/Fitdays/Omron 공식/제휴/인증 오해 문구 차단 |
| `Tools/Release/audit_public_repo_privacy.sh` | public repo 전환 전 token/private path/email/device id scan |

## TestFlight Local Preflight Evidence

| 항목 | 상태 | evidence |
| --- | --- | --- |
| private evidence template | ready | `Docs/TESTFLIGHT_INTERNAL_EVIDENCE_TEMPLATE.md` |
| private draft generation | local substitute passed | `Tools/Release/prepare_testflight_evidence.sh`로 repository 밖 draft 생성 확인. 완료 evidence는 커밋하지 않음 |
| TestFlight local preflight | local substitute passed | `Docs/TESTFLIGHT_LOCAL_PREFLIGHT_EVIDENCE.md` |
| TestFlight install/run | manual pending | 실제 TestFlight 설치와 첫 실행은 실기기 필요 |

## Real Device Simulator Substitute Evidence

| 항목 | 상태 | evidence |
| --- | --- | --- |
| actual iPhone foreground/background/overnight | not run; simulator/local substitute passed | `Docs/REAL_DEVICE_SIMULATOR_SUBSTITUTE_EVIDENCE.md` |
| HealthKit permission dialog | not run; simulator/local substitute passed | `healthPermissionEmpty` simulator scenario와 `HealthKitReadOnlyPolicy` focused tests |
| Fitdays app export menu | not run; simulator/local substitute passed | `fitdaysImport` simulator scenario와 Fitdays parser/import focused tests |
| Event audio sample off/default UI | simulator substitute passed | `eventAudioStorageOff` simulator scenario와 storage policy coverage |

## Manual Pending

- 실제 iPhone foreground/background/overnight QA. Simulator/local substitute는 통과했지만 실제 기기 evidence는 미확인
- 실제 HealthKit 권한 조합과 데이터 없음/일부 허용 상태 확인. Simulator/mock state substitute는 통과했지만 실제 permission dialog는 미확인
- 실제 Fitdays export/share 노출 확인. Local import substitute는 통과했지만 실제 Fitdays app export menu는 미확인
- App Store Connect에서 실제 app record, bundle identifier, TestFlight/App Store candidate build 선택. 로컬 version/build/release note/metadata 재점검은 통과했지만 실제 ASC 선택은 미확인
- App Store Connect upload 화면에서 screenshot 순서, 잘림, locale copy 최종 preview. 로컬 대체 QA는 통과했지만 실제 ASC 화면은 미확인
- TestFlight 내부 테스트 실행과 private evidence 기록. 로컬 preflight와 repository 밖 draft 생성은 통과했지만 실제 TestFlight 설치/실행은 실기기 필요

## Decision

현재 simulator-first evidence 기준으로 App Store screenshot 후보 8장, Health/Fitdays gallery, Sleep recording gallery, direct detail gallery, Edge/Privacy/Support gallery는 각각 정해진 범위 안에서 승인 상태입니다. README 대표 8장은 프로젝트 소개용 문서 preview로 유지하며, App Store 제출 후보나 UI Gallery 승인 이미지로 승격하지 않습니다.
