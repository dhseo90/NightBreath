# NightBreath / 밤숨 V1 QA Checklist

이 체크리스트는 NightBreath / 밤숨 V1 프로토타입을 실제 iPhone에서 검증하기 위한 문서입니다.

앱은 수면 중 소리 기반 웰니스 리포트를 제공하는 프로토타입입니다. 진단 목적의 의료기기가 아니며, HealthKit 실제 연동, 서버 업로드, 클라우드 동기화, 외부 SDK는 V1 범위에 포함되지 않습니다.

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
- [ ] 종료 시간이 세션에 반영된다.
- [ ] 수집된 이벤트 후보로 NightReport가 생성된다.
- [ ] 종료 직후 수면 리포트 화면으로 이동한다.
- [ ] 종료를 여러 번 눌러도 중복 저장이나 크래시가 발생하지 않는다.

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
- [ ] 잠꼬대/말소리 텍스트가 저장되지 않는다.

## 8. 데이터 삭제

- [ ] 개인정보 설정 화면에 로컬 데이터 삭제 기능이 있다.
- [ ] 특정 세션 삭제가 동작한다.
- [ ] 전체 수면 데이터 삭제가 동작한다.
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
- [ ] 코드에 전체 밤 오디오 파일 저장 목적의 `AVAudioFile` 쓰기 로직이 없다.
- [ ] 코드에 전체 밤 오디오 파일 저장 목적의 `AVAssetWriter` 사용이 없다.
- [ ] ring buffer가 최근 제한된 청크만 유지한다.
- [ ] 저장소에는 이벤트 type, 시간, duration, confidence, intensity 같은 요약 정보만 저장된다.

코드 스캔 예시:

```bash
rg -n "AVAudioFile|AVAssetWriter|write\\(|\\.caf|\\.wav|\\.m4a" SleepSoundApp Tests
```

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

## 12. HealthKit 미구현 확인

- [ ] V1 앱 실행 중 HealthKit 권한 팝업이 표시되지 않는다.
- [ ] `HKHealthStore`를 생성하지 않는다.
- [ ] HealthKit 데이터를 읽거나 쓰지 않는다.
- [ ] FutureHealth 모듈은 protocol/placeholder 수준으로만 남아 있다.

코드 스캔 예시:

```bash
rg -n "import HealthKit|HKHealthStore|requestAuthorization|HKSampleQuery" SleepSoundApp Tests Package.swift
```

## 13. 의료 표현 확인

- [ ] “수면무호흡증”이라는 확정적 표현을 사용하지 않는다.
- [ ] “이갈이 확진”이라는 표현을 사용하지 않는다.
- [ ] “질병 판정”이라는 표현을 사용하지 않는다.
- [ ] “치료 필요”처럼 치료 판단으로 읽히는 표현을 사용하지 않는다.
- [ ] “AHI 정확 측정”처럼 임상 지표를 정확히 산출한다는 표현을 사용하지 않는다.
- [ ] “호흡정지 의심 구간”, “이갈이 의심 소리”, “수면 소리 점수” 표현을 사용한다.
- [ ] 반복적으로 높게 나타나는 패턴은 “전문가 상담을 고려해보세요” 수준으로 안내한다.
- [ ] 앱이 진단 목적의 의료기기가 아니라는 안내가 표시된다.

코드 스캔 예시:

```bash
rg -n "수면무호흡증|이갈이 확진|질병 판정|치료 필요|AHI 정확|확정 진단" SleepSoundApp README.md QA_CHECKLIST.md
```

## 14. 아직 남은 수동 위험 요소

- [ ] 실제 iPhone 장시간 측정 중 배터리 사용량을 확인해야 한다.
- [ ] 잠금 화면 상태에서 캡처 지속 여부를 확인해야 한다.
- [ ] 백그라운드 전환 후 캡처 상태 복구 여부를 확인해야 한다.
- [ ] 다양한 iPhone 모델에서 마이크 입력 level 차이를 확인해야 한다.
- [ ] 조용한 방, 선풍기/에어컨, 거리 소음, 침구 마찰 등 환경별 오탐 가능성을 기록해야 한다.
- [ ] rule-based detector threshold는 실제 데이터로 계속 튜닝해야 한다.
- [ ] 리포트 문구가 불안감을 주지 않는지 사용자 관점에서 확인해야 한다.
