# Core ML Models

이 폴더는 로컬에서 변환한 Core ML 모델을 앱에 추가하기 전 확인하는 위치입니다.

현재 앱 backend가 찾는 코골기 모델 이름:

```text
SnoreDetector.mlmodel
```

모델을 실제 앱에서 사용하려면:

1. `Tools/Training/convert_snore_detector_to_coreml.py`로 `SnoreDetector.mlmodel`을 생성합니다.
2. Xcode에서 생성된 모델 파일을 앱 target에 추가합니다.
3. DEBUG 화면에서 `Snore Core ML model`이 `Installed`로 표시되는지 확인합니다.

모델 파일이 없거나 target에 포함되지 않아도 앱은 종료되지 않습니다. 이 경우 `hybrid` backend는 기존 rule-based detector로 fallback합니다.
