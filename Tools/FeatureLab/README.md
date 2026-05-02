# Feature Lab

Feature Lab은 NightBreath / 밤숨의 수면 소리 feature와 rule-based detector 후보를 개발 중 검증하기 위한 로컬 도구 영역입니다.

현재 repo에 포함된 도구:
- `AudioFeatureExtractor`
- `RuleBasedSleepEventDetector`
- `DetectionSmoothingPolicy`
- `FeatureCSVExporter`
- DEBUG-only `SampleCaptureView`
- synthetic audio 기반 unit tests

출력 파일을 만들 경우 다음 폴더를 사용합니다.

```text
Tools/FeatureLab/output/
```

이 폴더는 `.gitignore`에 포함되어 있습니다. CSV summary는 개발 중 확인용으로만 쓰고, 개인 오디오 파일이나 원본 PCM payload는 export하지 않습니다.

실제 iPhone에서 수집한 DEBUG 샘플은 앱 sandbox의 `Documents/Samples/Personal/`에 저장됩니다. 필요한 경우 Xcode Devices and Simulators에서 앱 container를 내려받아 로컬 `Samples/Personal/`로 옮겨 검토합니다. 해당 폴더와 오디오 확장자는 git에 포함되지 않습니다.

관련 문서:
- `Docs/DATASET_GUIDE.md`
- `Docs/FEATURE_VALIDATION.md`

권장 실행:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun swift test --cache-path .build/swiftpm-cache
```
