# Development & QA

## 로컬 환경

| 항목 | 기준 |
| --- | --- |
| Xcode | `/Applications/Xcode.app` 기준 |
| Swift | Swift tools 6.0 |
| 플랫폼 | iOS 17 이상, macOS 14 이상 |
| 프로젝트 파일 | `SleepSoundApp.xcodeproj` |
| 패키지 | `Package.swift` |
| 서버/계정 | 필요 없음. 추가하면 안 됨 |
| 실기기 | 오디오 캡처, 백그라운드, 장시간 기록, HealthKit, Fitdays 공유/import 확인에 필요 |

작업 전에는 항상 `AGENTS.md`를 먼저 읽습니다. 특히 개인정보, 의료 문구, HealthKit/Fitdays 금지선, 5.6 모델 추천 기준을 확인해야 합니다.

## 기본 명령

### 전체 테스트

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /usr/bin/xcrun swift test --no-parallel
```

### iOS generic build

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project SleepSoundApp.xcodeproj -scheme SleepSoundApp -configuration Debug -destination generic/platform=iOS -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO build
```

### 문서/릴리스 gate

```bash
git diff --check
Tools/Docs/validate_readme_links.sh
Tools/UI/validate_navigation_chrome.sh
Tools/Screenshots/validate_screenshot_manifest.sh
Tools/Screenshots/validate_app_store_release_approval.sh
Tools/Release/audit_tracked_artifacts.sh
```

문서만 수정한 경우 최소 `git diff --check`와 `Tools/Docs/validate_readme_links.sh`를 실행합니다. README 이미지, release evidence, navigation copy를 건드렸다면 관련 gate까지 확장합니다.

## 검증 매트릭스

| 변경 유형 | 최소 검증 | 추가 검증 |
| --- | --- | --- |
| 문서/로드맵 | `git diff --check`, README link 검증 | release evidence 문구 변경 시 copy/privacy review |
| 단일 순수 로직 | 관련 Swift test, 전체 `swift test --no-parallel` | edge fixture 추가 |
| 수면 리포트/점수 | 리포트 builder/scorer tests | 실기기 session evidence와 wording 확인 |
| 오디오 캡처/저장 | 관련 단위 테스트 | 실기기 장시간, interruption, background, storage cap |
| HealthKit | mock/real service boundary tests | 실기기 권한 조합, read-only 확인 |
| Fitdays import | parser/import tests | 실제 공유/export 파일의 local import 경로 확인 |
| Screenshot/UI chrome | UI validation scripts | simulator screenshot 갱신 및 manifest 확인 |
| Release candidate | 전체 테스트, 전체 gate | 실기기 장시간 QA와 release evidence review |

## 실기기에서만 닫아야 하는 항목

| 항목 | 이유 |
| --- | --- |
| 장시간 수면 기록 | simulator는 실제 audio route, lock/background, thermal/battery 상태를 대체하지 못함 |
| 오디오 interruption 복구 | 전화, 알람, route change, system interruption은 실제 기기 확인 필요 |
| HealthKit 권한 | 권한 prompt, denied/partial/authorized 조합은 실기기 기준 |
| Fitdays share/import | 실제 앱 export/share sheet와 파일 형태 확인 필요 |
| release screenshot | App Store evidence와 실제 iOS rendering 차이 확인 필요 |

## Xcode 작업 흐름

1. `SleepSoundApp.xcodeproj`를 엽니다.
2. scheme은 `SleepSoundApp`을 사용합니다.
3. simulator로 UI와 순수 흐름을 먼저 확인합니다.
4. 오디오/HealthKit/Fitdays 관련 작업은 실기기로 전환합니다.
5. 코드 변경 후 CLI test와 Xcode build 중 최소 하나 이상을 통과시킵니다. release에 가까운 변경은 둘 다 실행합니다.

## 흔한 실패와 처리 기준

| 증상 | 우선 확인 |
| --- | --- |
| SwiftPM/Xcode 캐시 관련 오류 | Xcode derived data와 SwiftPM cache 상태를 확인하고 재시도합니다. |
| sandbox에서 simulator/build 접근 실패 | 로컬 Xcode 또는 승인된 unsandboxed 명령으로 재실행합니다. |
| HealthKit 데이터가 없음 | 권한 상태, 실제 건강앱 source, mock/real service 선택을 분리해 확인합니다. |
| Fitdays import row skip 증가 | parser mapping, unit, locale decimal separator, header alias를 확인합니다. |
| 수면 리포트가 과도하게 확정적으로 보임 | 문구를 “의심”, “참고용”, “개인 패턴” 기준으로 낮춥니다. |
| 장시간 기록 후 warning 발생 | interruption count, longest gap, audio coverage ratio가 리포트에 반영되는지 확인합니다. |

## QA 산출물 관리

| 산출물 | 위치/원칙 |
| --- | --- |
| 공개 문서 | `Docs/` 아래 markdown |
| README 스크린샷 | `Docs/Screenshots/README/` 및 cropped 하위 경로 |
| release evidence | 개인정보가 제거된 요약만 repository에 포함 |
| 개인 실기기 로그 | 원본 사용자 데이터/오디오/HealthKit 세부값은 repo에 추가하지 않음 |
| 테스트 fixture | 합성 데이터 또는 익명화된 fixture만 사용 |

## 개인정보와 release hard stop

아래 항목이 발견되면 release candidate 판단 전에 중단하고 수정합니다.

| Hard stop | 확인 방법 |
| --- | --- |
| 서버/외부 API/analytics/ads SDK 추가 | dependency, entitlements, network usage audit |
| HealthKit write path 추가 | HealthKit service API와 capability review |
| 앱 첫 실행 HealthKit 권한 요청 | onboarding/app launch flow 확인 |
| 전체 밤 원본 오디오 저장 | audio storage path와 file retention 확인 |
| sample opt-in 기본값 on | settings/default storage test |
| 의료 진단/치료 문구 | UI, docs, App Store copy, release notes review |
| 실제 개인 CSV/오디오/건강 로그 commit | `git status`, tracked artifact audit |

## 모델/추론 추천 사용법

로드맵, 후속 작업, QA 계획을 제시할 때 아래 형식을 함께 씁니다.

```text
추천 모델: 5.6 Terra
추론 수준: 높음 (high)
선정 근거: 여러 스크립트와 빌드 경계를 검증하지만 의료/개인정보 계약을 직접 변경하지 않는 통합 작업
```

VATester 점수는 영향도, 불확실성, 검증 난이도, 변경 범위를 각각 0~2점으로 계산합니다. 0~2점은 `5.6 Luna`, 3~5점은 `5.6 Terra`, 6~8점은 `5.6 Sol`입니다. 개인정보, 의료 오해, HealthKit write 금지, 기록 유실, release gate 판단은 상향 규칙을 적용합니다.
