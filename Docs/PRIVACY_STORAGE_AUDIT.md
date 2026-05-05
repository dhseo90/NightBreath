# Privacy / Storage Audit

작성일: 2026-05-03

이 문서는 NightBreath / 밤숨 V1 프로토타입의 개인정보와 로컬 저장소 상태를 점검한 결과입니다.

## 결론

- 전체 밤 원본 오디오를 파일로 저장하는 코드는 없습니다.
- 이벤트 오디오 샘플 저장은 사용자 opt-in입니다.
- 기본값은 꺼짐입니다.
- 저장된 이벤트 오디오 샘플은 로컬 앱 컨테이너 안에만 저장됩니다.
- 서버 전송, 클라우드 동기화, 외부 API 호출, 외부 분석 SDK, 광고 SDK는 없습니다.
- Daily Rhythm 확장은 mock/protocol 기반 preview와 HealthKit read-only adapter를 함께 사용합니다.
- HealthKit 권한 요청은 건강 데이터 연결 버튼에서만 시작합니다.
- HealthKit 쓰기, save/delete, 수면 소리 점수 기록은 없습니다.
- Fitdays import는 사용자가 직접 선택한 로컬 CSV 또는 structured export 파일만 처리합니다.
- Fitdays 원격 서비스 연결, 비공식 연결 방식, 자동 동기화는 없습니다.
- Fitdays extended local-only 지표는 HealthKit으로 읽거나 HealthKit에 쓰지 않습니다.
- HealthKit 표준 지표가 Fitdays CSV에 포함되어도 `sourceType == fitdaysCSV`로 보관합니다.
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
  - 앱 sandbox의 `Documents/Samples/Personal/` 아래에 `.caf`, `.metadata.json`, `.features.csv`를 함께 저장합니다.
  - `DebugSampleStoragePolicy`로 샘플 1개 최대 길이, 앱 실행당 샘플 수, 폴더 용량, 오래된 샘플 정리를 제한합니다.
  - Release 사용자 UI에 노출하지 않습니다.

`AVAudioRecorder` 사용은 없습니다.

`DatasetReplayAudioSource`의 `AVAudioFile` 사용은 로컬 오디오 파일을 읽어 개발/검증용 replay chunk로 변환하는 용도입니다. 파일을 저장하지 않습니다.

실제 코골이 원인 분석은 전체 밤 오디오가 아니라 사용자가 직접 수집한 짧은 DEBUG 샘플 또는 repo 밖 로컬 샘플로 수행합니다. 개인 오디오 파일은 `Samples/Personal/`, `Datasets/`, 또는 repo 밖 경로에만 두고, repository에는 metadata/문서/테스트용 synthetic 값만 남깁니다.

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
- 이벤트별 사용자 feedback
- opt-in 상태에서만 짧은 이벤트 오디오 샘플

저장하지 않는 것:

- 전체 밤 원본 오디오 파일
- sleep talk 내용 텍스트
- 서버 전송용 payload
- HealthKit 쓰기용 payload
- 개인 DEBUG 오디오 파일의 git-tracked fixture

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

HealthKit 관련 adapter 경계는 read-only 방향으로 제한합니다. 권한 요청은 건강 데이터 대시보드의 연결 버튼을 선택한 경우에만 시작합니다.

- `HealthKitServiceProtocol`
- `DisabledHealthKitService`
- `HealthMetricSample`
- `RealHealthKitService`
- `HealthKitService` typealias

허용되는 항목:

- `import HealthKit`
- `HKHealthStore`
- `requestAuthorization`
- `HKSampleQuery`

제한 사항:

- `requestAuthorization(toShare: Set<HKSampleType>(), read: ...)`에서 share 대상은 빈 set입니다.
- HealthKit sample은 화면 표시용으로만 읽습니다.
- HealthKit save/delete API를 사용하지 않습니다.
- 수면 소리 점수, 이벤트, 리포트, feedback을 HealthKit에 쓰지 않습니다.
- HealthKit 권한 요청은 건강 데이터 대시보드의 연결 버튼에서만 시작해야 합니다.

## Fitdays import 점검

Fitdays 확장 체성분 지표는 HealthKit으로 읽으려 하지 않고, 사용자가 직접 선택한 CSV 또는 structured export 파일에서 로컬 `UnifiedHealthMetricSample`로 변환합니다.

2026-05-04 조사 기준으로 Fitdays 공식 도움말은 Progress Report 공유 시 CSV 형식 선택을 언급하고, Fitdays privacy 문서는 History Records / Data Reports를 통한 CSV export를 설명합니다. Fitdays+ privacy 문서도 personal data를 CSV로 export 요청할 권리를 설명합니다. 다만 실제 메뉴명과 export 방식은 앱 버전, 지역, Fitdays/Fitdays+ 차이, 로그인 상태에 따라 달라질 수 있으므로 NightBreath는 사용자가 직접 확보한 로컬 파일만 입력으로 받습니다.

허용되는 항목:

- `FitdaysImportView`의 사용자 명시 파일 선택
- iOS document type/open-in으로 전달된 CSV 또는 plain text export file preview
- `FitdaysImportService`의 로컬 CSV parsing, flexible column mapping, row validation
- `ImportBatch`와 `UnifiedHealthMetricSample` 저장
- HealthKit 표준 지표가 CSV에 포함된 경우에도 `sourceType == fitdaysCSV`로 저장
- synthetic fixture와 mock scenario를 이용한 테스트와 screenshot
- unknown column warning, invalid row skip, unsupported extension 실패, missing date 실패, duplicate import replacement

제한 사항:

- Fitdays 계정 로그인이나 원격 서비스 직접 연결을 만들지 않습니다.
- 비공식 연결 방식이나 reverse engineering을 사용하지 않습니다.
- Fitdays 앱 내부 데이터에 접근하지 않습니다.
- Fitdays 화면 scraping이나 UI automation을 만들지 않습니다.
- 자동 동기화를 만들지 않습니다.
- HealthKit에 Fitdays import 값을 쓰지 않습니다.
- CSV 원본 파일을 앱 repository에 포함하지 않습니다.
- screenshot에 실제 CSV 파일명이나 실제 local path를 노출하지 않습니다.
- screenshot에는 synthetic/mock import data만 사용합니다.

현재 저장 원칙:

- 선택된 CSV 또는 structured export 파일은 import 입력으로만 사용하고, 원본 파일 자체를 앱 repository나 screenshot asset으로 보관하지 않습니다.
- file picker와 open-in document URL은 같은 preview validation을 통과해야 저장할 수 있습니다.
- 앱은 `.csv`, `.txt` 외의 파일을 Fitdays import 입력으로 처리하지 않습니다.
- CSV 구조가 맞지 않는 plain text file은 저장 전에 실패합니다.
- import 결과는 `Application Support/NightBreath/imported-health-metrics.json`의 `ImportBatch`와 `UnifiedHealthMetricSample`로 묶어 관리합니다.
- batch 단위 삭제가 필요한 경우 `importBatchId`로 관련 sample을 함께 삭제할 수 있게 설계합니다.
- extended metric sample은 sourceType/sourceName/importBatchId를 함께 저장해 HealthKit read-only sample과 구분합니다.
- HealthKit-backed sample, Fitdays CSV sample, manual/appComputed/mock sample은 source type과 UI badge로 구분합니다.
- 실제 개인 CSV, 실제 개인 건강 데이터, 실제 HealthKit source device 식별 정보는 문서용 screenshot에 사용하지 않습니다.
- Share Extension은 아직 구현하지 않고, 실제 Fitdays share UX를 확인한 뒤 별도 이슈로 판단합니다.

## Daily Health Card export/share 점검

Daily Health Card image export/share는 아직 구현하지 않았으며, 다음 구현 단계에서도 로컬 렌더링과 사용자 명시 액션을 기준으로 제한합니다.

허용되는 항목:

- SwiftUI export 전용 view를 iOS 로컬 renderer로 이미지화
- export 전 preview와 privacy level 선택
- `minimal`, `standard`, `detailed` privacy level에 따른 표시 항목 제한
- 민감할 수 있는 건강 수치 포함 여부 안내
- 사용자가 명시적으로 선택한 저장 또는 시스템 share sheet 열기
- 저장/공유 취소 state와 실패 state 표시

제한 사항:

- 자동 공유를 만들지 않습니다.
- 서버 업로드를 만들지 않습니다.
- 외부 SDK나 외부 API를 사용하지 않습니다.
- HealthKit에 export 이미지나 카드 요약을 쓰지 않습니다.
- 생성된 이미지를 analytics event, crash log, debug log에 첨부하지 않습니다.
- 실제 personal CSV 파일명, 실제 local path, 실제 HealthKit device 식별자를 export preview나 screenshot에 표시하지 않습니다.

privacy level 기준:

- `minimal`: 날짜, 오늘의 리듬 점수, 한 줄 요약 중심으로 표시하고 혈압, 체중, 체성분 같은 민감할 수 있는 수치는 숨깁니다.
- `standard`: 주요 점수와 사용자가 허용한 주요 건강 수치를 표시하되 source 세부 정보와 기록 시간은 줄입니다.
- `detailed`: 사용자가 허용한 주요 건강 수치, source, 기록 시간을 표시할 수 있지만 internal id, import batch id, 파일명, local path는 표시하지 않습니다.

사용자가 저장 또는 공유를 취소한 경우 생성된 이미지는 앱 밖으로 나가지 않았다는 상태만 표시합니다. 렌더링이나 저장이 실패한 경우 이미지를 만들지 못했다는 안내와 다시 시도 동작만 제공합니다.

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
