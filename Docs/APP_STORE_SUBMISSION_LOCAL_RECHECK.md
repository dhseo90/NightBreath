# App Store Submission Local Recheck

이 문서는 실제 App Store Connect 제출 화면을 완료했다는 기록이 아닙니다. 제출 직전 로컬에서 확인할 수 있는 version/build, release note, product metadata 정합성을 먼저 정리하고, 실제 ASC/TestFlight 후보 선택은 manual pending으로 남깁니다.

## Run Identity

| 항목 | 값 |
| --- | --- |
| date | 2026-05-09 |
| reviewer | Codex local recheck |
| source of truth | `SleepSoundApp.xcodeproj/project.pbxproj`, `SleepSoundApp/App/Info.plist`, `Docs/APP_STORE_PRODUCT_PAGE_COPY.md` |
| actual ASC/TestFlight candidate build | not selected |

## Version And Build

| Field | Local value | Evidence | Decision |
| --- | --- | --- | --- |
| MARKETING_VERSION | 1.0 | Release build settings and project file | local recheck passed |
| CURRENT_PROJECT_VERSION | 1 | Release build settings and project file | local recheck passed |
| CFBundleShortVersionString | `$(MARKETING_VERSION)` | `SleepSoundApp/App/Info.plist` | local recheck passed |
| CFBundleVersion | `$(CURRENT_PROJECT_VERSION)` | `SleepSoundApp/App/Info.plist` | local recheck passed |
| local bundle identifier | `com.local.NightBreath` | Release build settings and project file | ASC bundle id/app record must be selected before archive upload |

## Release Notes

| Locale | Candidate | Decision |
| --- | --- | --- |
| ko-KR | App Store 준비를 위해 screenshot 후보, 앱 아이콘 검증, TestFlight 내부 테스트 기준, 개인정보/HealthKit read-only 검토 문서를 정리했습니다. | local recheck passed |
| en-US | Prepared screenshot candidates, app icon checks, internal TestFlight criteria, and local-first privacy/HealthKit read-only review docs. | local recheck passed |

## Product Metadata

| Locale | Field | Candidate | Local check |
| --- | --- | --- | --- |
| ko-KR | App Name | 밤숨 | pass |
| ko-KR | Subtitle | 수면 소리와 하루 리듬 | pass |
| ko-KR | Promotional Text | 수면 소리 리포트, 아침 컨디션, 오늘의 리듬을 iPhone 안에서 개인 참고용으로 정리합니다. | pass |
| ko-KR | Keywords | 밤숨,수면,코골기,수면소리,수면기록,건강리듬,HealthKit,컨디션 | pass |
| en-US | App Name | NightBreath | pass |
| en-US | Subtitle | Sleep Sound & Rhythm | pass |
| en-US | Promotional Text | Review sleep sound reports, morning check-ins, and daily rhythm context on iPhone with local-first privacy. | pass |
| en-US | Keywords | sleep,snore,sound,rhythm,wellness,HealthKit,checkin,report | pass |

## Commands

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /usr/bin/xcodebuild -project SleepSoundApp.xcodeproj -scheme SleepSoundApp -configuration Release -showBuildSettings
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /usr/bin/xcrun swift test --filter AppStoreReadiness --filter ReleaseReadiness --no-parallel
Tools/Release/audit_release_copy.sh
Tools/Docs/validate_readme_links.sh
git diff --check
```

## Remaining Manual Gates

- App Store Connect에서 실제 app record와 bundle identifier 확인
- TestFlight/App Store 제출 후보 build number 선택
- ko-KR/en-US metadata를 ASC 입력 칸에서 글자 수와 잘림 없이 재확인
- What's New / release notes를 실제 제출 화면에서 locale별로 재확인
- App Store Connect upload preview와 실제 TestFlight 실행 결과를 `Docs/Release/RELEASE_READINESS_EVIDENCE.md`에 반영

## Decision

로컬 version/build, release note, product metadata 정합성은 통과했습니다. 실제 ASC/TestFlight build 선택과 app record 확인은 아직 manual pending입니다.
