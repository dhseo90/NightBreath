# Privacy / Storage Audit

작성일: 2026-05-03

이 문서는 NightBreath / 밤숨 V1 프로토타입의 개인정보와 로컬 저장소 상태를 점검한 결과입니다.

## 결론

- 전체 밤 원본 오디오를 파일로 저장하는 코드는 없습니다.
- 이벤트 오디오 샘플 저장은 사용자 opt-in입니다.
- 기본값은 꺼짐입니다.
- 저장된 이벤트 오디오 샘플은 로컬 앱 컨테이너 안에만 저장됩니다.
- 서버 전송, 클라우드 동기화, 외부 API 호출, 외부 분석 SDK, 광고 SDK는 없습니다.
- HealthKit 실제 권한 요청, `HKHealthStore` 생성, HealthKit 데이터 읽기/쓰기는 없습니다.
- 잠꼬대/말소리 내용을 텍스트로 변환하지 않습니다.
- 공개/개인 오디오 파일은 git에 포함하지 않도록 `.gitignore`에 포함되어 있습니다.

## 검색 기준

다음 키워드로 repository를 점검했습니다.

```bash
rg -n "AVAudioFile|AVAudioRecorder|\\bwrite\\b|Documents|Caches|FileManager|\\.wav|\\.caf|\\.m4a|URLSession|Network|HealthKit|HKHealthStore" .
```

## 오디오 파일 저장 점검

앱 코드에서 `AVAudioFile(forWriting:)`를 사용하는 위치는 다음 용도에 한정되어 있습니다.

- `EventAudioSnippetStore`
  - 감지된 이벤트 전후의 짧은 오디오 샘플을 `.caf`로 저장합니다.
  - `EventAudioSnippetPolicy`로 길이, 개수, 폴더 용량, 보관 기간을 제한합니다.
  - `AppState`에서 `isEventAudioSampleStorageEnabled == true`일 때만 호출됩니다.
- `SampleCaptureView`
  - DEBUG 빌드 전용 개발자 수동 샘플 수집 화면입니다.
  - 사용자가 명시적으로 2초/3초/5초 샘플 캡처를 누를 때만 저장합니다.
  - Release 사용자 UI에 노출하지 않습니다.

`AVAudioRecorder` 사용은 없습니다.

`DatasetReplayAudioSource`의 `AVAudioFile` 사용은 로컬 오디오 파일을 읽어 개발/검증용 replay chunk로 변환하는 용도입니다. 파일을 저장하지 않습니다.

## 전체 밤 원본 오디오 저장 여부

전체 밤 원본 오디오를 하나의 파일로 쓰는 코드가 없습니다.

현재 녹음 중 오디오는 다음 방식으로만 다룹니다.

- `AudioChunk` 단위로 분석 pipeline에 전달
- `AudioRingBuffer`에 최근 N초/N개 chunk만 유지
- 이벤트 샘플 opt-in이 켜진 경우에만 이벤트 전후의 짧은 구간을 추출해 저장
- 최종 이벤트와 연결되지 않은 후보 샘플은 세션 종료 시 정리

즉, 앱 동작 시간 전체를 `.caf`, `.wav`, `.m4a` 같은 파일로 저장하지 않습니다.

## 이벤트 오디오 샘플 opt-in

설정 위치:

- `PrivacySettingsView` > “이벤트 오디오 샘플 저장”

저장 설정:

- `UserSettings.isEventAudioSampleStorageEnabled`
- 기본값: `false`

저장 조건:

- 설정이 켜져 있어야 합니다.
- 이벤트 타입이 `unknown`이면 저장하지 않습니다.
- 이벤트 duration이 유효해야 합니다.
- confidence가 최소 기준 이상이어야 합니다.
- 세션당 샘플 개수 제한을 넘지 않아야 합니다.
- 샘플 폴더 용량 제한을 넘지 않아야 합니다.

설정이 꺼져 있으면 새 이벤트 오디오 샘플은 저장되지 않고, 수면 이벤트 요약과 리포트 수치만 남습니다.

## 저장소 위치와 통계

이벤트 오디오 샘플 저장 기본 위치:

```text
Application Support/NightBreath/EventAudioSnippets/
```

저장소 통계 모델:

- `sampleCount`
- `linkedSampleCount`
- `orphanSampleCount`
- `totalBytes`
- `linkedBytes`
- `orphanBytes`
- `totalDurationSeconds`
- `linkedDurationSeconds`
- `orphanDurationSeconds`
- `latestSampleCreatedAt`
- `formattedTotalSize`

UI 표시 위치:

- `PrivacySettingsView` > “이벤트 오디오 샘플 관리”
- 일부 요약은 홈/리포트 화면에서도 표시됩니다.

## 삭제와 orphan cleanup

삭제 기능:

- 개별 이벤트 오디오 샘플 삭제
- 저장된 이벤트 오디오 샘플 전체 삭제
- 전체 로컬 수면 데이터 삭제 시 이벤트 오디오 샘플도 삭제

orphan cleanup:

- 최종 `SleepEvent`와 연결된 sample file name은 linked sample로 간주합니다.
- 저장소에는 있지만 최종 이벤트와 연결되지 않은 `.caf` 파일은 orphan sample로 간주합니다.
- “연결되지 않은 샘플 정리” 버튼으로 orphan sample을 삭제할 수 있습니다.
- 파일이 이미 없거나 duration을 읽을 수 없어도 앱이 crash하지 않도록 처리합니다.

## 로컬 저장 데이터

로컬 저장 대상:

- `SleepSession`
- `SleepEvent`
- `NightReport`
- `MorningCheckIn`
- detector diagnostics summary
- 이갈이 의심 소리 사용자 feedback
- opt-in 상태에서만 짧은 이벤트 오디오 샘플

저장하지 않는 것:

- 전체 밤 원본 오디오 파일
- sleep talk 내용 텍스트
- 서버 전송용 payload
- HealthKit 원본 데이터

## 네트워크 / 서버 / 외부 SDK 점검

앱 코드에서 다음 항목은 발견되지 않았습니다.

- `URLSession`
- `import Network`
- `NWConnection`
- `Alamofire`
- `Firebase`
- `AdMob`
- 광고 SDK
- 외부 분석 SDK

Tools 폴더의 offline evaluation과 training 도구도 공개 데이터셋을 자동 다운로드하지 않으며, 로컬 파일만 사용하도록 문서화되어 있습니다.

## HealthKit 점검

현재 포함된 것은 향후 확장용 placeholder입니다.

- `HealthKitServiceProtocol`
- `DisabledHealthKitService`
- `HealthMetricSample`

다음 항목은 없습니다.

- `import HealthKit`
- `HKHealthStore`
- `requestAuthorization`
- HealthKit query
- HealthKit 데이터 읽기/쓰기

## git 제외 규칙

`.gitignore`에서 다음 항목을 제외합니다.

```text
.DS_Store
Datasets/
Samples/Public/
Samples/Personal/
*.wav
*.caf
*.m4a
Tools/FeatureLab/output/
Tools/Training/output/
Tools/DatasetReplay/output/
Tools/OfflineEvaluation/output/
```

현재 git에 추적되는 `.wav`, `.caf`, `.m4a` 파일은 없습니다.

확인 명령:

```bash
git ls-files "*.wav" "*.caf" "*.m4a"
```

## 사용자 안내 문구

UI와 문서에서 다음 원칙을 유지합니다.

- “원본 전체 오디오는 저장하지 않습니다.”
- “감지된 이벤트 전후의 짧은 오디오만 저장합니다.”
- “분석은 iPhone 안에서 수행됩니다.”
- “서버로 전송되지 않습니다.”
- “이 앱은 진단 목적의 의료기기가 아닙니다.”

피하는 문구 방향:

- 질환명을 확정하는 표현
- 임상 지표를 정확히 산출한다는 표현
- 특정 수면 소리를 확정 상태로 단정하는 표현
- 사용자의 건강 상태를 판정하는 표현
- 치료 판단처럼 읽히는 표현

## 남은 실기기 QA

코드 audit은 저장 구조와 네트워크 부재를 확인하지만, 다음은 실제 iPhone에서 별도 확인해야 합니다.

- 화면 잠금 상태에서 오디오 chunk가 계속 들어오는지
- 백그라운드 상태에서 오디오 chunk가 계속 들어오는지
- 이벤트 오디오 샘플 opt-in ON 상태에서 실제 짧은 샘플만 저장되는지
- 저장 용량이 긴 테스트 후에도 제한 안에서 유지되는지
- 이벤트 오디오 샘플 삭제와 orphan cleanup이 실제 기기에서도 정상 동작하는지
