# NightBreath / 밤숨 V1 QA Checklist

이 체크리스트는 NightBreath / 밤숨 V1 프로토타입을 실제 iPhone에서 검증하기 위한 문서입니다.

앱은 수면 중 소리 기반 웰니스 리포트에서 시작해 온디바이스 개인 건강 리듬 리포트로 확장되는 프로토타입입니다. 진단 목적의 의료기기가 아니며, Daily Rhythm 화면은 mock/protocol 기반 상태와 HealthKit read-only 연결 상태를 구분해 검증합니다. 서버 업로드, 클라우드 동기화, 외부 SDK는 범위에 포함되지 않습니다.

## 문서 역할

이 체크리스트는 실제 iPhone smoke test, background recording test, release/TestFlight 전 manual QA를 위한 문서입니다.

일상 개발 중 모든 변경마다 매번 수행하는 체크리스트가 아니라, 실제 기기 동작과 배포 전 위험을 확인할 때 사용하는 문서입니다.

README screenshot과 `Docs/UI_GALLERY.md`는 mock data와 screenshot scenario 기반 문서용 화면을 정리합니다. 현재 기존 screenshot 후보는 품질 재검토 중이며, 내부 QA label 노출과 crop 정렬 문제가 해결되기 전에는 README/App Store/user-facing 문서에 렌더링하지 않습니다. 이 체크리스트는 실제 기기에서 마이크, 권한, 저장소, 장시간 동작, HealthKit read-only 연결 상태를 확인하는 용도로 유지합니다.

README/UI Gallery의 문서용 screenshot은 실제 iPhone QA screenshot, 실제 개인 건강 데이터, 실제 오디오 샘플과 혼동하지 않습니다.

실제 iPhone에서 smoke test와 HealthKit/Fitdays import 흐름을 순서대로 실행할 때는 `Docs/QA_GUIDE.md`를 함께 사용합니다.

TestFlight 내부 테스트 후보 build를 검증할 때는 `Docs/TESTFLIGHT_INTERNAL_TEST_PLAN.md`의 blocking gate와 evidence template을 함께 사용합니다.

## 1. 빌드와 테스트

- [ ] Xcode에서 `SleepSoundApp.xcodeproj`가 열린다.
- [ ] 실제 iPhone 대상이 선택된다.
- [ ] Signing & Capabilities에서 개발 팀 설정 후 iPhone 실행이 가능하다.
- [ ] Debug iOS 빌드가 성공한다.
- [ ] Release iOS 빌드가 성공한다.
- [ ] `swift test`가 성공한다.
- [ ] 테스트 실패가 있으면 실패 테스트명과 재현 조건을 기록한다.

명령줄 확인 예시:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun swift test --cache-path .build/swiftpm-cache
```

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild \
  -project SleepSoundApp.xcodeproj \
  -scheme SleepSoundApp \
  -configuration Debug \
  -destination generic/platform=iOS \
  -derivedDataPath .build/XcodeDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## 2. 마이크 권한 요청

- [ ] 앱 최초 실행 후 “수면 시작”을 누르면 마이크 권한 요청이 표시된다.
- [ ] 권한 허용 시 수면 측정 화면으로 이동하거나 캡처가 시작된다.
- [ ] 권한 거부 시 사용자에게 권한 문제가 명확히 표시된다.
- [ ] iOS 설정에서 마이크 권한을 다시 허용한 뒤 앱 흐름이 복구된다.
- [ ] 권한 안내 문구가 과장되거나 불안감을 주지 않는다.

## 3. 수면 시작

- [ ] “수면 시작” 버튼을 누르면 새 수면 세션이 생성된다.
- [ ] 오디오 세션 설정 실패 시 에러가 표시된다.
- [ ] 오디오 캡처 시작 실패 시 앱이 멈추지 않는다.
- [ ] 수면 시작 직후 경과 시간이 증가한다.
- [ ] 전체 밤 원본 오디오 파일을 저장하지 않는다.

## 4. 캡처 중 UI

- [ ] 캡처 상태가 “녹음/분석 중” 성격으로 표시된다.
- [ ] 경과 시간이 실시간으로 갱신된다.
- [ ] 현재 RMS 또는 level 값이 갱신된다.
- [ ] 최근 감지 이벤트 수가 갱신된다.
- [ ] 캡처 중 화면에서 앱이 멈추거나 과도하게 버벅이지 않는다.
- [ ] 화면 잠금 또는 앱 전환 상황은 별도 장시간 테스트 항목으로 기록한다.

## 5. 수면 종료

- [ ] “수면 종료” 버튼을 누르면 오디오 캡처가 안전하게 중지된다.
- [ ] “수면 종료” 버튼을 누른 직후 실제 오디오 수신 시간이 더 이상 증가하지 않는다.
- [ ] 리포트 정리가 늦어져도 캡처 상태는 먼저 “캡처 종료됨”으로 바뀐다.
- [ ] DEBUG 측정 상태에서 `종료 후 입력 chunk`가 0 또는 매우 작은 값이다.
- [ ] stop timeout safety 또는 force stop이 발생하면 diagnostics/debug log에 reason이 남는다.
- [ ] 종료 시간이 세션에 반영된다.
- [ ] 수집된 이벤트 후보로 NightReport가 생성된다.
- [ ] 종료 직후 수면 리포트 화면으로 이동한다.
- [ ] 종료를 여러 번 눌러도 중복 저장이나 크래시가 발생하지 않는다.

P0 fix 이후 overnight 전 gate:

- [ ] `Docs/QA_GUIDE.md`의 Foreground stop smoke를 통과했다.
- [ ] `Docs/QA_GUIDE.md`의 Double stop tap을 통과했다.
- [ ] `Docs/QA_GUIDE.md`의 Lock/background short stop을 통과했다.
- [ ] stop 이후 `receivedAudioDuration`이 계속 증가하지 않는다.
- [ ] evidence template에 stop diagnostics와 `sensitive data included in repo: No`를 기록했다.

## 6. 리포트 생성

- [ ] 리포트에 측정 시간이 표시된다.
- [ ] 리포트에 추정 수면 시간이 표시된다.
- [ ] 수면 소리 점수가 0~100 범위로 표시된다.
- [ ] 코골기 시간이 표시된다.
- [ ] 이갈이 의심 소리 횟수가 표시된다.
- [ ] 호흡정지 의심 구간 횟수가 표시된다.
- [ ] gasp-like 회복 호흡 횟수가 표시된다.
- [ ] 기침 의심 소리 횟수가 표시된다.
- [ ] 환경 소음 횟수가 표시된다.
- [ ] 각성 의심 구간 횟수가 표시된다.
- [ ] 가장 방해가 컸던 시간대가 표시되거나 데이터 부족 상태가 자연스럽게 표시된다.
- [ ] 이벤트 타임라인이 표시된다.
- [ ] 주요 원인 설명이 한국어로 자연스럽게 표시된다.
- [ ] 주의 문구가 웰니스 참고 정보 톤으로 표시된다.

## 7. 로컬 저장

- [ ] 수면 세션이 로컬에 저장된다.
- [ ] 수면 이벤트 요약이 로컬에 저장된다.
- [ ] NightReport가 로컬에 저장된다.
- [ ] MorningCheckIn이 로컬에 저장된다.
- [ ] 앱 재실행 후 최근 리포트가 유지된다.
- [ ] 최근 7일 리포트 조회가 가능하다.
- [ ] 저장 데이터에 전체 밤 원본 오디오가 포함되지 않는다.
- [ ] 이벤트 오디오 샘플은 감지 이벤트 전후의 짧은 구간만 저장된다.
- [ ] 이벤트 오디오 샘플의 저장 시간, 개수, 용량 제한이 적용된다.
- [ ] 이벤트와 연결되지 않은 후보 샘플이 세션 종료 후 남지 않는다.
- [ ] 잠꼬대/말소리 텍스트가 저장되지 않는다.

## 8. 데이터 삭제

- [ ] 개인정보 설정 화면에 로컬 데이터 삭제 기능이 있다.
- [ ] 특정 세션 삭제가 동작한다.
- [ ] 전체 수면 데이터 삭제가 동작한다.
- [ ] 이벤트 오디오 샘플 전체 삭제가 동작한다.
- [ ] 이벤트 타임라인에서 개별 이벤트 오디오 샘플 삭제가 동작한다.
- [ ] 이벤트 오디오 샘플 삭제 후 리포트의 저장된 오디오 시간이 갱신된다.
- [ ] 삭제 후 홈 화면과 최근 리포트 화면이 빈 상태를 자연스럽게 표시한다.
- [ ] 삭제 후 앱 재실행 시 삭제된 데이터가 복구되지 않는다.

## 9. DEBUG 오디오 화면

- [ ] DEBUG 빌드에서 오디오 디버그 화면이 노출된다.
- [ ] Release 빌드에서 디버그 메뉴가 노출되지 않는다.
- [ ] capture state가 표시된다.
- [ ] current RMS가 표시된다.
- [ ] current energy가 표시된다.
- [ ] silence/noise 추정 상태가 표시된다.
- [ ] latest DetectorOutput이 표시된다.
- [ ] event type이 표시된다.
- [ ] confidence가 0.0~1.0 범위로 표시된다.
- [ ] intensity가 표시된다.
- [ ] debugReason이 표시된다.
- [ ] threshold 값이 표시되거나 조정된다.
- [ ] 디버그 데이터가 서버로 전송되지 않는다.
- [ ] 디버그 화면이 원본 전체 오디오를 파일로 저장하지 않는다.

## 10. 원본 전체 오디오 저장 여부 확인

- [ ] 앱 샌드박스 Documents/Library/Caches에 전체 밤 원본 오디오 파일이 생성되지 않는다.
- [ ] `AVAudioFile` 쓰기 로직은 DEBUG 수동 샘플 또는 짧은 이벤트 오디오 샘플 저장 용도로만 사용된다.
- [ ] 코드에 전체 밤 오디오 파일 저장 목적의 `AVAssetWriter` 사용이 없다.
- [ ] ring buffer가 최근 제한된 청크만 유지한다.
- [ ] 이벤트 요약에는 type, 시간, duration, confidence, intensity, 짧은 이벤트 오디오 파일명과 duration 정도만 저장된다.
- [ ] 이벤트 오디오 샘플 저장 토글의 기본값은 꺼짐이다.
- [ ] 토글이 꺼진 상태에서는 새 이벤트 오디오 샘플 파일이 저장되지 않는다.
- [ ] 토글을 켠 경우에만 이벤트 전후의 짧은 오디오 샘플이 저장된다.
- [ ] 토글 OFF와 저장된 이벤트 오디오 샘플 삭제 버튼은 별도로 동작한다.
- [ ] 개인정보 화면에서 저장된 이벤트 오디오 샘플 수, 총 시간, 총 용량을 확인할 수 있다.
- [ ] 개인정보 화면에서 연결되지 않은 이벤트 오디오 샘플 수와 용량을 확인할 수 있다.
- [ ] 연결되지 않은 샘플 정리 버튼이 기존 orphan `.caf` 파일을 삭제한다.
- [ ] 이벤트 오디오 샘플 저장 위치는 `Application Support/NightBreath/EventAudioSnippets/`이다.
- [ ] 일반 수면 세션용 전체 밤 오디오 파일은 존재하지 않는다.

코드 스캔 예시:

```bash
rg -n "AVAudioFile|AVAssetWriter|write\\(|\\.caf|\\.wav|\\.m4a" SleepSoundApp Tests
```

허용되는 예외:

- `EventAudioSnippetStore`의 짧은 이벤트 오디오 `.caf` 저장
- DEBUG 전용 `SampleCaptureView`의 수동 짧은 샘플 `.caf` 저장

## 11. 네트워크 호출 없음 확인

- [ ] `URLSession` 기반 호출이 없다.
- [ ] `http://` 또는 `https://` endpoint가 없다.
- [ ] 서버 업로드 코드가 없다.
- [ ] 클라우드 동기화 코드가 없다.
- [ ] 외부 분석 SDK가 없다.
- [ ] 광고 SDK가 없다.

코드 스캔 예시:

```bash
rg -n "URLSession|http://|https://|NWConnection|Alamofire|Firebase|Analytics|AdMob" SleepSoundApp Tests Package.swift
```

## 12. HealthKit / Daily Rhythm 확인

- [ ] 앱 첫 실행이나 수면 시작 시 HealthKit 권한 팝업이 표시되지 않는다.
- [ ] Daily Rhythm 확장은 mock/protocol 기반 상태에서도 화면이 정상 동작한다.
- [ ] 실제 HealthKit 연동 단계에서는 사용자가 “건강 데이터 연결”을 누를 때만 HealthKit read 권한을 요청한다.
- [ ] 실제 HealthKit 연동 단계에서는 HealthKit share/write 대상이 비어 있다.
- [ ] HealthKit 권한 sheet에서 쓰기 항목이 보이지 않고, 허용/일부 허용/거부 결과를 private note에만 기록한다.
- [ ] 일부 허용 상태에서는 허용된 항목만 표시되고, 제한된 항목은 empty/limited state로 남는다.
- [ ] HealthKit save/delete API를 사용하지 않는다.
- [ ] 권한 거부 또는 데이터 없음 상태에서 앱이 정상 동작한다.
- [ ] HealthKit 권한 거부 후에도 수면 시작/종료와 리포트 화면이 정상 동작한다.
- [ ] 수면 소리 점수, 이벤트, 리포트, 피드백을 HealthKit에 쓰지 않는다.

코드 스캔 예시:

```bash
rg -n "import HealthKit|HKHealthStore|requestAuthorization|toShare|HKSampleQuery|save\\(|delete\\(" SleepSoundApp Tests Package.swift
```

## 13. Extended Health Metrics / Fitdays import 확인

- [ ] `HealthDashboardView`에서 전체 건강 지표, 월 건강 캘린더, Fitdays 가져오기, 기존 혈압/체성분 dashboard 진입점이 보인다.
- [ ] `FitdaysImportView`에서 사용자가 명시적으로 확보한 CSV/export 파일을 선택하거나 `클립보드 붙여넣고 미리보기`를 눌렀을 때만 import 흐름이 시작된다.
- [ ] 실제 Fitdays 앱에서 Reports / Data Reports / Chart / History Records / More Data / Account / Customer Service Center 경로를 확인하고, 결과는 private note에만 남긴다.
- [ ] 실제 Fitdays 앱에서 CSV/export 메뉴가 보이지 않으면 Apple 건강앱 read-only 표준 지표만 사용하고, Fitdays 서버/API나 비공식 연결을 시도하지 않는다.
- [ ] Fitdays 앱 버전, 로그인 상태, 실제 메뉴명, 실제 파일명, 실제 path, 실제 수치는 repository나 screenshot에 남기지 않는다.
- [ ] export가 보이지 않아도 Fitdays 로그인, 서버/API 연결, 자동 동기화, UI scraping, reverse engineering을 추가하지 않는다.
- [ ] valid synthetic CSV/TSV와 synthetic 월별 데이터 붙여넣기 텍스트로 import preview와 import result가 표시된다.
- [ ] invalid CSV row는 앱을 멈추지 않고 skipped row로 표시된다.
- [ ] 알 수 없는 column은 unknown column으로 표시되고 전체 import를 막지 않는다.
- [ ] 지원 지표 column 없음 또는 import 가능한 sample 0개인 파일이 저장 전에 거부된다.
- [ ] import result에서 생성 sample 수, skipped row, error count, sourceName이 명확히 보인다.
- [ ] import batch 삭제가 가능한 경우 해당 batch의 sample도 함께 삭제되는지 확인한다.
- [ ] extended metric sample 삭제가 가능한 경우 삭제 후 overview, calendar, metric detail에서 사라지는지 확인한다.
- [ ] `HealthMetricsOverviewView`에서 HealthKit-backed metric과 Fitdays local-only metric이 category와 source badge로 구분된다.
- [ ] `HealthCalendarView`에서 이전/다음 월 이동과 오늘 이동이 동작한다.
- [ ] 데이터가 있는 날짜 cell에 수면, 혈압, 체성분, 활동, check-in indicator가 표시된다.
- [ ] 날짜를 누르면 `DailyMeasurementDetailView`에서 수면, 아침 컨디션, 저녁 체크인, 혈압, 체성분, Fitdays 확장 체성분, 활동, 앱 계산 지표가 category별로 보인다.
- [ ] `DailyMeasurementDetailView`의 metric row에서 `MetricDetailView`로 이동할 수 있다.
- [ ] `MetricDetailView`에서 7일, 30일, 90일, 1년, 전체 기간 선택이 동작한다.
- [ ] `MetricDetailView`에서 전체, HealthKit, Fitdays CSV, Manual, App Computed source filter가 동작한다.
- [ ] `MetricDetailView`에서 최근 값, 평균, 최소, 최대, 최근 변화, 측정 횟수, sample list가 표시된다.
- [ ] Fitdays local-only 지표 설명이 HealthKit-backed 지표 설명과 구분된다.
- [ ] 모든 EHM 화면에서 서버 전송 없음, HealthKit write 없음, 개인 참고용 원칙이 유지된다.
- [ ] 의료 진단이나 인과관계처럼 읽히는 문구가 없다.

## 14. 의료 표현 확인

- [ ] 질환명을 확정하는 표현을 사용하지 않는다.
- [ ] 특정 수면 소리를 확정 상태로 단정하지 않는다.
- [ ] 사용자의 건강 상태를 판정하는 표현을 사용하지 않는다.
- [ ] 치료 판단처럼 읽히는 표현을 사용하지 않는다.
- [ ] 임상 지표를 정확히 산출한다는 표현을 사용하지 않는다.
- [ ] “호흡정지 의심 구간”, “이갈이 의심 소리”, “수면 소리 점수” 표현을 사용한다.
- [ ] 반복적으로 높게 나타나는 패턴은 “전문가 상담을 고려해보세요” 수준으로 안내한다.
- [ ] 앱이 진단 목적의 의료기기가 아니라는 안내가 표시된다.

코드 스캔 예시:

```bash
rg -n "확진|질병|치료|AHI|확정" SleepSoundApp README.md QA_CHECKLIST.md
```

## 15. 아직 남은 수동 위험 요소

- [ ] 실제 iPhone 장시간 측정 중 배터리 사용량을 확인해야 한다.
- [ ] 잠금 화면 상태에서 캡처 지속 여부를 확인해야 한다.
- [ ] 백그라운드 전환 후 캡처 상태 복구 여부를 확인해야 한다.
- [ ] 다양한 iPhone 모델에서 마이크 입력 level 차이를 확인해야 한다.
- [ ] 조용한 방, 선풍기/에어컨, 거리 소음, 침구 마찰 등 환경별 오탐 가능성을 기록해야 한다.
- [ ] rule-based detector threshold는 실제 데이터로 계속 튜닝해야 한다.
- [ ] 장시간 측정에서 이벤트가 0개일 때 Detector 분석 요약의 raw 후보 수, smoothing 전/후 후보 수, 주요 탈락 이유, RMS/energy p90을 확인해야 한다.
- [ ] 실제 코골이 또는 코골기 유사 smoke에서 final event가 0개여도 raw/reject diagnostics가 남는지 확인해야 한다.
- [ ] Snore signal smoke에서 raw diagnostics가 전혀 없으면 detector 판단용 overnight로 넘어가지 않는다.
- [ ] 이벤트 오디오 샘플 저장 opt-in 토글이 실제 iPhone에서도 기본 OFF로 표시되는지 확인해야 한다.
- [ ] 리포트 문구가 불안감을 주지 않는지 사용자 관점에서 확인해야 한다.
