import Foundation

#if DEBUG
enum ScreenshotScenario: String, CaseIterable, Identifiable, Sendable {
  case homeDashboard
  case sleepRecording
  case sleepReport
  case eventTimeline
  case privacySettings
  case healthDashboard

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .homeDashboard:
      "ScreenshotHomeScenario"
    case .sleepRecording:
      "ScreenshotRecordingScenario"
    case .sleepReport:
      "ScreenshotReportScenario"
    case .eventTimeline:
      "ScreenshotTimelineScenario"
    case .privacySettings:
      "ScreenshotPrivacyScenario"
    case .healthDashboard:
      "ScreenshotHealthDashboardScenario"
    }
  }

  var headlineCopy: String {
    switch self {
    case .homeDashboard:
      "수면 중 소리 기반 지표를 한눈에"
    case .sleepRecording:
      "iPhone 안에서 조용히 분석"
    case .sleepReport:
      "아침에 읽기 쉬운 수면 소리 리포트"
    case .eventTimeline:
      "코골기와 환경 소음 흐름 확인"
    case .privacySettings:
      "전체 밤 오디오는 저장하지 않습니다"
    case .healthDashboard:
      "혈압/체성분 대시보드 준비"
    }
  }

  var captureNote: String {
    switch self {
    case .homeDashboard:
      "최근 리포트, 수면 소리 점수, 측정 품질, 온디바이스 안내가 보이게 캡처합니다."
    case .sleepRecording:
      "녹음 중 상태, 실제 오디오 수신 시간, 커버리지, 수면 종료 버튼이 보이게 캡처합니다."
    case .sleepReport:
      "점수, 주요 이벤트, detector diagnostics 요약, 진단 목적 아님 안내가 보이게 캡처합니다."
    case .eventTimeline:
      "이벤트 시간, 타입, duration, 오디오 샘플 상태가 보이게 캡처합니다."
    case .privacySettings:
      "이벤트 샘플 opt-in, 저장 용량, 삭제 가능성, 서버 전송 없음 안내가 보이게 캡처합니다."
    case .healthDashboard:
      "HealthKit read-only 방향과 혈압/체성분/CrossMetric 진입이 보이게 캡처합니다."
    }
  }

  var simulatorPreset: SimulatorQAScenarioPreset {
    switch self {
    case .homeDashboard, .sleepReport, .eventTimeline:
      .snoreHeavyNight
    case .sleepRecording, .privacySettings:
      .eventAudioStorageOnWithSamples
    case .healthDashboard:
      .quietNight
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

    if scenario == .sleepRecording {
      applyRecordingState(to: state)
    }

    return state
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
