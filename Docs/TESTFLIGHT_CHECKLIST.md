# TestFlight Checklist

## 앱 정보

- 앱 표시 이름이 `밤숨`인지 확인한다.
- 영어 브랜드 표기는 `NightBreath`로 유지한다.
- 부제는 `수면 소리 리포트`를 우선 사용한다.
- 앱 설명에는 온디바이스 분석, 원본 전체 오디오 미저장, HealthKit read-only, 서버 전송 없음이 들어가야 한다.

## 빌드 설정

- `MARKETING_VERSION`과 `CURRENT_PROJECT_VERSION`을 TestFlight 업로드 전에 확인한다.
- Bundle Identifier가 `com.local.NightBreath`에서 배포용 identifier로 바뀌어야 하는지 확인한다.
- Release configuration으로 archive한다.
- `CODE_SIGN_STYLE`, Team, Provisioning Profile, HealthKit capability를 확인한다.
- `NSMicrophoneUsageDescription`과 `NSHealthShareUsageDescription`이 한국어 우선 문구인지 확인한다.

## Release 노출 점검

- `DatasetReplayView`는 Release 빌드에 노출되지 않아야 한다.
- `DetectorTuningView`는 Release 빌드에 노출되지 않아야 한다.
- `SimulatorScenarioView`는 Release 빌드에 노출되지 않아야 한다.
- `AudioDebugView`는 Release 빌드에 노출되지 않아야 한다.
- `SampleCaptureView`는 Release 빌드에 노출되지 않아야 한다.
- Settings의 개발 섹션은 `#if DEBUG` 안에 있어야 한다.
- Offline Evaluation, Training, Dataset manifest 도구는 앱 UI에 노출하지 않는다.

## 개인정보와 권한

- 마이크 권한 문구가 수면 중 소리 기반 지표 분석 목적을 설명하는지 확인한다.
- 원본 전체 오디오는 저장하지 않는다는 문구가 온보딩/설정/권한 설명에 들어가 있는지 확인한다.
- 이벤트 오디오 샘플 저장 기본값이 OFF인지 확인한다.
- 이벤트 오디오 샘플은 opt-in, 짧은 구간, 로컬 저장, 삭제 가능 정책을 유지한다.
- HealthKit은 read-only로만 사용한다.
- HealthKit에 수면 소리 점수나 앱 데이터를 쓰지 않는다.
- 서버 업로드, 클라우드 처리, 외부 분석 SDK, 광고 SDK가 없는지 확인한다.
- 계정/로그인 기능이 없는지 확인한다.

## 문구 점검

- 앱 설명과 UI는 “수면 중 소리 기반 지표”, “호흡정지 의심 구간”, “이갈이 의심 소리”, “이 앱은 진단 목적의 의료기기가 아닙니다”처럼 신중한 표현을 사용한다.
- 수면 소리 점수는 웰니스 참고 지표로 설명한다.
- 혈압/체성분 그래프는 건강 상태 결론처럼 보이지 않게 설명한다.
- 교차 분석 화면은 개인 패턴 탐색이며 인과관계를 의미하지 않는다고 안내한다.

## 외부 자산 점검

- Toss/TDS 로고, 아이콘, 이미지, 컴포넌트가 앱 bundle에 포함되어 있지 않은지 확인한다.
- AppIcon, LaunchScreen, screenshot asset의 라이선스와 출처를 확인한다.
- 외부 SDK, 광고 SDK, analytics SDK가 추가되지 않았는지 확인한다.

## Smoke Test

- Release configuration으로 빌드한다.
- 실제 iPhone에서 3분 수면 측정을 실행한다.
- 측정 종료 후 수면 리포트가 열리는지 확인한다.
- 마이크 권한 거부 시 앱이 crash하지 않는지 확인한다.
- 이벤트 오디오 샘플 저장 OFF 상태에서 오디오 파일이 생성되지 않는지 확인한다.
- 이벤트 오디오 샘플 저장 ON 상태에서 짧은 샘플만 생성되고 삭제가 가능한지 확인한다.
- HealthKit 권한 거부 시 건강 대시보드가 empty/permission state를 안전하게 표시하는지 확인한다.
- HealthKit 일부 항목만 허용했을 때 source와 빈 상태가 자연스럽게 표시되는지 확인한다.
- 가능한 경우 overnight 1회 측정 후 리포트, 저장 용량, 배터리 사용량을 확인한다.

## 업로드 전 명령

```sh
xcodebuild -project SleepSoundApp.xcodeproj -scheme SleepSoundApp -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
swift test --filter AppStoreReadiness
swift test --filter Privacy
```

실제 TestFlight archive는 Xcode Organizer 또는 CI의 signing 환경에서 수행한다.
