# Daily Health Card

NightBreath / 밤숨의 Daily Health Card는 하루 리듬 리포트를 한 장의 이미지 카드처럼 보여주기 위한 화면 구조입니다. 수면 소리, 컨디션, 활동, mock 건강 데이터를 사용 가능한 범위에서 요약하되, 개인 참고용 표현만 사용합니다.

## 목적

- 오늘의 리듬 점수와 핵심 지표를 한눈에 보기 쉽게 정리합니다.
- Morning Brief, Daily Rhythm Report, 건강 대시보드에서 나온 정보를 카드 형태로 재구성합니다.
- 나중에 SwiftUI View를 이미지로 렌더링해 저장 또는 공유할 수 있는 구조를 준비합니다.
- 이번 단계에서는 실제 이미지 export/share 기능을 구현하지 않습니다.

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

`CardRendererProtocol`은 나중에 SwiftUI View를 이미지로 렌더링하는 구현을 붙이기 위한 자리입니다. 현재 `PlaceholderDailyHealthCardRenderer`는 이미지 데이터를 만들지 않고, 선택된 report/template/privacyLevel만 담은 placeholder result를 반환합니다.

실제 구현 시에도 렌더링은 로컬 기기 안에서 수행해야 하며, 생성된 이미지를 서버로 보내면 안 됩니다.

## Export / Share 설계

이번 단계에서는 실제 export/share 기능을 구현하지 않고, 다음 구현 이슈에서 붙일 수 있도록 흐름만 고정합니다.

### SwiftUI View to Image Rendering

계획:

1. `DailyHealthCardContent`와 `DailyHealthCardTemplate`으로 export 전용 SwiftUI card view를 구성합니다.
2. iOS 16+에서는 `ImageRenderer` 기반으로 SwiftUI view를 로컬 이미지 데이터로 렌더링합니다.
3. 렌더링 크기는 card template별 고정 비율을 사용하고, Dynamic Type으로 내용이 잘리지 않도록 export preview에서 검증합니다.
4. 렌더링은 기기 안에서만 수행합니다.
5. 생성된 이미지에는 사용자가 선택한 privacy level에 맞는 항목만 포함합니다.
6. 렌더링 실패 시 이미지를 만들지 않고 사용자에게 다시 시도 안내만 표시합니다.

### Export 전 확인 화면

export/share를 누르면 바로 공유 sheet를 열지 않고 확인 화면을 먼저 표시합니다.

확인 화면에 포함할 항목:

- 선택한 template
- 선택한 privacy level
- 카드 preview
- 포함되는 지표 요약
- 민감 수치 포함 여부
- "자동 공유 없음" 안내
- "서버 업로드 없음" 안내
- "외부 SDK 없음" 안내

사용자가 확인 화면에서 명시적으로 export 또는 share를 선택한 경우에만 이미지 생성과 공유 흐름을 시작합니다.

### Privacy Level별 표시 항목

| Privacy level | 표시 항목 | 숨기는 항목 |
| --- | --- | --- |
| `minimal` | 오늘의 리듬 점수, 한 줄 요약, 날짜 | 혈압, 체중, 체성분, source, 측정 시간 |
| `standard` | 오늘의 리듬 점수, 수면 소리 점수, 측정 품질, 주요 지표 값 일부 | source 세부 정보, 기록 시간, import batch |
| `detailed` | 주요 지표 값, source, 기록 시간 | import batch id 같은 내부 추적 값 |

`privacyMinimal` template은 항상 `minimal` 표시 수준으로 export합니다.

### 민감 수치 포함 경고

`standard` 또는 `detailed`에서 혈압, 체중, 체지방률, 체성분, 심박수 같은 민감할 수 있는 수치가 포함되면 확인 화면에 다음 성격의 문구를 표시합니다.

```text
이 카드에는 건강 관련 수치가 포함됩니다. 공유 전 표시 항목을 확인해 주세요.
```

이 문구는 사용자를 겁주기 위한 경고가 아니라, 공유 전 표시 항목을 다시 확인하게 하는 개인정보 안내입니다.

### 공유 원칙

- 자동 공유 없음
- 서버 업로드 없음
- 외부 SDK 없음
- cloud processing 없음
- 광고/분석 SDK 연결 없음
- HealthKit write 없음
- 사용자가 명시적으로 선택한 경우에만 export/share
- share sheet를 열기 전 preview와 privacy level을 다시 확인
- 생성된 이미지는 사용자가 저장/공유를 선택하지 않으면 앱 밖으로 나가지 않음

### 다음 구현 이슈

남은 구현:

- `ImageRenderer` 기반 `DailyHealthCardImageRenderer` 구현
- export preview confirmation view 추가
- privacy level별 export snapshot test 추가
- 민감 수치 포함 여부 계산 helper 추가
- 공유 sheet 연결

## 의료 진단 아님

Daily Health Card는 개인 패턴을 살펴보기 위한 참고용 보기입니다. 질병을 진단하거나 예측하지 않고, 치료 권고를 하지 않습니다.

표현 원칙:
- “오늘의 리듬 점수”를 사용합니다.
- 진단 성격의 점수처럼 보이는 표현을 쓰지 않습니다.
- 수면 소리와 건강 지표 사이의 인과관계를 단정하지 않습니다.
- “이 앱은 진단 목적의 의료기기가 아닙니다.” 문구를 유지합니다.
