import Foundation

public struct SleepAudioProcessingSnapshot: Sendable {
    public var metrics: AudioCaptureMetrics
    public var capturedAudioChunkCount: Int
    public var detectedEventCandidateCount: Int
    public var latestAudioLevel: Double
    public var latestDetectedEventText: String?
    public var latestDetectedEventAt: Date?
    public var outputsForSnippetCapture: [DetectorOutput]

    public init(
        metrics: AudioCaptureMetrics,
        capturedAudioChunkCount: Int,
        detectedEventCandidateCount: Int,
        latestAudioLevel: Double,
        latestDetectedEventText: String? = nil,
        latestDetectedEventAt: Date? = nil,
        outputsForSnippetCapture: [DetectorOutput] = []
    ) {
        self.metrics = metrics
        self.capturedAudioChunkCount = max(0, capturedAudioChunkCount)
        self.detectedEventCandidateCount = max(0, detectedEventCandidateCount)
        self.latestAudioLevel = min(max(latestAudioLevel, 0), 1)
        self.latestDetectedEventText = latestDetectedEventText
        self.latestDetectedEventAt = latestDetectedEventAt
        self.outputsForSnippetCapture = outputsForSnippetCapture
    }
}

public struct SleepAudioProcessingFinalizationResult: Sendable {
    public var metrics: AudioCaptureMetrics
    public var allOutputs: [DetectorOutput]
    public var smoothedOutputs: [DetectorOutput]
    public var smoothingDiagnostics: DetectionSmoothingDiagnostics
    public var sequenceResult: SuspectedBreathingPauseSequenceResult

    public init(
        metrics: AudioCaptureMetrics,
        allOutputs: [DetectorOutput],
        smoothedOutputs: [DetectorOutput],
        smoothingDiagnostics: DetectionSmoothingDiagnostics,
        sequenceResult: SuspectedBreathingPauseSequenceResult
    ) {
        self.metrics = metrics
        self.allOutputs = allOutputs
        self.smoothedOutputs = smoothedOutputs
        self.smoothingDiagnostics = smoothingDiagnostics
        self.sequenceResult = sequenceResult
    }
}

public actor SleepAudioProcessingPipeline {
    private let sessionId: UUID
    private var analyzer: SleepAnalyzer
    private var metrics: AudioCaptureMetrics
    private let diagnosticsCollector: DetectorDiagnosticsCollector
    private var compactedOutputs: [DetectorOutput] = []
    private var sequenceFeatureWindow: [AudioFeatures] = []
    private var sequenceContextOutputWindow: [DetectorOutput] = []
    private var emittedSequenceOutputKeys = Set<String>()
    private var latestSequenceResult = SuspectedBreathingPauseSequenceResult()
    private var latestSmoothedCandidateCount = 0
    private var lastSmoothingRefreshAt: Date?
    private var lastSequenceRefreshAt: Date?
    private let sequenceWindowSeconds: TimeInterval
    private let smoothingRefreshInterval: TimeInterval
    private let sequenceRefreshInterval: TimeInterval
    private let outputCompactionMergeGap: TimeInterval

    public init(
        sessionId: UUID,
        startedAt: Date,
        analyzer: SleepAnalyzer,
        detectorBackend: String,
        modelInstalled: Bool,
        thresholdsSnapshot: [String: Double],
        tuningProfile: String?,
        eventAudioSampleStorageEnabled: Bool,
        sequenceWindowSeconds: TimeInterval = 180,
        smoothingRefreshInterval: TimeInterval = 1,
        sequenceRefreshInterval: TimeInterval = 2,
        outputCompactionMergeGap: TimeInterval = 1
    ) {
        self.sessionId = sessionId
        self.analyzer = analyzer
        self.metrics = AudioCaptureMetrics()
        self.metrics.start(at: startedAt)
        self.diagnosticsCollector = DetectorDiagnosticsCollector()
        self.sequenceWindowSeconds = max(30, sequenceWindowSeconds)
        self.smoothingRefreshInterval = max(0.25, smoothingRefreshInterval)
        self.sequenceRefreshInterval = max(0.5, sequenceRefreshInterval)
        self.outputCompactionMergeGap = max(0, outputCompactionMergeGap)
        diagnosticsCollector.reset(
            sessionId: sessionId,
            startedAt: startedAt,
            detectorBackend: detectorBackend,
            modelInstalled: modelInstalled,
            thresholdsSnapshot: thresholdsSnapshot,
            tuningProfile: tuningProfile,
            eventAudioSampleStorageEnabled: eventAudioSampleStorageEnabled
        )
        diagnosticsCollector.addNote("Detector tuning profile: \(tuningProfile ?? "unknown")")
        diagnosticsCollector.addNote("Audio processing runs off the main UI actor with throttled UI snapshots.")
    }

    public func process(chunk: AudioChunk) -> SleepAudioProcessingSnapshot {
        metrics.recordReceived(chunk: chunk, at: chunk.startedAt)
        let detection = analyzer.detectOutputsWithFeatures(from: chunk, updating: &metrics)
        diagnosticsCollector.recordModelFallbackIfNeeded(
            backend: analyzer.detectorBackend,
            modelInstalled: analyzer.isModelInstalled
        )
        diagnosticsCollector.record(features: detection.features, outputs: detection.outputs)

        appendCompacted(outputs: detection.outputs, to: &compactedOutputs)
        appendCompacted(outputs: detection.outputs, to: &sequenceContextOutputWindow)
        appendFeatureToSequenceWindow(detection.features)

        let sequenceOutputs = refreshSequenceIfNeeded(at: chunk.startedAt)
        appendCompacted(outputs: sequenceOutputs, to: &compactedOutputs)
        appendCompacted(outputs: sequenceOutputs, to: &sequenceContextOutputWindow)
        trimSequenceContext(endingAt: chunk.startedAt)
        refreshSmoothingCountIfNeeded(at: chunk.startedAt)

        let outputsForSnippetCapture = detection.outputs + sequenceOutputs
        let strongestOutput = outputsForSnippetCapture.max { lhs, rhs in
            lhs.confidence < rhs.confidence
        }
        return SleepAudioProcessingSnapshot(
            metrics: metrics.snapshot(at: Date()),
            capturedAudioChunkCount: metrics.analyzedChunkCount,
            detectedEventCandidateCount: latestSmoothedCandidateCount,
            latestAudioLevel: chunk.basicLevel,
            latestDetectedEventText: strongestOutput.map {
                "\($0.eventType.displayName) \(Int($0.confidence * 100))%"
            },
            latestDetectedEventAt: strongestOutput == nil ? nil : Date(),
            outputsForSnippetCapture: outputsForSnippetCapture
        )
    }

    public func finalize(
        endedAt: Date,
        stopMetrics: AudioCaptureMetrics
    ) -> SleepAudioProcessingFinalizationResult {
        metrics.mergeStopDiagnostics(from: stopMetrics)
        if metrics.captureStoppedAt == nil {
            metrics.stop(at: endedAt)
        }
        metrics.recordAnalyzerFinalizeStarted(at: stopMetrics.analyzerFinalizeStartedAt ?? Date())
        let sequenceOutputs = refreshSequence(force: true)
        appendCompacted(outputs: sequenceOutputs, to: &compactedOutputs)
        let smoothingResult = analyzer.smoothWithDiagnostics(outputs: compactedOutputs)
        metrics.recordAnalyzerFinalizeFinished(at: Date())
        diagnosticsCollector.record(sequenceResult: latestSequenceResult)
        diagnosticsCollector.record(smoothingDiagnostics: smoothingResult.diagnostics)
        return SleepAudioProcessingFinalizationResult(
            metrics: metrics,
            allOutputs: compactedOutputs,
            smoothedOutputs: smoothingResult.outputs,
            smoothingDiagnostics: smoothingResult.diagnostics,
            sequenceResult: latestSequenceResult
        )
    }

    public func finalizeDiagnostics(
        endedAt: Date,
        finalEvents: [SleepEvent],
        finalMetrics: AudioCaptureMetrics
    ) -> DetectorDiagnostics? {
        metrics.mergeStopDiagnostics(from: finalMetrics)
        diagnosticsCollector.record(finalEvents: finalEvents)
        if finalEvents.isEmpty {
            diagnosticsCollector.addNote("오디오 입력은 수신되었지만 최종 이벤트 기준을 통과한 이벤트가 없었습니다.")
        }
        if let stopDiagnosticsSummary = metrics.stopDiagnosticsSummary {
            diagnosticsCollector.addNote("Capture stop diagnostics: \(stopDiagnosticsSummary)")
        }
        if metrics.audioCoverageRatio < 0.85 {
            diagnosticsCollector.addNote("Audio coverage diagnostics: \(metrics.coverageDiagnosticsSummary)")
        }
        return diagnosticsCollector.finalize(endedAt: endedAt, metrics: metrics)
    }

    public func metricsSnapshot() -> AudioCaptureMetrics {
        metrics.snapshot(at: Date())
    }

    private func appendFeatureToSequenceWindow(_ features: AudioFeatures) {
        sequenceFeatureWindow.append(features)
        let cutoff = features.endedAt.addingTimeInterval(-sequenceWindowSeconds)
        while let first = sequenceFeatureWindow.first, first.endedAt < cutoff {
            sequenceFeatureWindow.removeFirst()
        }
    }

    private func trimSequenceContext(endingAt date: Date) {
        let cutoff = date.addingTimeInterval(-sequenceWindowSeconds)
        while let first = sequenceContextOutputWindow.first, first.endedAt < cutoff {
            sequenceContextOutputWindow.removeFirst()
        }
    }

    private func refreshSequenceIfNeeded(at date: Date) -> [DetectorOutput] {
        guard lastSequenceRefreshAt == nil ||
            date.timeIntervalSince(lastSequenceRefreshAt ?? date) >= sequenceRefreshInterval else {
            return []
        }
        lastSequenceRefreshAt = date
        return refreshSequence(force: false)
    }

    private func refreshSequence(force: Bool) -> [DetectorOutput] {
        guard force || !sequenceFeatureWindow.isEmpty else { return [] }

        let result = analyzer.detectSuspectedBreathingPauseSequence(
            features: sequenceFeatureWindow,
            contextOutputs: sequenceContextOutputWindow
        )
        latestSequenceResult = result

        var newOutputs: [DetectorOutput] = []
        for output in result.outputs {
            let key = sequenceOutputKey(output)
            guard !emittedSequenceOutputKeys.contains(key) else { continue }
            emittedSequenceOutputKeys.insert(key)
            newOutputs.append(output)
        }
        return newOutputs
    }

    private func refreshSmoothingCountIfNeeded(at date: Date) {
        guard lastSmoothingRefreshAt == nil ||
            date.timeIntervalSince(lastSmoothingRefreshAt ?? date) >= smoothingRefreshInterval else {
            return
        }

        lastSmoothingRefreshAt = date
        latestSmoothedCandidateCount = analyzer.smooth(outputs: compactedOutputs).count
    }

    private func appendCompacted(outputs: [DetectorOutput], to store: inout [DetectorOutput]) {
        for output in outputs.sorted(by: outputSort) {
            appendCompacted(output: output, to: &store)
        }
    }

    private func appendCompacted(output: DetectorOutput, to store: inout [DetectorOutput]) {
        guard output.duration > 0 else { return }

        if let last = store.last,
           last.eventType == output.eventType,
           output.startedAt.timeIntervalSince(last.endedAt) <= outputCompactionMergeGap {
            store[store.count - 1] = merge(last, output)
            return
        }

        store.append(output)
    }

    private func merge(_ lhs: DetectorOutput, _ rhs: DetectorOutput) -> DetectorOutput {
        DetectorOutput(
            eventType: lhs.eventType,
            startedAt: min(lhs.startedAt, rhs.startedAt),
            endedAt: max(lhs.endedAt, rhs.endedAt),
            confidence: max(lhs.confidence, rhs.confidence),
            intensity: max(lhs.intensity, rhs.intensity),
            debugReason: [lhs.debugReason, rhs.debugReason]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .suffix(2)
                .joined(separator: " / ")
        )
    }

    private func outputSort(_ lhs: DetectorOutput, _ rhs: DetectorOutput) -> Bool {
        if lhs.startedAt == rhs.startedAt {
            return lhs.eventType.rawValue < rhs.eventType.rawValue
        }
        return lhs.startedAt < rhs.startedAt
    }

    private func sequenceOutputKey(_ output: DetectorOutput) -> String {
        let startBucket = Int(output.startedAt.timeIntervalSinceReferenceDate.rounded())
        let endBucket = Int(output.endedAt.timeIntervalSinceReferenceDate.rounded())
        return "\(output.eventType.rawValue)-\(startBucket)-\(endBucket)"
    }
}
