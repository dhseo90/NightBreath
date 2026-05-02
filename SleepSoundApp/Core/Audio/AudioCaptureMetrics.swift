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
    public var lastChunkReceivedAt: Date?
    public var lastChunkAnalyzedAt: Date?
    public var interruptionCount: Int
    public var captureErrorCount: Int
    public var longestChunkGapSeconds: TimeInterval
    public var currentChunkGapSeconds: TimeInterval
    public var audioCoverageRatio: Double

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
        lastChunkReceivedAt: Date? = nil,
        lastChunkAnalyzedAt: Date? = nil,
        interruptionCount: Int = 0,
        captureErrorCount: Int = 0,
        longestChunkGapSeconds: TimeInterval = 0,
        currentChunkGapSeconds: TimeInterval = 0,
        audioCoverageRatio: Double = 0
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
        self.lastChunkReceivedAt = lastChunkReceivedAt
        self.lastChunkAnalyzedAt = lastChunkAnalyzedAt
        self.interruptionCount = max(0, interruptionCount)
        self.captureErrorCount = max(0, captureErrorCount)
        self.longestChunkGapSeconds = Self.sanitizedSeconds(longestChunkGapSeconds)
        self.currentChunkGapSeconds = Self.sanitizedSeconds(currentChunkGapSeconds)
        self.audioCoverageRatio = Self.clampedRatio(audioCoverageRatio)
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
        lastChunkReceivedAt = nil
        lastChunkAnalyzedAt = nil
        interruptionCount = 0
        captureErrorCount = 0
        longestChunkGapSeconds = 0
        currentChunkGapSeconds = 0
        audioCoverageRatio = 0
    }

    public mutating func stop(at date: Date = Date()) {
        captureStoppedAt = date
        refreshTiming(at: date)
    }

    public mutating func recordReceived(chunk: AudioChunk, at date: Date = Date()) {
        refreshTiming(at: date)

        if let lastChunkReceivedAt {
            let gap = max(0, date.timeIntervalSince(lastChunkReceivedAt) - audioSeconds(for: chunk))
            currentChunkGapSeconds = gap
            longestChunkGapSeconds = max(longestChunkGapSeconds, gap)
        } else {
            currentChunkGapSeconds = 0
        }

        receivedChunkCount += 1
        totalReceivedFrameCount += Int64(chunk.frameCount)
        sampleRate = sampleRate > 0 ? sampleRate : Self.sanitizedSampleRate(chunk.sampleRate)
        receivedAudioSeconds += audioSeconds(for: chunk)
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

    private static func clampedRatio(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }
}
