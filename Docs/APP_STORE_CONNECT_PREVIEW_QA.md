# App Store Connect Preview QA

이 문서는 NightBreath / 밤숨 App Store screenshot과 product page copy를 App Store Connect 업로드 화면에서 최종 확인하기 위한 수동 QA runbook입니다. Codex 로컬 실행만으로는 App Store Connect 로그인/업로드 화면을 확인하지 않습니다.

## Scope

- ko-KR primary locale screenshot 순서와 crop preview
- en-US secondary locale copy와 screenshot headline 정합성
- iPhone size별 upload preview에서 하단/상단 잘림 여부
- 실제 개인 건강 데이터, 실제 HealthKit 데이터, 실제 Fitdays 파일명, 실제 오디오 파일명, local path 노출 여부
- 의료적 판단, HealthKit write, 서버/클라우드 처리로 오해될 copy 여부

## Preflight

로컬에서 먼저 통과해야 하는 gate:

```sh
Tools/Screenshots/validate_app_store_export_manifest.sh
REQUIRE_APP_STORE_RELEASE_APPROVED=1 Tools/Screenshots/validate_app_store_release_approval.sh
Tools/Release/audit_release_copy.sh
```

업로드 source:

- Raw source: `Docs/Screenshots/AppStore/raw/`
- Export output: `Docs/Screenshots/AppStore/export/`
- Product page copy: `Docs/APP_STORE_PRODUCT_PAGE_COPY.md`

`Docs/Screenshots/AppStore/export/`는 재생성 가능한 산출물이므로 repository에 커밋하지 않습니다.

## Screenshot Order

| 순서 | 파일 | expected headline |
| --- | --- | --- |
| 1 | `01_home_dashboard_light.png` | 수면 중 소리 기반 지표를 한눈에 |
| 2 | `02_sleep_report_light.png` | 아침에 읽기 쉬운 수면 소리 리포트 |
| 3 | `03_sleep_timeline_light.png` | 코골기와 환경 소음 흐름 확인 |
| 4 | `04_daily_rhythm_report_light.png` | 오늘의 리듬 점수를 참고용으로 |
| 5 | `05_daily_health_card_light.png` | 하루 리듬을 카드 한 장으로 |
| 6 | `06_health_metrics_overview_light.png` | 모든 건강 지표를 출처와 함께 |
| 7 | `07_privacy_settings_light.png` | 전체 밤 오디오는 저장하지 않습니다 |
| 8 | `08_zero_event_report_light.png` | 이벤트가 적은 밤도 측정 맥락과 함께 |

## Manual QA Checklist

| 항목 | Pass/Fail | Evidence note |
| --- | --- | --- |
| 8개 screenshot 순서가 product page copy와 일치함 |  |  |
| 각 upload preview에서 제목, 주요 카드, CTA가 잘리지 않음 |  |  |
| ko-KR subtitle/promotional text/keywords가 App Store Connect 필드 제한 안에 있음 |  |  |
| en-US subtitle/promotional text/keywords가 ko-KR과 같은 개인정보/웰니스 경계를 유지함 |  |  |
| 실제 개인 데이터, 실제 파일명, local path, 내부 DEBUG label이 없음 |  |  |
| 서버 업로드, 클라우드 처리, HealthKit write를 암시하지 않음 |  |  |
| 이벤트 없음/낮은 측정 품질이 건강 상태 단정으로 보이지 않음 |  |  |
| review-cropped 내부 검토 이미지를 upload source로 잘못 쓰지 않음 |  |  |

## Evidence Entry

아래 항목은 실제 App Store Connect 화면 확인 후 private/release evidence에 옮겨 적습니다. 계정 정보, 개인 데이터, 실제 사용자명은 기록하지 않습니다.

```text
ASC preview QA date:
Reviewer:
Locale checked: ko-KR / en-US
Screenshot set: App Store 8 raw/export set
Order result: pass / fail
Crop result: pass / fail
Locale copy result: pass / fail
Sensitive data result: pass / fail
Rejected items:
Follow-up:
Repository evidence updated: yes / no
```

## Blocking Conditions

- upload preview에서 주요 UI가 잘리거나 headline이 가려짐
- 순서가 `Docs/APP_STORE_PRODUCT_PAGE_COPY.md`의 screenshot order와 다름
- 실제 개인 데이터, 실제 파일명, local path, 내부 DEBUG label이 보임
- 진단, 치료, 질병 판단, HealthKit write, 서버/클라우드 처리로 읽히는 문구가 보임
- App Store Connect 화면의 locale copy가 문서화된 copy와 다름
