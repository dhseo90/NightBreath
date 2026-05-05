# Rule-based vs ML Comparison

이 문서는 NightBreath / 밤숨의 rule-based detector, Snore ML detector, hybrid backend를 같은 manifest segment에서 비교하는 방법을 정리합니다. 이 비교는 detector 개발과 회귀 확인용이며 의료 성능 검증이나 진단 목적의 결과가 아닙니다.

## 목적

- 같은 로컬 오디오 segment에서 backend별 event count와 confidence 차이를 확인합니다.
- rule-based가 너무 보수적인지, ML이 너무 민감한지 후보를 찾습니다.
- 실제 iPhone 반복 테스트 전에 detector 변경 영향 범위를 빠르게 확인합니다.
- hybrid fallback을 유지해야 하는 상황을 문서화합니다.

## 실행 방법

먼저 공개/개인 오디오 파일을 직접 로컬에 준비하고 manifest의 `localFilePath`를 수정합니다. 오디오 파일은 repository에 넣지 않습니다.

```bash
swift run OfflineBackendCompare \
  --manifest Tools/OfflineEvaluation/sample_manifest.example.json \
  --output Tools/OfflineEvaluation/output \
  --profile balanced
```

`OfflineEvaluation` 자체에서도 backend를 지정할 수 있습니다.

```bash
swift run OfflineEvaluation \
  --manifest Tools/OfflineEvaluation/sample_manifest.example.json \
  --output Tools/OfflineEvaluation/output \
  --profiles balanced \
  --backends ruleBased,coreML,hybrid
```

## Output

`OfflineBackendCompare`는 다음 파일을 만듭니다.

- `backend_comparison_YYYYMMDD_HHMMSS.json`
- `backend_comparison_YYYYMMDD_HHMMSS.csv`
- `backend_comparison_report.md`

주요 record 필드:

- `fileId`
- `segmentStartSeconds`
- `expectedLabels`
- `ruleBasedEventCountByType`
- `mlEventCountByType`
- `hybridEventCountByType`
- `ruleBasedConfidenceSummary`
- `mlConfidenceSummary`
- `hybridConfidenceSummary`
- `disagreementType`
- `possibleFalsePositiveBackend`
- `possibleFalseNegativeBackend`
- `zeroEventReasonByBackend`

## disagreementType

- `bothNoEvent`: rule-based와 ML 둘 다 최종 이벤트가 없습니다.
- `bothDetectedSnore`: rule-based와 ML 둘 다 snore를 감지했고 confidence 차이가 크지 않습니다.
- `ruleOnlySnore`: rule-based만 snore를 감지했습니다.
- `mlOnlySnore`: ML만 snore를 감지했습니다.
- `differentEventType`: 두 backend가 서로 다른 이벤트 타입을 만들었습니다.
- `confidenceGapLarge`: 두 backend 모두 후보를 만들었지만 평균 confidence 차이가 큽니다.

## 해석 기준

ML이 `silence`, `unknown`, `environmentalNoise` 중심 segment에서 snore를 자주 만들면 false-positive-like 증가 가능성을 먼저 봅니다.

rule-based가 `snore` expected segment에서 자주 0 event이면 threshold가 보수적이거나 smoothing 단계에서 후보가 사라지는지 확인합니다.

`mlOnlySnore`가 많고 quiet/noise segment의 false-positive-like가 적다면 ML 후보를 다음 iteration에서 더 자세히 볼 가치가 있습니다. 그래도 바로 기본값으로 바꾸지 않고 실제 iPhone 짧은 테스트와 함께 확인합니다.

## 2026-05-05 rule-based recall safeguard

실제 코골이 zero-event를 재현할 개인 샘플은 repository에 넣지 않았습니다. 대신 local-only synthetic/replay 경로에서 rule-based 병목을 확인했습니다.

- 기존 balanced RMS 0.050 경계에서는 낮은 진폭의 코골기 유사 sample이 feature 단계에서는 near-threshold로 보이지만 raw snore 후보가 0개가 될 수 있습니다.
- balanced RMS를 0.045로 작게 완화하되, RMS 0.050 미만 구간에는 low-band/ZCR/high-band/spectral centroid guard를 적용했습니다.
- rule-based smoothing과 report aggregation은 final snore event를 유지하는 regression test로 묶었습니다.
- quiet, low-energy noise, high-frequency negative는 snore로 승격되지 않아야 합니다.

ML backend를 비교할 때도 이 guard를 기준으로 `ruleOnlySnore`, `mlOnlySnore`, `bothNoEvent`를 해석합니다. ML이 low-amplitude snore-like segment만 보완하고 negative segment를 과하게 snore로 만들지 않는지 먼저 확인합니다.

## Hybrid를 유지해야 하는 경우

- Core ML 모델이 아직 앱 target에 없거나 optional 상태인 경우
- ML confidence가 낮거나 non-snore label을 반환하는 경우
- ML이 조용한 구간/환경 소음에서 너무 민감하게 반응하는 경우
- 공개 데이터와 개인 디버그 샘플 사이의 녹음 환경 차이가 큰 경우
- 실제 iPhone 마이크 위치, 백그라운드, 잠금 상태 테스트가 아직 부족한 경우

hybrid는 Core ML snore 결과를 사용할 수 있을 때만 우선하고, 모델 미설치/낮은 confidence/non-snore 결과에서는 rule-based fallback을 유지하는 안정 장치입니다.

## 한계

- Offline 비교는 실제 iPhone 마이크, 기기 배치, 백그라운드/잠금 상태, 배터리/발열 조건을 대체하지 못합니다.
- manifest label은 detector 개발용 참고 label입니다. 공개 데이터셋 label도 직접 확인해야 합니다.
- Core ML 모델 파일과 공개/개인 오디오 파일은 repository에 포함하지 않습니다.
- 서버/네트워크, HealthKit 실제 연동, 전체 밤 원본 오디오 저장 기능은 추가하지 않습니다.
