# Next Issues

이 문서는 NightBreath / 밤숨의 다음 작업 후보를 정리합니다.

## 우선순위 후보

1. Daily Rhythm 도메인 모델 설계
2. Mock Health Data 구조 정리
3. Daily Rhythm Score 계산기 초안
4. Morning Brief 화면 설계
5. Daily Health Card UI 초안
6. 혈압/체성분 대시보드 mock data polish
7. 수면 지표와 건강 지표 교차 분석 문구 점검
8. 공개 데이터 manifest 작성
9. snore detector Offline Evaluation 실행
10. 실제 iPhone background smoke test
11. 잠금 30분 테스트
12. overnight test

## Daily Rhythm

수면 소리 리포트를 유지하면서 온디바이스 개인 건강 리듬 리포트로 확장하기 위한 다음 작업 후보입니다.

- `DailyRhythmReport` 도메인 모델
- `DailyRhythmScore` 계산기
- 아침 리포트와 하루 리듬 카드의 데이터 계약
- Mock Health Data seed 구조
- 아침/저녁 컨디션 체크인 확장
- 데이터 품질과 권한 제한 상태 모델
- 건강 대시보드와 Daily Rhythm 카드의 navigation 연결
- 수면 지표와 건강 지표 교차 분석의 안전한 문구

주의:

- 실제 HealthKit 권한 요청과 `HKHealthStore` query는 이번 단계에서 추가하지 않습니다.
- HealthKit 실제 연동 전에는 mock service/protocol 기반으로 설계합니다.
- 오늘의 리듬 점수는 웰니스/개인 참고용이며 의료 점수가 아닙니다.
- 수면 소리와 건강 지표 사이의 인과관계를 주장하지 않습니다.

## Detector / ML

- 공개 또는 로컬 데이터셋 manifest 작성
- snore / non-snore labeled segment 정리
- Offline Evaluation으로 conservative / balanced / sensitive profile 비교
- false-positive-like / false-negative-like segment 검토
- tuning report 기반 threshold 후보 정리
- Core ML 변환 결과를 앱 target에 추가하는 절차 검증
- Rule-based와 Core ML backend 비교 DEBUG UI 보강

주의:

- 모델 성능을 확정적으로 표현하지 않습니다.
- 공개/개인 오디오 파일을 repo에 포함하지 않습니다.
- threshold 변경은 자동 적용하지 않고 수동 검토합니다.

## Simulator-first QA

- Simulator QA scenario별 수동 화면 확인
- zero-event scenario 문구 검토
- low coverage scenario 문구 검토
- 이벤트 오디오 저장 ON/OFF 상태 확인
- orphan sample cleanup UI 확인
- Dynamic Type에서 주요 텍스트가 깨지지 않는지 확인

## 실제 iPhone QA

- foreground 1분 smoke test
- 화면 잠금 3분 smoke test
- 앱 백그라운드 3분 smoke test
- 잠금 30분 테스트
- 충전 상태 overnight test
- 이벤트 오디오 샘플 opt-in ON/OFF 각각 확인
- 배터리/발열 확인

## 개인정보 / 저장소

- 긴 세션 후 이벤트 오디오 저장 용량 확인
- orphan cleanup 반복 실행 확인
- 전체 이벤트 오디오 샘플 삭제 확인
- 전체 로컬 수면 데이터 삭제 확인
- 앱 재설치/업데이트 후 저장소 migration 필요성 검토

## Health Dashboard / HealthKit

건강 대시보드는 Daily Rhythm 확장의 상세 보기로 다룹니다. 먼저 mock/protocol 기반으로 혈압, 체중, 체성분, 활동, 컨디션 데이터를 표시하고, 실제 HealthKit read-only 연동은 나중 단계의 별도 작업으로 둡니다.

다음 확인 항목:

- Daily Rhythm mock data source 구조
- 권한 없음/일부 허용/데이터 없음 상태 문구
- Omron Connect 혈압 source mock 표시
- Fitdays 체중/체성분 source mock 표시
- 교차 보기에서 matched sample 부족 안내 확인
- HealthKit read-only 연동 설계 문서화
- HealthKit 실제 구현 단계에서 쓰기 API가 없는지 재점검

## 문서 유지보수

- `README.md` 최신화
- `Docs/CURRENT_STATUS.md` 업데이트
- `Docs/DEVELOPMENT_WORKFLOW.md` 업데이트
- `Docs/REAL_DEVICE_REQUIRED_TESTS.md` 업데이트
- `QA_CHECKLIST.md` 업데이트
