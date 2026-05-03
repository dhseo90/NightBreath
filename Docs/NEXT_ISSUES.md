# Next Issues

이 문서는 NightBreath / 밤숨의 다음 작업 후보를 정리합니다.

## 우선순위 후보

1. 공개 데이터 manifest 작성
2. snore detector Offline Evaluation 실행
3. profile tuning report 생성
4. threshold 변경 후보 수동 검토
5. Core ML 모델 실제 적용 준비
6. 실제 iPhone background smoke test
7. 잠금 30분 테스트
8. overnight test

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

## Health Dashboard 방향

V1에서는 HealthKit 실제 연동을 하지 않습니다.

향후 별도 이슈로 설계할 항목:

- Health dashboard 정보 구조
- 혈압/체중/체성분 카드 UI
- Apple 건강앱 권한 요청 UX
- 건강 데이터 source 표시
- 수면 소리 리포트와 건강 지표를 한 화면에서 비교하는 방식

## 문서 유지보수

- `README.md` 최신화
- `Docs/CURRENT_STATUS.md` 업데이트
- `Docs/DEVELOPMENT_WORKFLOW.md` 업데이트
- `Docs/REAL_DEVICE_REQUIRED_TESTS.md` 업데이트
- `QA_CHECKLIST.md` 업데이트
