import Foundation

public enum SimulatorQAScenarioPreset: String, CaseIterable, Codable, Identifiable, Sendable {
  case quietNight
  case snoreHeavyNight
  case noiseHeavyNight
  case coughGaspNight
  case bruxismLikeNight
  case zeroEventButGoodAudioCoverage
  case zeroEventBecauseNoAudioReceived
  case lowAudioCoverageNight
  case eventAudioStorageOff
  case eventAudioStorageOnWithSamples
  case orphanSamplesPresent

  public var id: String { rawValue }

  public var displayName: String {
    switch self {
    case .quietNight:
      "QuietNight"
    case .snoreHeavyNight:
      "SnoreHeavyNight"
    case .noiseHeavyNight:
      "NoiseHeavyNight"
    case .coughGaspNight:
      "CoughGaspNight"
    case .bruxismLikeNight:
      "BruxismLikeNight"
    case .zeroEventButGoodAudioCoverage:
      "ZeroEventButGoodAudioCoverage"
    case .zeroEventBecauseNoAudioReceived:
      "ZeroEventBecauseNoAudioReceived"
    case .lowAudioCoverageNight:
      "LowAudioCoverageNight"
    case .eventAudioStorageOff:
      "EventAudioStorageOff"
    case .eventAudioStorageOnWithSamples:
      "EventAudioStorageOnWithSamples"
    case .orphanSamplesPresent:
      "OrphanSamplesPresent"
    }
  }

  public var koreanTitle: String {
    switch self {
    case .quietNight:
      "조용한 밤"
    case .snoreHeavyNight:
      "코골기 많은 밤"
    case .noiseHeavyNight:
      "환경 소음 많은 밤"
    case .coughGaspNight:
      "기침/gasp-like 많은 밤"
    case .bruxismLikeNight:
      "이갈이 의심 소리 많은 밤"
    case .zeroEventButGoodAudioCoverage:
      "커버리지는 좋지만 이벤트 0개"
    case .zeroEventBecauseNoAudioReceived:
      "오디오 수신 없음"
    case .lowAudioCoverageNight:
      "낮은 오디오 커버리지"
    case .eventAudioStorageOff:
      "이벤트 오디오 저장 꺼짐"
    case .eventAudioStorageOnWithSamples:
      "이벤트 오디오 저장 켜짐"
    case .orphanSamplesPresent:
      "연결되지 않은 샘플 있음"
    }
  }

  public var qaFocus: String {
    switch self {
    case .quietNight:
      "높은 수면 소리 점수와 빈 타임라인 상태를 확인합니다."
    case .snoreHeavyNight:
      "코골기 시간, 주요 원인 설명, 타임라인 밀도를 확인합니다."
    case .noiseHeavyNight:
      "환경 소음과 각성 의심 구간이 많은 리포트를 확인합니다."
    case .coughGaspNight:
      "기침 의심 소리와 gasp-like 회복 호흡 표시를 확인합니다."
    case .bruxismLikeNight:
      "이갈이 의심 소리 문구와 사용자 확인 UI를 확인합니다."
    case .zeroEventButGoodAudioCoverage:
      "오디오 입력은 충분하지만 최종 이벤트가 없는 zero-event 분석을 확인합니다."
    case .zeroEventBecauseNoAudioReceived:
      "실제 오디오 수신 시간이 0에 가까운 낮은 측정 품질 상태를 확인합니다."
    case .lowAudioCoverageNight:
      "앱 동작 시간과 실제 오디오 수신 시간이 크게 다른 리포트를 확인합니다."
    case .eventAudioStorageOff:
      "샘플 저장 OFF 상태에서 이벤트 요약만 남는 흐름을 확인합니다."
    case .eventAudioStorageOnWithSamples:
      "샘플 저장 ON 상태의 저장 오디오 시간/용량 표시를 확인합니다."
    case .orphanSamplesPresent:
      "연결되지 않은 이벤트 오디오 샘플 관리 UI를 확인합니다."
    }
  }
}

public struct SimulatorQAScenarioBundle: Equatable {
  public var preset: SimulatorQAScenarioPreset
  public var session: SleepSession
  public var events: [SleepEvent]
  public var report: NightReport
  public var detectorDiagnostics: DetectorDiagnostics
  public var eventAudioStorageStats: EventAudioStorageStats
  public var isEventAudioSampleStorageEnabled: Bool
  public var recentReports: [NightReport]

  public init(
    preset: SimulatorQAScenarioPreset,
    session: SleepSession,
    events: [SleepEvent],
    report: NightReport,
    detectorDiagnostics: DetectorDiagnostics,
    eventAudioStorageStats: EventAudioStorageStats,
    isEventAudioSampleStorageEnabled: Bool,
    recentReports: [NightReport]
  ) {
    self.preset = preset
    self.session = session
    self.events = events
    self.report = report
    self.detectorDiagnostics = detectorDiagnostics
    self.eventAudioStorageStats = eventAudioStorageStats
    self.isEventAudioSampleStorageEnabled = isEventAudioSampleStorageEnabled
    self.recentReports = recentReports
  }
}

public enum SimulatorQAScenarioFactory {
  public static func make(
    preset: SimulatorQAScenarioPreset,
    now: Date = Date(timeIntervalSince1970: 1_777_680_000)
  ) -> SimulatorQAScenarioBundle {
    let startedAt = Calendar(identifier: .gregorian).date(
      from: DateComponents(year: 2026, month: 5, day: 2, hour: 23, minute: 10)
    ) ?? now.addingTimeInterval(-8 * 60 * 60)
    let measurementDuration = defaultMeasurementDuration(for: preset)
    let endedAt = startedAt.addingTimeInterval(measurementDuration)
    let session = SleepSession(
      startedAt: startedAt,
      endedAt: endedAt,
      estimatedSleepStart: startedAt.addingTimeInterval(18 * 60),
      estimatedWakeTime: endedAt.addingTimeInterval(-12 * 60),
      measurementDuration: measurementDuration,
      estimatedSleepDuration: max(measurementDuration - 30 * 60, 0),
      devicePlacement: .bedside,
      ambientNoiseBaseline: 0.012,
      appVersion: "1.0-simulator-qa",
      modelVersion: "simulator-qa-\(preset.rawValue)"
    )
    let storageEnabled = storageEnabled(for: preset)
    let events = makeEvents(preset: preset, session: session, startedAt: startedAt)
    let metrics = makeMetrics(preset: preset, startedAt: startedAt, endedAt: endedAt)
    let diagnostics = makeDiagnostics(
      preset: preset,
      session: session,
      events: events,
      metrics: metrics,
      storageEnabled: storageEnabled
    )
    var report = SleepScoreCalculator().makeReport(
      session: session,
      events: events,
      captureMetrics: metrics
    )
    report.generatedAt = endedAt.addingTimeInterval(10 * 60)
    report.detectorDiagnostics = diagnostics
    let storageStats = makeStorageStats(preset: preset, events: events, generatedAt: report.generatedAt)

    return SimulatorQAScenarioBundle(
      preset: preset,
      session: session,
      events: events,
      report: report,
      detectorDiagnostics: diagnostics,
      eventAudioStorageStats: storageStats,
      isEventAudioSampleStorageEnabled: storageEnabled,
      recentReports: makeRecentReports(currentReport: report)
    )
  }

  private static func defaultMeasurementDuration(for preset: SimulatorQAScenarioPreset) -> TimeInterval {
    switch preset {
    case .zeroEventBecauseNoAudioReceived:
      45 * 60
    case .lowAudioCoverageNight:
      6.5 * 60 * 60
    default:
      7.8 * 60 * 60
    }
  }

  private static func storageEnabled(for preset: SimulatorQAScenarioPreset) -> Bool {
    switch preset {
    case .eventAudioStorageOnWithSamples, .orphanSamplesPresent:
      true
    default:
      false
    }
  }

  private static func makeEvents(
    preset: SimulatorQAScenarioPreset,
    session: SleepSession,
    startedAt: Date
  ) -> [SleepEvent] {
    switch preset {
    case .quietNight, .zeroEventButGoodAudioCoverage, .zeroEventBecauseNoAudioReceived:
      return []
    case .snoreHeavyNight:
      return [
        event(session, .snore, startedAt, minute: 72, duration: 22 * 60, confidence: 0.78, intensity: 0.68),
        event(session, .snore, startedAt, minute: 168, duration: 31 * 60, confidence: 0.82, intensity: 0.72),
        event(session, .snore, startedAt, minute: 252, duration: 38 * 60, confidence: 0.80, intensity: 0.74),
        event(session, .awakeningSuspected, startedAt, minute: 292, duration: 4 * 60, confidence: 0.56, intensity: 0.42),
      ]
    case .noiseHeavyNight:
      return [
        event(session, .environmentalNoise, startedAt, minute: 55, duration: 90, confidence: 0.74, intensity: 0.88),
        event(session, .environmentalNoise, startedAt, minute: 118, duration: 120, confidence: 0.70, intensity: 0.82),
        event(session, .environmentalNoise, startedAt, minute: 202, duration: 75, confidence: 0.76, intensity: 0.86),
        event(session, .awakeningSuspected, startedAt, minute: 203, duration: 180, confidence: 0.62, intensity: 0.64),
        event(session, .awakeningSuspected, startedAt, minute: 310, duration: 240, confidence: 0.59, intensity: 0.55),
      ]
    case .coughGaspNight:
      return [
        event(session, .coughLike, startedAt, minute: 62, duration: 6, confidence: 0.67, intensity: 0.74),
        event(session, .coughLike, startedAt, minute: 64, duration: 5, confidence: 0.64, intensity: 0.69),
        event(session, .breathingPauseSuspected, startedAt, minute: 188, duration: 24, confidence: 0.58, intensity: 0.22),
        event(session, .gaspLike, startedAt, minute: 189, duration: 5, confidence: 0.61, intensity: 0.62),
        event(session, .breathingPauseSuspected, startedAt, minute: 244, duration: 31, confidence: 0.60, intensity: 0.24),
        event(session, .gaspLike, startedAt, minute: 245, duration: 4, confidence: 0.63, intensity: 0.66),
      ]
    case .bruxismLikeNight:
      return [
        event(session, .bruxismLike, startedAt, minute: 80, duration: 7, confidence: 0.61, intensity: 0.58),
        event(session, .bruxismLike, startedAt, minute: 112, duration: 9, confidence: 0.66, intensity: 0.61),
        event(session, .bruxismLike, startedAt, minute: 146, duration: 5, confidence: 0.57, intensity: 0.54),
        event(session, .movementLike, startedAt, minute: 150, duration: 18, confidence: 0.50, intensity: 0.42),
      ]
    case .lowAudioCoverageNight:
      return [
        event(session, .snore, startedAt, minute: 30, duration: 12 * 60, confidence: 0.73, intensity: 0.64),
        event(session, .environmentalNoise, startedAt, minute: 74, duration: 80, confidence: 0.69, intensity: 0.82),
      ]
    case .eventAudioStorageOff:
      return [
        event(session, .snore, startedAt, minute: 90, duration: 14 * 60, confidence: 0.78, intensity: 0.64),
        event(session, .coughLike, startedAt, minute: 160, duration: 7, confidence: 0.69, intensity: 0.72),
      ]
    case .eventAudioStorageOnWithSamples:
      return [
        event(session, .snore, startedAt, minute: 90, duration: 14 * 60, confidence: 0.78, intensity: 0.64, snippet: "qa_snore_001.caf", snippetDuration: 8),
        event(session, .coughLike, startedAt, minute: 160, duration: 7, confidence: 0.69, intensity: 0.72, snippet: "qa_cough_001.caf", snippetDuration: 5),
      ]
    case .orphanSamplesPresent:
      return [
        event(session, .snore, startedAt, minute: 120, duration: 16 * 60, confidence: 0.75, intensity: 0.62, snippet: "qa_linked_snore.caf", snippetDuration: 7),
        event(session, .movementLike, startedAt, minute: 280, duration: 18, confidence: 0.55, intensity: 0.48),
      ]
    }
  }

  private static func event(
    _ session: SleepSession,
    _ type: SleepEventType,
    _ startedAt: Date,
    minute: TimeInterval,
    duration: TimeInterval,
    confidence: Double,
    intensity: Double,
    snippet: String? = nil,
    snippetDuration: TimeInterval? = nil
  ) -> SleepEvent {
    let eventStartedAt = startedAt.addingTimeInterval(minute * 60)
    return SleepEvent(
      sessionId: session.id,
      type: type,
      startedAt: eventStartedAt,
      endedAt: eventStartedAt.addingTimeInterval(duration),
      confidence: confidence,
      intensity: intensity,
      audioSnippetFileName: snippet,
      audioSnippetDuration: snippetDuration
    )
  }

  private static func makeMetrics(
    preset: SimulatorQAScenarioPreset,
    startedAt: Date,
    endedAt: Date
  ) -> AudioCaptureMetrics {
    let elapsed = max(0, endedAt.timeIntervalSince(startedAt))
    let received: TimeInterval
    let analyzed: TimeInterval
    let interruptions: Int
    let longestGap: TimeInterval

    switch preset {
    case .zeroEventBecauseNoAudioReceived:
      received = 0
      analyzed = 0
      interruptions = 1
      longestGap = elapsed
    case .lowAudioCoverageNight:
      received = elapsed * 0.42
      analyzed = elapsed * 0.40
      interruptions = 3
      longestGap = 38 * 60
    default:
      received = elapsed * 0.985
      analyzed = elapsed * 0.982
      interruptions = 0
      longestGap = 4
    }

    return AudioCaptureMetrics(
      captureStartedAt: startedAt,
      captureStoppedAt: endedAt,
      sessionElapsedSeconds: elapsed,
      captureActiveSeconds: elapsed,
      receivedAudioSeconds: received,
      analyzedAudioSeconds: analyzed,
      receivedChunkCount: Int(received),
      analyzedChunkCount: Int(analyzed),
      totalReceivedFrameCount: Int64(received * 16_000),
      totalAnalyzedFrameCount: Int64(analyzed * 16_000),
      sampleRate: 16_000,
      lastChunkReceivedAt: received > 0 ? startedAt.addingTimeInterval(received) : nil,
      lastChunkAnalyzedAt: analyzed > 0 ? startedAt.addingTimeInterval(analyzed) : nil,
      interruptionCount: interruptions,
      longestChunkGapSeconds: longestGap,
      currentChunkGapSeconds: max(0, elapsed - received),
      audioCoverageRatio: elapsed > 0 ? received / elapsed : 0
    )
  }

  private static func makeDiagnostics(
    preset: SimulatorQAScenarioPreset,
    session: SleepSession,
    events: [SleepEvent],
    metrics: AudioCaptureMetrics,
    storageEnabled: Bool
  ) -> DetectorDiagnostics {
    let finalCounts = eventCounts(events)
    let rawCounts = rawCandidateCounts(preset: preset, finalCounts: finalCounts)
    let rawCandidateCount = rawCounts.values.reduce(0, +)
    let rejected = rejectReasons(preset: preset, analyzedChunkCount: metrics.analyzedChunkCount)

    return DetectorDiagnostics(
      sessionId: session.id,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      detectorBackend: SleepDetectionBackend.ruleBased.displayName,
      modelInstalled: false,
      modelFallbackCount: 0,
      analyzedChunkCount: metrics.analyzedChunkCount,
      receivedAudioSeconds: metrics.receivedAudioSeconds,
      analyzedAudioSeconds: metrics.analyzedAudioSeconds,
      audioCoverageRatio: metrics.audioCoverageRatio,
      rawCandidateCount: rawCandidateCount,
      rawCandidateCountByType: rawCounts,
      preSmoothingCandidateCount: rawCandidateCount,
      postSmoothingEventCount: events.count,
      finalEventCountByType: finalCounts,
      rejectedCountByReason: rejected,
      confidenceHistogram: confidenceHistogram(events: events, rawCandidateCount: rawCandidateCount),
      rmsSummary: rmsSummary(preset: preset),
      energySummary: energySummary(preset: preset),
      zeroCrossingRateSummary: SummaryStats.make(values: [0.04, 0.08, 0.12, 0.18]),
      spectralCentroidSummary: SummaryStats.make(values: [180, 420, 780, 1_600]),
      lowBandEnergySummary: SummaryStats.make(values: [0.22, 0.38, 0.48, 0.62]),
      midBandEnergySummary: SummaryStats.make(values: [0.18, 0.24, 0.32, 0.42]),
      highBandEnergySummary: SummaryStats.make(values: [0.08, 0.16, 0.22, 0.36]),
      thresholdsSnapshot: DetectorTuningProfile.balanced.configuration.thresholdSnapshot,
      eventAudioSampleStorageEnabled: storageEnabled,
      notes: [preset.qaFocus]
    )
  }

  private static func rawCandidateCounts(
    preset: SimulatorQAScenarioPreset,
    finalCounts: [SleepEventType: Int]
  ) -> [SleepEventType: Int] {
    switch preset {
    case .zeroEventButGoodAudioCoverage, .zeroEventBecauseNoAudioReceived, .quietNight:
      return [:]
    case .lowAudioCoverageNight:
      return finalCounts.mapValues { $0 + 2 }
    default:
      return finalCounts.mapValues { max($0, 1) + 1 }
    }
  }

  private static func rejectReasons(
    preset: SimulatorQAScenarioPreset,
    analyzedChunkCount: Int
  ) -> [RejectReason: Int] {
    switch preset {
    case .zeroEventButGoodAudioCoverage:
      return [
        .likelySilence: max(1, analyzedChunkCount / 2),
        .belowRmsThreshold: max(1, analyzedChunkCount / 3),
        .belowEnergyThreshold: max(1, analyzedChunkCount / 3),
      ]
    case .zeroEventBecauseNoAudioReceived:
      return [.unknown: 1]
    case .lowAudioCoverageNight:
      return [.belowConfidenceThreshold: 8, .tooShort: 4]
    case .eventAudioStorageOff, .eventAudioStorageOnWithSamples, .orphanSamplesPresent:
      return [.mergedIntoNearbyEvent: 2]
    default:
      return [.belowConfidenceThreshold: 3, .tooShort: 2]
    }
  }

  private static func eventCounts(_ events: [SleepEvent]) -> [SleepEventType: Int] {
    events.reduce(into: [SleepEventType: Int]()) { result, event in
      result[event.type, default: 0] += 1
    }
  }

  private static func confidenceHistogram(
    events: [SleepEvent],
    rawCandidateCount: Int
  ) -> [String: Int] {
    guard rawCandidateCount > 0 else { return [:] }
    let highConfidenceCount = events.filter { $0.confidence >= 0.6 }.count
    return [
      "0.4-0.6": max(0, rawCandidateCount - highConfidenceCount),
      "0.6-0.8": highConfidenceCount,
    ].filter { $0.value > 0 }
  }

  private static func rmsSummary(preset: SimulatorQAScenarioPreset) -> SummaryStats {
    switch preset {
    case .zeroEventBecauseNoAudioReceived:
      return SummaryStats()
    case .zeroEventButGoodAudioCoverage, .quietNight:
      return SummaryStats.make(values: [0.001, 0.002, 0.003, 0.005])
    case .noiseHeavyNight:
      return SummaryStats.make(values: [0.03, 0.08, 0.18, 0.34])
    case .lowAudioCoverageNight:
      return SummaryStats.make(values: [0.005, 0.02, 0.07, 0.16])
    default:
      return SummaryStats.make(values: [0.01, 0.03, 0.07, 0.12])
    }
  }

  private static func energySummary(preset: SimulatorQAScenarioPreset) -> SummaryStats {
    switch preset {
    case .zeroEventBecauseNoAudioReceived:
      return SummaryStats()
    case .zeroEventButGoodAudioCoverage, .quietNight:
      return SummaryStats.make(values: [0.000001, 0.000004, 0.000009, 0.000025])
    case .noiseHeavyNight:
      return SummaryStats.make(values: [0.0009, 0.0064, 0.0324, 0.1156])
    case .lowAudioCoverageNight:
      return SummaryStats.make(values: [0.000025, 0.0004, 0.0049, 0.0256])
    default:
      return SummaryStats.make(values: [0.0001, 0.0009, 0.0049, 0.0144])
    }
  }

  private static func makeStorageStats(
    preset: SimulatorQAScenarioPreset,
    events: [SleepEvent],
    generatedAt: Date
  ) -> EventAudioStorageStats {
    switch preset {
    case .eventAudioStorageOnWithSamples:
      let linkedDuration = events.reduce(0) { $0 + max(0, $1.audioSnippetDuration ?? 0) }
      return EventAudioStorageStats(
        sampleCount: 2,
        linkedSampleCount: 2,
        orphanSampleCount: 0,
        totalBytes: 420_000,
        linkedBytes: 420_000,
        orphanBytes: 0,
        totalDurationSeconds: linkedDuration,
        linkedDurationSeconds: linkedDuration,
        orphanDurationSeconds: 0,
        latestSampleCreatedAt: generatedAt
      )
    case .orphanSamplesPresent:
      let linkedDuration = events.reduce(0) { $0 + max(0, $1.audioSnippetDuration ?? 0) }
      return EventAudioStorageStats(
        sampleCount: 5,
        linkedSampleCount: 1,
        orphanSampleCount: 4,
        totalBytes: 1_280_000,
        linkedBytes: 180_000,
        orphanBytes: 1_100_000,
        totalDurationSeconds: linkedDuration + 24,
        linkedDurationSeconds: linkedDuration,
        orphanDurationSeconds: 24,
        latestSampleCreatedAt: generatedAt
      )
    default:
      return .empty
    }
  }

  private static func makeRecentReports(currentReport: NightReport) -> [NightReport] {
    (-6...0).map { offset in
      var report = currentReport
      report.generatedAt = currentReport.generatedAt.addingTimeInterval(TimeInterval(offset) * 24 * 60 * 60)
      if offset != 0 {
        report.sessionId = UUID()
        report.sleepSoundScore = min(max(currentReport.sleepSoundScore + offset * 2, 0), 100)
        report.snoreTotalSeconds = max(0, currentReport.snoreTotalSeconds + TimeInterval(offset * 5 * 60))
        report.environmentalNoiseCount = max(0, currentReport.environmentalNoiseCount + offset)
      }
      return report
    }
  }
}
