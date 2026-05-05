# Screenshot Folder Guide

이 폴더는 NightBreath / 밤숨의 README 대표 screenshot과 UI gallery용 screenshot 후보를 정리하기 위한 구조입니다.

## 원칙

- 모든 screenshot은 mock data 또는 simulator scenario 기반으로 생성합니다.
- 실제 개인 건강 데이터, 실제 HealthKit 데이터, 실제 오디오 파일, 실제 이벤트 오디오 샘플을 사용하지 않습니다.
- README에는 대표 screenshot만 사용합니다.
- 가능한 모든 화면과 edge state 설명은 `Docs/UI_GALLERY.md`에서 관리합니다.
- 실제 screenshot 파일이 없는 경우 문서에는 `screenshot pending`으로 표시하고 broken image link를 만들지 않습니다.
- screenshot 생성 방법은 `Tools/Screenshots/README.md`에서 관리합니다.
- DEBUG 앱의 `Simulator QA / Screenshot Scenario` 화면에서 screenshot preset을 선택한 뒤 캡처합니다.

## 폴더

- `README/`: README 대표 screenshot 후보
- `Home/`: 홈과 대시보드 계열
- `Sleep/`: 수면 시작, 녹음 중, 리포트, 타임라인
- `DailyRhythm/`: 아침 리포트, 오늘의 리듬 리포트, 하루 리듬 카드
- `Health/`: 건강 대시보드, 전체 건강 지표, Fitdays import, 월 건강 캘린더, 날짜별 상세, metric detail, 혈압, 체성분, 교차 보기
- `Privacy/`: 개인정보 설정, 배치 가이드, 온보딩
- `EdgeStates/`: empty, 권한 없음, 데이터 부족, 낮은 측정 품질
- `Debug/`: DEBUG 전용 검증 화면

## 현재 README 대표 screenshot

다음 파일은 DEBUG simulator와 mock data 상태에서 생성했습니다.

- `README/home_dashboard_light.png`
- `README/sleep_start_light.png`
- `README/sleep_report_light.png`
- `README/sleep_timeline_light.png`
- `README/morning_brief_light.png`
- `README/daily_rhythm_report_light.png`
- `README/daily_health_card_light.png`
- `README/health_dashboard_light.png`

README 본문에는 위 원본을 직접 쓰지 않고, status bar, 시간, Dynamic Island 영역과 하단 floating tab bar 겹침 영역을 제거한 crop 버전을 사용합니다.

- 원본 위치: `Docs/Screenshots/README/*.png`
- README용 crop 위치: `Docs/Screenshots/README/cropped/*.png`
- 현재 기준: 1206x2622 simulator capture에서 상단 180px 제거
- 현재 crop 결과: 1206x2122

Crop은 화면 title과 주요 content를 자르지 않아야 합니다. crop 결과가 title을 자르거나 UI를 오해하게 만들면 fake image를 만들지 말고 원본을 다시 캡처하거나 crop 값을 조정합니다.

Crop script:

```bash
Tools/Screenshots/crop_readme_screenshots.sh
```

## EHM 상세 screenshot 후보

다음 파일은 Extended Health Metrics/Fitdays import/metric detail 문서용 screenshot입니다. 원본은 `Health/`에 보존하고, UI Gallery에는 status bar, 시간, Dynamic Island 영역을 제거한 `Health/cropped/` 버전을 우선 사용합니다. 실제 capture 전에는 `Docs/UI_GALLERY.md`에 `screenshot pending`으로 남기고 image markdown을 만들지 않습니다.

- `Health/health_metrics_overview_light.png`
- `Health/fitdays_import_light.png`
- `Health/fitdays_import_result_light.png`
- `Health/health_calendar_light.png`
- `Health/daily_measurement_detail_light.png`
- `Health/metric_detail_body_water_light.png`
- `Health/metric_detail_basal_metabolic_rate_light.png`
- `Health/fitdays_import_error_light.png`

UI Gallery crop 위치:

- `Health/cropped/health_metrics_overview_light.png`
- `Health/cropped/fitdays_import_light.png`
- `Health/cropped/fitdays_import_result_light.png`
- `Health/cropped/health_calendar_light.png`
- `Health/cropped/daily_measurement_detail_light.png`
- `Health/cropped/metric_detail_body_water_light.png`
- `Health/cropped/metric_detail_basal_metabolic_rate_light.png`
- `Health/cropped/fitdays_import_error_light.png`

## 주의

Screenshot은 앱의 제품 방향을 보여주는 문서 자료입니다. 건강 상태를 단정하거나 수면 소리와 건강 지표 사이의 원인과 결과를 주장하는 copy를 사용하지 않습니다.
