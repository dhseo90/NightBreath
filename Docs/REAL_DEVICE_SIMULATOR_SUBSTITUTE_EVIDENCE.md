# Real Device Simulator Substitute Evidence

이 문서는 실제 iPhone 전용 QA를 완료했다는 기록이 아닙니다. 실기기 없이 진행 가능한 범위를 simulator와 local focused tests로 먼저 확인하고, 실제 iPhone / HealthKit / Fitdays app evidence는 manual pending으로 남깁니다.

## Run Identity

| 항목 | 값 |
| --- | --- |
| date | 2026-05-09 |
| reviewer | Codex simulator/local substitute |
| branch | `main` |
| simulator | iPhone 17 Pro, iOS 26.4, booted |
| app build | Debug simulator build |
| private artifacts | simulator screenshots captured outside repository; not committed |

## Scope Matrix

| 실제 QA 항목 | 이번 실행 상태 | 대체 실행 | 판정 |
| --- | --- | --- | --- |
| actual iPhone foreground/background/overnight | not run | Debug simulator build, install, launch, screenshot scenario smoke, audio pipeline focused tests | local substitute pass; real-device manual QA pending |
| HealthKit permission dialog | not run | `healthPermissionEmpty` simulator scenario, HealthKit read-only policy tests, mock permission/data state tests | local substitute pass; real-device manual QA pending |
| Fitdays app export menu | not run | `fitdaysImport` simulator scenario, Fitdays parser/import/manual metric tests | local substitute pass; real-device manual QA pending |
| Event audio sample opt-in/off storage UI | actual device not run | `eventAudioStorageOff` simulator scenario, storage/capture policy focused tests | local substitute pass; real-device manual QA pending |

## Simulator UI Smoke

The following screens were launched from the installed Debug app on the booted simulator with `--nightbreath-screenshot-scenario`. Screenshots were kept outside the repository and are not release assets.

| Scenario | 확인 결과 |
| --- | --- |
| `healthPermissionEmpty` | HealthKit read-only boundary and local import fallback copy visible; no write/server implication observed |
| `fitdaysImport` | Local CSV/text and clipboard preview flow visible; no server/API/login/import path exposure observed |
| `sleepRecording` | Recording-state dashboard rendered with local report wording; no full-night raw storage claim observed |
| `eventAudioStorageOff` | Sample storage OFF/default protection visible; short event sample policy and no speech text conversion copy visible |

## Local Test Coverage

| 범위 | 대표 coverage |
| --- | --- |
| Overnight/capture substitute | `SleepAudioProcessingPipeline`, `AudioCaptureStopFlow`, `AudioCaptureMetrics` |
| HealthKit substitute | `HealthKitReadOnlyPolicy`, `MockHealthKitService`, Health dashboard empty/partial/mixed states |
| Fitdays substitute | `FitdaysCSVParser`, `FitdaysImport`, `FitdaysManualMetricEntry`, `HealthCalendar` large local dataset |
| Release safety | `AppStoreReadiness`, `ReleaseReadiness`, screenshot manifest, README link validation |

## Commands

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /usr/bin/xcodebuild -project SleepSoundApp.xcodeproj -scheme SleepSoundApp -configuration Debug -destination id=<booted-simulator-id> -derivedDataPath Build/SimulatorSubstitute build CODE_SIGNING_ALLOWED=NO
/Applications/Xcode.app/Contents/Developer/usr/bin/simctl install booted Build/SimulatorSubstitute/Build/Products/Debug-iphonesimulator/SleepSoundApp.app
/Applications/Xcode.app/Contents/Developer/usr/bin/simctl launch --terminate-running-process booted com.local.NightBreath --nightbreath-screenshot-scenario healthPermissionEmpty
/Applications/Xcode.app/Contents/Developer/usr/bin/simctl launch --terminate-running-process booted com.local.NightBreath --nightbreath-screenshot-scenario fitdaysImport
/Applications/Xcode.app/Contents/Developer/usr/bin/simctl launch --terminate-running-process booted com.local.NightBreath --nightbreath-screenshot-scenario sleepRecording
/Applications/Xcode.app/Contents/Developer/usr/bin/simctl launch --terminate-running-process booted com.local.NightBreath --nightbreath-screenshot-scenario eventAudioStorageOff
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /usr/bin/xcrun swift test --filter SleepAudioProcessingPipeline --filter AudioCaptureStopFlow --filter AudioCaptureMetrics --filter HealthKitReadOnlyPolicy --filter MockHealthKitService --filter FitdaysCSVParser --filter FitdaysImport --filter FitdaysManualMetricEntry --filter HealthCalendar --filter AppStoreReadiness --filter ReleaseReadiness --no-parallel
Tools/Screenshots/validate_screenshot_manifest.sh
Tools/Docs/validate_readme_links.sh
git diff --check
```

## Remaining Manual Gates

- 실제 iPhone foreground/background/overnight QA
- 실제 iPhone lock/background short stop 후 received audio 증가 여부 확인
- 실제 HealthKit permission dialog 조합, 데이터 없음, 일부 허용 상태 확인
- 실제 Fitdays app export/share/Open in NightBreath 노출 확인
- 실제 개인 데이터나 파일명은 private QA note에만 기록하고 repository에는 aggregate 상태만 남김

## Decision

Simulator/local substitute 범위는 통과했습니다. 이 결과는 실제 iPhone QA를 대체하지 않으며, release readiness의 실제 기기 항목은 계속 manual pending입니다.
