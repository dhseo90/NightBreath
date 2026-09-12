# AGENTS.md

NightBreath / 밤숨 자동화 개발 에이전트의 작업 규칙이다. 대상은 iOS SwiftUI 기반 온디바이스 수면 소리 리포트 앱이며, Daily Rhythm Report, HealthKit read-only 대시보드, Fitdays local import, 로컬 저장, 개인정보 보호 정책을 포함한다.

개발·테스트·보고·커밋·푸시 권한은 이 문서를 프로젝트 기준 source-of-truth로 삼는다. 단, 시스템/개발자 지시와 사용자의 최신 명시 지시가 더 높은 우선순위를 가진다.

참고:
- MediaServer v4.1.0 AGENTS.md의 개발론, 권한 경계, 검증/보고, 문서 관리 방식을 NightBreath에 맞게 변환했다.
- OpenAI: <https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra>
- OpenAI model guidance: <https://developers.openai.com/api/docs/guides/latest-model>

## 1. 문서 운용 원칙과 요청 라우터

최신 사용자 요청을 먼저 분류한다. 애매하면 더 넓은 권한을 추정하지 않고, 사용자가 명시한 범위 안에서 가장 좁은 유형으로 처리한다.

| 요청 유형 | 허용 범위 | 별도 승인 없이 금지 | 주요 적용 장 |
| --- | --- | --- | --- |
| 조사/검토/목록화 | 읽기, 직접 확인, 근거 분리 보고 | 수정, 테스트 실행, 커밋, 푸시 | 1, 8 |
| 문서 변경/정리 | 지정 문서와 직접 관련 문서 수정, 문서 검증 | 코드 동작 변경, 미실행 검증의 완료 기록 | 9 |
| 단계/로드맵 개발 | 지정 범위 구현, 관련 테스트, 필요한 문서 업데이트 | 범위 밖 개발, 다음 단계 자동 착수 | 4, 5 |
| 테스트 실행 | 명시된 테스트 또는 변경 영향 범위 검증 | 다른 검증으로 PASS 대체, 임의 장시간 테스트 | 5 |
| 릴리즈 잔여 이슈 | roadmap/evidence/구현/검증 대조와 우선순위 보고 | 승인 없는 수정, release action | 6, 8 |
| 릴리즈 실행 | 명시 승인된 PR, merge, tag, release 단계 | 미승인 외부 변경, force push, tag 교체 | 6, 7 |
| 커밋/푸시 | 승인 범위 stage, commit, push | 자의적 수행, unrelated 파일 포함 | 7 |

### 1.1 최우선 원칙

1. 모든 대화, 진행 업데이트, 최종 보고는 한글로 한다.
2. 사용자가 지정한 범위와 순서를 지킨다.
3. 실패, 미실행, 미확인, 추정을 숨기지 않는다.
4. 확인한 사실과 추론을 분리해서 보고한다.
5. 실패한 검증 뒤의 외부 변경 단계는 중단한다. 같은 승인 범위 안의 안전한 수정과 재검증은 4.4를 따른다.
6. 작은 수정에 전체 repo 지도와 모든 문서를 매번 요구하지 않는다. 작업에 필요한 문서만 읽고, 필요한 경우 왜 읽었는지 짧게 남긴다.
7. 로컬 테스트가 disposable fixture와 앱 sandbox를 사용하고 외부 서비스에 접근하지 않으면, 요청 변경으로 생긴 실패를 수정하고 관련 테스트를 재실행할 수 있다.
8. 다른 프로젝트의 서버, 스트리밍, 운영자 콘솔, 인증 시스템 특화 용어와 정책을 NightBreath 규칙으로 옮기지 않는다.

### 1.2 우선순위와 충돌 처리

AGENTS.md는 repository 내부 운영 정책의 기준이다. README, Docs, roadmap, QA checklist, release evidence, verifier 설명이 이 문서보다 넓은 완료/통과/푸시 권한을 주는 것처럼 보이면 이 문서를 우선한다.

다음 상황은 중단하고 충돌로 보고한다.

1. 사용자 최신 지시와 기존 문서 또는 과거 대화가 충돌한다.
2. 문서상 완료 표기가 실제 구현 또는 검증 evidence와 맞지 않는다.
3. verifier 설명이 실기기 QA, App Store evidence, privacy review를 대체할 수 있는 것처럼 보인다.
4. 사용자가 조사만 요청했는데 구현/테스트/커밋/푸시가 필요해진다.
5. 금지된 개인정보 처리, HealthKit 쓰기, 외부 연동, 의학적 판정 문구를 추가해야만 요구를 만족할 수 있다.

최신 명시 지시가 충돌을 해소하고 범위를 분명히 하면 같은 확인을 반복하지 않는다. 단, destructive action, 외부 release action, force operation은 별도 명시 승인이 필요하다.

### 1.3 문맥과 절차의 적용 범위

목표, 불변 조건, 완료 evidence를 먼저 잡고 그 안에서 도구, 읽기 순서, 테스트 범위를 선택한다.

| 작업 | 우선 읽을 문서 |
| --- | --- |
| 제품 방향, 문구, 범위 | `AGENTS.md`, `Docs/Product/README.md`, `Docs/PRODUCT_DIRECTION.md` |
| 아키텍처, 데이터 흐름 | `Docs/Handoff/PROJECT_ARCHITECTURE.md`, `Docs/Architecture/README.md` |
| 개발 환경, QA | `Docs/Handoff/DEVELOPMENT_QA.md`, `Docs/QA/README.md`, `Docs/QA_GUIDE.md` |
| v1.1.x roadmap | `Docs/V1_1_ROADMAP.md`, `Docs/NEXT_ISSUES.md`, `Docs/CURRENT_STATUS.md` |
| 개인정보, HealthKit, 저장 | `Docs/Privacy/README.md`, `Docs/PRIVACY_STORAGE_AUDIT.md`, `Docs/HEALTH_DATA_GUIDE.md` |
| UI, screenshot | `Docs/UI/README.md`, `Docs/UI_SCREEN_MAP.md`, `Docs/Screenshots/README.md` |
| 릴리즈 | `Docs/Release/README.md`, `Docs/APP_RELEASE_GUIDE.md`, release evidence 문서 |

이미 읽은 같은 지침을 매 수정마다 다시 읽지 않는다. 새 요구, 새 충돌, 새 실패가 나오면 관련 문서만 갱신해서 확인한다.

## 2. 제품과 개인정보 불변 조건

### 2.1 제품 정체성

| 항목 | 기준 |
| --- | --- |
| 한국어 앱 이름 | 밤숨 |
| 영어 프로젝트/브랜드 | NightBreath |
| 한국어 부제 | 수면 소리 리포트 |
| 영어 부제 | Sleep Sound Report |
| 현재 제품 | iPhone 온디바이스 수면 소리 리포트 앱 |
| 확장 방향 | 온디바이스 개인 건강 리듬 리포트 앱 |
| 사용자 가치 | 수면 소리와 하루 건강 리듬을 개인 참고용으로 살펴보는 웰니스 리포트 |

앱은 수면과 관련된 소리를 분석해 아침 리포트를 만들고, 향후 수면, 혈압, 체중, 체성분, 활동, 아침/저녁 컨디션을 함께 보는 Daily Rhythm Report로 확장한다.

### 2.2 사용할 수 있는 표현

- 코골기
- 이갈이 의심 소리
- 호흡정지 의심 구간
- gasp-like 회복 호흡
- 기침 의심 소리
- 환경 소음
- 움직임 의심 소리
- 각성 의심 구간
- 수면 소리 점수
- 오늘의 리듬 점수
- 회복 리듬
- 아침 리포트
- 하루 리듬 카드
- 개인 패턴을 살펴보기 위한 참고용 보기

### 2.3 피해야 할 표현 범주

다음 범주의 문구는 UI, 문서, App Store copy, release note, test fixture에 넣지 않는다.

| 범주 | 대체 방향 |
| --- | --- |
| 특정 질환을 단정하는 표현 | “의심”, “참고”, “패턴” 기준으로 낮춘다. |
| 임상 지표를 정밀 산출한다는 표현 | 앱 지표와 임상 지표를 분리한다. |
| 소리 이벤트를 확정 판정하는 표현 | “의심 소리”, “추정 구간”을 사용한다. |
| 건강 상태를 판정하는 점수 표현 | 웰니스/개인 참고용 점수임을 밝힌다. |
| 의학적 조치가 필요하다는 표현 | 앱은 조치 판단을 하지 않는다고 설명한다. |
| 수면 소리와 건강 지표의 원인/결과 단정 | 같은 날 함께 보이는 참고 정보로만 표현한다. |

### 2.4 개인정보와 로컬 처리

다음은 제품 불변 조건이다.

1. 서버 업로드를 하지 않는다.
2. 클라우드 처리를 하지 않는다.
3. 외부 API 호출을 추가하지 않는다.
4. 외부 분석 SDK, 광고 SDK, 계정/로그인 시스템을 추가하지 않는다.
5. 기본 동작으로 밤새 원본 오디오 전체를 저장하지 않는다.
6. 잠꼬대나 말소리를 텍스트로 변환하지 않는다.
7. 명시적으로 요청되지 않는 한 로컬 이벤트 요약만 저장한다.
8. 실제 개인 CSV, 오디오, HealthKit export, device log를 repository에 포함하지 않는다.

### 2.5 이벤트 오디오 샘플 예외

짧은 이벤트 전후 오디오 샘플은 사용자가 opt-in 설정을 켠 경우에만 로컬 저장할 수 있다.

| 항목 | 기준 |
| --- | --- |
| 기본값 | 꺼짐 |
| 저장 위치 | `Application Support/NightBreath/EventAudioSnippets/` |
| 기본 정책 | 이벤트 전 2초, 이벤트 후 3초 |
| 샘플 상한 | 샘플 최대 10초, 세션당 최대 100개, 폴더 최대 200MB |
| 사용자 제어 | 샘플 재생, 개별 삭제, 전체 삭제 기능 유지 |
| 금지 | 전체 밤 오디오 저장, 말소리 텍스트 변환 |

### 2.6 HealthKit과 Fitdays 경계

| 영역 | 허용 | 금지 |
| --- | --- | --- |
| HealthKit | 사용자가 대시보드에서 연결한 뒤 read-only 조회 | 앱 첫 실행 권한 요청, 데이터 쓰기, custom type 생성, 앱 점수 쓰기 |
| Fitdays | 사용자가 직접 선택한 CSV/export/local text import | 서버/API 직접 연결, 비공식 연동, reverse engineering, HealthKit으로 import 값 쓰기 |
| Mock data | preview, 테스트, 데모 seed | 실제 사용자 evidence처럼 공개 repository에 포함 |

HealthKit-backed metric과 Fitdays local-only metric은 `UnifiedHealthMetricID` catalog에서 함께 표현하되 source type을 섞지 않는다. Fitdays import 값에 HealthKit 표준 지표가 포함되어도 `sourceType == fitdaysCSV`를 유지한다.

## 3. 아키텍처와 데이터 계약

### 3.1 권장 구조

| 경로 | 책임 |
| --- | --- |
| `SleepSoundApp/App` | SwiftUI 앱 진입점, AppState, assets, entitlements |
| `SleepSoundApp/Features/Sleep` | 수면 시작/기록/종료, 리포트, 타임라인, 아침 체크인 |
| `SleepSoundApp/Features/DailyRhythm` | Morning Brief, Daily Rhythm Report, Daily Health Card, Evening Check-in |
| `SleepSoundApp/Features/Dashboard` | 건강 대시보드, metric detail, calendar, Fitdays import |
| `SleepSoundApp/Features/Onboarding` | 첫 사용 안내와 권한 설명 |
| `SleepSoundApp/Features/Settings` | privacy, debug/dev tools, sample capture, detector tuning |
| `SleepSoundApp/Core/Audio` | 오디오 캡처, audio source, ring buffer, capture metrics |
| `SleepSoundApp/Core/Analysis` | rule-based detector, pipeline, scoring, diagnostics, offline evaluation |
| `SleepSoundApp/Core/Models` | SleepSession, SleepEvent, NightReport, MorningCheckIn 등 domain model |
| `SleepSoundApp/Core/Storage` | 로컬 JSON repository, recovery draft, snippet/feedback 저장 |
| `SleepSoundApp/Core/Privacy` | privacy policy model, user settings |
| `SleepSoundApp/Core/FutureHealth` | HealthKit protocol, mock/real service, metric catalog |
| `SleepSoundApp/Core/HealthImport` | Fitdays CSV/local import |
| `SleepSoundApp/Core/DailyRhythm` | Daily Rhythm score, snapshot, report builder |
| `Tests` | Swift Testing 기반 단위/통합 테스트 |
| `Tools` | docs, screenshots, release, offline evaluation automation |
| `Docs` | 제품, 아키텍처, QA, release evidence, handoff 문서 |

### 3.2 설계 원칙

1. 비즈니스 로직은 SwiftUI View와 분리한다.
2. 외부 상태, platform service, storage, audio source, HealthKit 접근에는 protocol boundary를 우선한다.
3. 점수 계산, 이벤트 집계, import parsing, Daily Rhythm 집계는 독립 테스트 가능하게 둔다.
4. UI는 한국어를 우선 사용하고 기존 design system component를 따른다.
5. 앱 흐름과 model contract를 바꾸는 작업은 테스트와 문서 업데이트를 함께 고려한다.
6. 파일 이동은 Xcode project와 SwiftPM target 참조를 모두 확인한 뒤 수행한다.

### 3.3 핵심 모델

| 모델 | 핵심 책임 |
| --- | --- |
| `SleepSession` | 측정 시작/종료, 추정 수면 시간, measurement duration, device placement, app/model version |
| `SleepEvent` | 이벤트 타입, 시작/종료, duration, confidence, intensity, user review, optional snippet metadata |
| `NightReport` | 측정 품질, audio coverage, interruption, sleep sound score, 이벤트 집계, main reason |
| `MorningCheckIn` | refresh/fatigue score, 불편감, 기억나는 각성, memo |
| `HealthMetricSample` | HealthKit 표준 지표 sample |
| `UnifiedHealthMetricSample` | HealthKit, Fitdays CSV, manual, appComputed, mock source를 통합 표현 |
| `ImportBatch` | local import batch의 row/sample/skipped/error 집계 |

## 4. 단계/로드맵 개발 규칙

### 4.1 시작 기준

개발 시작 전에 아래를 짧게 확정한다.

1. 구현 범위와 비범위
2. 유지해야 할 제품/개인정보/데이터 계약
3. 정상, 오류, 빈 상태, 권한 제한, 데이터 부족 상태의 합격 기준
4. 실행할 테스트와 실행하지 않을 테스트
5. 문서 또는 release evidence 업데이트 필요 여부

사용자가 구현을 요청했으면 제안만 하고 멈추지 않는다. 다만 조사/검토만 요청했거나 destructive/external action이 필요한 경우에는 멈추고 보고한다.

### 4.2 TDD와 회귀 기준

로직, parser, score, repository, privacy boundary, bugfix는 가능한 한 테스트를 먼저 추가하거나 기존 테스트를 식별한다.

예상된 RED와 실제 실패를 구분한다.

| 구분 | 기준 |
| --- | --- |
| 예상된 RED | 특정 assertion, 미구현 원인, 영향 범위가 실행 전 설명된 실패 |
| 실제 실패 | 빌드 오류, 환경 오류, 기존 회귀, 요구와 무관한 실패, 예상과 다른 assertion |

실제 실패를 사후에 RED로 바꾸지 않는다. GREEN과 영향 회귀가 통과하기 전 완료 또는 커밋 가능으로 보고하지 않는다.

### 4.3 범위 이탈 금지

특정 roadmap category, 버전 step, 화면, module을 지정받으면 그 범위 안에서만 작업한다. 완료 후 다음 category를 자동 착수하지 않는다. 새 요구는 기존 결함, 영향 회귀, 새 범위로 분리한다.

### 4.4 승인 범위 안의 수정과 재검증

요청받은 개발 또는 수정 범위 안에서 발생한 로컬 실패는 다음 조건을 모두 만족하면 재승인 없이 수정하고 관련 검증을 다시 실행할 수 있다.

1. disposable fixture, 앱 sandbox, local-only data만 사용한다.
2. 원인이 요청 변경 또는 검증 준비에 있다.
3. 제품/개인정보/데이터 계약과 완료 기준을 바꾸지 않는다.
4. 수정 대상과 영향 범위가 확인된다.
5. 11장의 중단 조건에 해당하지 않는다.

동일 원인 반복, 다른 계약의 교차 회귀, 외부 권한 필요, 사용자 제품 판단 필요가 생기면 중단하고 보고한다.

### 4.5 단계 완료 조건

아래가 모두 충족되어야 단계 완료로 보고한다.

1. 요청 산출물이 구현됐다.
2. 직접 관련 테스트가 PASS했다.
3. `git diff --check`가 PASS했다.
4. 변경 파일과 변경 이유를 설명할 수 있다.
5. 미실행/제외/잔여 위험을 분리해 보고한다.
6. 필요한 문서 또는 roadmap 상태가 갱신됐다.

## 5. 테스트 정책

### 5.1 기본 명령

| 목적 | 명령 |
| --- | --- |
| 전체 Swift test | `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /usr/bin/xcrun swift test --no-parallel` |
| iOS generic build | `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project SleepSoundApp.xcodeproj -scheme SleepSoundApp -configuration Debug -destination generic/platform=iOS -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO build` |
| whitespace/diff | `git diff --check` |
| README links | `Tools/Docs/validate_readme_links.sh` |
| navigation chrome | `Tools/UI/validate_navigation_chrome.sh` |
| screenshot manifest | `Tools/Screenshots/validate_screenshot_manifest.sh` |
| App Store screenshot approval | `Tools/Screenshots/validate_app_store_release_approval.sh` |
| tracked artifact audit | `Tools/Release/audit_tracked_artifacts.sh` |

### 5.2 변경 유형별 최소 검증

| 변경 유형 | 최소 검증 | 추가 검증 기준 |
| --- | --- | --- |
| AGENTS/문서만 | `git diff --check`, README link 영향 시 README link 검증, 관련 정적/문구 검토 | release-facing copy를 바꾸면 관련 copy/privacy 테스트, 코드로 강제되는 계약이나 release candidate를 바꾸면 전체 Swift test |
| 순수 로직 | 관련 단위 테스트, `git diff --check` | 공유 model/score/storage면 전체 Swift test |
| SwiftUI 화면 | 관련 UI contract test 또는 snapshot/script, `git diff --check` | navigation/screenshot 영향 시 UI scripts |
| 오디오 캡처/복구 | 관련 audio/recovery tests | 장시간/실기기 QA |
| HealthKit | read-only policy tests, mock/real boundary tests | 실기기 권한 상태 matrix |
| Fitdays import | parser/import tests | 실제 local export/share 흐름 |
| release candidate | 전체 Swift test, iOS build, 문서/UI/screenshot/release gate | 실기기 장시간 QA와 release evidence |

테스트 이름은 실행한 항목만 결과표에 넣는다. 실행하지 않은 항목을 PASS, 조건부 PASS, 암묵적 PASS로 쓰지 않는다.

### 5.3 실기기 전용 검증

다음은 simulator나 단위 테스트만으로 닫지 않는다.

| 항목 | 이유 |
| --- | --- |
| 장시간 수면 기록 | lock/background, audio route, battery/thermal 영향 확인 필요 |
| interruption 복구 | 전화, 알람, route change, media service reset 확인 필요 |
| HealthKit 권한 | denied/partial/authorized 상태와 실제 prompt 확인 필요 |
| Fitdays share/import | 실제 앱 export/share sheet와 파일 형태 확인 필요 |
| App Store screenshot | 실제 iOS rendering, safe area, 잘림 여부 확인 필요 |

### 5.4 임시 산출물 정리

테스트가 생성한 `/tmp`, `$TMPDIR`, derived output, screenshot raw, export raw, local log는 최종 evidence가 아니다. 필요한 값만 redaction 후 repository 문서에 남기고, 원본 개인정보성 파일은 commit하지 않는다.

삭제 전에는 소유 경로와 보존 필요성을 확인한다. 소유가 불명확한 파일은 임의 삭제하지 않는다.

## 6. 릴리즈 실행 프로토콜

릴리즈 준비는 blocker 정리와 evidence 확인이지 외부 변경 승인이 아니다. push, PR 생성/갱신, main merge, tag, GitHub Release, 후속 브랜치는 각각 명시 승인이 필요하다.

### 6.1 릴리즈 준비 순서

1. 기준 버전, branch, build metadata, roadmap 상태를 확인한다.
2. `git status --short --branch`, upstream ahead/behind, local/remote tag, main 최신 여부를 확인한다.
3. README, Docs, privacy copy, App Store copy, screenshot manifest, release evidence를 현재 구현과 대조한다.
4. 변경 범위에 맞는 local gate를 실행한다.
5. CI required check와 local 검증을 분리해 기록한다.
6. PR/merge/tag/release는 승인된 단계만 순서대로 진행한다.
7. 실패하면 뒤 외부 단계는 중단하고 실패 지점, 생성된 hash/URL, 미실행 단계를 보고한다.

### 6.2 릴리즈 최종 보고 형식

릴리즈 준비 또는 실행 최종 보고에는 아래 항목을 포함한다.

```text
릴리즈 준비 결과:
- 기준 버전:
- 사전 clean/sync:
- 문서 업데이트:
- 빌드/검증:
- PR:
- main merge:
- tag:
- GitHub Release:
- published metadata 재검증:
- 후속 브랜치:
- CHANGELOG/변경 이력:
- 미실행/제외 테스트:
- 실패/중단 지점:
```

## 7. 커밋과 푸시 규칙

### 7.1 커밋

커밋은 사용자가 해당 범위에 명시 승인한 경우만 수행한다. “마무리”, “릴리즈 준비”, “끝내”, PASS 보고는 커밋 승인으로 해석하지 않는다.

명시 승인이 있고 완료 조건이 충족되면 재승인을 반복하지 않는다. stage 전후로 `git status --short`와 staged 파일을 확인하고, 요청 범위 파일만 포함한다. 여러 독립 단계, 실패한 단계, unrelated untracked 파일을 한 커밋에 섞지 않는다.

### 7.2 푸시

푸시는 별도 명시 승인과 해당 범위 커밋/검증 조건 충족 후에만 수행한다. 보호된 `main`에 직접 push가 거부되면 우회하지 않고 PR/check/merge 경로로 진행하거나 중단 보고한다.

최종 보고에는 푸시 가능 여부, 수행 여부, 원격 브랜치, commit hash, PR/merge URL이 있으면 함께 남긴다.

## 8. 진실성, 완료 판정, 보고 형식

### 8.1 거짓 보고 금지

다음을 하지 않는다.

1. 미실행을 실행한 것처럼 보고
2. 실패를 PASS로 보고
3. 부분 구현을 전체 완료로 보고
4. 추정을 직접 확인으로 보고
5. 문서상 완료만 보고 실제 구현/evidence를 생략
6. 생성하지 않은 파일, commit, push, PR, release를 꾸며서 보고

### 8.2 완료 보고 전 점검

완료, 통과, 안정화, merge, push를 말하기 전 fresh evidence를 확인한다.

| 주장 | 필요한 evidence |
| --- | --- |
| 테스트 통과 | 명령, exit code 0, test count 또는 PASS 요약 |
| 빌드 성공 | build 명령과 exit code 0 |
| 문서 검증 통과 | diffcheck/link/script output |
| main 반영 | local/remote branch, PR merge 또는 push 결과 |
| release 준비 | release gate와 미실행/제외 항목 분리 |

### 8.3 실패 보고

실패 시 아래를 짧게 남긴다.

| 항목 | 내용 |
| --- | --- |
| 실패 명령 | 실제 실행한 명령 |
| 관측 결과 | exit code, 핵심 오류 |
| 원인 판단 | 직접 근거와 추정 분리 |
| 진행한 수정 | 승인 범위 안에서 수정한 내용 |
| 중단/재개 조건 | 다음에 필요한 사용자 결정 또는 외부 조건 |

## 9. 문서 관리 규칙

### 9.1 문서 언어와 구조

문서는 한글을 기본으로 한다. README.en처럼 의도된 영문 공개 문서만 예외다.

README는 제품 정체성, 빠른 시작, 핵심 링크, 대표 이미지에 집중한다. 세부 정책과 긴 목록은 `Docs/` 하위 source-of-truth에 둔다.

### 9.2 문서 분할과 중복 관리

1. 새 문서 작성 전 기존 독자, 목적, lifecycle, source-of-truth 관계를 확인한다.
2. 같은 독자와 목적이면 기존 문서에 흡수한다.
3. 별도 문서는 독자, 유지 주기, 보존 이유가 분명할 때만 만든다.
4. 정책, roadmap, 실행 로그, 연구 기록, 사용법을 한 문서에 무리하게 섞지 않는다.
5. 같은 목록을 여러 문서에 복제하지 않는다. 복제가 필요하면 어느 문서가 기준인지 명시한다.
6. historical evidence, fixture, log는 현재 정책이 아님을 표시한다.

### 9.3 문서 이미지와 스크린샷

주요 화면 문서는 가능하면 현재 UI screenshot을 사용한다. 이미지 갱신 시 잘림, 흐림, safe area, 개인정보, 원본 데이터, debug 정보 노출 여부를 확인한다.

README 또는 App Store용 이미지를 바꾸면 screenshot manifest와 release approval gate를 함께 확인한다. 링크 검증만으로 시각 검토를 대체하지 않는다.

## 10. UI 작업 규칙

1. 기존 SwiftUI design system component와 spacing/token을 따른다.
2. UI 문구는 한국어를 우선한다.
3. 점수, 경고, empty state, 권한 상태는 웰니스 참고용으로 표현한다.
4. HealthKit 연결은 건강 데이터 대시보드의 사용자 action 뒤에 둔다.
5. Fitdays import는 local file/text 흐름으로 유지한다.
6. debug/dev 화면은 release-facing 화면에 섞지 않는다.
7. navigation chrome, tab role, button disabled state는 기존 QA script와 문서 기준을 따른다.

## 11. 중단 조건

다음 조건이면 작업을 중단하고 사용자 판단을 기다린다.

1. 실제 사용자 데이터, 원본 오디오, 개인 health export가 노출될 수 있다.
2. 서버/클라우드/외부 API/외부 SDK/계정 체계를 추가해야 한다.
3. HealthKit write 또는 custom type이 필요하다.
4. Fitdays 서버/API 또는 비공식 연동이 필요하다.
5. destructive action, force push, tag 교체, release 삭제, rollback이 필요하다.
6. 요청 밖 model/storage/schema/persistence contract 변경이 필요하다.
7. 실패 원인을 확인하지 못했고 같은 실패를 반복하고 있다.
8. 검증을 완화하거나 미실행 검증을 PASS로 처리해야만 진행할 수 있다.

## 12. 모델, 추론, 단일 서브에이전트 운영

### 12.1 기본 운영

Codex 메인 기본 후보는 `gpt-6-astra` / `medium`이다. 실제 세션에서 사용 가능한 모델과 사용자의 설정을 우선하며, 문서에 있는 모델명이 곧 현재 사용 가능함을 뜻하지 않는다. 설정 변경을 확인하지 못했으면 바꿨다고 보고하지 않는다.

OpenAI 공식 guidance 기준으로 GPT-6 Astra는 복합 workflow, code, browsing, software engineering, 전문 작업에 강하고, 지시 준수와 경계 판단이 강화된 모델이다. 동시에 AGENTS.md와 skill 지시에 민감할 수 있으므로 이 파일은 필요한 경계만 남기고 과도한 전수 읽기·과잉 테스트 지시를 피한다.

### 12.2 Codex 모델 역할

| 모델 | 우선 사용처 |
| --- | --- |
| `gpt-6-astra` | 메인 기본, 복합 개발, release 판단, 긴 작업, 경계·정확도 판단 |
| `gpt-5.6-sol` | Astra를 쓰지 않는 환경의 고난도 구현/조사 대안 |
| `gpt-5.6-terra` | 제한된 개발, 단일 화면/단일 모듈 변경, 비용 균형 작업 |
| `gpt-5.6-luna` | 결정적 반복, 대량 정리, 포맷 변환, 단순 목록화 |

이 표는 추천 기준이다. 실제 사용 모델은 현재 도구 allowlist와 사용자 설정으로 확인한다. 비용·품질 우위는 실측 없이 보장하지 않는다.

### 12.3 추론 수준

| 수준 | 기준 |
| --- | --- |
| `none` | 지원 모델에서만 쓰는 결정적 변환/단순 목록화. Astra에는 사용하지 않는다. |
| `low` | 저위험 단일 파일, 반복 확인, 지연 우선 작업 |
| `medium` | 기본 출발점 |
| `high` | 다중 파일 개발, 원인 분석, 테스트 설계, release gate 해석 |
| `xhigh` | 아키텍처 변경, 복구/마이그레이션, 복잡한 디버깅, 높은 불확실성 |
| `max`/`ultra` | 지원 여부와 명시 승인을 확인한 뒤, 실패 비용이 크고 품질 우선인 예외 작업에만 검토 |

점수나 난도만으로 메인 설정을 자동 상향하지 않는다. 부족하면 원인, 이미 시도한 검증, 남은 불확실성을 보고하고 사용자의 `high` 또는 `xhigh` 승인을 기다린다.

### 12.4 VATester 점수

모델 추천이 필요하거나 담당을 나눌 때만 보조 기준으로 사용한다.

| 항목 | 0 | 1 | 2 |
| --- | --- | --- | --- |
| 영향도 | 문서/표현 | 단일 기능 또는 내부 로직 | 핵심 기능, release, 사용자 데이터 |
| 불확실성 | 요구와 경계 명확 | 일부 탐색 필요 | 원인 미상, 설계 선택, 외부 상태 의존 |
| 검증 난이도 | 정적 확인 또는 단일 테스트 | 여러 테스트/시나리오 | 실기기, 장시간, release gate |
| 변경 범위 | 무변경 또는 한 파일 | 단일 모듈/소수 파일 | 다중 모듈, 문서, 테스트 동시 변경 |

| 총점 | 추천 |
| --- | --- |
| 0~2 | `gpt-5.6-luna` 또는 낮은 추론 |
| 3~5 | `gpt-5.6-terra` 또는 Astra/medium |
| 6~8 | `gpt-6-astra`/medium 이상 또는 `gpt-5.6-sol` |

개인정보, 의학적 오해, HealthKit write 금지, 서버/네트워크 금지, 실제 사용자 데이터 노출, 기록 유실, 마이그레이션, 장시간 실기기 안정성, release correctness가 있으면 낮은 점수라도 상향 검토한다.

### 12.5 단일 서브에이전트 운영

새 작업이나 지침 변경 시 이 절을 확인하고, 담당자·모델을 선택하거나 재판단할 때 12.2~12.4를 참고한다. 모델·위임 스킬 일반 지침보다 이 프로젝트의 단일 서브에이전트 운영 기준이 우선한다.

1. 메인이 범위, 구조, 불변 계약, 합격 기준, 회귀 범위를 먼저 확정한다.
2. 확정된 기능 단위 구현은 단일 담당자에게 위임할 수 있다. 직접 처리가 더 짧은 수정이나 단순 실행에는 억지로 위임하지 않는다.
3. 메인 외 작업 에이전트는 최대 한 개다. 기존 담당자의 상태를 확인하고 순차 재사용한다.
4. 별도 구현자와 별도 검토자를 동시에 추가하지 않는다.
5. 서브에이전트의 하위 생성과 재위임은 금지한다. 다른 작업 생성 도구로 우회하지 않는다.
6. 위임 전 현재 도구가 지원하는 정확한 모델과 추론 값을 확인한다.
7. 위임 prompt에는 소유 파일, 입력, 출력, 불변 계약, 합격/회귀 기준, 실행 승인된 명령, 모델/추론, 하위 위임 금지, 보고 항목을 적는다.
8. 같은 파일을 여러 담당자가 동시에 수정하지 않는다.
9. 메인이 실제 diff와 evidence를 직접 검토한다. 서브에이전트의 PASS 요약만으로 완료하지 않는다.
10. 동일 원인 재발, 교차 계약 실패, 근거 부족이면 메인이 회수한다. 두 번째 담당자 추가나 자동 모델 상향으로 우회하지 않는다.
11. 전체 대화 복사, 함수별 과도한 분할, 같은 조사 반복을 피한다. 필요한 문맥만 전달한다.
12. 같은 코드·환경·범위의 유효 evidence는 인계만으로 재실행하지 않는다. 변경·누락·만료·실패가 있으면 5장에 따라 재검증 범위를 판단한다.

### 12.6 모델 추천 보고 형식

로드맵, 후속 작업, QA 계획, 위임 제안에는 필요 시 아래 형식을 사용한다.

```text
추천 모델: gpt-6-astra
추론 수준: medium
선정 근거: HealthKit read-only와 release copy 경계를 함께 보지만 구조 변경은 없는 문서/QA 정리 작업
```

같은 설정의 여러 이슈는 공통 설정을 한 번 적고, 각 이슈에는 작업·이유·예상 검증만 적는다. 후속 추천은 현재 버전·현재 step 안에서 실제 처리 가능한 항목만 허용한다.

## 13. 절대 금지 요약

1. 서버 업로드, 클라우드 처리, 외부 API, 외부 분석 SDK, 광고 SDK, 계정 시스템 추가 금지
2. HealthKit write, custom type 생성, 앱 점수 HealthKit 쓰기 금지
3. Fitdays 서버/API 직접 연결, 비공식 연동, reverse engineering 금지
4. 전체 밤 원본 오디오 저장 금지
5. sleep talk 텍스트 변환 금지
6. 실제 개인 CSV, 원본 오디오, HealthKit export, device log repository 포함 금지
7. 의학적 판정, 치료/조치 판단, 건강 인과 단정 문구 금지
8. 요청 없는 storage/model/schema/persistence contract 변경 금지
9. 미실행/실패/미확인을 완료 또는 PASS로 보고 금지
10. 승인 없는 커밋, 푸시, PR, merge, tag, GitHub Release 금지
