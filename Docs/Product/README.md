# Product README

이 문서는 NightBreath / 밤숨의 제품 방향을 빠르게 이해하기 위한 입구입니다. 더 긴 설명은 각 세부 문서에서 관리합니다.

## 제품 정체성

밤숨은 iPhone 온디바이스 수면 소리 리포트에서 출발해, 하루 동안의 수면, 혈압, 체중, 체성분, 활동, 컨디션 기록을 함께 살펴보는 개인 건강 리듬 리포트 앱으로 확장됩니다.

핵심은 “진단”이 아니라 “개인 패턴을 살펴보기 위한 참고용 보기”입니다. 수면 중 소리 이벤트와 건강 지표가 같은 날짜에 보이더라도 원인과 결과를 단정하지 않습니다.

## V1 범위

V1은 정확도 확정보다 앱 구조, 개인정보 원칙, 테스트 가능한 분석 pipeline, mock/protocol 기반 건강 데이터 확장을 우선합니다.

- SwiftUI 앱 구조와 수면 시작/종료 흐름
- 로컬 수면 세션, 수면 이벤트, 밤 수면 리포트, 아침 컨디션 체크인
- mock 리포트 UI, 이벤트 타임라인, 수면 소리 점수
- rule-based 분석 placeholder와 오디오 캡처 service skeleton
- HealthKit read-only dashboard adapter
- Fitdays CSV/export local import flow
- Daily Rhythm 확장 모델과 화면

## V1에서 하지 않는 것

- Apple Watch 연동
- 원격 API, 클라우드 동기화, 계정 시스템
- 외부 분석 SDK, 광고 SDK
- HealthKit 쓰기
- Fitdays 서버/API 직접 연결
- 임상 지표로서의 AHI 계산
- 전체 밤 원본 오디오 저장
- 진단적 판단, 질병 여부 판정, 치료 권고

## 표현 원칙

사용하는 표현:

- 코골기
- 이갈이 의심 소리
- 호흡정지 의심 구간
- gasp-like 회복 호흡
- 기침 의심 소리
- 환경 소음
- 움직임 의심 소리
- 각성 의심 구간
- 수면 소리 점수
- 오늘의 리듬 점수
- 회복 리듬
- 아침 리포트
- 하루 리듬 카드

피하는 방향:

- 질환명을 확정하는 표현
- 임상 지표를 정확히 산출한다는 표현
- 의심이 아닌 확정으로 읽히는 표현
- 치료 판단이나 의학적 조치를 권하는 표현
- 건강 데이터와 수면 소리 사이의 인과관계를 단정하는 표현

## 관련 문서

| 문서 | 내용 |
| --- | --- |
| [PRODUCT_DIRECTION](../PRODUCT_DIRECTION.md) | 제품 확장 방향과 Daily Rhythm 원칙 |
| [CURRENT_STATUS](../CURRENT_STATUS.md) | 현재 구현/미구현 상태 |
| [NEXT_ISSUES](../NEXT_ISSUES.md) | 다음 이슈 후보 |
| [APP_STORE_PRODUCT_PAGE_COPY](../APP_STORE_PRODUCT_PAGE_COPY.md) | App Store용 제품 문구 후보 |
| [LICENSING](../LICENSING.md) | Apache-2.0 코드 범위와 ESC-50/ESC-10 dataset license 경계 |
| [DEPENDENCIES](../DEPENDENCIES.md) | 외부 dependency 이름, version constraint, 라이선스 inventory |
