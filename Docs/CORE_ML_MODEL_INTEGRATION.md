# Core ML Model Integration Gate

이 문서는 Snore ML v0 또는 multiclass event classifier를 실제 앱 target에 넣기 전 통과해야 하는 gate를 정리합니다. 현재 앱은 Core ML adapter와 hybrid fallback 경로를 갖고 있지만, 실제 모델 artifact는 아직 앱 target에 포함하지 않습니다.

## 현재 상태

- `CoreMLSleepEventDetector`는 `MLModelProvider` 뒤에서 모델 유무를 확인합니다.
- 기본 앱 detector backend는 `hybrid`입니다.
- 모델이 없으면 `modelInstalled == false` 상태로 남고 rule-based fallback을 사용합니다.
- fallback 발생 여부는 `DetectorDiagnostics.fallbackUsed`, `modelFallbackCount`, `activeDetectorBackend`, `thresholdSnapshot`으로 확인합니다.
- `ModelInputAdapter`는 Snore ML v0 scalar feature schema를 유지합니다.
- 실제 `.mlmodel`, `.mlmodelc`, `.mlpackage` artifact는 repository와 Xcode app target에 아직 포함하지 않습니다.
- 모델 artifact를 추가하려면 `Docs/MODEL_PROVENANCE_CHECKLIST.md`와 `Models/CoreML/model_provenance.tsv` gate를 먼저 통과해야 합니다.

## Integration 전제

실제 모델을 target에 추가하기 전에는 아래 항목을 먼저 충족해야 합니다.

- snore / non-snore 또는 multiclass label 샘플 수와 라벨 균형을 문서화합니다.
- false-positive-like segment와 false-negative-like segment를 검토합니다.
- 조용한 방, 공조음, 이불 스침, 낮은 커버리지 negative가 과하게 이벤트로 바뀌지 않는지 확인합니다.
- 실제 iPhone 침대 배치에서 feature scale과 threshold snapshot을 비교합니다.
- Offline Evaluation에서 `ruleBased`, `coreML`, `hybrid` backend를 같은 manifest로 비교합니다.
- Release 기본 profile은 충분한 evidence 전까지 `balanced`로 유지합니다.
- 모델 결과는 건강 상태 판단이나 조치 안내로 표현하지 않습니다.

## Target 적용 절차

1. `Tools/Training/`에서 생성한 모델 output을 검토합니다.
2. 민감 데이터, 실제 개인 오디오 파일, 실제 개인 파일명이 artifact 이름이나 metadata에 들어가지 않았는지 확인합니다.
3. 승인된 모델만 `Models/CoreML/` 아래에 둡니다.
4. Xcode에서 `.mlmodel` 또는 compiled `.mlmodelc`를 `SleepSoundApp` target resource로 추가합니다.
5. DEBUG 빌드에서 `DetectorTuningView`와 `AudioDebugView`의 `modelInstalled` 상태를 확인합니다.
6. `hybrid` backend에서 Core ML confidence가 낮거나 non-snore label이면 rule-based fallback이 유지되는지 확인합니다.
7. 실제 iPhone smoke 전에는 Release 기본 profile이나 사용자 기본 민감도를 변경하지 않습니다.

## Required Local Checks

모델을 target에 넣기 전후로 아래 local check를 실행합니다.

모델 artifact를 앱 target에 추가하기 전 현재 repo가 gate 이전 상태를 유지하는지 먼저 확인합니다.

```sh
Tools/Training/validate_coreml_integration_gate.sh
Tools/Training/validate_model_provenance_gate.sh
```

```sh
xcrun swift test --filter CoreMLSleepEventDetector --filter CompositeSleepEventDetector --filter ModelOutputMapper --filter DetectorThresholdConfiguration --no-parallel
```

```sh
xcodebuild -project SleepSoundApp.xcodeproj -scheme SleepSoundApp -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO build
```

모델이 없는 현재 상태에서는 다음이 기대값입니다.

- `CoreMLSnoreModelProvider.isModelAvailable == false`
- `CoreMLSleepEventDetector.detectWithStatus`가 crash 없이 `modelUnavailable`을 반환
- `CompositeSleepEventDetector(backend: .hybrid)`가 rule-based fallback으로 결과를 유지
- `DetectorDiagnostics.modelInstalled == false`
- `fallbackUsed`와 `modelFallbackCount`가 fallback 상태를 설명

## Required Offline Comparison

가능하면 같은 manifest를 세 backend로 비교합니다.

```sh
swift run OfflineEvaluation --manifest Tools/OfflineEvaluation/sample_manifest.example.json --output Tools/OfflineEvaluation/output --profiles balanced,sensitive,verySensitive --backends ruleBased,coreML,hybrid
```

비교 결과에서 확인할 항목:

- snore positive에서 raw/final event가 늘어나는지
- quiet/noise negative가 snore로 과하게 바뀌지 않는지
- `coreML` 단독 zero-event와 `hybrid` fallback 차이가 설명되는지
- confidence gap이 큰 segment가 있는지
- fallback이 발생했을 때 report diagnostics가 유지되는지

## Privacy / Safety Boundary

- 전체 밤 원본 오디오 저장 기능을 추가하지 않습니다.
- 실제 개인 오디오 파일이나 공개 오디오 fixture를 repository에 추가하지 않습니다.
- sleep talk 내용을 텍스트로 변환하지 않습니다.
- 서버 업로드, 클라우드 처리, 외부 API 호출, 외부 분석 SDK를 추가하지 않습니다.
- HealthKit write를 추가하지 않습니다.
- Fitdays 서버/API 연결이나 비공식 연결 방식은 추가하지 않습니다.
- 결과 copy는 웰니스/개인 참고용 detector 표현으로만 유지합니다.

## Release Gate

실제 모델을 포함한 build를 TestFlight 후보로 올리기 전에는 다음 evidence가 필요합니다.

- `Docs/REAL_DEVICE_QA_RUNBOOK.md`의 foreground stop, lock/background stop, snore signal smoke 통과
- 모델 포함 build에서 `modelInstalled == true` 확인
- 모델 미포함 build 또는 missing model 상태에서 crash 없는 fallback 확인
- `Docs/DETECTOR_TUNING.md`에 threshold/profile 변경 여부 기록
- `Docs/SNORE_BASELINE_EVALUATION.md` 또는 Offline Evaluation output summary에 backend 비교 결과 기록
- `Models/CoreML/model_provenance.tsv`에 artifact path, 학습 데이터 출처, license, 상업 사용 상태, review evidence 기록

이 gate가 끝나기 전에는 sensitive/verySensitive profile을 Release 기본값으로 올리지 않습니다.
