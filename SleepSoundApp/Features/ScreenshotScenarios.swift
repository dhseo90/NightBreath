import Foundation

#if DEBUG
enum ScreenshotScenario: String, CaseIterable, Identifiable, Sendable {
  case homeDashboard
  case sleepStart
  case sleepRecording
  case sleepReport
  case eventTimeline
  case morningBrief
  case dailyRhythmReport
  case dailyHealthCard
  case privacySettings
  case healthDashboard
  case zeroEventReport
  case lowCoverageReport
  case eventAudioStorageOff
  case debugTools

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .homeDashboard:
      "ScreenshotHomeScenario"
    case .sleepStart:
      "ScreenshotSleepStartScenario"
    case .sleepRecording:
      "ScreenshotRecordingScenario"
    case .sleepReport:
      "ScreenshotReportScenario"
    case .eventTimeline:
      "ScreenshotTimelineScenario"
    case .morningBrief:
      "ScreenshotMorningBriefScenario"
    case .dailyRhythmReport:
      "ScreenshotDailyRhythmScenario"
    case .dailyHealthCard:
      "ScreenshotDailyHealthCardScenario"
    case .privacySettings:
      "ScreenshotPrivacyScenario"
    case .healthDashboard:
      "ScreenshotHealthDashboardScenario"
    case .zeroEventReport:
      "ScreenshotZeroEventScenario"
    case .lowCoverageReport:
      "ScreenshotLowCoverageScenario"
    case .eventAudioStorageOff:
      "ScreenshotEventAudioStorageOffScenario"
    case .debugTools:
      "ScreenshotDebugScenario"
    }
  }

  var headlineCopy: String {
    switch self {
    case .homeDashboard:
      "수면 중 소리 기반 지표를 한눈에"
    case .sleepStart:
      "잠들기 전 준비를 차분하게"
    case .sleepRecording:
      "iPhone 안에서 조용히 분석"
    case .sleepReport:
      "아침에 읽기 쉬운 수면 소리 리포트"
    case .eventTimeline:
      "코골기와 환경 소음 흐름 확인"
    case .morningBrief:
      "아침에 시작하는 하루 건강 리듬"
    case .dailyRhythmReport:
      "오늘의 리듬 점수를 참고용으로"
    case .dailyHealthCard:
      "하루 리듬을 카드 한 장으로"
    case .privacySettings:
      "전체 밤 오디오는 저장하지 않습니다"
    case .healthDashboard:
      "혈압/체성분 대시보드 준비"
    case .zeroEventReport:
      "이벤트가 적은 밤도 측정 맥락과 함께"
    case .lowCoverageReport:
      "측정 품질이 낮은 날은 제한적으로"
    case .eventAudioStorageOff:
      "이벤트 샘플 저장은 사용자가 선택"
    case .debugTools:
      "DEBUG에서만 확인하는 검증 화면"
    }
  }

  var captureNote: String {
    switch self {
    case .homeDashboard:
      "최근 리포트, 수면 소리 점수, 측정 품질, 온디바이스 안내가 보이게 캡처합니다."
    case .sleepStart:
      "수면 시작 CTA, 마이크 권한, 기기 배치, 이벤트 오디오 샘플 저장 상태가 보이게 캡처합니다."
    case .sleepRecording:
      "녹음 중 상태, 실제 오디오 수신 시간, 커버리지, 수면 종료 버튼이 보이게 캡처합니다."
    case .sleepReport:
      "점수, 주요 이벤트, detector diagnostics 요약, 진단 목적 아님 안내가 보이게 캡처합니다."
    case .eventTimeline:
      "이벤트 시간, 타입, duration, 오디오 샘플 상태가 보이게 캡처합니다."
    case .morningBrief:
      "수면 요약, 아침 컨디션, mock 혈압/체성분, 데이터 품질이 보이게 캡처합니다."
    case .dailyRhythmReport:
      "오늘의 리듬 점수, component score, Daily Insight, 인과관계 아님 안내가 보이게 캡처합니다."
    case .dailyHealthCard:
      "카드 template, privacy level, 오늘의 리듬 카드 preview가 보이게 캡처합니다."
    case .privacySettings:
      "이벤트 샘플 opt-in, 저장 용량, 삭제 가능성, 서버 전송 없음 안내가 보이게 캡처합니다."
    case .healthDashboard:
      "HealthKit read-only 방향과 혈압/체성분/CrossMetric 진입이 보이게 캡처합니다."
    case .zeroEventReport:
      "이벤트 0개 상태, zero-event 분석, 측정 품질 안내가 보이게 캡처합니다."
    case .lowCoverageReport:
      "낮은 오디오 커버리지, 제한 안내, 측정 품질 배지가 보이게 캡처합니다."
    case .eventAudioStorageOff:
      "이벤트 오디오 샘플 저장 꺼짐, 원본 전체 오디오 미저장 안내가 보이게 캡처합니다."
    case .debugTools:
      "Dataset Replay 또는 Detector Tuning 같은 DEBUG 전용 검증 화면임이 보이게 캡처합니다."
    }
  }

  var simulatorPreset: SimulatorQAScenarioPreset {
    switch self {
    case .homeDashboard, .sleepStart, .sleepReport, .eventTimeline, .morningBrief, .dailyRhythmReport, .dailyHealthCard:
      .snoreHeavyNight
    case .sleepRecording, .privacySettings:
      .eventAudioStorageOnWithSamples
    case .healthDashboard:
      .quietNight
    case .zeroEventReport:
      .zeroEventButGoodAudioCoverage
    case .lowCoverageReport:
      .lowAudioCoverageNight
    case .eventAudioStorageOff:
      .eventAudioStorageOff
    case .debugTools:
      .zeroEventButGoodAudioCoverage
    }
  }

  var suggestedScreenshotPath: String {
    switch self {
    case .homeDashboard:
      "Docs/Screenshots/README/home-dashboard.png"
    case .sleepStart:
      "Docs/Screenshots/Sleep/sleep-start.png"
    case .sleepRecording:
      "Docs/Screenshots/README/recording.png"
    case .sleepReport:
      "Docs/Screenshots/README/sleep-report.png"
    case .eventTimeline:
      "Docs/Screenshots/Sleep/timeline.png"
    case .morningBrief:
      "Docs/Screenshots/DailyRhythm/morning-brief.png"
    case .dailyRhythmReport:
      "Docs/Screenshots/README/daily-rhythm-report.png"
    case .dailyHealthCard:
      "Docs/Screenshots/README/daily-health-card.png"
    case .privacySettings:
      "Docs/Screenshots/Privacy/privacy-settings.png"
    case .healthDashboard:
      "Docs/Screenshots/README/health-dashboard.png"
    case .zeroEventReport:
      "Docs/Screenshots/EdgeStates/zero-event-report.png"
    case .lowCoverageReport:
      "Docs/Screenshots/EdgeStates/low-coverage-report.png"
    case .eventAudioStorageOff:
      "Docs/Screenshots/EdgeStates/event-audio-storage-off.png"
    case .debugTools:
      "Docs/Screenshots/Debug/detector-tuning.png"
    }
  }
}

@MainActor
enum ScreenshotScenarioFactory {
  static func makeAppState(for scenario: ScreenshotScenario) -> AppState {
    let settings = ScreenshotUserSettings()
    settings.hasCompletedOnboarding = true
    settings.isEventAudioSampleStorageEnabled = scenario == .privacySettings || scenario == .sleepRecording

    let state = AppState(
      repository: InMemorySleepRepository(),
      audioSessionManager: PreviewAudioSessionManager(),
      audioCaptureService: MockAudioCaptureService(),
      userSettings: settings
    )

    state.applySimulatorQAScenario(scenario.simulatorPreset)
    state.microphonePermissionState = .granted
    state.morningCheckIn = makeScreenshotMorningCheckIn(sessionId: state.latestSession.id)

    if scenario == .sleepRecording {
      applyRecordingState(to: state)
    }

    return state
  }

  static func makeScreenshotMorningCheckIn(sessionId: UUID) -> MorningCheckIn {
    MorningCheckIn(
      sessionId: sessionId,
      refreshScore: 4,
      fatigueScore: 2,
      headache: false,
      dryMouth: true,
      soreThroat: false,
      rememberedAwakenings: 1,
      memo: "Simulator mock 기록"
    )
  }

  private static func applyRecordingState(to state: AppState) {
    var session = state.latestSession
    session.endedAt = nil
    session.measurementDuration = 2 * 60 * 60 + 18 * 60

    let now = session.startedAt.addingTimeInterval(session.measurementDuration)
    let receivedAudioSeconds = session.measurementDuration * 0.97
    let analyzedAudioSeconds = session.measurementDuration * 0.965

    state.activeSession = session
    state.audioCaptureState = .capturing(startedAt: session.startedAt)
    state.audioCaptureMetrics = AudioCaptureMetrics(
      captureStartedAt: session.startedAt,
      sessionElapsedSeconds: session.measurementDuration,
      captureActiveSeconds: session.measurementDuration,
      receivedAudioSeconds: receivedAudioSeconds,
      analyzedAudioSeconds: analyzedAudioSeconds,
      receivedChunkCount: Int(receivedAudioSeconds),
      analyzedChunkCount: Int(analyzedAudioSeconds),
      totalReceivedFrameCount: Int64(receivedAudioSeconds * 16_000),
      totalAnalyzedFrameCount: Int64(analyzedAudioSeconds * 16_000),
      sampleRate: 16_000,
      lastChunkReceivedAt: now.addingTimeInterval(-4),
      lastChunkAnalyzedAt: now.addingTimeInterval(-6),
      interruptionCount: 0,
      longestChunkGapSeconds: 4,
      currentChunkGapSeconds: 4,
      audioCoverageRatio: 0.97
    )
    state.latestAudioLevel = 0.08
    state.capturedAudioChunkCount = 128
    state.detectedEventCandidateCount = 6
    state.latestDetectedEventText = "코골기 후보"
    state.latestDetectedEventAt = now.addingTimeInterval(-12 * 60)
    state.audioCaptureMessage = "Screenshot preset입니다. 실제 오디오 파일은 생성하지 않습니다."
  }
}

private final class ScreenshotUserSettings: UserSettingsProviding {
  var isEventAudioSampleStorageEnabled = false
  var hasCompletedOnboarding = true
}
#endif
