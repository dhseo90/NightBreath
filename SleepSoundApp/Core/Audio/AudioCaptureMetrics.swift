import Foundation

public enum MeasurementQuality: String, Codable, CaseIterable, Sendable {
    case excellent
    case good
    case limited
    case poor

    public static func quality(for audioCoverageRatio: Double) -> MeasurementQuality {
        let coverage = min(max(audioCoverageRatio.isFinite ? audioCoverageRatio : 0, 0), 1)

        switch coverage {
        case 0.95...:
            return .excellent
        case 0.85..<0.95:
            return .good
        case 0.60..<0.85:
            return .limited
        default:
            return .poor
        }
    }

    public var displayName: String {
        switch self {
        case .excellent:
            return "매우 좋음"
        case .good:
            return "좋음"
        case .limited:
            return "제한적"
        case .poor:
            return "낮음"
        }
    }
}

public struct AudioCaptureMetrics: Codable, Equatable, Sendable {
    public var captureStartedAt: Date?
    public var captureStoppedAt: Date?
    public var sessionElapsedSeconds: TimeInterval
    public var captureActiveSeconds: TimeInterval
    public var receivedAudioSeconds: TimeInterval
    public var analyzedAudioSeconds: TimeInterval
    public var receivedChunkCount: Int
    public var analyzedChunkCount: Int
    public var totalReceivedFrameCount: Int64
    public var totalAnalyzedFrameCount: Int64
    public var sampleRate: Double
    public var firstChunkReceivedAt: Date?
    public var lastChunkReceivedAt: Date?
    public var lastChunkAnalyzedAt: Date?
    public var interruptionCount: Int
    public var captureErrorCount: Int
    public var longestChunkGapSeconds: TimeInterval
    public var currentChunkGapSeconds: TimeInterval
    public var firstAudioInputDelaySeconds: TimeInterval
    public var audioCoverageRatio: Double
    public var stopButtonTappedAt: Date?
    public var stopRequestedAt: Date?
    public var captureStopStartedAt: Date?
    public var inputTapRemovedAt: Date?
    public var audioEngineStoppedAt: Date?
    public var audioSessionDeactivatedAt: Date?
    public var captureTaskCancelledAt: Date?
    public var analyzerFinalizeStartedAt: Date?
    public var analyzerFinalizeFinishedAt: Date?
    public var reportGenerationStartedAt: Date?
    public var reportGenerationFinishedAt: Date?
    public var forceStopStartedAt: Date?
    public var forceStopReason: String?
    public var chunksReceivedAfterStopRequest: Int
    public var secondsReceivingAudioAfterStopRequest: TimeInterval

    public var measurementQuality: MeasurementQuality {
        MeasurementQuality.quality(for: audioCoverageRatio)
    }

    public init(
        captureStartedAt: Date? = nil,
        captureStoppedAt: Date? = nil,
        sessionElapsedSeconds: TimeInterval = 0,
        captureActiveSeconds: TimeInterval = 0,
        receivedAudioSeconds: TimeInterval = 0,
        analyzedAudioSeconds: TimeInterval = 0,
        receivedChunkCount: Int = 0,
        analyzedChunkCount: Int = 0,
        totalReceivedFrameCount: Int64 = 0,
        totalAnalyzedFrameCount: Int64 = 0,
        sampleRate: Double = 0,
        firstChunkReceivedAt: Date? = nil,
        lastChunkReceivedAt: Date? = nil,
        lastChunkAnalyzedAt: Date? = nil,
        interruptionCount: Int = 0,
        captureErrorCount: Int = 0,
        longestChunkGapSeconds: TimeInterval = 0,
        currentChunkGapSeconds: TimeInterval = 0,
        firstAudioInputDelaySeconds: TimeInterval = 0,
        audioCoverageRatio: Double = 0,
        stopButtonTappedAt: Date? = nil,
        stopRequestedAt: Date? = nil,
        captureStopStartedAt: Date? = nil,
        inputTapRemovedAt: Date? = nil,
        audioEngineStoppedAt: Date? = nil,
        audioSessionDeactivatedAt: Date? = nil,
        captureTaskCancelledAt: Date? = nil,
        analyzerFinalizeStartedAt: Date? = nil,
        analyzerFinalizeFinishedAt: Date? = nil,
        reportGenerationStartedAt: Date? = nil,
        reportGenerationFinishedAt: Date? = nil,
        forceStopStartedAt: Date? = nil,
        forceStopReason: String? = nil,
        chunksReceivedAfterStopRequest: Int = 0,
        secondsReceivingAudioAfterStopRequest: TimeInterval = 0
    ) {
        self.captureStartedAt = captureStartedAt
        self.captureStoppedAt = captureStoppedAt
        self.sessionElapsedSeconds = Self.sanitizedSeconds(sessionElapsedSeconds)
        self.captureActiveSeconds = Self.sanitizedSeconds(captureActiveSeconds)
        self.receivedAudioSeconds = Self.sanitizedSeconds(receivedAudioSeconds)
        self.analyzedAudioSeconds = Self.sanitizedSeconds(analyzedAudioSeconds)
        self.receivedChunkCount = max(0, receivedChunkCount)
        self.analyzedChunkCount = max(0, analyzedChunkCount)
        self.totalReceivedFrameCount = max(0, totalReceivedFrameCount)
        self.totalAnalyzedFrameCount = max(0, totalAnalyzedFrameCount)
        self.sampleRate = Self.sanitizedSampleRate(sampleRate)
        self.firstChunkReceivedAt = firstChunkReceivedAt
        self.lastChunkReceivedAt = lastChunkReceivedAt
        self.lastChunkAnalyzedAt = lastChunkAnalyzedAt
        self.interruptionCount = max(0, interruptionCount)
        self.captureErrorCount = max(0, captureErrorCount)
        self.longestChunkGapSeconds = Self.sanitizedSeconds(longestChunkGapSeconds)
        self.currentChunkGapSeconds = Self.sanitizedSeconds(currentChunkGapSeconds)
        self.firstAudioInputDelaySeconds = Self.sanitizedSeconds(firstAudioInputDelaySeconds)
        self.audioCoverageRatio = Self.clampedRatio(audioCoverageRatio)
        self.stopButtonTappedAt = stopButtonTappedAt
        self.stopRequestedAt = stopRequestedAt
        self.captureStopStartedAt = captureStopStartedAt
        self.inputTapRemovedAt = inputTapRemovedAt
        self.audioEngineStoppedAt = audioEngineStoppedAt
        self.audioSessionDeactivatedAt = audioSessionDeactivatedAt
        self.captureTaskCancelledAt = captureTaskCancelledAt
        self.analyzerFinalizeStartedAt = analyzerFinalizeStartedAt
        self.analyzerFinalizeFinishedAt = analyzerFinalizeFinishedAt
        self.reportGenerationStartedAt = reportGenerationStartedAt
        self.reportGenerationFinishedAt = reportGenerationFinishedAt
        self.forceStopStartedAt = forceStopStartedAt
        self.forceStopReason = forceStopReason?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.chunksReceivedAfterStopRequest = max(0, chunksReceivedAfterStopRequest)
        self.secondsReceivingAudioAfterStopRequest = Self.sanitizedSeconds(secondsReceivingAudioAfterStopRequest)
    }

    public mutating func start(at date: Date = Date()) {
        captureStartedAt = date
        captureStoppedAt = nil
        sessionElapsedSeconds = 0
        captureActiveSeconds = 0
        receivedAudioSeconds = 0
        analyzedAudioSeconds = 0
        receivedChunkCount = 0
        analyzedChunkCount = 0
        totalReceivedFrameCount = 0
        totalAnalyzedFrameCount = 0
        sampleRate = 0
        firstChunkReceivedAt = nil
        lastChunkReceivedAt = nil
        lastChunkAnalyzedAt = nil
        interruptionCount = 0
        captureErrorCount = 0
        longestChunkGapSeconds = 0
        currentChunkGapSeconds = 0
        firstAudioInputDelaySeconds = 0
        audioCoverageRatio = 0
        stopButtonTappedAt = nil
        stopRequestedAt = nil
        captureStopStartedAt = nil
        inputTapRemovedAt = nil
        audioEngineStoppedAt = nil
        audioSessionDeactivatedAt = nil
        captureTaskCancelledAt = nil
        analyzerFinalizeStartedAt = nil
        analyzerFinalizeFinishedAt = nil
        reportGenerationStartedAt = nil
        reportGenerationFinishedAt = nil
        forceStopStartedAt = nil
        forceStopReason = nil
        chunksReceivedAfterStopRequest = 0
        secondsReceivingAudioAfterStopRequest = 0
    }

    public mutating func stop(at date: Date = Date()) {
        captureStoppedAt = date
        refreshTiming(at: date)
    }

    public mutating func recordReceived(chunk: AudioChunk, at date: Date = Date()) {
        refreshTiming(at: date)
        let chunkAudioSeconds = audioSeconds(for: chunk)

        if let lastChunkReceivedAt {
            let gap = max(0, date.timeIntervalSince(lastChunkReceivedAt) - chunkAudioSeconds)
            currentChunkGapSeconds = gap
            longestChunkGapSeconds = max(longestChunkGapSeconds, gap)
        } else {
            firstChunkReceivedAt = date
            firstAudioInputDelaySeconds = Self.sanitizedSeconds(
                date.timeIntervalSince(captureStartedAt ?? date) - chunkAudioSeconds
            )
            currentChunkGapSeconds = firstAudioInputDelaySeconds
            longestChunkGapSeconds = max(longestChunkGapSeconds, firstAudioInputDelaySeconds)
        }

        receivedChunkCount += 1
        totalReceivedFrameCount += Int64(chunk.frameCount)
        sampleRate = sampleRate > 0 ? sampleRate : Self.sanitizedSampleRate(chunk.sampleRate)
        receivedAudioSeconds += chunkAudioSeconds
        lastChunkReceivedAt = date
        refreshTiming(at: date)
    }

    public mutating func recordAnalyzed(chunk: AudioChunk, at date: Date = Date()) {
        analyzedChunkCount += 1
        totalAnalyzedFrameCount += Int64(chunk.frameCount)
        sampleRate = sampleRate > 0 ? sampleRate : Self.sanitizedSampleRate(chunk.sampleRate)
        analyzedAudioSeconds += audioSeconds(for: chunk)
        lastChunkAnalyzedAt = date
        refreshTiming(at: date)
    }

    public mutating func recordInterruption(at date: Date = Date()) {
        interruptionCount += 1
        refreshTiming(at: date)
    }

    public mutating func recordCaptureError(at date: Date = Date()) {
        captureErrorCount += 1
        refreshTiming(at: date)
    }

    public mutating func recordStopButtonTapped(at date: Date = Date()) {
        stopButtonTappedAt = stopButtonTappedAt ?? date
        recordStopRequested(at: date)
    }

    public mutating func recordStopRequested(at date: Date = Date()) {
        stopRequestedAt = stopRequestedAt ?? date
        refreshTiming(at: date)
    }

    public mutating func recordCaptureStopStarted(at date: Date = Date()) {
        captureStopStartedAt = captureStopStartedAt ?? date
        refreshTiming(at: date)
    }

    public mutating func recordInputTapRemoved(at date: Date = Date()) {
        inputTapRemovedAt = inputTapRemovedAt ?? date
        refreshTiming(at: date)
    }

    public mutating func recordAudioEngineStopped(at date: Date = Date()) {
        audioEngineStoppedAt = audioEngineStoppedAt ?? date
        refreshTiming(at: date)
    }

    public mutating func recordAudioSessionDeactivated(at date: Date = Date()) {
        audioSessionDeactivatedAt = audioSessionDeactivatedAt ?? date
        refreshTiming(at: date)
    }

    public mutating func recordCaptureTaskCancelled(at date: Date = Date()) {
        captureTaskCancelledAt = captureTaskCancelledAt ?? date
        refreshTiming(at: date)
    }

    public mutating func recordAnalyzerFinalizeStarted(at date: Date = Date()) {
        analyzerFinalizeStartedAt = analyzerFinalizeStartedAt ?? date
        refreshTiming(at: date)
    }

    public mutating func recordAnalyzerFinalizeFinished(at date: Date = Date()) {
        analyzerFinalizeFinishedAt = analyzerFinalizeFinishedAt ?? date
        refreshTiming(at: date)
    }

    public mutating func recordReportGenerationStarted(at date: Date = Date()) {
        reportGenerationStartedAt = reportGenerationStartedAt ?? date
        refreshTiming(at: date)
    }

    public mutating func recordReportGenerationFinished(at date: Date = Date()) {
        reportGenerationFinishedAt = reportGenerationFinishedAt ?? date
        refreshTiming(at: date)
    }

    public mutating func recordForceStop(reason: String, at date: Date = Date()) {
        forceStopStartedAt = forceStopStartedAt ?? date
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedReason.isEmpty, forceStopReason == nil {
            forceStopReason = trimmedReason
        }
        refreshTiming(at: date)
    }

    public mutating func recordReceivedAfterStopRequest(chunk: AudioChunk, at date: Date = Date()) {
        recordStopRequested(at: stopRequestedAt ?? date)
        chunksReceivedAfterStopRequest += 1
        secondsReceivingAudioAfterStopRequest += audioSeconds(for: chunk)
        lastChunkReceivedAt = date
        refreshTiming(at: date)
    }

    public mutating func mergeStopDiagnostics(from other: AudioCaptureMetrics) {
        stopButtonTappedAt = stopButtonTappedAt ?? other.stopButtonTappedAt
        stopRequestedAt = stopRequestedAt ?? other.stopRequestedAt
        captureStopStartedAt = captureStopStartedAt ?? other.captureStopStartedAt
        inputTapRemovedAt = inputTapRemovedAt ?? other.inputTapRemovedAt
        audioEngineStoppedAt = audioEngineStoppedAt ?? other.audioEngineStoppedAt
        audioSessionDeactivatedAt = audioSessionDeactivatedAt ?? other.audioSessionDeactivatedAt
        captureTaskCancelledAt = captureTaskCancelledAt ?? other.captureTaskCancelledAt
        analyzerFinalizeStartedAt = analyzerFinalizeStartedAt ?? other.analyzerFinalizeStartedAt
        analyzerFinalizeFinishedAt = analyzerFinalizeFinishedAt ?? other.analyzerFinalizeFinishedAt
        reportGenerationStartedAt = reportGenerationStartedAt ?? other.reportGenerationStartedAt
        reportGenerationFinishedAt = reportGenerationFinishedAt ?? other.reportGenerationFinishedAt
        forceStopStartedAt = forceStopStartedAt ?? other.forceStopStartedAt
        forceStopReason = forceStopReason ?? other.forceStopReason
        chunksReceivedAfterStopRequest = max(chunksReceivedAfterStopRequest, other.chunksReceivedAfterStopRequest)
        secondsReceivingAudioAfterStopRequest = max(
            secondsReceivingAudioAfterStopRequest,
            other.secondsReceivingAudioAfterStopRequest
        )
        if let otherLastChunkReceivedAt = other.lastChunkReceivedAt,
           lastChunkReceivedAt == nil || otherLastChunkReceivedAt > lastChunkReceivedAt! {
            lastChunkReceivedAt = otherLastChunkReceivedAt
        }
        if let otherFirstChunkReceivedAt = other.firstChunkReceivedAt,
           firstChunkReceivedAt == nil || otherFirstChunkReceivedAt < firstChunkReceivedAt! {
            firstChunkReceivedAt = otherFirstChunkReceivedAt
        }
        firstAudioInputDelaySeconds = max(firstAudioInputDelaySeconds, other.firstAudioInputDelaySeconds)
        refreshTiming(at: Date())
    }

    public var stopDiagnosticsSummary: String? {
        guard stopRequestedAt != nil else { return nil }

        var parts = [
            "stop requested",
            "tapRemoved=\(inputTapRemovedAt != nil)",
            "engineStopped=\(audioEngineStoppedAt != nil)",
            "sessionDeactivated=\(audioSessionDeactivatedAt != nil)",
            "postStopChunks=\(chunksReceivedAfterStopRequest)"
        ]

        if secondsReceivingAudioAfterStopRequest > 0 {
            parts.append("postStopAudio=\(Self.shortSeconds(secondsReceivingAudioAfterStopRequest))s")
        }
        if let forceStopReason {
            parts.append("forceStop=\(forceStopReason)")
        }

        return parts.joined(separator: ", ")
    }

    public var missingAudioSeconds: TimeInterval {
        Self.sanitizedSeconds(sessionElapsedSeconds - receivedAudioSeconds)
    }

    public var coverageDiagnosticsSummary: String {
        var parts = [
            "session=\(Self.shortSeconds(sessionElapsedSeconds))s",
            "received=\(Self.shortSeconds(receivedAudioSeconds))s",
            "missing=\(Self.shortSeconds(missingAudioSeconds))s",
            "coverage=\(Self.percent(audioCoverageRatio))"
        ]

        if firstAudioInputDelaySeconds > 1 {
            parts.append("firstInputDelay=\(Self.shortSeconds(firstAudioInputDelaySeconds))s")
        }
        if longestChunkGapSeconds > 1 {
            parts.append("longestGap=\(Self.shortSeconds(longestChunkGapSeconds))s")
        }
        if interruptionCount > 0 {
            parts.append("interruptions=\(interruptionCount)")
        }
        if captureErrorCount > 0 {
            parts.append("captureErrors=\(captureErrorCount)")
        }

        return parts.joined(separator: ", ")
    }

    public func snapshot(at date: Date = Date()) -> AudioCaptureMetrics {
        var copy = self
        copy.refreshTiming(at: date)
        return copy
    }

    public static func fallback(sessionElapsedSeconds: TimeInterval) -> AudioCaptureMetrics {
        let elapsed = sanitizedSeconds(sessionElapsedSeconds)
        return AudioCaptureMetrics(
            sessionElapsedSeconds: elapsed,
            captureActiveSeconds: elapsed,
            receivedAudioSeconds: elapsed,
            analyzedAudioSeconds: elapsed,
            audioCoverageRatio: elapsed > 0 ? 1 : 0
        )
    }

    private mutating func refreshTiming(at date: Date) {
        guard let captureStartedAt else {
            sessionElapsedSeconds = 0
            captureActiveSeconds = 0
            audioCoverageRatio = 0
            return
        }

        let endDate = captureStoppedAt ?? date
        sessionElapsedSeconds = Self.sanitizedSeconds(endDate.timeIntervalSince(captureStartedAt))
        captureActiveSeconds = sessionElapsedSeconds

        if let lastChunkReceivedAt {
            currentChunkGapSeconds = Self.sanitizedSeconds(date.timeIntervalSince(lastChunkReceivedAt))
        } else {
            currentChunkGapSeconds = sessionElapsedSeconds
        }

        if sessionElapsedSeconds > 0 {
            audioCoverageRatio = Self.clampedRatio(receivedAudioSeconds / sessionElapsedSeconds)
        } else {
            audioCoverageRatio = 0
        }
    }

    private func audioSeconds(for chunk: AudioChunk) -> TimeInterval {
        let sampleRate = Self.sanitizedSampleRate(chunk.sampleRate)
        if chunk.frameCount > 0, sampleRate > 0 {
            return Double(chunk.frameCount) / sampleRate
        }
        return Self.sanitizedSeconds(chunk.duration)
    }

    private static func sanitizedSampleRate(_ value: Double) -> Double {
        guard value.isFinite, value > 0 else { return 0 }
        return value
    }

    private static func sanitizedSeconds(_ value: TimeInterval) -> TimeInterval {
        guard value.isFinite, value > 0 else { return 0 }
        return value
    }

    private static func shortSeconds(_ value: TimeInterval) -> String {
        String(format: "%.2f", sanitizedSeconds(value))
    }

    private static func percent(_ value: Double) -> String {
        String(format: "%.1f%%", clampedRatio(value) * 100)
    }

    private static func clampedRatio(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }
}
