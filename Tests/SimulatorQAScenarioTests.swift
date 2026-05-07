import Foundation
import Testing

@testable import SleepSoundCore

@Suite("Simulator QA Scenarios")
struct SimulatorQAScenarioTests {
  @Test
  func allPresetsCreateCompleteMockBundles() {
    for preset in SimulatorQAScenarioPreset.allCases {
      let bundle = SimulatorQAScenarioFactory.make(preset: preset)

      #expect(bundle.preset == preset)
      #expect(bundle.session.id == bundle.report.sessionId)
      #expect(bundle.detectorDiagnostics.sessionId == bundle.session.id)
      #expect((0...100).contains(bundle.report.sleepSoundScore))
      #expect((0...1).contains(bundle.report.audioCoverageRatio))
      #expect(bundle.report.detectorDiagnostics == bundle.detectorDiagnostics)
      #expect(bundle.recentReports.count == 7)
      #expect(bundle.events.allSatisfy { $0.sessionId == bundle.session.id })
      #expect(bundle.eventAudioStorageStats.totalBytes >= 0)
    }
  }

  @Test
  func zeroEventGoodCoverageScenarioExplainsQuietOrConservativeSession() throws {
    let bundle = SimulatorQAScenarioFactory.make(preset: .zeroEventButGoodAudioCoverage)

    #expect(bundle.events.isEmpty)
    #expect(bundle.report.audioCoverageRatio >= 0.95)
    #expect(bundle.report.measurementQuality == .excellent)
    #expect(bundle.detectorDiagnostics.rawCandidateCount == 0)
    #expect(bundle.detectorDiagnostics.finalEventCountByType.values.reduce(0, +) == 0)

    let analysis = try #require(ZeroEventAnalysis.make(diagnostics: bundle.detectorDiagnostics))
    #expect(
      analysis.probableReason == .featuresMostlySilence ||
        analysis.probableReason == .genuinelyQuietSession ||
        analysis.probableReason == .detectorTooConservative
    )
  }

  @Test
  func zeroEventNoAudioScenarioShowsPoorCoverage() throws {
    let bundle = SimulatorQAScenarioFactory.make(preset: .zeroEventBecauseNoAudioReceived)

    #expect(bundle.events.isEmpty)
    #expect(bundle.report.receivedAudioDuration == 0)
    #expect(bundle.report.analyzedAudioDuration == 0)
    #expect(bundle.report.audioCoverageRatio == 0)
    #expect(bundle.report.measurementQuality == .poor)
    #expect(bundle.detectorDiagnostics.analyzedChunkCount == 0)

    let analysis = try #require(ZeroEventAnalysis.make(diagnostics: bundle.detectorDiagnostics))
    #expect(analysis.probableReason == .audioNotReceivedEnough)
  }

  @Test
  func lowCoverageScenarioKeepsSessionAndAudioTimeSeparate() {
    let bundle = SimulatorQAScenarioFactory.make(preset: .lowAudioCoverageNight)

    #expect(bundle.report.measurementDuration > bundle.report.receivedAudioDuration)
    #expect(bundle.report.receivedAudioDuration > 0)
    #expect(bundle.report.audioCoverageRatio < 0.60)
    #expect(bundle.report.measurementQuality == .poor)
    #expect(bundle.report.longestAudioGapSeconds >= 30 * 60)
  }

  @Test
  func eventAudioStorageOffScenarioDoesNotAttachSamples() {
    let bundle = SimulatorQAScenarioFactory.make(preset: .eventAudioStorageOff)

    #expect(bundle.isEventAudioSampleStorageEnabled == false)
    #expect(bundle.events.isEmpty == false)
    #expect(bundle.events.allSatisfy { $0.audioSnippetFileName == nil })
    #expect(bundle.report.savedAudioDuration == 0)
    #expect(bundle.eventAudioStorageStats.sampleCount == 0)
    #expect(bundle.detectorDiagnostics.eventAudioSampleStorageEnabled == false)
  }

  @Test
  func eventAudioStorageOnScenarioShowsOnlyShortMockSamples() {
    let bundle = SimulatorQAScenarioFactory.make(preset: .eventAudioStorageOnWithSamples)
    let snippetEvents = bundle.events.filter { $0.audioSnippetFileName != nil }

    #expect(bundle.isEventAudioSampleStorageEnabled)
    #expect(snippetEvents.count == 2)
    #expect(bundle.report.savedAudioDuration == 13)
    #expect(bundle.eventAudioStorageStats.sampleCount == 2)
    #expect(bundle.eventAudioStorageStats.linkedSampleCount == 2)
    #expect(bundle.eventAudioStorageStats.orphanSampleCount == 0)
    #expect(bundle.eventAudioStorageStats.totalDurationSeconds == bundle.report.savedAudioDuration)
  }

  @Test
  func orphanSampleScenarioSeparatesLinkedAndUnlinkedStorageStats() {
    let bundle = SimulatorQAScenarioFactory.make(preset: .orphanSamplesPresent)

    #expect(bundle.isEventAudioSampleStorageEnabled)
    #expect(bundle.eventAudioStorageStats.sampleCount == 5)
    #expect(bundle.eventAudioStorageStats.linkedSampleCount == 1)
    #expect(bundle.eventAudioStorageStats.orphanSampleCount == 4)
    #expect(bundle.eventAudioStorageStats.orphanBytes > bundle.eventAudioStorageStats.linkedBytes)
    #expect(bundle.eventAudioStorageStats.orphanDurationSeconds > 0)
    #expect(bundle.events.contains { $0.audioSnippetFileName != nil })
  }

  @Test
  func debugScreenshotScenariosExposeExtendedHealthMetricScreens() throws {
    let screenshotScenarios = try sourceContents("SleepSoundApp/Features/ScreenshotScenarios.swift")
    let simulatorScenarioView = try sourceContents("SleepSoundApp/Features/Settings/SimulatorScenarioView.swift")
    let expectedScenarioNames = [
      "ScreenshotHealthMetricsOverviewScenario",
      "ScreenshotFitdaysImportScenario",
      "ScreenshotHealthCalendarScenario",
      "ScreenshotDailyMeasurementDetailScenario",
      "ScreenshotMetricDetailScenario",
      "ScreenshotImportErrorScenario",
      "ScreenshotLocalOnlyMetricScenario",
      "ScreenshotBloodPressureDashboardScenario",
      "ScreenshotBodyCompositionDashboardScenario",
      "ScreenshotCrossMetricDashboardScenario",
      "ScreenshotHealthPermissionEmptyScenario",
      "ScreenshotMetricDetailEmptyScenario",
      "ScreenshotCrossMetricInsufficientScenario",
    ]

    #expect(screenshotScenarios.contains("#if DEBUG\nenum ScreenshotScenario"))
    #expect(simulatorScenarioView.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("#if DEBUG"))
    for scenarioName in expectedScenarioNames {
      #expect(screenshotScenarios.contains(scenarioName), "\(scenarioName) should stay available for simulator screenshot QA.")
    }
    #expect(simulatorScenarioView.contains("EHM 화면 상태"))
    #expect(simulatorScenarioView.contains("HealthKit 사용 불가"))
    #expect(simulatorScenarioView.contains("출처 혼합"))
    #expect(simulatorScenarioView.contains("HealthCalendar 빈 날짜"))
    #expect(simulatorScenarioView.contains("MetricDetail HealthKit 기반"))
    #expect(simulatorScenarioView.contains("BloodPressure dashboard"))
    #expect(simulatorScenarioView.contains("BodyComposition dashboard"))
    #expect(simulatorScenarioView.contains("CrossMetric insufficient"))
  }

  @Test
  func supportScreenshotScenariosExposeOnboardingPrivacyAndDebugScreens() throws {
    let screenshotScenarios = try sourceContents("SleepSoundApp/Features/ScreenshotScenarios.swift")
    let simulatorScenarioView = try sourceContents("SleepSoundApp/Features/Settings/SimulatorScenarioView.swift")
    let captureScript = try sourceContents("Tools/Screenshots/capture_support_screenshots.sh")
    let screenshotGuide = try sourceContents("Docs/Screenshots/README.md")
    let uiGallery = try sourceContents("Docs/UI_GALLERY.md")
    let expectedScenarios = [
      ("ScreenshotOnboardingScenario", "OnboardingView()", "Privacy/cropped/onboarding_light.png"),
      ("ScreenshotDevicePlacementScenario", "DevicePlacementGuideView()", "Privacy/cropped/device_placement_guide_light.png"),
      ("ScreenshotCalibrationScenario", "CalibrationView()", "Privacy/cropped/calibration_light.png"),
      ("ScreenshotAudioDebugScenario", "AudioDebugView()", "Debug/cropped/audio_debug_light.png"),
      ("ScreenshotSampleCaptureScenario", "SampleCaptureView()", "Debug/cropped/sample_capture_light.png"),
      ("ScreenshotDatasetReplayScenario", "DatasetReplayView()", "Debug/cropped/dataset_replay_light.png"),
      ("ScreenshotDebugScenario", "DetectorTuningView()", "Debug/cropped/detector_tuning_light.png"),
    ]

    #expect(captureScript.contains("SUPPORT_SCREENSHOT_SCENARIOS"))
    #expect(captureScript.contains("--nightbreath-screenshot-scenario"))
    #expect(captureScript.contains("Docs/Screenshots/Privacy"))
    #expect(captureScript.contains("Docs/Screenshots/Debug"))
    #expect(screenshotGuide.contains("capture_support_screenshots.sh"))
    #expect(uiGallery.contains("DEBUG only"))
    #expect(uiGallery.contains("실제 개인 오디오 파일명"))

    for (scenarioName, destination, croppedPath) in expectedScenarios {
      #expect(screenshotScenarios.contains(scenarioName), "\(scenarioName) should exist in ScreenshotScenario.")
      #expect(simulatorScenarioView.contains(destination), "\(destination) should be reachable from screenshot launch routing.")
      #expect(captureScript.contains(croppedPath.replacingOccurrences(of: "cropped/", with: "")), "\(croppedPath) raw capture should be scripted.")
      #expect(screenshotGuide.contains(croppedPath), "\(croppedPath) should be documented in screenshot guide.")
      #expect(uiGallery.contains(croppedPath), "\(croppedPath) should be tracked in UI Gallery.")
      #expect(uiGallery.contains("quality review pending"), "Captured support/debug screenshots should stay quarantined until visual QA passes.")
    }
  }

  @Test
  func pendingScreenshotScreensHaveDirectLaunchScenarios() throws {
    let screenshotScenarios = try sourceContents("SleepSoundApp/Features/ScreenshotScenarios.swift")
    let simulatorScenarioView = try sourceContents("SleepSoundApp/Features/Settings/SimulatorScenarioView.swift")
    let detailCaptureScript = try sourceContents("Tools/Screenshots/capture_detail_screenshots.sh")
    let supportCaptureScript = try sourceContents("Tools/Screenshots/capture_support_screenshots.sh")
    let uiGallery = try sourceContents("Docs/UI_GALLERY.md")
    let screenshotGuide = try sourceContents("Docs/Screenshots/README.md")
    let manifest = try sourceContents("Docs/Screenshots/screenshot_status.tsv")
    let expectedReleaseScenarios = [
      ("trendDashboard", "ScreenshotTrendDashboardScenario", "TrendDashboardView()", "Docs/Screenshots/Home/trend-dashboard.png"),
      ("morningCheckIn", "ScreenshotMorningCheckInScenario", "MorningCheckInView(sessionId:", "Docs/Screenshots/Sleep/morning-check-in.png"),
      ("eveningCheckIn", "ScreenshotEveningCheckInScenario", "EveningCheckInView()", "Docs/Screenshots/DailyRhythm/evening-check-in.png"),
      ("dailyHealthCardExport", "ScreenshotDailyHealthCardExportScenario", "initialExportPreview: true", "Docs/Screenshots/DailyRhythm/daily-health-card-export-preview.png"),
      ("reportEmpty", "ScreenshotReportEmptyScenario", "ScreenshotReportEmptyStateView()", "Docs/Screenshots/EdgeStates/report-empty.png"),
    ]

    #expect(screenshotGuide.contains("capture_detail_screenshots.sh"))
    #expect(uiGallery.contains("직접 scenario 추가, 캡처 대기"))
    #expect(uiGallery.contains("simulator 직접 launch scenario는 준비"))

    for (rawValue, scenarioName, destination, screenshotPath) in expectedReleaseScenarios {
      #expect(screenshotScenarios.contains("case \(rawValue)"), "\(scenarioName) should be a screenshot launch case.")
      #expect(screenshotScenarios.contains(scenarioName), "\(scenarioName) should expose stable display name.")
      #expect(simulatorScenarioView.contains(destination), "\(scenarioName) should route directly to its destination view.")
      #expect(detailCaptureScript.contains("\(rawValue):\(screenshotPath)"), "\(scenarioName) should be scripted for capture.")
      #expect(uiGallery.contains(scenarioName), "\(scenarioName) should replace manual navigation wording in UI Gallery.")
      #expect(manifest.contains("\(scenarioName)\t\(screenshotPath)"), "\(screenshotPath) should be tracked with the direct scenario.")
    }

    #expect(screenshotScenarios.contains("ScreenshotSimulatorScenario"))
    #expect(simulatorScenarioView.contains("SimulatorScenarioView()"))
    #expect(supportCaptureScript.contains("simulatorScenario:Docs/Screenshots/Debug/simulator-scenario.png"))
    #expect(manifest.contains("ScreenshotSimulatorScenario\tDocs/Screenshots/Debug/simulator-scenario.png"))
  }

  @Test
  func screenshotScenariosDoNotExposeInternalQASourceInUserFacingData() throws {
    let appState = try sourceContents("SleepSoundApp/App/AppState.swift")
    let screenshotScenarios = try sourceContents("SleepSoundApp/Features/ScreenshotScenarios.swift")
    let calibrationView = try sourceContents("SleepSoundApp/Features/Onboarding/CalibrationView.swift")

    #expect(appState.contains("func applyScreenshotScenario(_ scenario: ScreenshotScenario)"))
    #expect(appState.contains("latestReportSource = .sample"))
    #expect(screenshotScenarios.contains("state.latestReportSource = .sample"))
    #expect(!screenshotScenarios.contains("Simulator 예시 기록"))
    #expect(!screenshotScenarios.contains("Simulator 예시 수면 소리 리포트입니다."))
    #expect(!screenshotScenarios.contains("synthetic_fitdays_preview.csv"))
    #expect(!calibrationView.contains("Simulator 예시 입력"))
    #expect(screenshotScenarios.contains("fitdays_example_export.csv"))
  }

  @Test
  func userFacingScreenshotLaunchScenariosUsePublicReportSourceCopy() throws {
    let appState = try sourceContents("SleepSoundApp/App/AppState.swift")
    let screenshotScenarios = try sourceContents("SleepSoundApp/Features/ScreenshotScenarios.swift")

    #expect(appState.contains("func applyScreenshotScenario(_ scenario: ScreenshotScenario)"))
    #expect(appState.contains("latestReportSource = .sample"))
    #expect(appState.contains("case .simulatorQA:\n            \"검증용 예시\""))
    #expect(!appState.contains("case .simulatorQA:\n            \"Simulator QA\""))
    #expect(screenshotScenarios.contains("state.latestReportSource = .sample"))
  }

  private func sourceContents(_ relativePath: String) throws -> String {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    return try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
  }
}
