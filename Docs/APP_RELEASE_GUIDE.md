# App Release Guide

이 문서는 NightBreath / 밤숨의 App Store copy, screenshot, app icon, TestFlight 준비 기준을 한곳에 묶은 release 문서입니다.

## Release 원칙

- 앱 표시 이름은 `밤숨`입니다.
- 영어 프로젝트/브랜드 이름은 `NightBreath`입니다.
- 앱은 수면 중 소리 기반 지표와 하루 건강 리듬을 개인 참고용으로 정리합니다.
- 이 앱은 진단 목적의 의료기기가 아닙니다.
- HealthKit은 사용자가 건강 데이터 연결을 선택한 경우에만 read-only로 사용합니다.
- 앱은 HealthKit에 데이터를 쓰지 않습니다.
- 서버 업로드, 클라우드 처리, 외부 분석 SDK, 광고 SDK는 사용하지 않습니다.
- 기본 동작으로 원본 전체 오디오는 저장하지 않습니다.
- Fitdays 서버/API 직접 연결이나 비공식 연결 방식은 사용하지 않습니다.

## App Store Product Page Copy

Product page의 primary/secondary locale 후보 문구는 `Docs/APP_STORE_PRODUCT_PAGE_COPY.md`를 기준으로 합니다. 아래 문구는 release guide 안에서 빠르게 확인하기 위한 요약입니다.

짧은 소개:

```text
밤숨은 iPhone 안에서 수면 중 소리 기반 지표를 정리하고, 아침에 읽기 쉬운 개인 참고용 리포트를 보여주는 앱입니다.
```

확장 소개:

```text
밤숨은 수면 소리 리포트에서 시작해 오늘의 리듬 점수, 아침 리포트, 하루 리듬 카드, 건강 데이터 대시보드로 확장되는 온디바이스 개인 건강 리듬 리포트 앱입니다.
```

주요 기능:

- 수면 시작/종료 흐름
- 수면 소리 점수
- 수면 이벤트 타임라인
- 아침 컨디션 체크인
- 오늘의 리듬 점수
- Daily Rhythm Report
- HealthKit read-only 건강 데이터 대시보드
- Fitdays CSV/import 기반 로컬 전용 확장 지표
- 월 건강 캘린더와 Metric Detail
- 개인정보/저장소 설정

안전 문구:

- 개인 패턴을 살펴보기 위한 참고용 보기입니다.
- 수면 소리 지표와 건강 데이터를 함께 정리하되 인과관계를 의미하지 않습니다.
- 서버 전송 없이 iPhone 안에서 처리하는 방향을 우선합니다.
- 전체 밤 원본 오디오는 기본 저장하지 않습니다.

피해야 할 copy:

- 특정 건강 상태를 확정하는 문구
- 임상 지표처럼 정확도를 보장하는 문구
- 치료나 의학적 조치를 직접 권하는 문구
- 수면 소리와 혈압/체중/체성분 변화 사이의 원인과 결과를 단정하는 문구

제출 직전 확인:

- `Docs/APP_STORE_PRODUCT_PAGE_COPY.md`의 ko-KR subtitle, promotional text, keywords 글자 수를 App Store Connect 화면에서 다시 확인합니다.
- en-US secondary locale을 사용할 경우 한국어 copy와 개인정보/HealthKit/read-only 경계가 어긋나지 않는지 확인합니다.
- screenshot headline과 product description이 서로 다른 기능 범위를 주장하지 않는지 확인합니다.

## App Store Screenshot Guide

Screenshot은 mock data와 simulator scenario 기반으로만 생성합니다.

현재 저장된 README 대표 screenshot은 문서 preview로만 사용하며 release-approved 상태가 아닙니다. App Store screenshot 후보는 2026-05-09에 raw 8개 재캡처와 size별 export 생성을 확인했지만, marketing copy/crop visual QA가 남아 있어 App Store Connect 제출 후보로 승인하지 않습니다.

금지:

- 실제 개인 건강 데이터
- 실제 HealthKit 데이터
- 실제 Fitdays CSV 파일명
- 실제 오디오 파일명
- 실제 local path
- 실제 이름, 생년월일, 위치
- 타사 앱 screenshot, 타사 로고, 타사 앱 아이콘

대표 screenshot 후보:

- 홈 대시보드
- 수면 시작
- 수면 리포트
- 이벤트 타임라인
- 아침 리포트
- 오늘의 리듬 리포트
- 하루 리듬 카드
- 건강 데이터 대시보드
- 건강 지표 overview
- 월 건강 캘린더
- Metric Detail

README에는 대표 screenshot만 사용합니다. 전체 화면별 설명과 pending 상태는 `Docs/UI_GALLERY.md`에서 관리합니다.

### Mock Scenario / Headline Plan

App Store screenshot은 아래 mock scenario와 headline copy를 우선 후보로 사용합니다. 모든 화면은 DEBUG simulator scenario 또는 mock bundle 기반으로만 만들고, 실제 개인 건강 데이터, 실제 HealthKit 데이터, 실제 Fitdays CSV 파일명, 실제 오디오 파일명은 쓰지 않습니다.

Daily Health Card screenshot은 README 대표 카드와 App Store 후보 카드를 분리합니다. README 대표 카드는 `readmeRepresentative` display profile을 사용하고, App Store 후보 카드는 `appStoreMarketing` display profile을 사용합니다. App Store 후보 카드는 `privacyMinimal`/`minimal` 표시 수준을 기본으로 하며 실제 HealthKit/Fitdays source나 혈압, 체중, 체성분 같은 민감 수치를 노출하지 않습니다.

| 우선순위 | Scenario | Headline copy | 화면 / 파일 후보 | 현재 상태 | 안전 기준 |
| --- | --- | --- | --- | --- | --- |
| 1 | `ScreenshotHomeScenario` | 수면 중 소리 기반 지표를 한눈에 | `Docs/Screenshots/AppStore/raw/01_home_dashboard_light.png` | blocked, recapture required | 온디바이스, 서버 전송 없음, 최근 리포트가 보이게 구성 |
| 2 | `ScreenshotSleepReportScenario` | 아침에 읽기 쉬운 수면 소리 리포트 | `Docs/Screenshots/AppStore/raw/02_sleep_report_light.png` | blocked, recapture required | 점수와 이벤트는 개인 참고용으로 표현 |
| 3 | `ScreenshotTimelineScenario` | 코골기와 환경 소음 흐름 확인 | `Docs/Screenshots/AppStore/raw/03_sleep_timeline_light.png` | blocked, recapture required | 이벤트 샘플은 opt-in 짧은 구간만 가능하다는 맥락 유지 |
| 4 | `ScreenshotDailyRhythmScenario` | 오늘의 리듬 점수를 참고용으로 | `Docs/Screenshots/AppStore/raw/04_daily_rhythm_report_light.png` | blocked, recapture required | 건강 상태나 원인과 결과를 단정하지 않음 |
| 5 | `ScreenshotDailyHealthCardScenario` | 하루 리듬을 카드 한 장으로 | `Docs/Screenshots/AppStore/raw/05_daily_health_card_light.png` | blocked, recapture required | README는 `readmeRepresentative`, App Store 후보는 `appStoreMarketing` display profile 사용 |
| 6 | `ScreenshotHealthMetricsOverviewScenario` | 모든 건강 지표를 출처와 함께 | `Docs/Screenshots/AppStore/raw/06_health_metrics_overview_light.png` | blocked, recapture required | HealthKit read-only와 Fitdays local-only 출처 구분 |
| 후보 | `ScreenshotPrivacyScenario` | 전체 밤 오디오는 저장하지 않습니다 | `Docs/Screenshots/AppStore/raw/07_privacy_settings_light.png` | blocked, recapture required | 개인정보/저장소 원칙을 직접 보여주는 보조 컷 |
| 후보 | `ScreenshotZeroEventScenario` | 이벤트가 적은 밤도 측정 맥락과 함께 | `Docs/Screenshots/AppStore/raw/08_zero_event_report_light.png` | blocked, recapture required | 이벤트 없음은 건강 상태 해석으로 표현하지 않음 |

최근 visual QA 기록은 `Docs/Screenshots/VISUAL_QA_2026-05-09.md`를 확인합니다.

App Store marketing capture source:

- raw source: `Docs/Screenshots/AppStore/raw/`
- review crop: `Docs/Screenshots/AppStore/review-cropped/`
- capture script: `Tools/Screenshots/capture_app_store_screenshots.sh`
- review sheet script: `Tools/Screenshots/build_screenshot_review_sheet.sh`
- App Store Connect size export script: `Tools/Screenshots/export_app_store_connect_screenshots.sh`

Raw source는 App Store Connect size export 입력으로 사용하고, review crop은 내부 검토용으로만 사용합니다. 모든 파일은 DEBUG simulator scenario와 synthetic/mock data 기반이어야 합니다.

재캡처 전 gate:

- 내부 `Simulator QA` label, `synthetic` 파일명, local path, 실제 개인 데이터가 보이면 실패입니다.
- fixed crop 결과만으로 승인하지 않고, raw/review crop/export PNG를 contact sheet로 확인합니다.
- `Docs/Screenshots/review/screenshot_review_sheet.html`에서 raw source와 review crop을 나란히 확인합니다.
- DEBUG-only 화면은 App Store screenshot 후보에서 제외합니다.

Size export 기준:

- Apple Developer의 App Store Connect `Screenshot specifications`에서 iPhone portrait size를 확인합니다: https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/
- `Docs/Screenshots/AppStore/export/`는 raw source에서 재생성 가능한 산출물이므로 커밋하지 않습니다.
- `manifest.tsv`로 source file, target size, fit mode를 확인합니다.
- 기본 `contain` export는 화면 잘림을 피하기 위한 검토용 fallback입니다. 제출 전에는 각 PNG를 눈으로 확인하고, 가능하면 대상 simulator에서 직접 capture한 raw screenshot을 우선합니다.

Headline copy 원칙:

- 제품명을 가리는 과장 headline보다 화면의 실제 가치와 제한을 짧게 설명합니다.
- “진단”, “정확 측정”, “질병 여부 단정”, “치료”처럼 의료적 판단으로 읽힐 수 있는 표현을 쓰지 않습니다.
- 혈압, 체중, 체성분, 수면 소리 지표가 함께 보여도 인과관계를 주장하지 않습니다.
- privacy screenshot은 마케팅 컷으로 쓰더라도 서버 미전송, 전체 밤 원본 오디오 미저장, opt-in 샘플 정책이 보이게 구성합니다.

README용 crop 원칙:

- status bar, 시간, Dynamic Island 영역은 README 대표 이미지에서 제거합니다.
- title이나 주요 카드가 잘리지 않아야 합니다.
- HTML `img` width는 240-280px 범위로 제한합니다.
- 원본 screenshot은 보존하고 cropped 이미지를 README에 사용합니다.

Capture workflow는 `Tools/Screenshots/README.md`와 `Tools/Screenshots/` scripts를 기준으로 합니다.

## App Icon Guide

현재 앱 아이콘:

- `SleepSoundApp/App/Assets.xcassets/AppIcon.appiconset`에 NightBreath 전용 PNG artwork가 들어 있습니다.
- `Tools/AppIcon/generate_app_icon.swift`로 1024px 원본과 iOS/iPad 슬롯별 PNG를 재생성할 수 있습니다.
- `Tools/AppIcon/validate_app_icon.swift`로 App Store/iPhone/iPad 슬롯, PNG dimension, opaque source 조건을 검증할 수 있습니다.
- `Tools/AppIcon/render_app_icon_review_sheet.swift`로 작은 크기 리뷰 시트 `Docs/AppIcon/app_icon_review_sheet.png`를 재생성할 수 있습니다.
- Xcode target은 `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`으로 이 asset을 사용합니다.

아이콘 방향:

- NightBreath / 밤숨 브랜드를 바로 떠올릴 수 있어야 합니다.
- 수면, 밤, 조용한 호흡, 온디바이스 privacy 느낌을 단순하게 표현합니다.
- 의료기기처럼 보이는 십자, 병원, 심전도 중심 이미지는 피합니다.
- 타사 asset이나 로고를 사용하지 않습니다.
- App Store small size에서도 식별 가능해야 합니다.

검토 기준:

- light/dark 배경에서 식별 가능한가
- iOS 홈 화면에서 너무 복잡하지 않은가
- 앱의 “수면 소리 리포트 + 하루 건강 리듬” 방향과 어울리는가
- 과도하게 의료/진단 앱처럼 보이지 않는가
- App Store 1024px source가 alpha channel 없이 opaque PNG인가
- iPhone `60@3x`, `60@2x`, Settings/Search 작은 크기에서도 호흡 파형과 달 형태가 구분되는가

로컬 검증:

```sh
xcrun swift Tools/AppIcon/generate_app_icon.swift
xcrun swift Tools/AppIcon/validate_app_icon.swift
xcrun swift Tools/AppIcon/render_app_icon_review_sheet.swift
```

생성된 `Docs/AppIcon/app_icon_review_sheet.png`는 App Store, Home Screen, Settings, Search, smallest size를 한 번에 보는 내부 리뷰용입니다. App Store 제출 전에는 실제 기기 홈 화면, Settings 앱 목록, TestFlight install 화면에서 작은 크기 식별성을 다시 확인합니다.

## TestFlight Checklist

상세 내부 테스트 기준은 `Docs/TESTFLIGHT_INTERNAL_TEST_PLAN.md`를 따릅니다.

TestFlight 전 확인:

- `swift test --no-parallel` 통과
- iOS Debug/Release build 확인
- 실제 iPhone smoke test
- 화면 잠금/백그라운드 녹음 확인
- HealthKit read-only 권한 흐름 확인
- 권한 거부/일부 허용/데이터 없음 상태 확인
- Fitdays CSV import valid/invalid/unknown column 확인
- 이벤트 오디오 샘플 opt-in ON/OFF 확인
- 개인정보/저장소 설정 확인
- App Store copy와 screenshot에 민감정보가 없는지 확인
- 금지 표현 scan
- 서버/네트워크/외부 SDK scan
- HealthKit write scan
- 전체 밤 원본 오디오 저장 scan

TestFlight blocking gate:

- 수면 종료 후 실제 오디오 수신 시간이 계속 증가하면 확대 배포를 중단합니다.
- double stop tap에서 duplicate report나 crash가 있으면 중단합니다.
- 이벤트 0개 세션에서 raw/reject diagnostics가 전혀 남지 않으면 detector 판단을 보류합니다.
- HealthKit write 요청, 전체 밤 원본 오디오 저장, 서버/네트워크/외부 SDK 호출이 발견되면 중단합니다.
- 의료 진단처럼 읽히는 copy가 있으면 수정 전 배포하지 않습니다.

실제 iPhone manual QA 절차는 `Docs/QA_GUIDE.md`와 `Docs/REAL_DEVICE_QA_RUNBOOK.md`를 따릅니다.

## Automated Release Readiness Gate

실기기 QA와 별도로, release branch나 TestFlight 후보를 만들기 전에는 아래 자동 점검을 실행합니다.

```sh
Tools/Release/audit_release_copy.sh
Tools/Docs/validate_readme_links.sh
```

`Tools/Release/audit_release_copy.sh`는 `ReleaseReadiness`, `AppStoreReadiness`, `UIGalleryDocumentation`, `SimulatorQAScenario`, `PrivacyCopySafety`, `HealthKitReadOnlyPolicy` filter를 실행합니다. `Tools/Docs/validate_readme_links.sh`는 루트 README와 주요 sub README의 상대 링크/이미지 경로를 검증합니다.

이 gate는 다음 항목을 한 번에 확인합니다.

- App Store product page copy와 release 문서가 개인정보/HealthKit/read-only 경계를 유지하는지 확인합니다.
- 금지 의료 표현, 건강 상태 단정, 원인과 결과 단정 문구가 release 문서에 들어가지 않았는지 확인합니다.
- 서버 업로드, 클라우드 분석, 외부 API 전송, Fitdays 자동 동기화 같은 긍정형 약속 문구가 release-facing 문서에 들어가지 않았는지 확인합니다.
- 앱 source에 서버/네트워크 코드, 외부 분석 SDK, 광고 SDK signature가 없는지 확인합니다.
- `RealHealthKitService`가 read-only adapter로 유지되고 HealthKit write/delete/streaming query가 없는지 확인합니다.
- 오디오 파일 write가 opt-in 이벤트 샘플 저장소와 DEBUG 짧은 수동 샘플 저장소에만 남아 있는지 확인합니다.
- README preview screenshot이 release-approved/App Store 후보로 오해되지 않는지, App Store 후보가 visual QA 전에는 export나 marketing 문서에 승격되지 않는지 확인합니다.
- DEBUG simulator scenario가 mock/synthetic data만 쓰고 내부 QA label을 user-facing screenshot source에 노출하지 않는지 확인합니다.
- 루트 README가 주요 sub README를 모두 연결하고, README 내부 문서/이미지 링크가 깨지지 않는지 확인합니다.

이 자동 gate는 실제 iPhone stop/background/overnight QA를 대체하지 않습니다. 자동 gate 통과 후에도 `Docs/QA_GUIDE.md`와 `Docs/REAL_DEVICE_QA_RUNBOOK.md`의 manual evidence를 별도로 기록합니다.

## App Review Notes 후보

상세 App Review / Legal audit는 `Docs/APP_REVIEW_AUDIT.md`를 기준으로 최종 제출 직전에 다시 확인합니다.

```text
NightBreath / 밤숨 uses HealthKit only when the user explicitly chooses to connect health data from the health dashboard. The app requests read access only and does not write data to HealthKit.

The app does not upload health data or audio to a server. Sleep sound analysis and reports are handled on device.

The app does not store full-night raw audio by default. Short event audio snippets can be stored locally only when the user explicitly enables the setting.

Reports are for personal wellness reference and are not intended for medical diagnosis.
```

## 남은 release 작업

- 실제 기기 홈 화면/Settings/TestFlight 표면에서 최종 앱 아이콘 작은 크기 확인
- App Store marketing screenshot final
- App Store product page copy 제출 직전 글자 수/locale 확인
- TestFlight 내부 테스트
- Legal/App Review audit 최종 재확인
- 실제 iPhone overnight 안정성 확인
