import Foundation
import Testing

@testable import SleepSoundCore

@Suite("Regression Test Suite")
struct RegressionTestSuiteTests {
  @Test
  func syntheticPatternsExerciseDetectorWithoutPersonalAudioFixtures() throws {
    let expectations: [(pattern: SyntheticAudioPattern, acceptableTypes: Set<SleepEventType>)] = [
      (.silence, []),
      (.lowEnergyNoise, []),
      (.highEnergyNoise, [.environmentalNoise, .awakeningSuspected, .coughLike, .bruxismLike]),
      (.snoreLikeBurst, [.snore]),
      (.coughLikeBurst, [.coughLike, .environmentalNoise]),
      (.gaspLikeBurst, [.gaspLike, .coughLike, .movementLike, .bruxismLike]),
      (.movementLikeNoise, [.movementLike, .sleepTalkLike, .coughLike, .environmentalNoise, .bruxismLike]),
    ]

    for expectation in expectations {
      let result = try makeRegressionResult(pattern: expectation.pattern, duration: 12)

      #expect(result.chunks.isEmpty == false)
      #expect(result.metrics.receivedAudioSeconds > 0)
      #expect(result.metrics.analyzedAudioSeconds > 0)
      #expect(result.diagnostics.analyzedChunkCount == result.chunks.count)
      #expect(result.diagnostics.rmsSummary.count == result.chunks.count)
      #expect(result.diagnostics.energySummary.count == result.chunks.count)

      if expectation.acceptableTypes.isEmpty {
        #expect(result.rawOutputs.isEmpty)
        #expect(result.events.isEmpty)
      } else {
        let rawTypes = Set(result.rawOutputs.map(\.eventType))
        #expect(
          rawTypes.isDisjoint(with: expectation.acceptableTypes) == false,
          "\(expectation.pattern.rawValue) raw types: \(rawTypes.map(\.rawValue).sorted())"
        )
      }
    }
  }

  @Test
  func detectorDiagnosticsSurviveFullSyntheticAnalysisPipeline() throws {
    let result = try makeRegressionResult(
      pattern: .snoreLikeBurst,
      duration: 20,
      eventAudioSampleStorageEnabled: true
    )

    #expect(result.diagnostics.rawCandidateCount > 0)
    #expect(result.diagnostics.preSmoothingCandidateCount == result.rawOutputs.count)
    #expect(result.diagnostics.postSmoothingEventCount == result.smoothing.outputs.count)
    #expect(result.diagnostics.finalEventCountByType.values.reduce(0, +) == result.events.count)
    #expect(result.diagnostics.thresholdsSnapshot["tuning.minimumConfidence"] != nil)
    #expect(result.diagnostics.eventAudioSampleStorageEnabled)
    #expect(result.report.detectorDiagnostics == result.diagnostics)
    #expect(result.report.receivedAudioDuration > 0)
    #expect(result.report.analyzedAudioDuration > 0)
    #expect(result.report.audioCoverageRatio > 0.95)
  }

  @Test
  func zeroEventHighCoverageSessionExplainsNoRawCandidates() throws {
    let result = try makeRegressionResult(pattern: .silence, duration: 60)

    #expect(result.report.detectorDiagnostics?.rawCandidateCount == 0)
    #expect(result.report.detectorDiagnostics?.finalEventCountByType.values.reduce(0, +) == 0)
    #expect(result.report.audioCoverageRatio > 0.95)

    let diagnostics = try #require(result.report.detectorDiagnostics)
    let analysis = try #require(ZeroEventAnalysis.make(diagnostics: diagnostics))

    #expect(
      analysis.probableReason == .featuresMostlySilence ||
        analysis.probableReason == .genuinelyQuietSession
    )
    #expect(analysis.confidence > 0.5)
  }

  @Test
  func zeroEventSessionExplainsCandidatesRemovedBySmoothing() throws {
    let startedAt = Date(timeIntervalSince1970: 10_000)
    var metrics = AudioCaptureMetrics()
    metrics.start(at: startedAt)
    let chunk = AudioChunk(
      samples: Array(repeating: 0.2, count: 16_000),
      sampleRate: 16_000,
      startedAt: startedAt,
      duration: 1
    )
    metrics.recordReceived(chunk: chunk, at: startedAt)
    metrics.recordAnalyzed(chunk: chunk, at: startedAt)
    metrics.stop(at: startedAt.addingTimeInterval(60))

    let output = DetectorOutput(
      eventType: .coughLike,
      startedAt: startedAt,
      endedAt: startedAt.addingTimeInterval(0.1),
      confidence: 0.8,
      intensity: 0.7,
      debugReason: "regression short candidate"
    )
    let smoothing = DetectionSmoothingPolicy(
      minimumEventDuration: 0.5,
      maximumMergeGap: 1,
      confidenceThreshold: 0.35
    ).applyWithDiagnostics(to: [output])

    let diagnostics = DetectorDiagnostics(
      sessionId: UUID(),
      startedAt: startedAt,
      endedAt: startedAt.addingTimeInterval(60),
      detectorBackend: SleepDetectionBackend.ruleBased.displayName,
      modelInstalled: false,
      analyzedChunkCount: 60,
      receivedAudioSeconds: 60,
      analyzedAudioSeconds: 60,
      audioCoverageRatio: 1,
      rawCandidateCount: 1,
      rawCandidateCountByType: [.coughLike: 1],
      preSmoothingCandidateCount: smoothing.diagnostics.preSmoothingCandidateCount,
      postSmoothingEventCount: smoothing.diagnostics.postSmoothingEventCount,
      finalEventCountByType: [:],
      rejectedCountByReason: smoothing.diagnostics.rejectedCountByReason,
      confidenceHistogram: ["0.8-1.0": 1],
      rmsSummary: SummaryStats.make(values: [0.2]),
      energySummary: SummaryStats.make(values: [0.04]),
      thresholdsSnapshot: DetectorTuningProfile.balanced.configuration.thresholdSnapshot,
      eventAudioSampleStorageEnabled: false
    )

    let analysis = try #require(ZeroEventAnalysis.make(diagnostics: diagnostics))

    #expect(smoothing.outputs.isEmpty)
    #expect(diagnostics.rejectedCountByReason[.tooShort] == 1)
    #expect(
      analysis.probableReason == .candidatesRejectedByTooShort ||
        analysis.probableReason == .smoothingRemovedCandidates
    )
  }

  @Test
  func reportKeepsSessionTimeAudioTimeAndQualitySeparate() throws {
    let startedAt = Date(timeIntervalSince1970: 20_000)
    let session = SleepSession(
      startedAt: startedAt,
      endedAt: startedAt.addingTimeInterval(300),
      measurementDuration: 300,
      estimatedSleepDuration: 280
    )
    var metrics = AudioCaptureMetrics()
    metrics.start(at: startedAt)
    metrics.stop(at: startedAt.addingTimeInterval(300))
    metrics = AudioCaptureMetrics(
      captureStartedAt: startedAt,
      captureStoppedAt: startedAt.addingTimeInterval(300),
      sessionElapsedSeconds: 300,
      captureActiveSeconds: 300,
      receivedAudioSeconds: 260,
      analyzedAudioSeconds: 250,
      receivedChunkCount: 260,
      analyzedChunkCount: 250,
      totalReceivedFrameCount: 4_160_000,
      totalAnalyzedFrameCount: 4_000_000,
      sampleRate: 16_000,
      lastChunkReceivedAt: startedAt.addingTimeInterval(260),
      lastChunkAnalyzedAt: startedAt.addingTimeInterval(250),
      longestChunkGapSeconds: 8,
      currentChunkGapSeconds: 40,
      audioCoverageRatio: 260.0 / 300.0
    )

    let events = [
      SleepEvent(
        sessionId: session.id,
        type: .environmentalNoise,
        startedAt: startedAt.addingTimeInterval(120),
        endedAt: startedAt.addingTimeInterval(125),
        confidence: 0.7,
        intensity: 0.8
      )
    ]

    let report = SleepScoreCalculator().makeReport(
      session: session,
      events: events,
      captureMetrics: metrics
    )

    #expect(report.measurementDuration == 300)
    #expect(report.receivedAudioDuration == 260)
    #expect(report.analyzedAudioDuration == 250)
    #expect(report.audioCoverageRatio == 260.0 / 300.0)
    #expect(report.measurementQuality == .good)
    #expect(report.environmentalNoiseCount == 1)
  }

  private func makeRegressionResult(
    pattern: SyntheticAudioPattern,
    duration: TimeInterval,
    eventAudioSampleStorageEnabled: Bool = false
  ) throws -> RegressionAnalysisResult {
    let sessionId = UUID()
    let startedAt = Date(timeIntervalSince1970: 1_000)
    let configuration = DetectorTuningProfile.balanced.configuration
    let analyzer = configuration.makeSleepAnalyzer()
    let chunks = SyntheticAudioSource.makeChunks(
      pattern: pattern,
      duration: duration,
      sampleRate: 16_000,
      chunkDuration: 1,
      startedAt: startedAt
    )

    var metrics = AudioCaptureMetrics()
    metrics.start(at: startedAt)

    let collector = DetectorDiagnosticsCollector()
    collector.reset(
      sessionId: sessionId,
      startedAt: startedAt,
      detectorBackend: analyzer.detectorBackend.displayName,
      modelInstalled: analyzer.isModelInstalled,
      thresholdsSnapshot: analyzer.thresholdsSnapshot.merging(configuration.thresholdSnapshot) {
        current, _ in current
      },
      eventAudioSampleStorageEnabled: eventAudioSampleStorageEnabled
    )

    var rawOutputs: [DetectorOutput] = []
    var audioFeatures: [AudioFeatures] = []
    for chunk in chunks {
      metrics.recordReceived(chunk: chunk, at: chunk.startedAt)
      let features = analyzer.extractor.extractFeatures(from: chunk)
      let outputs = analyzer.detector.detect(features: features)
      metrics.recordAnalyzed(chunk: chunk, at: chunk.startedAt)
      collector.record(features: features, outputs: outputs)
      audioFeatures.append(features)
      rawOutputs.append(contentsOf: outputs)
    }

    let sequenceResult = analyzer.detectSuspectedBreathingPauseSequence(
      features: audioFeatures,
      contextOutputs: rawOutputs
    )
    collector.record(sequenceResult: sequenceResult)
    rawOutputs.append(contentsOf: sequenceResult.outputs)

    let smoothing = analyzer.smoothWithDiagnostics(outputs: rawOutputs)
    collector.record(smoothingDiagnostics: smoothing.diagnostics)

    let session = SleepSession(
      id: sessionId,
      startedAt: startedAt,
      endedAt: startedAt.addingTimeInterval(duration),
      measurementDuration: duration,
      estimatedSleepDuration: duration
    )
    let events = analyzer.makeEvents(session: session, outputs: smoothing.outputs)
    collector.record(finalEvents: events)
    metrics.stop(at: startedAt.addingTimeInterval(duration))

    let diagnostics = try #require(collector.finalize(
      endedAt: startedAt.addingTimeInterval(duration),
      metrics: metrics
    ))

    var report = SleepScoreCalculator().makeReport(
      session: session,
      events: events,
      captureMetrics: metrics
    )
    report.detectorDiagnostics = diagnostics

    return RegressionAnalysisResult(
      chunks: chunks,
      rawOutputs: rawOutputs,
      smoothing: smoothing,
      events: events,
      metrics: metrics,
      diagnostics: diagnostics,
      report: report
    )
  }
}

private struct RegressionAnalysisResult {
  var chunks: [AudioChunk]
  var rawOutputs: [DetectorOutput]
  var smoothing: DetectionSmoothingResult
  var events: [SleepEvent]
  var metrics: AudioCaptureMetrics
  var diagnostics: DetectorDiagnostics
  var report: NightReport
}
