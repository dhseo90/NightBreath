import Foundation

public struct NightReport: Identifiable, Codable, Equatable {
    public var id: UUID { sessionId }

    public var sessionId: UUID
    public var generatedAt: Date
    public var measurementDuration: TimeInterval
    public var estimatedSleepDuration: TimeInterval
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
        self.measurementDuration = measurementDuration
        self.estimatedSleepDuration = estimatedSleepDuration
        self.sleepSoundScore = min(max(sleepSoundScore, 0), 100)
        self.snoreTotalSeconds = snoreTotalSeconds
        self.snoreRatio = snoreRatio
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
}
