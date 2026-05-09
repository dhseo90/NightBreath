# UI README

이 문서는 NightBreath / 밤숨의 주요 화면과 screenshot 문서 흐름을 설명합니다. 루트 README에는 대표 UI만 싣고, 전체 화면 설명과 상태별 screenshot 관리는 이 문서에서 시작합니다.

## 주요 화면

- 홈 대시보드: 최근 수면 리포트, 수면 소리 점수, 측정 품질, 수면 시작 CTA, Daily Rhythm 진입점을 보여줍니다.
- 수면 시작: 마이크 권한, 기기 배치, 이벤트 오디오 샘플 저장 상태, 수면 시작 CTA를 확인합니다.
- 수면 녹음 중: 세션 경과 시간, 실제 오디오 수신/분석 시간, 커버리지, detector backend, 수면 종료 버튼을 표시합니다.
- 수면 리포트: 수면 소리 점수, 측정 품질, 이벤트 요약, diagnostics, zero-event 안내를 보여줍니다.
- 이벤트 타임라인: 이벤트별 시간, duration, confidence, 샘플 보유 여부, feedback 흐름을 확인합니다.
- 아침 리포트: 지난밤 요약, 아침 컨디션, 예시 건강 데이터, 데이터 품질을 함께 보여줍니다.
- 오늘의 리듬 리포트: 오늘의 리듬 점수, component score, data quality, Daily Insight를 참고용으로 보여줍니다.
- 건강 대시보드: HealthKit read-only, Fitdays local import, 전체 건강 지표, 월 캘린더, metric detail로 이동하는 허브입니다.
- 개인정보 설정: 이벤트 오디오 샘플 opt-in, 저장 용량, 삭제, 서버 전송 없음 안내를 제공합니다.

## Screenshot 원칙

- README 대표 이미지는 mock/simulator data 기반이어야 합니다.
- 실제 개인 건강 데이터, 실제 Fitdays CSV 파일명, 실제 오디오 파일명, local path를 노출하지 않습니다.
- DEBUG-only 화면은 Release/App Store/README 대표 이미지로 사용하지 않습니다.
- App Store 제출용 이미지는 README 대표 이미지와 별도로 approval flow를 거칩니다.
- 이미지가 존재해도 crop, 내부 label, 긴 한국어 문구, 하단 tab bar 가림을 눈으로 확인합니다.

## UI 문서 흐름

| 문서 | 내용 |
| --- | --- |
| [UI_GALLERY](../UI_GALLERY.md) | 화면별 역할, 상태, screenshot scenario, release 노출 여부 |
| [UI_SCREEN_MAP](../UI_SCREEN_MAP.md) | 화면 구조와 navigation map |
| [DESIGN_SYSTEM](../DESIGN_SYSTEM.md) | NightBreath 디자인 시스템과 컴포넌트 기준 |
| [Screenshots README](../Screenshots/README.md) | screenshot 폴더 구조, capture/crop/review flow |
| [ONBOARDING_AND_CALIBRATION](../ONBOARDING_AND_CALIBRATION.md) | 온보딩과 캘리브레이션 흐름 |
| [ONBOARDING_ILLUSTRATION_GUIDE](../ONBOARDING_ILLUSTRATION_GUIDE.md) | 온보딩 일러스트 기준 |
