# 호흡정지 의심 구간 Sequence Detector

이 문서는 NightBreath / 밤숨의 `breathingPauseSuspected` 후보 생성 구조를 설명합니다. 이 기능은 수면 소리 이벤트 detector 개발용이며, 진단 목적의 의료 기능이 아닙니다.

## 목적

- 짧은 chunk 하나가 아니라 시간 흐름에서 breathing activity가 낮은 구간을 추적합니다.
- 낮은 활동이 일정 시간 이상 이어지고, 그 전후에 호흡/코골기 맥락과 회복 패턴이 함께 보일 때만 `호흡정지 의심 구간` 후보로 승격합니다.
- 환경 소음이나 움직임 의심 소리와 겹치면 confidence를 낮추거나 후보에서 제외합니다.
- 녹음 시간당 의심 구간 수는 개발용 요약값이며, 임상 지표 계산으로 사용하지 않습니다.

## 동작 요약

1. `BreathingActivityEstimator`가 각 `AudioFeatures`에서 `breathingActivityScore`를 계산합니다.
2. score가 낮거나 silence로 보이는 구간을 low activity로 표시합니다.
3. `SuspectedBreathingPauseSequenceDetector`가 low activity 구간을 시간순으로 묶습니다.
4. low activity가 기본 10초 이상 지속되면 우선 관찰 구간으로 기록합니다.
5. low activity 이전에 호흡 활동 또는 코골기 유사 맥락이 있어야 후보가 될 수 있습니다.
6. 후보 이후 짧은 시간 안에 `gaspLike`, `snore` 재개, 또는 호흡 활동 재개가 있어야 recovery pattern으로 봅니다.
7. 순수 silence나 낮은 에너지 소음만 지속되는 경우는 관찰/탈락 이유로 남기고 `호흡정지 의심 구간` 이벤트로 승격하지 않습니다.
8. `environmentalNoise` 또는 높은 estimated noise가 있으면 confidence를 낮추거나 후보에서 제외합니다.
9. 강한 `movementLike` overlap이 있으면 움직임 영향으로 confidence를 낮춥니다.

## 안전한 표현

앱과 문서는 항상 `호흡정지 의심 구간`으로 표현합니다. 결과는 오디오 기반 의심 패턴이며, 건강 상태를 확정하거나 조치 필요 여부를 말하지 않습니다.

사용자-facing 문구는 다음 원칙을 따릅니다.

- “오디오 기반 의심 패턴입니다.”
- “반복적으로 높게 나타나면 전문가 상담을 고려해보세요.”
- “이 앱은 진단 목적의 의료기기가 아닙니다.”

## 한계

- iPhone 마이크의 위치, 침구 마찰음, 선풍기/가습기/차량 소리 같은 환경 소음에 영향을 받습니다.
- 움직임이 큰 구간은 낮은 breathing activity처럼 보일 수 있어 confidence를 낮춥니다.
- 전체 밤 원본 오디오는 저장하지 않으며, 이벤트 오디오 샘플도 사용자가 opt-in한 경우에만 짧게 로컬 저장됩니다.
- HealthKit 데이터나 생체신호를 결합하지 않습니다.

## Diagnostics

`DetectorDiagnostics`에는 sequence detector 해석을 돕는 개발용 필드가 저장됩니다.

- `lowActivityCandidateCount`
- `lowActivityObservedCount`
- `lowActivityDurationTotal`
- `noiseContaminatedLowActivityCount`
- `recoveryPatternCount`
- `pauseCandidatesRejectedByNoise`
- `pauseCandidatesRejectedByDuration`
- `pauseCandidatesRejectedByNoRecovery`
- `pauseCandidatesRejectedByInsufficientContext`
- `pauseCandidatesRejectedByLikelySilence`
- `pauseCandidatesPromotedByGasp`
- `latestBreathingActivityScore`
- `latestLowActivityDurationSeconds`
- `latestRecoveryPatternDetected`
- `latestPauseCandidateConfidence`
- `latestPauseCandidateRejectedReason`

이 값은 detector tuning과 offline comparison을 위한 자료입니다.

## Offline Evaluation

manifest 기반 offline evaluation은 실제 오디오 파일을 repo에 넣지 않고 private/ignored manifest의 local path reference만 사용합니다.

예시:

```sh
swift run OfflineEvaluation --manifest Tools/OfflineEvaluation/sample_manifest.example.json --profiles balanced --output Tools/OfflineEvaluation/output
```

확인할 항목:

- 10초 미만 low activity가 후보에서 제외되는지
- 10초 이상 low activity가 후보가 될 수 있는지
- `gaspLike` 회복 후보 이후 confidence가 올라가는지
- `environmentalNoise` 또는 `movementLike` overlap에서 confidence가 낮아지는지
- 결과 문구가 의료적 판단처럼 읽히지 않는지

공개/개인 오디오 파일은 직접 준비하고, repo에는 커밋하지 않습니다.
