import Foundation

public struct NightReport: Identifiable, Codable, Equatable {
    public var id: UUID { sessionId }

    public var sessionId: UUID
    public var generatedAt: Date
    public var measurementDuration: TimeInterval
    public var estimatedSleepDuration: TimeInterval
    public var detectedEventDuration: TimeInterval
    public var savedAudioDuration: TimeInterval
    public var receivedAudioDuration: TimeInterval
    public var analyzedAudioDuration: TimeInterval
    public var audioCoverageRatio: Double
    public var interruptionCount: Int
    public var longestAudioGapSeconds: TimeInterval
    public var measurementQuality: MeasurementQuality
    public var sleepSoundScore: Int
    public var snoreTotalSeconds: TimeInterval
    public var snoreRatio: Double
    public var bruxismLikeCount: Int
    public var suspectedPauseCount: Int
    public var gaspLikeCount: Int
    public var coughLikeCount: Int
    public var sleepTalkLikeCount: Int
    public var environmentalNoiseCount: Int
    public var awakeningSuspectedCount: Int
    public var longestSuspectedPause: TimeInterval
    public var mostDisturbedHourRange: String?
    public var mainDisturbanceReason: String

    public init(
        sessionId: UUID,
        generatedAt: Date = Date(),
        measurementDuration: TimeInterval,
        estimatedSleepDuration: TimeInterval,
        detectedEventDuration: TimeInterval = 0,
        savedAudioDuration: TimeInterval = 0,
        receivedAudioDuration: TimeInterval? = nil,
        analyzedAudioDuration: TimeInterval? = nil,
        audioCoverageRatio: Double? = nil,
        interruptionCount: Int = 0,
        longestAudioGapSeconds: TimeInterval = 0,
        measurementQuality: MeasurementQuality? = nil,
        sleepSoundScore: Int,
        snoreTotalSeconds: TimeInterval,
        snoreRatio: Double,
        bruxismLikeCount: Int,
        suspectedPauseCount: Int,
        gaspLikeCount: Int,
        coughLikeCount: Int,
        sleepTalkLikeCount: Int,
        environmentalNoiseCount: Int,
        awakeningSuspectedCount: Int,
        longestSuspectedPause: TimeInterval,
        mostDisturbedHourRange: String?,
        mainDisturbanceReason: String
    ) {
        self.sessionId = sessionId
        self.generatedAt = generatedAt
        self.measurementDuration = Self.sanitizedSeconds(measurementDuration)
        self.estimatedSleepDuration = Self.sanitizedSeconds(estimatedSleepDuration)
        self.detectedEventDuration = Self.sanitizedSeconds(detectedEventDuration)
        self.savedAudioDuration = Self.sanitizedSeconds(savedAudioDuration)
        self.receivedAudioDuration = Self.sanitizedSeconds(receivedAudioDuration ?? measurementDuration)
        self.analyzedAudioDuration = Self.sanitizedSeconds(analyzedAudioDuration ?? receivedAudioDuration ?? measurementDuration)
        let inferredCoverage = Self.coverageRatio(
            receivedAudioDuration: self.receivedAudioDuration,
            measurementDuration: self.measurementDuration
        )
        self.audioCoverageRatio = Self.clampedRatio(audioCoverageRatio ?? inferredCoverage)
        self.interruptionCount = max(0, interruptionCount)
        self.longestAudioGapSeconds = Self.sanitizedSeconds(longestAudioGapSeconds)
        self.measurementQuality = measurementQuality ?? MeasurementQuality.quality(for: self.audioCoverageRatio)
        self.sleepSoundScore = min(max(sleepSoundScore, 0), 100)
        self.snoreTotalSeconds = Self.sanitizedSeconds(snoreTotalSeconds)
        self.snoreRatio = Self.clampedRatio(snoreRatio)
        self.bruxismLikeCount = bruxismLikeCount
        self.suspectedPauseCount = suspectedPauseCount
        self.gaspLikeCount = gaspLikeCount
        self.coughLikeCount = coughLikeCount
        self.sleepTalkLikeCount = sleepTalkLikeCount
        self.environmentalNoiseCount = environmentalNoiseCount
        self.awakeningSuspectedCount = awakeningSuspectedCount
        self.longestSuspectedPause = longestSuspectedPause
        self.mostDisturbedHourRange = mostDisturbedHourRange
        self.mainDisturbanceReason = mainDisturbanceReason
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let sessionId = try container.decode(UUID.self, forKey: .sessionId)
        let generatedAt = try container.decodeIfPresent(Date.self, forKey: .generatedAt) ?? Date()
        let measurementDuration = try container.decode(TimeInterval.self, forKey: .measurementDuration)
        let estimatedSleepDuration = try container.decode(TimeInterval.self, forKey: .estimatedSleepDuration)
        let detectedEventDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .detectedEventDuration) ?? 0
        let savedAudioDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .savedAudioDuration) ?? 0
        let receivedAudioDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .receivedAudioDuration)
        let analyzedAudioDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .analyzedAudioDuration)
        let audioCoverageRatio = try container.decodeIfPresent(Double.self, forKey: .audioCoverageRatio)
        let interruptionCount = try container.decodeIfPresent(Int.self, forKey: .interruptionCount) ?? 0
        let longestAudioGapSeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .longestAudioGapSeconds) ?? 0
        let measurementQuality = try container.decodeIfPresent(MeasurementQuality.self, forKey: .measurementQuality)

        self.init(
            sessionId: sessionId,
            generatedAt: generatedAt,
            measurementDuration: measurementDuration,
            estimatedSleepDuration: estimatedSleepDuration,
            detectedEventDuration: detectedEventDuration,
            savedAudioDuration: savedAudioDuration,
            receivedAudioDuration: receivedAudioDuration,
            analyzedAudioDuration: analyzedAudioDuration,
            audioCoverageRatio: audioCoverageRatio,
            interruptionCount: interruptionCount,
            longestAudioGapSeconds: longestAudioGapSeconds,
            measurementQuality: measurementQuality,
            sleepSoundScore: try container.decode(Int.self, forKey: .sleepSoundScore),
            snoreTotalSeconds: try container.decode(TimeInterval.self, forKey: .snoreTotalSeconds),
            snoreRatio: try container.decode(Double.self, forKey: .snoreRatio),
            bruxismLikeCount: try container.decode(Int.self, forKey: .bruxismLikeCount),
            suspectedPauseCount: try container.decode(Int.self, forKey: .suspectedPauseCount),
            gaspLikeCount: try container.decode(Int.self, forKey: .gaspLikeCount),
            coughLikeCount: try container.decode(Int.self, forKey: .coughLikeCount),
            sleepTalkLikeCount: try container.decode(Int.self, forKey: .sleepTalkLikeCount),
            environmentalNoiseCount: try container.decode(Int.self, forKey: .environmentalNoiseCount),
            awakeningSuspectedCount: try container.decode(Int.self, forKey: .awakeningSuspectedCount),
            longestSuspectedPause: try container.decode(TimeInterval.self, forKey: .longestSuspectedPause),
            mostDisturbedHourRange: try container.decodeIfPresent(String.self, forKey: .mostDisturbedHourRange),
            mainDisturbanceReason: try container.decode(String.self, forKey: .mainDisturbanceReason)
        )
    }

    private enum CodingKeys: String, CodingKey {
        case sessionId
        case generatedAt
        case measurementDuration
        case estimatedSleepDuration
        case detectedEventDuration
        case savedAudioDuration
        case receivedAudioDuration
        case analyzedAudioDuration
        case audioCoverageRatio
        case interruptionCount
        case longestAudioGapSeconds
        case measurementQuality
        case sleepSoundScore
        case snoreTotalSeconds
        case snoreRatio
        case bruxismLikeCount
        case suspectedPauseCount
        case gaspLikeCount
        case coughLikeCount
        case sleepTalkLikeCount
        case environmentalNoiseCount
        case awakeningSuspectedCount
        case longestSuspectedPause
        case mostDisturbedHourRange
        case mainDisturbanceReason
    }

    private static func coverageRatio(
        receivedAudioDuration: TimeInterval,
        measurementDuration: TimeInterval
    ) -> Double {
        guard measurementDuration > 0 else { return 0 }
        return clampedRatio(receivedAudioDuration / measurementDuration)
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
