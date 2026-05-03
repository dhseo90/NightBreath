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

## App Store Copy Draft

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
- Fitdays CSV/import 기반 local-only 확장 지표
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

## App Store Screenshot Guide

Screenshot은 mock data와 simulator scenario 기반으로만 생성합니다.

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

README용 crop 원칙:

- status bar, 시간, Dynamic Island 영역은 README 대표 이미지에서 제거합니다.
- title이나 주요 카드가 잘리지 않아야 합니다.
- HTML `img` width는 240-280px 범위로 제한합니다.
- 원본 screenshot은 보존하고 cropped 이미지를 README에 사용합니다.

Capture workflow는 `Tools/Screenshots/README.md`와 `Tools/Screenshots/` scripts를 기준으로 합니다.

## App Icon Guide

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

최종 고품질 artwork와 App Store asset export는 아직 보류 항목입니다.

## TestFlight Checklist

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

실제 iPhone manual QA 절차는 `Docs/QA_GUIDE.md`를 따릅니다.

## App Review Notes 후보

```text
NightBreath / 밤숨 uses HealthKit only when the user explicitly chooses to connect health data from the health dashboard. The app requests read access only and does not write data to HealthKit.

The app does not upload health data or audio to a server. Sleep sound analysis and reports are handled on device.

The app does not store full-night raw audio by default. Short event audio snippets can be stored locally only when the user explicitly enables the setting.

Reports are for personal wellness reference and are not intended for medical diagnosis.
```

## 남은 release 작업

- 최종 앱 아이콘 고품질 artwork
- App Store marketing screenshot final
- App Store product page copy 최종 조정
- TestFlight 내부 테스트
- Legal/App Review audit
- 실제 iPhone overnight 안정성 확인
