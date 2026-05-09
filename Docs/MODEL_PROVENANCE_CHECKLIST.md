# Model Provenance Checklist

이 문서는 `.mlmodel`, `.mlpackage`, compiled `.mlmodelc`를 repository나 앱 target에 추가하기 전에 필요한 provenance gate입니다.

현재 기본 상태는 모델 artifact 미포함입니다. 모델 파일이 없을 때도 `Tools/Training/validate_model_provenance_gate.sh`는 이 문서가 유지되는지 확인합니다.

## Manifest

모델 artifact를 commit하거나 앱 target에 넣기 전에는 `Models/CoreML/model_provenance.tsv`를 먼저 추가합니다.

필수 header:

```tsv
artifact_path	model_name	version	training_data_summary	training_data_license	commercial_use_status	personal_data_status	evaluation_evidence	review_status	reviewer	review_date	notes
```

예시 row:

```tsv
Models/CoreML/SnoreDetector.mlmodel	SnoreDetector	Snore ML v0	Personal opt-in debug samples and synthetic/approved public negative references	No ESC-50 full dataset; no NonCommercial training data	commercial-release-candidate	no personal raw audio in artifact	Docs/SNORE_BASELINE_EVALUATION.md	approved	dhseo	2026-05-09	pre-target dry run only
```

## Required Review

- `artifact_path`는 실제 model artifact path와 일치해야 합니다.
- `review_status`는 앱 target 추가 전 `approved`여야 합니다.
- 학습 데이터 요약에는 개인 sample, synthetic data, public dataset 사용 여부를 분리해 적습니다.
- 실제 개인 오디오, 실제 개인 파일명, local path, subject 식별자가 artifact metadata에 들어가지 않았는지 확인합니다.
- ESC-50 full dataset 또는 CC BY-NC / NonCommercial 데이터가 학습에 들어간 경우 `commercial_use_status`를 `legal-reviewed` 또는 `not-for-commercial-release`로 표시해야 합니다.
- ESC-10 subset만 사용한 경우에도 upstream attribution과 clip별 source 확인을 기록합니다.
- 모델 결과는 웰니스/개인 참고용 detector output으로만 표현하며 진단, 치료, 임상 정확도 문구와 연결하지 않습니다.

## Local Gate

```sh
Tools/Training/validate_model_provenance_gate.sh
```

이 gate는 다음을 확인합니다.

- 모델이 없으면 checklist 기반 pre-model 상태를 통과시킵니다.
- 모델이 있으면 `Models/CoreML/model_provenance.tsv` 존재와 header를 확인합니다.
- 각 model artifact가 manifest에 있고 필수 provenance field가 비어 있지 않은지 확인합니다.
- `review_status=approved` 전에는 model artifact를 통과시키지 않습니다.
- ESC-50 / NonCommercial 데이터가 있으면 commercial-use 상태가 명시되어 있는지 확인합니다.
