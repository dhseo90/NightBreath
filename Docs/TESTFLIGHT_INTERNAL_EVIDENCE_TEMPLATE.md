# TestFlight Internal Evidence Template

이 문서는 TestFlight 내부 테스트를 실제로 실행할 때 private QA note에 복사해 쓰는 템플릿입니다. 완료된 evidence는 repository에 커밋하지 않습니다. 실제 개인 건강 데이터, 실제 오디오 파일명, 실제 CSV/export 파일명, 실제 local path, 기기 serial은 기록하지 않습니다.

## Run Identity

| 항목 | 값 |
| --- | --- |
| evidence id |  |
| candidate commit hash |  |
| branch |  |
| build number |  |
| TestFlight build version |  |
| tester |  |
| device model |  |
| iOS version |  |
| install source | TestFlight |
| started at |  |
| ended at |  |

## Local Preflight

| Gate | Result | Notes |
| --- | --- | --- |
| `git status --short` checked | pass / fail |  |
| `git diff --check` | pass / fail |  |
| `swift test --no-parallel` | pass / fail |  |
| iOS Debug/Release build | pass / fail |  |
| `Tools/Release/audit_release_copy.sh` | pass / fail |  |
| screenshot manifest/export gates | pass / fail |  |
| App Store Connect preview runbook checked | pass / fail / not run |  |

## Flow Evidence

| Flow | Result | Evidence to record privately |
| --- | --- | --- |
| install and first launch | pass / fail | app name, onboarding privacy copy, no first-launch HealthKit prompt |
| foreground stop smoke | pass / fail | stop timing fields and whether audio chunks stop after stop request |
| double stop tap | pass / fail | duplicate report/crash 여부 |
| lock/background short stop | pass / fail / not run | lock state, stop behavior, crash 여부 |
| zero-event diagnostics | pass / fail | raw candidate, reject reason, final event count summary |
| event audio opt-in default off | pass / fail | default state, no new snippet when off |
| HealthKit read-only flow | pass / fail / not run | read permission only, no write prompt |
| Fitdays local import fallback | pass / fail / not run | local file/manual fallback only, no server/API path |
| Daily Health Card export/share | pass / fail | explicit image/share/save action only, no local path in UI |

## Stop And Detector Fields

```text
stopButtonTappedAt:
captureStopStartedAt:
inputTapRemovedAt:
audioEngineStoppedAt:
audioSessionDeactivatedAt:
lastAudioChunkReceivedAt:
chunksReceivedAfterStopRequest:
receivedAudioDurationAfterStop:
rawCandidateCountByType:
postSmoothingEventCountByType:
finalEventCountByType:
topRejectReason:
RMS/energy p90:
```

## Redaction Checklist

| Check | Result |
| --- | --- |
| sensitive data included in repo | No |
| real personal audio committed | No |
| real personal CSV committed | No |
| real local path included in screenshot/docs | No |
| server/network code added | No |
| HealthKit write observed | No |
| diagnosis wording observed | No |

## Blocking Decision

| 항목 | 값 |
| --- | --- |
| blocker found | yes / no |
| blocker severity | P0 / P1 / P2 / P3 / none |
| blocking issue id |  |
| release decision | continue / hold |
| follow-up owner |  |
| notes |  |

