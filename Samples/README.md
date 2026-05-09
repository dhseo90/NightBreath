# Samples

이 폴더는 Feature Lab에서 사용할 로컬 오디오 샘플 위치를 설명하기 위한 문서만 포함합니다.

샘플 파일은 기본 workflow에서 repo에 커밋하지 않습니다.

로컬 전용 폴더:

```text
Samples/Personal/
Samples/Public/
```

- `Samples/Personal/`: 사용자가 직접 준비한 개인 검증용 짧은 샘플
- `Samples/Public/`: 라이선스를 직접 확인한 공개 샘플

두 폴더와 `*.wav`, `*.caf`, `*.m4a`는 `.gitignore`에 포함되어 있습니다.

주의:
- 전체 밤 원본 오디오를 보관하지 않습니다.
- sleep talk 내용을 텍스트화하지 않습니다.
- 파일명에 개인 정보가 들어가지 않게 합니다.
- 공개 데이터셋은 자동 다운로드하지 않습니다.
- 공개 dataset을 repository 또는 배포 archive에 포함하는 경우 upstream license와 attribution을 유지하고 `Docs/LICENSING.md`와 `THIRD_PARTY_NOTICES.md`에 범위를 명시합니다.
