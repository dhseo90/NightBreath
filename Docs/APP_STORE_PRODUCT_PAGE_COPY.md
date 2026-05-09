# App Store Product Page Copy

이 문서는 NightBreath / 밤숨의 App Store product page 후보 문구를 정리합니다. 제출 직전 App Store Connect 화면에서 글자 수와 screenshot 순서를 다시 확인하되, copy의 제품 방향과 안전 경계는 이 문서를 기준으로 유지합니다.

## Primary Locale: ko-KR

### Metadata

| Field | Candidate copy | Notes |
| --- | --- | --- |
| App Name | 밤숨 | 한국어 표시 이름 |
| Subtitle | 수면 소리와 하루 리듬 | 30자 이내 후보 |
| Promotional Text | 수면 소리 리포트, 아침 컨디션, 오늘의 리듬을 iPhone 안에서 개인 참고용으로 정리합니다. | 170자 이내 후보 |
| Keywords | 밤숨,수면,코골기,수면소리,수면기록,건강리듬,HealthKit,컨디션 | 100자 이내 후보. 실제 제출 전 경쟁/검색어 검토 필요 |

### Description

```text
밤숨은 iPhone 안에서 수면 중 소리 기반 지표를 정리하고, 아침에 읽기 쉬운 개인 참고용 리포트를 보여주는 앱입니다.

수면을 시작하고 아침에 종료하면, 앱은 수면 소리 점수, 코골기와 환경 소음 같은 이벤트 흐름, 아침 컨디션 기록을 한곳에 모아 보여줍니다. 결과는 개인 패턴을 살펴보기 위한 참고용 보기로 제공됩니다.

밤숨은 Daily Rhythm Report 방향으로 확장됩니다. 사용자가 선택한 경우 Apple 건강앱 데이터를 read-only로 연결해 혈압, 체중, 체성분, 활동 같은 지표를 하루 리듬 안에서 함께 볼 수 있습니다. Fitdays CSV/export 파일은 사용자가 직접 선택한 로컬 파일만 가져오며, HealthKit 기반 지표와 로컬 전용 지표를 구분해 표시합니다.

개인정보 보호를 우선합니다.
- 서버 업로드나 클라우드 처리를 사용하지 않습니다.
- 외부 분석 SDK, 광고 SDK, 계정 로그인을 사용하지 않습니다.
- HealthKit은 사용자가 건강 데이터 연결을 선택한 경우에만 read-only로 사용합니다.
- HealthKit에 데이터를 쓰지 않습니다.
- 전체 밤 원본 오디오는 기본 저장하지 않습니다.
- 짧은 이벤트 오디오 샘플은 사용자가 설정에서 켠 경우에만 로컬에 저장할 수 있습니다.

밤숨은 건강 상태를 단정하거나 의학적 조치를 안내하지 않습니다. 수면 소리와 건강 지표를 함께 보더라도 원인과 결과를 의미하지 않습니다. 리포트는 웰니스와 개인 참고용으로 사용해 주세요.
```

### What's New Candidate

```text
App Store 준비를 위해 screenshot 후보, 앱 아이콘 검증, TestFlight 내부 테스트 기준, 개인정보/HealthKit read-only 검토 문서를 정리했습니다.
```

## Secondary Locale: en-US

### Metadata

| Field | Candidate copy | Notes |
| --- | --- | --- |
| App Name | NightBreath | English brand name |
| Subtitle | Sleep Sound & Rhythm | Product subtitle |
| Promotional Text | Review sleep sound reports, morning check-ins, and daily rhythm context on iPhone with local-first privacy. | 170 characters or less |
| Keywords | sleep,snore,sound,rhythm,wellness,HealthKit,checkin,report | 100 characters or less |

### Description

```text
NightBreath organizes sleep-related sound indicators on iPhone and turns them into a morning report for personal reference.

Start a sleep session, stop it in the morning, and review sleep sound score, event timeline, morning check-in, and measurement quality in one place. The report is designed to help you look back at personal patterns.

NightBreath is also expanding toward Daily Rhythm Report. When you choose to connect Apple Health, the app reads selected HealthKit data only and shows available blood pressure, body, activity, and recovery-style metrics alongside your daily context. Fitdays CSV/export files are imported only when you manually select a local file.

Privacy comes first.
- No server upload or cloud processing.
- No external analytics SDK, advertising SDK, or account login.
- HealthKit is read-only and starts only from your health dashboard action.
- The app does not write data to HealthKit.
- Full-night raw audio is not stored by default.
- Short event audio snippets are local only and require an explicit setting.

NightBreath does not determine health conditions or recommend medical action. Sleep sound and health metrics may be shown together, but the app does not claim cause and effect. Use reports for wellness and personal reference.
```

## Screenshot Order

1. Home dashboard: 수면 중 소리 기반 지표를 한눈에
2. Sleep report: 아침에 읽기 쉬운 수면 소리 리포트
3. Timeline: 코골기와 환경 소음 흐름 확인
4. Daily Rhythm: 오늘의 리듬 점수를 참고용으로
5. Daily Health Card: 하루 리듬을 카드 한 장으로
6. Health metrics overview: 모든 건강 지표를 출처와 함께
7. Privacy settings: 전체 밤 오디오는 저장하지 않습니다
8. Zero-event explanation: 이벤트가 적은 밤도 측정 맥락과 함께

모든 screenshot은 공개 검수용 simulator scenario data만 사용합니다. 실제 개인 건강 데이터, 실제 HealthKit 데이터, 실제 Fitdays CSV 파일명, 실제 오디오 파일명, 실제 local path는 product page asset에 포함하지 않습니다.

## Copy Safety Checklist

- 질병 여부를 단정하지 않습니다.
- 임상 지표의 정확도를 보장하지 않습니다.
- 치료나 의학적 조치를 안내하지 않습니다.
- 수면 소리와 혈압/체중/체성분 사이의 원인과 결과를 주장하지 않습니다.
- 이벤트가 적은 밤을 건강 상태 해석으로 표현하지 않습니다.
- 서버 미전송, HealthKit read-only, 전체 밤 원본 오디오 기본 미저장, 이벤트 샘플 opt-in 정책을 product page와 App Review note가 같은 방향으로 설명해야 합니다.
