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

## 의료 진단 아님

Daily Health Card는 개인 패턴을 살펴보기 위한 참고용 보기입니다. 질병을 진단하거나 예측하지 않고, 치료 권고를 하지 않습니다.

표현 원칙:
- “오늘의 리듬 점수”를 사용합니다.
- 진단 성격의 점수처럼 보이는 표현을 쓰지 않습니다.
- 수면 소리와 건강 지표 사이의 인과관계를 단정하지 않습니다.
- “이 앱은 진단 목적의 의료기기가 아닙니다.” 문구를 유지합니다.
