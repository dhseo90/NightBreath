# NightBreath / 밤숨 App Icon Guide

## 목적

이 문서는 밤숨 / NightBreath 앱 아이콘의 제작 방향과 asset slot을 정리합니다. 실제 App Store 제출용 고품질 PNG/PDF/SVG 제작은 별도 디자인 작업으로 남기며, 이번 단계에서는 Xcode asset catalog의 placeholder 구조만 유지합니다.

## 제품 이름

- 한국어 앱 이름: 밤숨
- 영어 브랜드명: NightBreath
- 부제: 수면 소리 리포트 / Sleep Sound Report

아이콘은 밤, 숨, 수면, 소리, 프라이버시, 온디바이스 분석을 조용하고 신뢰감 있게 전달해야 합니다. 의료기기처럼 딱딱하거나 경고성으로 보이면 안 됩니다.

## 현재 Asset 상태

- 위치: `SleepSoundApp/App/Assets.xcassets/AppIcon.appiconset`
- 상태: metadata-only placeholder
- 주의: 최종 앱 아이콘 이미지는 아직 포함하지 않습니다.

최종 artwork를 받을 때는 기존 `AppIcon.appiconset` slot에만 채우고, 타사 이미지나 기존 앱 아이콘을 참고 파일로 프로젝트에 넣지 않습니다.

## 아이콘 컨셉 후보

1. 달 + 숨결 파형

- 가장 기본 방향입니다.
- 둥근 달 형태와 NightBreath 고유 breath wave를 결합합니다.
- 파형은 복잡한 오디오 그래프가 아니라 부드러운 호흡의 리듬처럼 보여야 합니다.

2. 밤하늘 + 호흡 wave

- 깊은 밤 배경 위에 작은 숨결 wave를 배치합니다.
- 작은 크기에서도 wave가 뭉개지지 않도록 요소 수를 줄입니다.
- 별 장식은 최소화하고, 수면 앱의 조용한 인상을 유지합니다.

3. 프라이버시 shield + breath wave

- 온디바이스 분석과 서버 전송 없음 원칙을 강조하는 방향입니다.
- shield는 보안 제품처럼 딱딱하지 않게 부드러운 형태로 처리합니다.
- breath wave가 주인공이고 shield는 보조 cue로 남깁니다.

## 피해야 할 것

- 의료 십자가, 병원 표식, 응급 알림처럼 보이는 형태
- 병원/검사 장비 같은 차갑고 임상적인 분위기
- 기존 수면 앱과 유사한 달 + 침대 조합
- 타사 브랜드, 로고, 앱 아이콘, 스크린샷, 이미지 asset
- Toss/TDS 또는 외부 디자인 시스템의 스타일, 색상 토큰, 아이콘, 컴포넌트 복제
- 글자가 많은 아이콘, 작은 크기에서 읽히지 않는 텍스트
- 질병을 확정하거나 검사를 대신한다고 보이는 시각 표현

## 권장 기준

- 작은 크기에서도 식별 가능한 단순한 실루엣
- NightBreath 고유 색상 토큰 기반의 조용한 대비
- Dark/Light 배경 모두에서 인식 가능한 중심 형태
- 한 개의 주 상징과 한 개 이하의 보조 cue
- 텍스트 없는 아이콘
- 20pt, 29pt, 40pt, 60pt, App Store 크기에서 축소 검수

## 최종 Artwork Export Checklist

- iOS app icon slot을 모두 채웁니다.
- iOS 최종 PNG에는 투명 영역을 넣지 않습니다.
- 프로젝트에는 최종 export 파일만 넣고, 참고 이미지나 타사 reference asset은 넣지 않습니다.
- 교체 후 앱 빌드를 다시 실행합니다.
- App Store screenshot과 함께 봤을 때 같은 NightBreath 시각 언어로 보이는지 확인합니다.

## SwiftUI Placeholder와의 관계

`SleepSoundApp/Core/Design/NBIllustration.swift`에는 SwiftUI Shape 기반 original placeholder가 있습니다. 이 placeholder는 온보딩, empty state, screenshot 준비용 visual direction을 잡기 위한 것이며, 최종 앱 아이콘 artwork를 대신하지 않습니다.
