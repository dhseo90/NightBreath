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
- `Health/`: 건강 대시보드, 혈압, 체성분, 교차 보기
- `Privacy/`: 개인정보 설정, 배치 가이드, 온보딩
- `EdgeStates/`: empty, 권한 없음, 데이터 부족, 낮은 측정 품질
- `Debug/`: DEBUG 전용 검증 화면

## 주의

Screenshot은 앱의 제품 방향을 보여주는 문서 자료입니다. 건강 상태를 단정하거나 수면 소리와 건강 지표 사이의 원인과 결과를 주장하는 copy를 사용하지 않습니다.
