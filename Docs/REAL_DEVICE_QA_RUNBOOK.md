# Real Device QA Runbook

이 문서는 실제 iPhone에서만 확인할 수 있는 smoke test 결과를 같은 형식으로 기록하기 위한 runbook입니다. Codex가 이 테스트를 자동 실행하지 않습니다. 사용자가 실제 기기에서 관찰한 결과를 전달하면, 아래 template 기준으로 원인 분류와 후속 이슈를 정리합니다.

## 기록 원칙

- 실제 개인 오디오 파일, 실제 CSV/export 파일, 실제 local path, 실제 파일명은 repository에 기록하지 않습니다.
- sleep talk 내용은 메모에 적거나 텍스트로 변환하지 않습니다.
- 실제 건강 수치가 필요한 경우에도 private QA note에만 남기고 repository에는 범위/상태만 기록합니다.
- TestFlight build, commit hash, device model, iOS version은 재현에 필요한 범위에서만 기록합니다.
- 결과 문구는 측정 품질, detector 동작, privacy/storage 정책 중심으로 기록하고 건강 상태를 단정하지 않습니다.

## Smoke Test Set

### 1. Foreground stop smoke

- 수면 시작 후 30초 대기합니다.
- 수면 종료를 탭합니다.
- 1~2초 안에 실제 오디오 수신 시간이 멈추는지 확인합니다.
- 리포트 생성이 계속 진행되더라도 capture 상태가 먼저 종료되는지 확인합니다.

### 2. Double stop tap

- 수면 시작 후 수면 종료 버튼을 빠르게 여러 번 탭합니다.
- duplicate report, crash, stuck state가 없는지 확인합니다.

### 3. Lock/background short stop

- 수면 시작 후 화면 잠금 또는 background 상태로 3분 둡니다.
- 앱 복귀 후 수면 종료를 탭합니다.
- stop 이후 received audio duration이 증가하지 않는지 확인합니다.

### 4. Snore signal smoke

- 실제 코골기처럼 들리는 짧은 상황 또는 명확한 코골기 유사 소리로 30~60초 측정합니다.
- final event가 있으면 timeline/report aggregation까지 표시되는지 확인합니다.
- final event가 0개여도 raw candidate, reject reason, smoothing count, RMS/energy summary가 남는지 확인합니다.

### 5. Zero-event explanation

- 이벤트 0개 리포트에서 no audio, no raw candidate, smoothing dropped, conservative threshold, backend fallback 중 하나로 설명되는지 확인합니다.
- “감지 기준을 통과한 이벤트가 없었습니다”처럼 안전한 설명인지 확인합니다.

## Result Template

```text
Real-device smoke result

commit hash:
build number:
install source: Xcode / TestFlight
device model:
iOS version:
build configuration:
test started at:
test ended at:

Foreground stop smoke: pass / fail / not run
Double stop tap: pass / fail / not run
Lock/background short stop: pass / fail / not run
Snore signal smoke: pass / fail / not run
Zero-event explanation: pass / fail / not run

Stop diagnostics:
stopButtonTappedAt:
stopRequestedAt:
captureStopStartedAt:
inputTapRemovedAt:
audioEngineStoppedAt:
audioSessionDeactivatedAt:
captureTaskCancelledAt:
lastAudioChunkReceivedAt:
chunksReceivedAfterStopRequest:
secondsReceivingAudioAfterStopRequest:
receivedAudioDurationBeforeStop:
receivedAudioDurationAfterStop:
forceStopTriggered:
forceStopReason:

Report/finalization diagnostics:
analyzerFinalizeStartedAt:
analyzerFinalizeFinishedAt:
reportGenerationStartedAt:
reportGenerationFinishedAt:
duplicateReportObserved:

Detector diagnostics:
audioChunkCount:
analyzedChunkCount:
rawCandidateCountByType:
preSmoothingCandidateCountByType:
postSmoothingEventCountByType:
finalEventCountByType:
snoreRawCandidateCount:
snoreRejectReasonTop:
rejectReasonCounts top 3:
rmsP90:
energyP90:
lowBandEnergyP90:
zeroCrossingRateP50:
spectralCentroidP50:
thresholdSnapshot profile:
activeDetectorBackend:
fallbackUsed:

Privacy/storage checks:
full-night raw audio observed: No
event audio opt-in default off: pass / fail
event snippet stored only after opt-in: pass / fail / not run
real personal audio committed: No
real personal CSV committed: No
server/network transfer observed: No
HealthKit write observed: No
diagnosis wording observed: No

Notes:
blocking issue:
next action:
```

## Overnight Gate

- Foreground stop smoke가 실패하면 overnight 측정을 진행하지 않습니다.
- Lock/background short stop에서 stop 이후 audio received time이 증가하면 overnight 측정을 진행하지 않습니다.
- Double stop tap에서 duplicate report나 crash가 있으면 overnight 측정을 진행하지 않습니다.
- Snore signal smoke에서 raw/reject diagnostics가 전혀 없으면 detector tuning 판단을 보류합니다.
- 전체 밤 원본 오디오 저장, HealthKit write, 서버/네트워크 전송, 의료 진단처럼 읽히는 문구가 관찰되면 배포를 보류합니다.

## Feedback Intake

사용자가 실제 iPhone 피드백을 전달하면 아래 순서로 분류합니다.

1. capture lifecycle 문제인지 확인합니다.
2. analyzer/report finalization 지연인지 확인합니다.
3. detector feature/raw/smoothing/final/report/UI 중 어느 단계에서 사라졌는지 확인합니다.
4. privacy/storage 정책 회귀가 있는지 확인합니다.
5. 실기기에서만 재현되는 AVAudioSession/background 문제는 별도 P0/P1 이슈로 분리합니다.
