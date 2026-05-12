# NightBreath / 밤숨

밤숨(NightBreath)은 iPhone 안에서 수면 중 소리 기반 리포트를 만들고, 향후 수면·혈압·체중·체성분·활동·컨디션을 함께 살펴보는 온디바이스 개인 건강 리듬 리포트 앱입니다.

앱의 첫 축은 `수면 소리 리포트`입니다. 사용자가 자기 전 수면 측정을 시작하면 앱은 마이크 입력을 iPhone 내부에서 처리하고, 아침에는 `수면 소리 점수`, 주요 소리 이벤트, 측정 품질, 이벤트 타임라인을 보여줍니다. 확장 방향은 이 아침 리포트를 하루 리듬의 시작점으로 삼아 `오늘의 리듬 점수`, `아침 리포트`, `하루 리듬 카드`, 건강 데이터 대시보드로 넓히는 것입니다.

밤숨은 질병을 진단하거나 치료 판단을 제공하지 않습니다. 모든 리포트와 점수는 개인 패턴을 살펴보기 위한 웰니스 참고용 보기입니다.

## 제품 요약

| 항목 | 내용 |
| --- | --- |
| 한국어 앱 이름 | 밤숨 |
| 영어 프로젝트 / 브랜드 | NightBreath |
| 한국어 부제 | 수면 소리 리포트 |
| 영어 부제 | Sleep Sound Report |
| 제품 방향 | 온디바이스 개인 건강 리듬 리포트 |
| 핵심 원칙 | 서버 전송 없음, HealthKit read-only, 전체 밤 원본 오디오 기본 미저장, 진단 목적 아님 |

## 주요 UI

아래 이미지는 mock/simulator data 기반 대표 화면입니다. App Store 제출용 최종 이미지는 별도 screenshot approval flow에서 관리합니다.

| 홈 대시보드 | 수면 시작 |
| --- | --- |
| ![홈 대시보드](Docs/Screenshots/README/cropped/home_dashboard_light.png) | ![수면 시작](Docs/Screenshots/README/cropped/sleep_start_light.png) |

| 수면 리포트 | 이벤트 타임라인 |
| --- | --- |
| ![수면 리포트](Docs/Screenshots/README/cropped/sleep_report_light.png) | ![이벤트 타임라인](Docs/Screenshots/README/cropped/sleep_timeline_light.png) |

| 아침 리포트 | 오늘의 리듬 리포트 |
| --- | --- |
| ![아침 리포트](Docs/Screenshots/README/cropped/morning_brief_light.png) | ![오늘의 리듬 리포트](Docs/Screenshots/README/cropped/daily_rhythm_report_light.png) |

| 하루 리듬 카드 | 건강 데이터 대시보드 |
| --- | --- |
| ![하루 리듬 카드](Docs/Screenshots/README/cropped/daily_health_card_light.png) | ![건강 데이터 대시보드](Docs/Screenshots/README/cropped/health_dashboard_light.png) |

## 주요 기능

- SwiftUI 기반 iOS 앱 구조
- 수면 시작/종료 흐름과 로컬 수면 세션 모델
- 온디바이스 오디오 캡처 skeleton과 rule-based 분석 placeholder
- 수면 이벤트 타임라인, 수면 소리 점수, 아침 컨디션 체크인
- 이벤트 오디오 샘플 opt-in 저장, 재생, 삭제, 저장 용량 표시
- HealthKit read-only adapter와 mock/protocol 기반 건강 데이터 대시보드
- Fitdays CSV/export 또는 월별 데이터 붙여넣기 기반 local-only import flow
- HealthKit 표준 지표와 Fitdays 로컬 전용 지표를 함께 다루는 Extended Health Metrics catalog
- 오늘의 리듬 점수, 아침 리포트, 저녁 체크인, 하루 리듬 카드
- Simulator QA scenarios, Dataset Replay, Offline Evaluation, screenshot workflow

## 라이선스

이 repository는 mixed-license입니다. NightBreath 소스 코드, 테스트, 로컬 개발 도구, 프로젝트 소유 문서와 앱 asset은 별도 표기가 없으면 Apache License 2.0을 따릅니다.

단, `Datasets/ESC-50-master/**` 같은 third-party dataset content가 포함되는 경우 해당 파일은 upstream 라이선스를 유지하며 Apache-2.0으로 재라이선스하지 않습니다. ESC-50 전체 dataset은 CC BY-NC 3.0, ESC-10 subset은 CC BY 3.0으로 다룹니다.

GitHub의 자동 license badge가 mixed/custom license를 단순하게 표시하지 못할 수 있습니다. 이 repository의 기준 license source는 루트 `LICENSE`와 `Docs/LICENSING.md`입니다.

자세한 범위는 [LICENSE](LICENSE), [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md), [Docs/LICENSING](Docs/LICENSING.md)을 확인하세요.

## 문서 지도

세부 설명은 아래 sub README에서 시작합니다.

| 문서 | 내용 | 대표 세부 문서 |
| --- | --- | --- |
| [Product](Docs/Product/README.md) | 제품 방향, V1 범위, 표현 원칙, 하지 않는 것 | [PRODUCT_DIRECTION](Docs/PRODUCT_DIRECTION.md), [CURRENT_STATUS](Docs/CURRENT_STATUS.md), [V1_1_ROADMAP](Docs/V1_1_ROADMAP.md) |
| [UI](Docs/UI/README.md) | 주요 화면, UI gallery, 디자인 시스템, screenshot 관리 | [UI_GALLERY](Docs/UI_GALLERY.md), [UI_SCREEN_MAP](Docs/UI_SCREEN_MAP.md), [DESIGN_SYSTEM](Docs/DESIGN_SYSTEM.md) |
| [Architecture](Docs/Architecture/README.md) | 앱 구조, 주요 모델, 분석 pipeline, storage 경계 | [CORE_ML_MODEL_INTEGRATION](Docs/CORE_ML_MODEL_INTEGRATION.md), [RULE_BASED_VS_ML_COMPARISON](Docs/RULE_BASED_VS_ML_COMPARISON.md) |
| [Privacy](Docs/Privacy/README.md) | 로컬 저장, 이벤트 오디오 샘플, HealthKit read-only, 금지 경로 | [PRIVACY_STORAGE_AUDIT](Docs/PRIVACY_STORAGE_AUDIT.md), [APP_REVIEW_AUDIT](Docs/APP_REVIEW_AUDIT.md) |
| [Health](Docs/Health/README.md) | Daily Rhythm, HealthKit, Fitdays import, Extended Health Metrics | [HEALTH_DATA_GUIDE](Docs/HEALTH_DATA_GUIDE.md), [DAILY_RHYTHM_SCORE](Docs/DAILY_RHYTHM_SCORE.md), [DAILY_HEALTH_CARD](Docs/DAILY_HEALTH_CARD.md) |
| [QA](Docs/QA/README.md) | Simulator-first 개발, 테스트, Dataset Replay, 실기기 QA | [QA_GUIDE](Docs/QA_GUIDE.md), [SIMULATOR_QA_AUTOMATION](Docs/SIMULATOR_QA_AUTOMATION.md), [REAL_DEVICE_QA_RUNBOOK](Docs/REAL_DEVICE_QA_RUNBOOK.md) |
| [Release](Docs/Release/README.md) | App Store 준비, product page copy, release gates, screenshot approval | [APP_RELEASE_GUIDE](Docs/APP_RELEASE_GUIDE.md), [APP_STORE_PRODUCT_PAGE_COPY](Docs/APP_STORE_PRODUCT_PAGE_COPY.md) |
| [Licensing](Docs/LICENSING.md) | Apache-2.0 코드 범위, ESC-50/ESC-10 upstream license 경계, third-party notice | [LICENSE](LICENSE), [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md), [DEPENDENCIES](Docs/DEPENDENCIES.md) |

## 빠른 시작

Xcode에서 열기:

```bash
open SleepSoundApp.xcodeproj
```

SwiftPM 테스트:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
swift test --no-parallel
```

iOS generic Debug build:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild \
  -project SleepSoundApp.xcodeproj \
  -scheme SleepSoundApp \
  -configuration Debug \
  -destination generic/platform=iOS \
  -derivedDataPath .derivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## 안전 원칙

- 서버 업로드, 클라우드 처리, 외부 API 호출, 외부 분석 SDK, 광고 SDK를 추가하지 않습니다.
- 계정/로그인 시스템을 만들지 않습니다.
- 전체 밤 원본 오디오를 기본 저장하지 않습니다.
- 이벤트 오디오 샘플은 사용자가 켠 경우에만 짧은 로컬 샘플로 저장합니다.
- 잠꼬대/말소리를 텍스트로 변환하지 않습니다.
- HealthKit은 read-only로만 사용하고, 앱 점수나 이벤트를 HealthKit에 쓰지 않습니다.
- Fitdays 서버/API 직접 연결, 비공식 연결 방식, reverse engineering을 하지 않습니다.
- 건강 데이터와 수면 소리 이벤트 사이의 확정적 인과관계를 주장하지 않습니다.
