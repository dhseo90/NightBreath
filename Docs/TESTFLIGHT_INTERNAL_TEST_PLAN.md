# TestFlight Internal Test Plan

이 문서는 NightBreath / 밤숨을 TestFlight 내부 테스트로 배포하기 전후에 확인할 최소 기준입니다. 실제 테스트 실행 기록은 private QA note에 남기고, repository에는 실제 개인 건강 데이터, 실제 오디오 파일, 실제 CSV/export 파일, 실제 local path를 남기지 않습니다. 실행용 빈 evidence template은 `Docs/TESTFLIGHT_INTERNAL_EVIDENCE_TEMPLATE.md`에 두고, `Tools/Release/prepare_testflight_evidence.sh`로 repository 밖 private draft를 만들 수 있습니다.

## 목적

- 내부 테스터가 같은 기준으로 build sanity와 주요 user flow를 확인합니다.
- P0 stop capture, detector zero-event diagnostics, 개인정보/저장소 정책을 TestFlight 전에 다시 확인합니다.
- 실패 시 release blocking 여부와 재현 정보를 빠르게 분리합니다.

## 사전 조건

- `git diff --check` 통과
- `swift test --no-parallel` 통과
- iOS Debug generic build 통과
- TestFlight 후보 commit hash와 build number 확인
- App Store screenshot/copy는 mock/synthetic data 기반만 사용
- 실제 iPhone smoke test는 `Docs/QA_GUIDE.md`와 `Docs/REAL_DEVICE_QA_RUNBOOK.md` 기준으로 별도 실행
- private evidence draft는 `Tools/Release/prepare_testflight_evidence.sh`로 repository 밖에 생성

## 내부 테스트 범위

### 1. 설치 / 첫 실행

- TestFlight 설치와 첫 실행이 성공한다.
- 앱 표시 이름이 `밤숨`으로 보인다.
- onboarding에서 온디바이스 분석, 서버 전송 없음, 전체 밤 원본 오디오 미저장 원칙이 보인다.
- 앱 첫 실행만으로 HealthKit 권한 요청이 뜨지 않는다.

### 2. 수면 시작 / 종료 smoke

- `수면 시작` 후 마이크 권한 흐름이 자연스럽다.
- `수면 종료` 탭 후 1~2초 안에 실제 오디오 수신 시간이 증가하지 않는다.
- 리포트 정리가 늦어도 화면은 캡처 중단 완료와 리포트 생성 중 상태를 구분한다.
- 빠른 double stop tap에서 duplicate report나 crash가 없다.

### 3. Detector zero-event / snore smoke

- 실제 코골기 유사 소리 또는 synthetic/debug sample에서 raw candidate count와 reject reason이 남는다.
- 이벤트가 0개여도 no audio, no raw candidate, smoothing dropped, conservative threshold 중 하나로 설명된다.
- user-facing copy는 “감지 기준을 통과한 이벤트가 없었습니다” 수준으로 유지하고 건강 상태를 단정하지 않는다.

### 4. Event audio snippet policy

- 이벤트 오디오 샘플 저장 기본값은 꺼짐이다.
- opt-in이 꺼져 있으면 새 이벤트 오디오 샘플이 저장되지 않는다.
- opt-in을 켠 경우에도 짧은 이벤트 전후 샘플만 로컬에 저장된다.
- 세션당 개수 제한과 폴더 용량 제한을 넘는 새 샘플은 저장되지 않는다.
- 전체 밤 원본 오디오 파일이 생성되지 않는다.

### 5. Health / Daily Rhythm

- 건강 데이터 대시보드에서 사용자가 연결 버튼을 누를 때만 HealthKit read 권한 흐름이 시작된다.
- HealthKit write 항목은 표시되지 않는다.
- 권한 거부, 일부 허용, 데이터 없음 상태가 crash 없이 표시된다.
- 오늘의 리듬 점수와 하루 리듬 카드는 개인 참고용 표현을 유지한다.

### 6. Fitdays local import

- Fitdays CSV/export 파일은 사용자가 직접 선택한 로컬 파일만 처리한다.
- Fitdays 서버/API, 자동 동기화, 비공식 연결 방식으로 이어지지 않는다.
- export 메뉴가 보이지 않으면 Apple 건강앱 read-only 표준 지표만 사용한다.
- 실제 개인 CSV 파일명, 경로, 수치는 repository와 screenshot에 남기지 않는다.

### 7. Daily Health Card export/share

- 이미지 생성과 시스템 share sheet는 사용자 명시 액션으로만 시작된다.
- export/share 파일명이나 local path가 일반 UI 또는 screenshot에 노출되지 않는다.
- privacy level별 표시 항목이 의도와 맞는다.
- 서버 업로드나 외부 SDK 공유 흐름이 없다.

## Blocking gate

- 수면 종료 후 실제 오디오 수신 시간이 계속 증가하면 TestFlight 확대 배포를 중단합니다.
- double stop tap에서 duplicate report나 crash가 있으면 중단합니다.
- 이벤트 0개 세션에서 raw/reject diagnostics가 전혀 남지 않으면 detector 판단을 보류합니다.
- HealthKit write 요청이 보이면 중단합니다.
- 전체 밤 원본 오디오 저장 파일이 생기면 중단합니다.
- 서버/네트워크/외부 SDK 호출이 발견되면 중단합니다.
- 의료 진단처럼 읽히는 copy가 있으면 수정 전 배포하지 않습니다.

## Evidence Template

실제 실행 시에는 아래 inline template 대신 `Docs/TESTFLIGHT_INTERNAL_EVIDENCE_TEMPLATE.md`를 private QA note에 복사하거나 `Tools/Release/prepare_testflight_evidence.sh`가 만든 private draft를 사용합니다.

```text
TestFlight internal test evidence

commit hash:
build number:
tester:
device model:
iOS version:
build configuration:
test started at:
test ended at:

install/launch: pass / fail
onboarding privacy copy: pass / fail
foreground stop smoke: pass / fail
double stop tap: pass / fail
lock/background short stop: pass / fail / not run
zero-event diagnostics present: pass / fail
snore-like smoke raw candidate/reject reason present: pass / fail / not run
event audio opt-in default off: pass / fail
HealthKit read-only permission flow: pass / fail / not run
Fitdays local import fallback: pass / fail / not run
Daily Health Card export/share explicit action: pass / fail

stopButtonTappedAt:
captureStopStartedAt:
audioEngineStoppedAt:
lastAudioChunkReceivedAt:
chunksReceivedAfterStopRequest:
receivedAudioDurationAfterStop:
rawCandidateCountByType:
postSmoothingEventCountByType:
finalEventCountByType:
topRejectReason:
RMS/energy p90:

sensitive data included in repo: No
real personal audio committed: No
real personal CSV committed: No
server/network code added: No
HealthKit write observed: No
diagnosis wording observed: No

notes:
blocking issue id:
```

## 실패 분류

- P0: capture가 멈추지 않음, HealthKit write, 전체 밤 원본 오디오 저장, crash/data loss
- P1: detector diagnostics 누락, privacy opt-in 정책 회귀, 주요 리포트 화면 사용 불가
- P2: copy 혼선, screenshot mismatch, 일부 edge state 표시 오류
- P3: 문서 보강, polish, 긴 문구 줄바꿈 개선

P0/P1은 build 확대 배포 전에 수정합니다. P2/P3은 release risk와 사용자 영향도를 기록하고 다음 후보 build에 반영합니다.
