# Roadmap & Remaining Issues

## 현재 v1.1.0 상태

| 이슈 | 상태 | 판단 |
| --- | --- | --- |
| v1.1.0 (1) 수면 기록 P0 안정화 | 완료 | 장시간 실기기 기록 확인됨. interruption warning은 품질 경고로 남기고 pass 가능 |
| v1.1.0 (2) 수면 리포트 신뢰도 | 완료 판단 가능 | 장시간 리포트 문구/품질/히스토리/아침 체크인 연결 기준 통과 가능 |
| v1.1.0 (3) 수면 UX와 공통 피드백 | 대기 | 시작/종료 UX, 버튼 상태, navigation chrome 정리 필요 |
| v1.1.0 (4) Health/Fitdays 사용성 정리 | 대기 | 건강 데이터 상태, source 표시, Fitdays import 흐름 정리 필요 |
| v1.1.0 (5) Daily Rhythm v1.1 보강 | 대기 | 수면 추세, Daily Rhythm 카드, 데이터 품질 설명 보강 필요 |
| v1.1.0 (6) 검증 자동화와 실기기 QA | 부분 완료 | 수면 P0 테스트는 완료. 전체 v1.1.0 gate는 후속 단계 후 재확인 |
| v1.1.0 (7) 문서와 release evidence 정리 | 진행 중 | 본 handoff 문서 포함. README, QA, privacy, release evidence 추가 정리 필요 |
| v1.1.0 (8) release candidate 결정 | 대기 | 1~7 완료 후 blocker 재판단 |

## 잔여 작업 우선순위

| 우선순위 | 작업 | 완료 기준 | 추천 모델 | 추론 수준 | 선정 근거 |
| --- | --- | --- | --- | --- | --- |
| P0 | v1.1.0 (3) 수면 UX와 공통 피드백 | 수면 시작/종료/중단/복구 버튼 상태와 navigation chrome이 일관되고 validation script 통과 | 5.6 Terra | 높음 (high) | 사용자 흐름과 UI state를 다루지만 핵심 분석 계약 변경은 제한적 |
| P0 | v1.1.0 (4) Health/Fitdays 사용성 정리 | source, 권한 상태, import 결과, skipped/error 설명이 명확하고 HealthKit write 금지 유지 | 5.6 Sol | 높음 (high) | 건강 데이터와 개인정보 경계가 포함되어 상향 필요 |
| P1 | v1.1.0 (5) Daily Rhythm v1.1 보강 | 수면 추세와 Daily Rhythm 카드가 데이터 품질/부족 상태를 안전하게 설명 | 5.6 Sol | 높음 (high) | 건강 리듬 해석과 의료 오해 방지 문구가 함께 필요 |
| P1 | v1.1.0 (6) 전체 gate 재검증 | 전체 Swift test, iOS build, docs/UI/screenshot/release scripts 통과 | 5.6 Sol | 높음 (high) | 릴리스 gate 판단과 회귀 방지가 포함됨 |
| P1 | v1.1.0 (7) 문서/evidence 정리 | README, QA docs, privacy copy, release evidence가 최신 구현과 일치 | 5.6 Sol | 높음 (high) | 문서 작업이지만 App Store/privacy/medical copy에 영향 |
| P0 at end | v1.1.0 (8) RC 판단 | blocker, residual risk, 실기기 evidence를 기준으로 release candidate 여부 결정 | 5.6 Sol | 최대 (max) | 릴리스 판단, 장시간 실기기 안정성, 개인정보/의료 오해 기준이 동시에 걸림 |

## 다음 개발자가 바로 볼 항목

| 항목 | 확인 위치 | 메모 |
| --- | --- | --- |
| 현재 상세 상태 | [Current Status](../CURRENT_STATUS.md) | 진행률과 완료된 gate의 최신 요약 |
| 다음 이슈 목록 | [Next Issues](../NEXT_ISSUES.md) | v1.1.0 후속 작업 queue |
| v1.1 roadmap | [V1.1 Roadmap](../V1_1_ROADMAP.md) | release gate와 모델 추천 리스트 |
| 개발 워크플로 | [Development Workflow](../DEVELOPMENT_WORKFLOW.md) | build/test/QA 기본 운영 |
| 앱 정책 | [AGENTS.md](../../AGENTS.md) | 작업 전 필독 |

## 남은 위험

| 위험 | 현재 판단 | 닫는 방법 |
| --- | --- | --- |
| 장시간 기록의 device variability | 한 번의 실기기 장시간 pass만으로 모든 device/route를 대표할 수 없음 | iPhone 모델/OS/audio route를 늘려 반복 QA |
| interruption warning 해석 | warning은 blocker가 아니지만 사용자가 이해할 수 있어야 함 | 리포트 품질 문구와 history 표시를 재확인 |
| HealthKit 권한 조합 | mock은 충분하나 실제 권한 상태 matrix는 제한적 | denied/partial/authorized 실기기 QA |
| Fitdays export 형식 변화 | local parser는 header/unit 변형에 취약할 수 있음 | 실제 export 샘플별 parser fixture 추가 |
| Daily Rhythm 과해석 | 건강 지표와 수면 소리의 인과관계처럼 보일 수 있음 | copy review와 QA checklist에 의료 오해 방지 포함 |
| release evidence 누락 | 구현은 되어도 App Store/release 문서가 뒤처질 수 있음 | release audit script와 수동 evidence review 병행 |

## 닫힌 것으로 봐도 되는 항목

| 항목 | 닫는 기준 |
| --- | --- |
| 수면 기록 P0 안정화 | 장시간 실기기 기록이 생성되고 report/history까지 이어짐. interruption warning은 pass with warning으로 기록 |
| 수면 리포트 신뢰도 | measurement quality, audio coverage, interruption/gap, morning check-in 연결, 리포트 문구가 안전 기준을 충족 |

위 두 항목은 새 blocker 증거가 나오지 않는 한 다시 P0로 되돌리지 않습니다. 새 증거가 있으면 어떤 release gate를 깨는지 먼저 적고 재오픈합니다.

## 다음 작업 분해 예시

### v1.1.0 (3) 수면 UX와 공통 피드백

| 단계 | 작업 |
| --- | --- |
| 1 | 수면 시작/종료/중단/복구 화면의 버튼 상태와 disabled reason 조사 |
| 2 | navigation chrome 일관성 검토 |
| 3 | 오류/경고 문구가 의료 진단처럼 읽히지 않는지 확인 |
| 4 | UI validation script 실행 |
| 5 | 변경 문서와 screenshot 필요 여부 판단 |

추천 모델: 5.6 Terra  
추론 수준: 높음 (high)  
선정 근거: 다중 화면 UX state와 QA script가 포함되지만 개인정보/HealthKit 저장 계약을 직접 바꾸지 않는 작업입니다.

### v1.1.0 (4) Health/Fitdays 사용성 정리

| 단계 | 작업 |
| --- | --- |
| 1 | HealthKit 연결/권한/빈 데이터 상태 문구 정리 |
| 2 | source type/source name/import batch 표시 기준 확인 |
| 3 | Fitdays import 성공/skip/error summary 개선 |
| 4 | HealthKit read-only와 local-only import 금지선 테스트 |
| 5 | 실제 export 파일 QA 항목 업데이트 |

추천 모델: 5.6 Sol  
추론 수준: 높음 (high)  
선정 근거: 건강 데이터와 개인정보 경계가 직접 포함되며 App Store/privacy review 영향이 있습니다.

## Release candidate 전 체크

| Gate | 기준 |
| --- | --- |
| Build | iOS generic Debug build 성공 |
| Tests | 전체 `swift test --no-parallel` 성공 |
| Docs | README 링크, screenshot manifest, release approval scripts 성공 |
| Privacy | 서버/SDK/HealthKit write/개인 파일 commit 없음 |
| Medical copy | 진단/치료/확정적 인과 문구 없음 |
| Device QA | 장시간 기록, interruption, report/history/check-in 흐름 확인 |
| Evidence | 개인정보 제거된 release evidence 최신화 |

RC 판단은 단순 체크박스 작업이 아닙니다. 통과 로그, 남은 warning, 사용자 영향, 되돌리기 비용을 함께 보고 결정합니다.
