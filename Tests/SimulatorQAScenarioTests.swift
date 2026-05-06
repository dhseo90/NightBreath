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

  private func sourceContents(_ relativePath: String) throws -> String {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    return try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
  }
}
