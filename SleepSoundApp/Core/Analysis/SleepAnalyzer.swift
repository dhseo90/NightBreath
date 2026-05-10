import Foundation

public protocol SleepAnalyzing {
  func analyze(session: SleepSession, chunks: [AudioChunk]) -> [SleepEvent]
  func analyze(chunks: [AudioChunk]) -> [DetectorOutput]
  func detectOutputs(from chunks: [AudioChunk]) -> [DetectorOutput]
  func detectOutputs(from chunk: AudioChunk) -> [DetectorOutput]
  func detectOutputs(from chunk: AudioChunk, updating metrics: inout AudioCaptureMetrics)
    -> [DetectorOutput]
  func detectOutputsWithFeatures(
    from chunk: AudioChunk, updating metrics: inout AudioCaptureMetrics
  ) -> (features: AudioFeatures, outputs: [DetectorOutput])
  func smooth(outputs: [DetectorOutput]) -> [DetectorOutput]
  func smoothWithDiagnostics(outputs: [DetectorOutput]) -> DetectionSmoothingResult
  func makeEvents(session: SleepSession, outputs: [DetectorOutput]) -> [SleepEvent]
  func makeReport(session: SleepSession, outputs: [DetectorOutput]) -> NightReport
  @MainActor func analyze(
    session: SleepSession, chunkStream: AsyncThrowingStream<AudioChunk, Error>
  )
    async throws -> [SleepEvent]
  @MainActor func analyze(session: SleepSession, audioSource: any AudioSourceProtocol) async throws
    -> [SleepEvent]
}

public struct SleepAnalyzer: SleepAnalyzing, Sendable {
  public var extractor: any AudioFeatureExtracting
  public var detector: any SleepEventDetector
  public var suspectedBreathingPauseSequenceDetector: SuspectedBreathingPauseSequenceDetector
  public var smoothingPolicy: DetectionSmoothingPolicy

  public init(
    extractor: any AudioFeatureExtracting = AudioFeatureExtractor(),
    detector: any SleepEventDetector = CompositeSleepEventDetector.ruleBasedDefault,
    suspectedBreathingPauseSequenceDetector: SuspectedBreathingPauseSequenceDetector = SuspectedBreathingPauseSequenceDetector(),
    smoothingPolicy: DetectionSmoothingPolicy = DetectionSmoothingPolicy()
  ) {
    self.extractor = extractor
    self.detector = detector
    self.suspectedBreathingPauseSequenceDetector = suspectedBreathingPauseSequenceDetector
    self.smoothingPolicy = smoothingPolicy
  }

  public func analyze(session: SleepSession, chunks: [AudioChunk]) -> [SleepEvent] {
    makeEvents(session: session, outputs: analyze(chunks: chunks))
  }

  public func analyze(chunks: [AudioChunk]) -> [DetectorOutput] {
    smooth(outputs: detectOutputs(from: chunks))
  }

  public func detectOutputs(from chunks: [AudioChunk]) -> [DetectorOutput] {
    var features: [AudioFeatures] = []
    var outputs: [DetectorOutput] = []

    for chunk in chunks {
      let extractedFeatures = extractor.extractFeatures(from: chunk)
      features.append(extractedFeatures)
      outputs.append(contentsOf: detector.detect(features: extractedFeatures))
    }

    let sequenceResult = detectSuspectedBreathingPauseSequence(
      features: features,
      contextOutputs: outputs
    )
    outputs.append(contentsOf: sequenceResult.outputs)
    return outputs
  }

  public func detectOutputs(from chunk: AudioChunk) -> [DetectorOutput] {
    let features = extractor.extractFeatures(from: chunk)
    return detector.detect(features: features)
  }

  public func detectOutputs(from chunk: AudioChunk, updating metrics: inout AudioCaptureMetrics)
    -> [DetectorOutput]
  {
    let (_, outputs) = detectOutputsWithFeatures(from: chunk, updating: &metrics)
    return outputs
  }

  public func detectOutputsWithFeatures(
    from chunk: AudioChunk,
    updating metrics: inout AudioCaptureMetrics
  ) -> (features: AudioFeatures, outputs: [DetectorOutput]) {
    let features = extractor.extractFeatures(from: chunk)
    let outputs = detector.detect(features: features)
    metrics.recordAnalyzed(chunk: chunk, at: chunk.startedAt)
    return (features, outputs)
  }

  public func smooth(outputs: [DetectorOutput]) -> [DetectorOutput] {
    smoothingPolicy.apply(to: outputs)
  }

  public func smoothWithDiagnostics(outputs: [DetectorOutput]) -> DetectionSmoothingResult {
    smoothingPolicy.applyWithDiagnostics(to: outputs)
  }

  public func detectSuspectedBreathingPauseSequence(
    features: [AudioFeatures],
    contextOutputs: [DetectorOutput]
  ) -> SuspectedBreathingPauseSequenceResult {
    suspectedBreathingPauseSequenceDetector.detect(
      features: features,
      contextOutputs: contextOutputs
    )
  }

  public func makeEvents(session: SleepSession, outputs: [DetectorOutput]) -> [SleepEvent] {
    DetectorOutputMapper.makeEvents(from: outputs, sessionId: session.id)
  }

  public func analyze(session: SleepSession, chunkStream: AsyncStream<AudioChunk>) async
    -> [SleepEvent]
  {
    var rawOutputs: [DetectorOutput] = []
    var features: [AudioFeatures] = []

    for await chunk in chunkStream {
      let extractedFeatures = extractor.extractFeatures(from: chunk)
      features.append(extractedFeatures)
      rawOutputs.append(contentsOf: detector.detect(features: extractedFeatures))
    }

    rawOutputs.append(contentsOf: detectSuspectedBreathingPauseSequence(
      features: features,
      contextOutputs: rawOutputs
    ).outputs)
    return makeEvents(session: session, outputs: smooth(outputs: rawOutputs))
  }

  @MainActor
  public func analyze(session: SleepSession, chunkStream: AsyncThrowingStream<AudioChunk, Error>)
    async throws -> [SleepEvent]
  {
    var rawOutputs: [DetectorOutput] = []
    var features: [AudioFeatures] = []

    for try await chunk in chunkStream {
      let extractedFeatures = extractor.extractFeatures(from: chunk)
      features.append(extractedFeatures)
      rawOutputs.append(contentsOf: detector.detect(features: extractedFeatures))
    }

    rawOutputs.append(contentsOf: detectSuspectedBreathingPauseSequence(
      features: features,
      contextOutputs: rawOutputs
    ).outputs)
    return makeEvents(session: session, outputs: smooth(outputs: rawOutputs))
  }

  @MainActor
  public func analyze(session: SleepSession, audioSource: any AudioSourceProtocol) async throws
    -> [SleepEvent]
  {
    let stream = audioSource.makeChunkStream()
    try await audioSource.start()
    defer { audioSource.stop() }
    return try await analyze(session: session, chunkStream: stream)
  }

  public func makeReport(session: SleepSession, chunks: [AudioChunk]) -> NightReport {
    let events = analyze(session: session, chunks: chunks)
    return SleepScoreCalculator().makeReport(session: session, events: events)
  }

  public func makeReport(session: SleepSession, outputs: [DetectorOutput]) -> NightReport {
    let events = makeEvents(session: session, outputs: smooth(outputs: outputs))
    return SleepScoreCalculator().makeReport(session: session, events: events)
  }

  public var detectorBackend: SleepDetectionBackend {
    if let compositeDetector = detector as? CompositeSleepEventDetector {
      return compositeDetector.backend
    }
    if detector is CoreMLSleepEventDetector {
      return .coreML
    }
    return .ruleBased
  }

  public var isModelInstalled: Bool {
    if let compositeDetector = detector as? CompositeSleepEventDetector {
      if compositeDetector.backend == .coreMLMulticlass {
        return compositeDetector.multiclassCoreMLDetector.modelProvider.isModelAvailable
      }
      return compositeDetector.coreMLDetector.modelProvider.isModelAvailable
    }
    if let coreMLDetector = detector as? CoreMLSleepEventDetector {
      return coreMLDetector.modelProvider.isModelAvailable
    }
    return false
  }

  public var thresholdsSnapshot: [String: Double] {
    var snapshot = smoothingThresholdsSnapshot

    if let ruleBasedDetector = detector as? RuleBasedSleepEventDetector {
      snapshot.merge(ruleThresholdSnapshot(ruleBasedDetector.thresholds)) { current, _ in current }
    }

    if let compositeDetector = detector as? CompositeSleepEventDetector,
      let ruleBasedDetector = compositeDetector.ruleBasedDetector as? RuleBasedSleepEventDetector
    {
      snapshot.merge(ruleThresholdSnapshot(ruleBasedDetector.thresholds)) { current, _ in current }
      snapshot["coreML.confidenceThreshold"] =
        compositeDetector.coreMLDetector.configuration.confidenceThreshold
      snapshot["coreMLMulticlass.confidenceThreshold"] =
        compositeDetector.multiclassCoreMLDetector.configuration.confidenceThreshold
    }

    if let coreMLDetector = detector as? CoreMLSleepEventDetector {
      snapshot["coreML.confidenceThreshold"] = coreMLDetector.configuration.confidenceThreshold
    }

    return snapshot
  }

  private var smoothingThresholdsSnapshot: [String: Double] {
    [
      "smoothing.minimumEventDuration": smoothingPolicy.minimumEventDuration,
      "smoothing.maximumMergeGap": smoothingPolicy.maximumMergeGap,
      "smoothing.confidenceThreshold": smoothingPolicy.confidenceThreshold,
      "smoothing.bruxismLikeMinimumEventDuration": smoothingPolicy.bruxismLikeMinimumEventDuration,
      "smoothing.bruxismLikeMaximumMergeGap": smoothingPolicy.bruxismLikeMaximumMergeGap,
      "smoothing.bruxismLikeConfidenceThreshold": smoothingPolicy.bruxismLikeConfidenceThreshold,
      "sequence.suspectedPauseMinimumLowActivityDuration": suspectedBreathingPauseSequenceDetector.minimumLowActivityDuration,
      "sequence.recoveryWindowSeconds": suspectedBreathingPauseSequenceDetector.recoveryWindowSeconds,
      "sequence.priorContextWindowSeconds": suspectedBreathingPauseSequenceDetector.priorContextWindowSeconds,
      "sequence.minimumOutputConfidence": suspectedBreathingPauseSequenceDetector.minimumOutputConfidence,
    ]
  }

  private func ruleThresholdSnapshot(_ thresholds: RuleBasedDetectionThresholds) -> [String: Double]
  {
    [
      "rule.silenceRMS": thresholds.silenceRMS,
      "rule.snoreRMS": thresholds.snoreRMS,
      "rule.lowLevelSnoreRMS": thresholds.lowLevelSnoreRMS,
      "rule.lowLevelSnoreEnergy": thresholds.lowLevelSnoreEnergy,
      "rule.lowLevelSnoreLowBandRatio": thresholds.lowLevelSnoreLowBandRatio,
      "rule.snoreRelativeEnergyRatio": thresholds.snoreRelativeEnergyRatio,
      "rule.noiseRMS": thresholds.noiseRMS,
      "rule.suspectedPauseMinimumDuration": thresholds.suspectedPauseMinimumDuration,
    ]
  }
}
