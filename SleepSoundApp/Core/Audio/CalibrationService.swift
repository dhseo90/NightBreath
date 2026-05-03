import Foundation

public enum CalibrationQuality: String, Codable, CaseIterable, Sendable {
    case good
    case highNoise
    case weakInput
    case microphonePossiblyBlocked
    case retryRecommended

    public var displayName: String {
        switch self {
        case .good:
            "좋음"
        case .highNoise:
            "소음 높음"
        case .weakInput:
            "입력 약함"
        case .microphonePossiblyBlocked:
            "마이크 막힘 의심"
        case .retryRecommended:
            "다시 시도 권장"
        }
    }
}

public struct CalibrationResult: Equatable, Sendable {
    public var ambientNoiseBaseline: Double
    public var inputReceived: Bool
    public var receivedAudioSeconds: TimeInterval
    public var audioCoverageRatio: Double
    public var recommendedPlacementMessage: String
    public var calibrationQuality: CalibrationQuality
    public var averageInputLevel: Double
    public var peakInputLevel: Double

    public init(
        ambientNoiseBaseline: Double,
        inputReceived: Bool,
        receivedAudioSeconds: TimeInterval,
        audioCoverageRatio: Double,
        recommendedPlacementMessage: String,
        calibrationQuality: CalibrationQuality,
        averageInputLevel: Double,
        peakInputLevel: Double
    ) {
        self.ambientNoiseBaseline = Self.clampedLevel(ambientNoiseBaseline)
        self.inputReceived = inputReceived
        self.receivedAudioSeconds = Self.sanitizedSeconds(receivedAudioSeconds)
        self.audioCoverageRatio = Self.clampedRatio(audioCoverageRatio)
        self.recommendedPlacementMessage = recommendedPlacementMessage
        self.calibrationQuality = calibrationQuality
        self.averageInputLevel = Self.clampedLevel(averageInputLevel)
        self.peakInputLevel = Self.clampedLevel(peakInputLevel)
    }

    private static func clampedLevel(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }

    private static func clampedRatio(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }

    private static func sanitizedSeconds(_ value: TimeInterval) -> TimeInterval {
        guard value.isFinite, value > 0 else { return 0 }
        return value
    }
}

public struct CalibrationService: Equatable, Sendable {
    public var targetDuration: TimeInterval

    public init(targetDuration: TimeInterval = 30) {
        self.targetDuration = max(1, targetDuration)
    }

    public func evaluate(chunks: [AudioChunk]) -> CalibrationResult {
        let levels = chunks.map(\.rms).filter(\.isFinite)
        let receivedAudioSeconds = chunks.reduce(0) { partialResult, chunk in
            partialResult + audioSeconds(for: chunk)
        }
        let audioCoverageRatio = min(max(receivedAudioSeconds / targetDuration, 0), 1)
        let inputReceived = receivedAudioSeconds > 0 && !chunks.isEmpty
        let averageInputLevel = average(levels) ?? 0
        let peakInputLevel = levels.max() ?? 0
        let ambientNoiseBaseline = percentile(levels, percentile: 0.50) ?? averageInputLevel
        let p90InputLevel = percentile(levels, percentile: 0.90) ?? peakInputLevel
        let quality = quality(
            inputReceived: inputReceived,
            receivedAudioSeconds: receivedAudioSeconds,
            audioCoverageRatio: audioCoverageRatio,
            averageInputLevel: averageInputLevel,
            peakInputLevel: peakInputLevel,
            p90InputLevel: p90InputLevel
        )

        return CalibrationResult(
            ambientNoiseBaseline: ambientNoiseBaseline,
            inputReceived: inputReceived,
            receivedAudioSeconds: receivedAudioSeconds,
            audioCoverageRatio: audioCoverageRatio,
            recommendedPlacementMessage: recommendedPlacementMessage(for: quality),
            calibrationQuality: quality,
            averageInputLevel: averageInputLevel,
            peakInputLevel: peakInputLevel
        )
    }

    public static func simulatorMockChunks(duration: TimeInterval = 30) -> [AudioChunk] {
        SyntheticAudioSource.makeChunks(
            pattern: .lowEnergyNoise,
            duration: duration,
            sampleRate: 16_000,
            chunkDuration: 1
        )
    }

    public static func simulatorMockResult(duration: TimeInterval = 30) -> CalibrationResult {
        CalibrationService(targetDuration: duration).evaluate(chunks: simulatorMockChunks(duration: duration))
    }

    private func quality(
        inputReceived: Bool,
        receivedAudioSeconds: TimeInterval,
        audioCoverageRatio: Double,
        averageInputLevel: Double,
        peakInputLevel: Double,
        p90InputLevel: Double
    ) -> CalibrationQuality {
        guard inputReceived, receivedAudioSeconds >= targetDuration * 0.20 else {
            return .retryRecommended
        }

        if audioCoverageRatio < 0.60 {
            return .retryRecommended
        }

        if peakInputLevel < 0.0015 {
            return .microphonePossiblyBlocked
        }

        if averageInputLevel < 0.003 {
            return .weakInput
        }

        if averageInputLevel > 0.12 || p90InputLevel > 0.15 {
            return .highNoise
        }

        if audioCoverageRatio < 0.85 {
            return .retryRecommended
        }

        return .good
    }

    private func recommendedPlacementMessage(for quality: CalibrationQuality) -> String {
        switch quality {
        case .good:
            "현재 위치에서 수면 소리 입력을 안정적으로 받을 수 있습니다."
        case .highNoise:
            "선풍기, 가습기, 충전기처럼 계속 나는 소음원에서 조금 떨어뜨려 보세요."
        case .weakInput:
            "iPhone을 머리맡이나 침대 옆 탁자 쪽으로 조금 더 가까이 두는 것을 권장합니다."
        case .microphonePossiblyBlocked:
            "마이크가 이불, 베개, 케이스, 책 등에 막혀 있지 않은지 확인해 주세요."
        case .retryRecommended:
            "입력 시간이 충분하지 않았습니다. 조용한 상태에서 다시 시도해 주세요."
        }
    }

    private func audioSeconds(for chunk: AudioChunk) -> TimeInterval {
        guard chunk.sampleRate.isFinite, chunk.sampleRate > 0, chunk.frameCount > 0 else {
            return chunk.duration.isFinite ? max(0, chunk.duration) : 0
        }
        return Double(chunk.frameCount) / chunk.sampleRate
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func percentile(_ values: [Double], percentile: Double) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let clampedPercentile = min(max(percentile, 0), 1)
        let index = Int((Double(sorted.count - 1) * clampedPercentile).rounded())
        return sorted[index]
    }
}
