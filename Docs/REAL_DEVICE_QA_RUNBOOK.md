# Real Device QA Runbook

이 문서는 NightBreath / 밤숨의 실제 iPhone manual QA를 실행할 때 사용하는 절차와 기록 템플릿입니다. `QA_CHECKLIST.md`는 전체 release/TestFlight 전 체크리스트이고, 이 문서는 실제 실행 순서와 증거 기록을 더 구체적으로 정리합니다.

## 원칙

- 실제 iPhone QA 결과를 simulator screenshot이나 mock data 결과와 섞지 않습니다.
- 실제 개인 건강 데이터, 실제 Fitdays CSV 파일, 실제 오디오 파일은 repository에 커밋하지 않습니다.
- HealthKit은 read-only로만 확인합니다.
- Fitdays import는 사용자가 직접 선택한 로컬 파일만 사용합니다.
- Fitdays 서버/API 연결, 비공식 연결 방식, reverse engineering은 하지 않습니다.
- 건강 상태를 판단하거나 지표 사이의 원인과 결과를 주장하지 않습니다.

## 준비 상태

1. iPhone을 Mac에 연결하거나 같은 네트워크의 paired 상태로 준비합니다.
2. iPhone 잠금 해제, Trust This Computer, Developer Mode, 개발자 서명을 확인합니다.
3. Xcode에서 `SleepSoundApp.xcodeproj`와 `SleepSoundApp` scheme을 선택합니다.
4. 실제 기기 대상과 signing team을 설정합니다.
5. 앱 실행 전 `swift test --no-parallel`과 iOS Debug build를 통과시킵니다.

기기 감지 명령:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun devicectl list devices
```

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun xctrace list devices
```

`devicectl`에서는 보이지만 `xctrace`에서 offline으로 표시되면 iPhone 잠금 해제, 신뢰 설정, Developer Mode, 케이블/네트워크 연결 상태를 먼저 확인합니다.

## 빌드와 설치

Xcode에서 직접 실행하는 방식을 우선 사용합니다. 명령줄 빌드는 signing 환경에 따라 다르므로 실패 시 Xcode Organizer와 Devices and Simulators에서 기기 상태를 먼저 확인합니다.

명령줄 빌드 예시:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild \
  -project SleepSoundApp.xcodeproj \
  -scheme SleepSoundApp \
  -configuration Debug \
  -destination 'platform=iOS,name=<실제 iPhone 이름>' \
  build
```

## QA 세션 기록 템플릿

아래 내용은 private QA note에 기록하고, repository에는 민감 값이나 실제 파일명을 넣지 않습니다.

```text
Date:
Tester:
Commit:
iPhone model:
iOS version:
Build configuration:
Signing team:

Microphone permission:
HealthKit permission scenario:
Fitdays import scenario:
Event audio sample setting:

Result summary:
Blocking issue:
Follow-up issue:
Evidence location:
Sensitive data included in repo: No
```

## Smoke Test 흐름

1. 앱 첫 실행
   - 온보딩이 표시되는지 확인합니다.
   - HealthKit 권한 sheet가 자동으로 표시되지 않는지 확인합니다.
   - 마이크 권한은 수면 시작 흐름에서만 요청되는지 확인합니다.

2. Foreground 1분
   - 수면 시작 후 1분 동안 화면을 켠 상태로 둡니다.
   - 경과 시간, 실제 오디오 수신 시간, 커버리지 값이 움직이는지 확인합니다.
   - 수면 종료 후 리포트가 생성되는지 확인합니다.

3. 화면 잠금 3분
   - 수면 시작 후 iPhone을 잠급니다.
   - 3분 후 잠금 해제하고 수신 시간과 interruption count를 확인합니다.
   - 리포트가 측정 품질을 안전하게 표시하는지 확인합니다.

4. 앱 백그라운드 3분
   - 수면 시작 후 홈 화면으로 나갑니다.
   - 3분 후 앱으로 돌아와 캡처 상태와 수신 시간을 확인합니다.

5. 잠금 30분
   - 충전 상태에서 30분 잠금 테스트를 수행합니다.
   - 배터리, 발열, 앱 복귀 상태를 기록합니다.

6. Overnight 후보
   - TestFlight 전 최소 1회 충전 상태 overnight 측정을 수행합니다.
   - 배터리, 발열, 리포트 생성, 저장 용량, 이벤트 오디오 샘플 정책을 확인합니다.

## HealthKit Read-Only QA

1. 앱 첫 실행과 수면 시작에서 HealthKit 권한 sheet가 표시되지 않는지 확인합니다.
2. `HealthDashboardView`에서 사용자가 `건강 데이터 연결`을 선택할 때만 권한 sheet가 표시되는지 확인합니다.
3. 전체 허용, 일부 허용, 거부, 데이터 없음 상태를 가능한 범위에서 각각 확인합니다.
4. 혈압, 체중, 체성분, 활동 지표가 sourceName과 측정 시각을 함께 표시하는지 확인합니다.
5. HealthKit-backed metric과 Fitdays local-only metric이 badge와 설명으로 구분되는지 확인합니다.
6. 앱이 HealthKit에 데이터를 쓰지 않는지 코드 scan과 실제 동작으로 확인합니다.
7. 수면 기능은 HealthKit 권한 거부 후에도 정상 동작해야 합니다.

기록 시 실제 수치 대신 다음처럼 요약합니다.

```text
HealthKit permission: allowed / denied / partial
Metrics visible: blood pressure / body mass / body fat / activity
Source labels visible: yes / no
Write attempt observed: no
Server transfer observed: no
```

## Fitdays CSV Import QA

1. 실제 개인 CSV는 repository 밖에 둡니다.
2. screenshot이나 public review에는 synthetic CSV만 사용합니다.
3. Fitdays import 화면에서 사용자가 명시적으로 파일을 선택할 때만 import가 시작되는지 확인합니다.
4. valid CSV에서 preview, result, sample count, skipped row, unknown column이 표시되는지 확인합니다.
5. invalid date/time row가 앱을 멈추지 않고 skipped row로 처리되는지 확인합니다.
6. HealthKit 표준 지표가 CSV에 있어도 `sourceType == fitdaysCSV`로 보이는지 확인합니다.
7. Fitdays 확장 지표는 HealthKit-backed가 아니라 local-only로 설명되는지 확인합니다.
8. import batch 삭제 흐름이 있으면 sample도 함께 사라지는지 확인합니다.

기록 시 실제 파일명과 실제 수치를 적지 않습니다.

```text
CSV type: private Fitdays export / synthetic fixture
Rows parsed:
Samples created:
Skipped rows:
Unknown columns:
Local-only metric visible: yes / no
Actual file name recorded in repo: no
```

## Event Audio Sample QA

1. 기본값 OFF에서 새 이벤트 오디오 샘플이 저장되지 않는지 확인합니다.
2. 사용자가 opt-in을 켠 경우에만 짧은 이벤트 전후 샘플이 저장되는지 확인합니다.
3. 저장 샘플은 전체 밤 오디오가 아닌지 확인합니다.
4. 개별 삭제, 전체 삭제, orphan cleanup이 동작하는지 확인합니다.
5. 저장소 통계가 앱 재실행 후에도 일관적인지 확인합니다.

## 실패 기록 기준

다음은 release/TestFlight 전 blocking으로 취급합니다.

- 앱 첫 실행에서 HealthKit 권한 sheet가 자동 표시됨
- HealthKit write 대상이 비어 있지 않음
- Fitdays 서버/API 연결 또는 비공식 연결 시도
- 실제 개인 CSV, 건강 데이터, 오디오 파일이 repository에 추가됨
- 전체 밤 원본 오디오 파일 생성
- 마이크 권한 거부 또는 HealthKit 권한 거부 시 앱 crash
- 의료 판단이나 인과관계처럼 읽히는 사용자-facing 문구

## 관련 문서

- `QA_CHECKLIST.md`
- `Docs/BACKGROUND_RECORDING_QA.md`
- `Docs/HEALTHKIT_READ_ONLY.md`
- `Docs/FITDAYS_IMPORT.md`
- `Docs/PRIVACY_STORAGE_AUDIT.md`
- `Docs/TESTFLIGHT_CHECKLIST.md`
