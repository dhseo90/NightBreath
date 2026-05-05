# Daily Health Card

NightBreath / 밤숨의 Daily Health Card는 하루 리듬 리포트를 한 장의 이미지 카드처럼 보여주기 위한 화면 구조입니다. 수면 소리, 컨디션, 활동, mock 건강 데이터를 사용 가능한 범위에서 요약하되, 개인 참고용 표현만 사용합니다.

## 목적

- 오늘의 리듬 점수와 핵심 지표를 한눈에 보기 쉽게 정리합니다.
- Morning Brief, Daily Rhythm Report, 건강 대시보드에서 나온 정보를 카드 형태로 재구성합니다.
- SwiftUI View를 로컬 이미지로 렌더링해 사용자가 명시적으로 공유할 수 있는 구조를 제공합니다.
- 현재 단계에서는 사진 앱 저장이 아니라 임시 로컬 PNG 생성과 시스템 공유 sheet 연결까지 지원합니다.

## 템플릿

- `simple`: 오늘의 리듬 점수와 가장 적은 핵심 항목 중심 카드입니다.
- `sleepFocused`: 수면 소리 점수와 측정 품질을 더 강조하는 카드입니다.
- `healthSummary`: 혈압, 체중, 체지방률, 걸음 수 같은 mock 건강 데이터를 함께 보여주는 카드입니다.
- `privacyMinimal`: 민감 수치를 줄이고 점수와 한 줄 요약 중심으로 보여주는 카드입니다.

## Privacy Level

- `minimal`: 오늘의 리듬 점수와 한 줄 요약만 표시합니다. 혈압, 체중, 체지방률 같은 민감 수치는 숨깁니다.
- `standard`: 주요 지표 값을 표시하되 source와 기록 시간 세부 정보는 줄입니다.
- `detailed`: 주요 지표 값과 mock source, 기록 시간을 함께 표시합니다.

`privacyMinimal` 템플릿은 사용자가 `standard`나 `detailed`를 선택해도 `minimal` 표시 수준으로 처리합니다.

## 민감 데이터 주의

Daily Health Card에는 혈압, 체중, 체성분처럼 민감할 수 있는 건강 데이터가 포함될 수 있습니다. 따라서 이미지 export 또는 공유는 사용자가 명시적으로 선택한 경우에만 수행하는 방향으로 설계합니다.

원칙:
- 자동 공유 없음
- 서버 업로드 없음
- 외부 SDK 없음
- 사용자가 선택한 privacy level에 따라 카드 표시 항목 제한
- export/share 전 사용자 확인 흐름 필요

## Rendering 구조

`CardRendererProtocol`은 테스트 가능한 renderer boundary를 유지하기 위한 자리입니다. `PlaceholderDailyHealthCardRenderer`는 이미지 데이터를 만들지 않고, 선택된 report/template/privacyLevel만 담은 placeholder result를 반환합니다.

`DailyHealthCardPreviewView`는 실제 사용자 액션이 있을 때 `ImageRenderer` 기반 `DailyHealthCardImageRenderer`로 현재 카드 상태를 로컬 PNG로 렌더링합니다. 생성된 파일은 임시 디렉터리에 저장하고, 이미지가 준비된 뒤에만 시스템 공유 sheet를 열 수 있습니다.

실제 구현 시에도 렌더링은 로컬 기기 안에서 수행해야 하며, 생성된 이미지를 서버로 보내면 안 됩니다.

렌더링 대상 view는 일반 화면용 card view와 분리한 export 전용 SwiftUI view로 둡니다. 화면 표시용 view는 현재 device width와 navigation chrome의 영향을 받지만, export view는 정해진 card size, safe padding, template palette, privacy level을 입력으로 받아 같은 데이터가 항상 같은 이미지 구조로 렌더링되도록 합니다.

렌더링 입력:

- `DailyRhythmReport`
- `DailyHealthCardTemplate`
- `DailyHealthCardPrivacyLevel`
- 표시 날짜와 locale
- 민감 수치 포함 여부
- export용 display model

렌더링 출력:

- 로컬 이미지 데이터
- 렌더링 size
- 적용된 template/privacy level
- 포함된 section 목록
- 사용자에게 보여줄 privacy notice

## Export / Share 설계

현재 단계에서는 카드 미리보기 화면에서 명시적인 `이미지 만들기` 액션을 제공하고, 렌더링이 성공한 경우에만 `공유` 액션을 활성화합니다. 자동 저장, 자동 공유, 서버 업로드는 없습니다.

### SwiftUI View to Image Rendering

현재 구현:

1. `DailyHealthCardContent`와 `DailyHealthCardTemplate`으로 export 전용 SwiftUI card view를 구성합니다.
2. iOS 17+ app target에서 `ImageRenderer` 기반으로 SwiftUI view를 로컬 PNG 데이터로 렌더링합니다.
3. 렌더링 표면은 고정 폭과 safe padding을 사용합니다.
4. 렌더링은 기기 안에서만 수행합니다.
5. 생성된 이미지에는 사용자가 선택한 privacy level에 맞는 항목만 포함합니다.
6. 렌더링 실패 시 이미지를 만들지 않고 사용자에게 다시 시도 안내만 표시합니다.

### Export 전 확인 화면

카드 미리보기 화면은 공유 sheet를 바로 열지 않고 먼저 현재 template/privacy level과 카드 preview를 보여줍니다. 사용자가 `이미지 만들기`를 선택해야 임시 PNG가 생성되고, 그 다음에만 `공유` 버튼이 활성화됩니다.

확인 화면에 포함할 항목:

- 선택한 template
- 선택한 privacy level
- 카드 preview
- 포함되는 지표 요약
- 민감 수치 포함 여부
- "자동 공유 없음" 안내
- "서버 업로드 없음" 안내
- "외부 SDK 없음" 안내

사용자가 명시적으로 이미지 생성을 선택한 경우에만 이미지 생성 흐름을 시작합니다. 공유 sheet는 이미지가 준비된 뒤 사용자가 다시 `공유`를 선택할 때 열립니다.

확인 흐름:

1. 카드 미리보기 화면에서 template과 privacy level을 선택합니다.
2. 카드 preview와 안내 문구를 확인합니다.
3. 사용자가 `이미지 만들기`를 선택한 경우에만 이미지 렌더링을 시작합니다.
4. 렌더링에 성공하면 임시 로컬 PNG와 `DailyHealthCardImageResult`가 생성됩니다.
5. 이미지가 준비된 뒤 사용자가 `공유`를 선택한 경우에만 시스템 share sheet를 엽니다.
6. 사용자가 취소하면 자동 재공유나 서버 전송 없이 미리보기 화면에 남습니다.

저장/공유/취소/실패 state:

| State | 동작 | 사용자 안내 |
| --- | --- | --- |
| `preview` | export 전 card preview와 포함 항목을 표시 | 표시 항목을 확인한 뒤 이미지 만들기를 선택 |
| `rendering` | 로컬에서 SwiftUI view를 이미지로 변환 | 잠시 기다리기 |
| `imageReady` | 임시 로컬 PNG 생성 완료 | 공유 버튼 활성화 |
| `saveRequested` | 사용자가 저장을 명시적으로 선택 | 향후 사진/파일 저장 흐름에서 구현 |
| `shareRequested` | 사용자가 공유를 명시적으로 선택 | 시스템 share sheet 표시 |
| `cancelled` | 사용자가 저장/공유를 취소 | 카드가 공유되지 않았다는 짧은 확인 표시 |
| `failed` | 렌더링, 저장, share sheet 준비가 실패 | 이미지를 만들지 못했으며 다시 시도할 수 있음 |
| `completed` | 저장 또는 공유 흐름이 정상 종료 | 완료 상태만 표시하고 자동 재공유는 하지 않음 |

### Privacy Level별 표시 항목

| Privacy level | 표시 항목 | 숨기는 항목 |
| --- | --- | --- |
| `minimal` | 오늘의 리듬 점수, 한 줄 요약, 날짜 | 혈압, 체중, 체성분, source, 측정 시간 |
| `standard` | 오늘의 리듬 점수, 수면 소리 점수, 측정 품질, 주요 지표 값 일부 | source 세부 정보, 기록 시간, import batch |
| `detailed` | 주요 지표 값, source, 기록 시간 | import batch id 같은 내부 추적 값 |

`privacyMinimal` template은 항상 `minimal` 표시 수준으로 export합니다.

세부 표시 기준:

| 항목 | `minimal` | `standard` | `detailed` |
| --- | --- | --- | --- |
| 날짜 | 표시 | 표시 | 표시 |
| 오늘의 리듬 점수 | 표시 | 표시 | 표시 |
| 한 줄 요약 | 표시 | 표시 | 표시 |
| 수면 소리 점수 | 숨김 또는 범주형 요약 | 표시 | 표시 |
| 측정 품질 | 숨김 또는 짧은 문구 | 표시 | 표시 |
| 아침/저녁 컨디션 | 요약만 표시 | 주요 선택값 표시 | 주요 선택값과 기록 시간 표시 |
| 활동 | 요약만 표시 | 주요 값 표시 | 주요 값과 source 표시 |
| 혈압 | 숨김 | 사용자가 허용한 경우 주요 값 표시 | 사용자가 허용한 경우 값, 시간, source 표시 |
| 체중/체성분 | 숨김 | 사용자가 허용한 경우 주요 값 표시 | 사용자가 허용한 경우 값, 시간, source 표시 |
| source | 숨김 | source 종류만 표시 | source 이름과 기록 시간 표시 |
| import batch id | 숨김 | 숨김 | 숨김 |
| 파일명/local path | 숨김 | 숨김 | 숨김 |

`standard`와 `detailed`에서도 사용자가 preview에서 특정 section을 끄면 해당 section은 export 이미지에 포함하지 않습니다. 파일명, local path, import batch id 같은 내부 추적 값은 어떤 privacy level에서도 표시하지 않습니다.

### 민감 수치 포함 경고

`standard` 또는 `detailed`에서 혈압, 체중, 체지방률, 체성분, 심박수 같은 민감할 수 있는 수치가 포함되면 확인 화면에 다음 성격의 문구를 표시합니다.

```text
이 카드에는 건강 관련 수치가 포함됩니다. 공유 전 표시 항목을 확인해 주세요.
```

이 문구는 사용자를 겁주기 위한 경고가 아니라, 공유 전 표시 항목을 다시 확인하게 하는 개인정보 안내입니다.

추가 안내 문구 후보:

```text
공유 이미지에는 선택한 건강 수치가 그대로 보일 수 있습니다.
```

```text
공유 전 날짜, 점수, 건강 수치, source 표시 여부를 확인해 주세요.
```

```text
이 이미지는 사용자가 선택한 경우에만 저장 또는 공유됩니다.
```

### 공유 원칙

- 자동 공유 없음
- 서버 업로드 없음
- 외부 SDK 없음
- cloud processing 없음
- 광고/분석 SDK 연결 없음
- HealthKit write 없음
- 사용자가 명시적으로 선택한 경우에만 export/share
- share sheet를 열기 전 preview와 privacy level을 확인
- 생성된 이미지는 사용자가 저장/공유를 선택하지 않으면 앱 밖으로 나가지 않음
- 생성된 이미지는 analytics event, crash log, debug log에 첨부하지 않음
- export preview screenshot에는 실제 personal CSV 파일명, 실제 local path, 실제 HealthKit device 식별자를 표시하지 않음

### 다음 구현 이슈

구현 완료:

- `ImageRenderer` 기반 `DailyHealthCardImageRenderer` 구현
- 명시적인 `이미지 만들기` 액션
- 임시 로컬 PNG 생성 후 시스템 공유 sheet 노출
- 서버 업로드/자동 공유 부재 source regression test
- 민감 수치 포함 여부 계산 helper
- 별도 export confirmation sheet
- 공유 취소/completed state UI

남은 구현:

- privacy level별 export snapshot test 추가
- 사진 앱 또는 파일 저장 흐름 추가

## 의료 진단 아님

Daily Health Card는 개인 패턴을 살펴보기 위한 참고용 보기입니다. 질병을 진단하거나 예측하지 않고, 치료 권고를 하지 않습니다.

표현 원칙:
- “오늘의 리듬 점수”를 사용합니다.
- 진단 성격의 점수처럼 보이는 표현을 쓰지 않습니다.
- 수면 소리와 건강 지표 사이의 인과관계를 단정하지 않습니다.
- “이 앱은 진단 목적의 의료기기가 아닙니다.” 문구를 유지합니다.
