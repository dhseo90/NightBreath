# Review Upload Set

이 문서는 NightBreath / 밤숨을 다음 리뷰 도구나 ChatGPT 세션에 업로드할 때, 파일 수 제한이 있는 상황에서 어떤 Markdown 문서를 우선 올릴지 정리합니다.

## 원칙

- 최신 repository의 현재 파일만 업로드합니다.
- 구버전 README, AGENTS, QA, DESIGN_SYSTEM 사본은 올리지 않습니다.
- screenshot PNG는 별도 시각 리뷰가 필요할 때만 올리고, 기본 코드/문서 리뷰 세트에는 Markdown을 우선합니다.
- 실제 개인 CSV, 실제 개인 건강 데이터, 실제 오디오 파일, 실제 HealthKit export는 업로드하지 않습니다.
- Detector/ML, App Store, real-device QA처럼 목적이 좁은 리뷰는 해당 주제 문서를 추가하고 관련 없는 문서는 줄입니다.

## 전체 앱 리뷰용 우선 세트

1. `AGENTS.md`
2. `README.md`
3. `Docs/CURRENT_STATUS.md`
4. `Docs/NEXT_ISSUES.md`
5. `QA_CHECKLIST.md`
6. `Docs/PRODUCT_DIRECTION.md`
7. `Docs/PRIVACY_STORAGE_AUDIT.md`
8. `Docs/DEVELOPMENT_WORKFLOW.md`
9. `Docs/DESIGN_SYSTEM.md`
10. `Docs/UI_SCREEN_MAP.md`
11. `Docs/UI_GALLERY.md`
12. `Docs/HEALTH_DATA_GUIDE.md`
13. `Docs/QA_GUIDE.md`
14. `Docs/APP_RELEASE_GUIDE.md`
15. `Docs/APP_STORE_PRODUCT_PAGE_COPY.md`
16. `Docs/DAILY_RHYTHM_SCORE.md`
17. `Docs/DAILY_HEALTH_CARD.md`

## EHM 리뷰용 우선 세트

1. `AGENTS.md`
2. `README.md`
3. `Docs/CURRENT_STATUS.md`
4. `Docs/NEXT_ISSUES.md`
5. `QA_CHECKLIST.md`
6. `Docs/PRODUCT_DIRECTION.md`
7. `Docs/PRIVACY_STORAGE_AUDIT.md`
8. `Docs/DESIGN_SYSTEM.md`
9. `Docs/UI_SCREEN_MAP.md`
10. `Docs/UI_GALLERY.md`
11. `Docs/HEALTH_DATA_GUIDE.md`
12. `Docs/QA_GUIDE.md`

## UI / Screenshot 리뷰용 우선 세트

1. `AGENTS.md`
2. `README.md`
3. `Docs/DESIGN_SYSTEM.md`
4. `Docs/UI_SCREEN_MAP.md`
5. `Docs/UI_GALLERY.md`
6. `Docs/PRODUCT_DIRECTION.md`
7. `Docs/CURRENT_STATUS.md`
8. `Docs/NEXT_ISSUES.md`
9. `Docs/PRIVACY_STORAGE_AUDIT.md`
10. `Docs/APP_RELEASE_GUIDE.md`
11. `Docs/APP_STORE_PRODUCT_PAGE_COPY.md`
12. `Docs/HEALTH_DATA_GUIDE.md`
13. `Docs/DAILY_HEALTH_CARD.md`
14. `Docs/DAILY_RHYTHM_SCORE.md`
15. `QA_CHECKLIST.md`

## 생략 가능 문서

- App Store 작업이 아니면 `Docs/APP_RELEASE_GUIDE.md`와 `Docs/APP_STORE_PRODUCT_PAGE_COPY.md`는 생략할 수 있습니다.
- Detector/ML 작업이 아니면 detector, dataset, offline evaluation, Core ML 문서는 생략할 수 있습니다.
- 실제 기기 오디오 QA가 아니면 `Docs/QA_GUIDE.md`의 관련 section만 공유해도 됩니다.
- HealthKit/EHM 작업이 아니면 `Docs/HEALTH_DATA_GUIDE.md`는 우선순위를 낮출 수 있습니다.
- screenshot 리뷰가 아니면 PNG 파일과 screenshot capture workflow는 링크만 공유해도 됩니다.

## 추가 추천

- 20개 제한이 없다면 detector/ML 작업용으로 `Docs/DETECTOR_TUNING.md`, `Docs/DATASET_GUIDE.md`, `Docs/DATASET_MANIFEST_GUIDE.md`, `Docs/SNORE_ML_V0.md`, `Docs/MULTICLASS_EVENT_CLASSIFIER.md`를 함께 올립니다.
- screenshot 품질 리뷰라면 `Docs/Screenshots/README/cropped/`의 대표 PNG와 `Docs/Screenshots/Health/cropped/`의 EHM PNG를 함께 올립니다.
- privacy/storage 리뷰라면 `Tests/PrivacyCopySafetyTests.swift`와 `Tests/HealthKitReadOnlyPolicyTests.swift`도 함께 검토합니다.
