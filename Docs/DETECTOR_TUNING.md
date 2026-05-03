# Detector Tuning Guide

이 문서는 NightBreath / 밤숨의 rule-based detector threshold/profile을 Offline Evaluation 결과로 비교하고, 수동 검토용 변경 후보를 만드는 절차를 설명합니다.

## 원칙

- threshold는 자동으로 변경하지 않습니다.
- `suggested_changes.json`은 수동 검토용입니다.
- false positive-like 이벤트가 늘어날 위험을 항상 함께 봅니다.
- 공개/개인 오디오 파일은 repo에 넣지 않습니다.
- 서버 전송, 클라우드 처리, 외부 API 호출은 사용하지 않습니다.
- 이 비교는 detector 개발용이며 의학적 성능 검증이 아닙니다.

## 1. Offline Evaluation 실행

먼저 manifest에 정의된 로컬 오디오 segment를 profile별로 평가합니다.

```bash
swift run OfflineEvaluation \
  --manifest Tools/OfflineEvaluation/sample_manifest.example.json \
  --output Tools/OfflineEvaluation/output \
  --profiles conservative,balanced,sensitive
```

결과는 다음 위치에 생성됩니다.

- `Tools/OfflineEvaluation/output/offline_evaluation_YYYYMMDD_HHMMSS.json`
- `Tools/OfflineEvaluation/output/offline_evaluation_YYYYMMDD_HHMMSS.csv`

`output/`은 gitignore 대상입니다.

## 2. Profile 비교 실행

생성된 JSON을 입력으로 profile 비교 도구를 실행합니다.

```bash
swift run OfflineProfileCompare \
  --input Tools/OfflineEvaluation/output/offline_evaluation_YYYYMMDD_HHMMSS.json \
  --output Tools/OfflineEvaluation/output
```

여러 evaluation 결과를 합쳐 비교할 수도 있습니다.

```bash
swift run OfflineProfileCompare \
  --inputs file1.json,file2.json \
  --output Tools/OfflineEvaluation/output
```

생성 파일:

- `Tools/OfflineEvaluation/output/tuning_report.md`
- `Tools/OfflineEvaluation/output/suggested_changes.json`

## 3. 비교 항목

profile별로 다음 값을 비교합니다.

- total evaluated segments
- raw candidate count
- pre-smoothing candidate count
- post-smoothing event count
- final event count by type
- zero-event count
- top reject reasons
- average confidence
- possible false-positive-like cases
- possible false-negative-like cases

## 4. expectedLabels 기반 mismatch 해석

manifest에 `expectedLabels`가 있으면 도구가 간단한 mismatch 후보를 표시합니다.

- expected label에 `snore`가 있는데 최종 `snore` 이벤트가 없으면 possible false-negative-like로 표시합니다.
- expected label이 `unknown`, `silence`, `quiet` 계열인데 이벤트가 생성되면 possible false-positive-like로 표시합니다.

이 값은 개발용 참고 지표입니다. 데이터셋 라벨 품질과 iPhone 마이크 특성 차이를 함께 봐야 합니다.

## 5. Threshold 제안 방식

도구는 다음과 같은 경우 수동 검토 후보를 만듭니다.

- balanced에서 zero-event가 많고 expected event가 누락되는 경우
- sensitive에서 후보는 늘지만 quiet/unknown segment 이벤트가 과도하게 늘어나는 경우
- conservative에서 raw 후보가 거의 없고 zero-event가 많은 경우

제안 파일에는 다음이 포함됩니다.

- profile
- thresholdName
- currentValue
- suggestedDirection
- reason
- falsePositiveRisk

중요: 이 파일은 코드에 자동 반영되지 않습니다. `DetectorThresholdConfiguration` 값은 개발자가 직접 검토한 뒤 별도 변경해야 합니다.

## 6. 실제 iPhone 검증이 필요한 항목

Offline Evaluation은 detector 변경 전후 비교에 유용하지만 아래 항목은 대체하지 못합니다.

- 실제 iPhone 마이크 입력
- 화면 잠금 상태 오디오 수신
- 앱 백그라운드 상태 오디오 수신
- 배터리와 발열
- 전화/알림/interruption
- 기기 배치와 침대 주변 환경
- overnight 안정성

threshold 후보를 Release 기본값으로 바꾸기 전에는 짧은 foreground 테스트, 잠금 3분 테스트, 백그라운드 3분 테스트, overnight 테스트 순서로 확인합니다.

## 7. 권장 반복 흐름

1. labeled segment를 manifest에 추가합니다.
2. `OfflineEvaluation`을 conservative/balanced/sensitive로 실행합니다.
3. `OfflineProfileCompare`로 `tuning_report.md`와 `suggested_changes.json`을 생성합니다.
4. possible false-positive-like와 possible false-negative-like를 함께 확인합니다.
5. 작은 threshold 변경 후보만 수동으로 검토합니다.
6. synthetic regression test와 Offline Evaluation을 다시 실행합니다.
7. 실제 iPhone에서 짧은 테스트 후 overnight 테스트로 넘어갑니다.
