# NightBreath v1.1.0 Roadmap

기준일: 2026-05-12

v1.1.0은 v1.0.0 공개 기준점 위에서 진행하는 실사용 안정화와 기능 보강 버전입니다. 핵심 목표는 새 기능을 많이 늘리는 것보다, 실제 iPhone에서 밤새 켜두고 믿을 수 있는 수면 기록 경험을 만드는 것입니다.

## 기준점

- v1.0.0은 공개 가능한 baseline으로 유지합니다.
- v1.1.0 개발은 v1.0.0과 같은 최신 main 기준점에서 시작합니다.
- v1.1.0의 우선순위는 실제 iPhone 안정성, 수면 종료/복구 UX, 기록 신뢰도, Health/Fitdays 사용성 정리입니다.

## 제품 원칙

- 모든 리포트와 점수는 개인 패턴을 살펴보기 위한 웰니스 참고용 보기입니다.
- 수면 소리 이벤트, 건강 데이터, 컨디션 기록 사이의 원인과 결과를 단정하지 않습니다.
- HealthKit은 read-only로 유지합니다.
- Fitdays는 사용자가 직접 선택하거나 붙여넣은 local import만 지원합니다.
- 서버 업로드, 클라우드 처리, 외부 API, 광고 SDK, 계정 시스템은 추가하지 않습니다.
- 전체 밤 원본 오디오는 기본 저장하지 않습니다.
- 이벤트 오디오 샘플은 opt-in 상태에서만 짧은 로컬 샘플로 저장합니다.

## P0 안정화

| 항목 | 목표 | 확인 방법 |
| --- | --- | --- |
| 수면 종료 지연 개선 | 종료 버튼 후 멈춘 것처럼 보이지 않게 finalizing 상태와 버튼 disabled 상태를 명확히 표시 | simulator smoke, 실제 iPhone foreground stop |
| background / lock / overnight 안정성 | 잠금, 백그라운드, 충전 상태 장시간 기록에서 세션이 사라지지 않게 유지 | 실제 iPhone lock/background/overnight QA |
| interruption 기록 정확도 | AVAudioSession interruption, capture error, coverage 저하 원인이 리포트와 diagnostics에 일관되게 남음 | unit test, 실제 iPhone logs |
| 장시간 세션 리포트 품질 | 4~8시간 세션에서 측정 품질과 안내 문구가 실제 기록 상태와 맞음 | 실제 sleep-data review, report UI QA |
| 앱 재실행 복구 | 수면 중 앱이 종료되거나 재실행됐을 때 세션 상태를 복구하거나 안전하게 정리 | simulator lifecycle smoke, 실제 iPhone 재실행 QA |
| 배터리/발열/CPU 점검 | 밤새 사용 가능한 수준의 리소스 사용인지 확인 | 실제 iPhone overnight, 필요 시 Instruments |

## P1 UX 개선

| 항목 | 목표 | 확인 방법 |
| --- | --- | --- |
| 수면 시작 화면 재배치 | 첫 화면에서 수면 시작 버튼이 바로 보이고, 최근 결과와 역할이 충돌하지 않음 | simulator screenshot QA, 실제 iPhone visual QA |
| 수면 종료 UX | 종료 중 상태, 재탭 방지, 완료/실패 메시지를 명확히 표시 | foreground stop smoke |
| 건강 데이터 새로고침 피드백 | 눌림, 진행 중, 완료, 실패 상태를 사용자가 바로 이해할 수 있음 | simulator + 실제 HealthKit permission QA |
| 공통 버튼 피드백 | 저장, 삭제, 가져오기, 비우기, 미리보기 계열 버튼의 pressed/loading/done/error 상태 통일 | 주요 flow smoke |
| Fitdays import UX | 붙여넣기, 미리보기, 저장, 비우기 흐름을 가까운 위치와 명확한 상태 문구로 정리 | synthetic fixture, 실제 Fitdays redacted QA |
| navigation chrome 유지 | root tab은 tab bar, detail은 back chevron과 hidden tab bar 정책 유지 | `Tools/UI/validate_navigation_chrome.sh` |

## P1 수면 리포트 보강

| 항목 | 목표 | 확인 방법 |
| --- | --- | --- |
| 수면 세션 히스토리 | 과거 수면 기록을 날짜별로 다시 볼 수 있음 | unit/UI smoke |
| 세션 상세 화면 | 이벤트, 측정 품질, coverage, interruption 요약을 한 화면에서 확인 | simulator scenario, 실제 세션 review |
| 짧은/긴 세션 문구 분리 | 측정 시간이 짧은 경우와 coverage/interruption 문제가 있는 경우를 분리해 설명 | report builder tests |
| 이벤트 오디오 관리 개선 | opt-in 상태, 저장 개수, 저장 용량, 개별/전체 삭제 UX를 명확히 표시 | simulator + 실제 iPhone audio snippet QA |
| 아침 체크인 연결 | 수면 리포트와 아침 컨디션 기록이 자연스럽게 이어짐 | flow smoke |

## P2 기능 확장

| 항목 | 목표 | 확인 방법 |
| --- | --- | --- |
| 수면 추세 카드 | 최근 7일/14일 수면 소리 점수와 측정 품질 추세를 표시 | mock/synthetic tests |
| Daily Rhythm 카드 v1.1 | 수면, 건강, 컨디션을 참고용 하루 리듬으로 요약 | simulator scenario |
| 건강 데이터 상태 표현 | 권한 없음, 데이터 없음, 일부 허용, 최신 데이터 있음 상태를 분리 | HealthKit mock + 실제 permission QA |
| source 표시 정리 | HealthKit, Fitdays CSV, mock/debug 출처를 사용자에게 오해 없이 표시 | UI screenshot QA |
| Fitdays import history | import batch 목록, 삭제, 재검토 흐름 제공 | parser/storage tests |
| 데이터 품질 설명 | 부족한 데이터는 부족하다고 표시하고 과장된 점수화를 피함 | copy review, UI QA |

## 테스트 및 자동화

| 항목 | 목표 |
| --- | --- |
| 수면 기록 unit test 확대 | interruption, partial coverage, crash recovery, report generation 회귀 방지 |
| clean simulator smoke 유지 | 완전 초기화 상태 첫 실행, 수면 시작, 리포트 빈 상태, 주요 scenario 확인 |
| 주요 flow smoke 확대 | Home/Sleep/Health/Settings 주요 CTA 도달성 확인 |
| release guardrail 유지 | forbidden wording, artifact, license, screenshot manifest 검사 |
| UI screenshot 품질 관리 | README/App Store/debug/internal screenshot 상태 분리 |
| 실기기 QA 체크리스트 유지 | 사용자가 밤샘 테스트할 때 볼 항목과 기록 양식을 고정 |

필수 로컬 gate:

```bash
git diff --check
Tools/Docs/validate_readme_links.sh
Tools/UI/validate_navigation_chrome.sh
Tools/Screenshots/validate_screenshot_manifest.sh
Tools/Screenshots/validate_app_store_release_approval.sh
Tools/Release/audit_tracked_artifacts.sh
```

수면 capture 또는 report logic 변경 시 Swift tests와 iOS Debug build를 추가로 실행합니다.

## 문서 및 공개 repo 정리

| 항목 | 목표 |
| --- | --- |
| README 유지 | 현재 기능 범위와 v1.1.0 방향을 과장 없이 유지 |
| 실제 iPhone QA 문서 | overnight, background, HealthKit, Fitdays 확인 방법 최신화 |
| Privacy 문구 재점검 | on-device, no cloud/server, HealthKit read-only를 일관되게 설명 |
| Third-party/license 유지 | mixed license, ESC-50/ESC-10, dependency notice 최신화 |
| Release evidence 정리 | v1.1.0 QA 결과를 release checklist에서 추적 가능하게 유지 |

## 완료 기준

v1.1.0은 아래 기준을 만족할 때 release candidate로 볼 수 있습니다.

1. 실제 iPhone에서 수면 시작/종료가 안정적으로 동작합니다.
2. 밤샘 테스트에서 앱이 죽거나 기록이 사라지지 않습니다.
3. 수면 종료 후 finalizing 상태가 명확하고, 멈춘 것처럼 보이지 않습니다.
4. 측정 품질, interruption, coverage가 리포트와 logs에 일관되게 남습니다.
5. 건강 데이터 새로고침, 가져오기, 저장, 삭제 버튼이 상태 피드백을 제공합니다.
6. HealthKit read-only, Fitdays local import, 이벤트 오디오 opt-in local snippet 원칙을 유지합니다.
7. simulator clean-state smoke, unit test, release guardrail이 통과합니다.
8. README와 공개 문서가 현재 기능 범위를 과장하지 않습니다.

## 고정 진행 순서

v1.1.0 개발은 아래 순서로만 진행합니다. 한 단계를 닫은 뒤에는 같은 주제로 돌아가지 않고, 새로 발견한 개선 아이디어는 후속 이슈 또는 다음 버전 후보로 넘깁니다. 단, crash, data loss, HealthKit write, 전체 밤 원본 오디오 저장, 서버/네트워크 전송, 의료 진단 문구처럼 release-blocking 안전 회귀가 발견되면 현재 단계의 blocker fix로만 처리합니다.

| 순서 | 범주 | 포함 항목 | 닫는 기준 |
| --- | --- | --- | --- |
| 1 | 수면 기록 P0 안정화 | 수면 종료 지연, finalizing 상태, double stop 방지, lock/background/overnight 기록 유지, interruption logs, 앱 재실행 복구, 배터리/발열/CPU 점검 | foreground stop, lock/background smoke, overnight gate가 release-blocking 이슈 없이 통과 |
| 2 | 수면 리포트 신뢰도 | 4~8시간 세션 리포트 품질, coverage/interruption 요약, 짧은/긴 세션 문구 분리, 세션 상세, 수면 세션 히스토리, 아침 체크인 연결 | report builder/unit test, simulator UI smoke, 실제 세션 review 기준 통과 |
| 3 | 수면 UX와 공통 피드백 | 수면 시작 화면 재배치, 수면 종료 UX, 저장/삭제/가져오기/비우기/미리보기 버튼 상태, navigation chrome 유지 | screenshot QA, 주요 flow smoke, `Tools/UI/validate_navigation_chrome.sh` 통과 |
| 4 | Health/Fitdays 사용성 정리 | 건강 데이터 새로고침 피드백, 권한 없음/일부 허용/데이터 없음/최신 데이터 상태, source 표시, Fitdays 붙여넣기/미리보기/저장/비우기/import history | HealthKit mock/permission QA, Fitdays synthetic fixture, 실제 redacted QA 기준 통과 |
| 5 | Daily Rhythm v1.1 보강 | 수면 추세 카드, Daily Rhythm 카드 v1.1, 데이터 품질 설명, 부족한 데이터 제한 표시, 인과관계 금지 copy 유지 | Daily Rhythm tests, simulator scenario, copy review 통과 |
| 6 | 검증 자동화와 실기기 QA | 수면 기록 unit test 확대, clean simulator smoke, 주요 CTA smoke, release guardrail, UI screenshot 품질 관리, 실기기 QA 체크리스트 | 필수 로컬 gate와 필요한 Swift tests/iOS Debug build 통과, private 실기기 evidence 정리 |
| 7 | 문서와 release evidence 정리 | README 유지, 실제 iPhone QA 문서 최신화, Privacy 문구 재점검, license/dependency notice 유지, screenshot/release evidence 정리 | README link gate, screenshot manifest/release approval gate, 공개 문서 범위 검토 통과 |
| 8 | v1.1.0 release candidate 결정 | 1~7 단계 결과를 기준으로 남은 blocker 여부 확인 | 완료 기준 8개를 만족하고 RC 후보로 고정 |
