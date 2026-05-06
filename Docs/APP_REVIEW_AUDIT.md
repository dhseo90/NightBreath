# App Review / Legal Audit

이 문서는 NightBreath / 밤숨의 App Review 제출 전 확인 항목을 정리합니다. 법률 자문이 아니라 개발/리뷰 준비용 체크리스트입니다.

## Product Positioning

- 앱 표시 이름: `밤숨`
- 영어 브랜드: `NightBreath`
- 용도: iPhone 안에서 수면 중 소리 기반 지표와 하루 리듬 정보를 개인 참고용으로 정리합니다.
- 범위: 웰니스/개인 참고용 리포트, HealthKit read-only dashboard, 사용자가 직접 선택한 Fitdays CSV/export local import
- 금지: 의료적 판단으로 읽히는 표현, 치료 조언, 질병 여부 단정, HealthKit write, 서버 업로드, 클라우드 처리, 외부 분석 SDK, 광고 SDK
- Product page 후보 문구: `Docs/APP_STORE_PRODUCT_PAGE_COPY.md`

## App Review Notes

App Review 메모 후보:

```text
NightBreath / 밤숨 analyzes sleep-related sound indicators on device and shows wellness-style reports for personal reference.

HealthKit is used only when the user explicitly chooses to connect health data from the health dashboard. The app requests read access only and does not write data to HealthKit.

The app does not upload health data or audio to a server. It does not use cloud processing, advertising SDKs, external analytics SDKs, or account login.

The app does not store full-night raw audio by default. Short event audio snippets can be stored locally only when the user explicitly enables the setting.

Reports are not intended for medical diagnosis, disease determination, or treatment decisions.
```

## Privacy / Data Boundary

| Area | Current policy | Review evidence |
| --- | --- | --- |
| Audio capture | Audio is processed as chunks for analysis | `Docs/PRIVACY_STORAGE_AUDIT.md`, `AudioCaptureService` |
| Full-night raw audio | Not stored | privacy audit, QA scan |
| Event audio snippets | Short local snippets only after user opt-in | `EventAudioSnippetStore`, privacy settings |
| DEBUG samples | DEBUG-only 2s/3s/5s manual samples | `SampleCaptureView`, `.gitignore` |
| HealthKit | Read-only, user-triggered permission flow | `RealHealthKitService`, HealthKit tests |
| Fitdays | User-selected local file import only | `FitdaysImportView`, import service tests |
| Daily Health Card export | User-triggered local rendering/share/save | Daily Health Card tests and privacy audit |
| Network/server | No app network/server integration | privacy tests and code scan |
| Tracking/ads | No tracking or ad SDK | privacy tests and code scan |

## HealthKit Review Checklist

- HealthKit permission is not requested on first launch.
- HealthKit permission is not requested during sleep start/stop.
- HealthKit permission starts only from the health dashboard connect action.
- `requestAuthorization` uses an empty share set.
- No HealthKit save/delete API is used.
- Sleep sound score, today rhythm score, events, reports, feedback, Fitdays import values are not written to HealthKit.
- HealthKit denial does not block sleep sound flows.

## Audio / Storage Review Checklist

- Full-night raw audio file is not created.
- Event snippets are opt-in, short, local, limited, and deletable.
- Event snippet storage default is off.
- DEBUG sample capture is compiled only for DEBUG and is not a Release user flow.
- Real personal audio files are not committed.
- Sleep talk content is not transcribed.

## Health / Wellness Copy Checklist

Allowed copy:

- 개인 패턴을 살펴보기 위한 참고용 보기
- 수면 소리 점수
- 오늘의 리듬 점수
- 코골기
- 의심 소리 / 의심 구간
- 감지 기준을 통과한 이벤트가 없었습니다

Avoid:

- disease diagnosis or determination
- exact clinical index claims
- treatment recommendation
- confirmed causal claims between sleep sound and health metrics
- copy implying that no detected event means no health concern

## App Store Asset Checklist

- Product page copy 후보는 `Docs/APP_STORE_PRODUCT_PAGE_COPY.md`에서 ko-KR/en-US locale별로 관리합니다.
- Screenshots use mock/synthetic data only.
- App Store raw screenshots live under `Docs/Screenshots/AppStore/raw/`.
- App Store Connect export output is regenerated locally and not committed.
- Screenshot copy avoids medical claims and sensitive personal values.
- App icon avoids hospital/medical-device visual language.

## Data Safety Questionnaire Notes

- Data is not sent to a server by the app.
- Health data is read only after user action and remains on device.
- Audio is analyzed on device.
- Full-night raw audio is not stored by default.
- Optional event snippets are local only and user-controlled.
- No tracking, ads, external analytics SDK, or account login is used.

Before answering App Store Connect questionnaires, verify the current binary and privacy policy wording again. If a new feature adds data transfer, account, subscription, analytics, or cloud sync, this audit must be updated before submission.

## Required Scans Before Submission

```bash
rg -n "URLSession|http://|https://|NWConnection|Alamofire|Firebase|Analytics|AdMob" SleepSoundApp Tests Package.swift
```

```bash
rg -n "import HealthKit|HKHealthStore|requestAuthorization|toShare|save\\(|delete\\(" SleepSoundApp Tests Package.swift
```

```bash
rg -n "AVAudioFile|AVAssetWriter|AVAudioRecorder|\\.wav|\\.caf|\\.m4a" SleepSoundApp Tests Package.swift
```

```bash
rg -n "수면무호흡증.*진단|AHI.*정확 측정|이갈이.*확진|질병.*판정|치료.*필요|정상.*입니다|코골이가.*없었습니다" SleepSoundApp Docs README.md QA_CHECKLIST.md
```

## Open Manual Gates

- 실제 iPhone foreground stop smoke
- 실제 iPhone lock/background short stop
- 실제 snore signal smoke with diagnostics
- TestFlight internal test evidence
- Final App Store screenshot visual inspection

이 항목은 실기기 또는 App Store Connect/TestFlight context가 있어야 완료할 수 있습니다.
