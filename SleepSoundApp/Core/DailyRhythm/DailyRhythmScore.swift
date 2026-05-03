import Foundation

public struct DailyRhythmScore: Codable, Equatable, Sendable {
    public var totalScore: Int
    public var sleepComponent: Int
    public var recoveryComponent: Int
    public var activityComponent: Int
    public var bloodPressureComponent: Int
    public var bodyMetricComponent: Int
    public var dataCompleteness: Double
    public var computedAt: Date

    public init(
        totalScore: Int,
        sleepComponent: Int,
        recoveryComponent: Int,
        activityComponent: Int,
        bloodPressureComponent: Int,
        bodyMetricComponent: Int,
        dataCompleteness: Double,
        computedAt: Date = Date()
    ) {
        self.totalScore = Self.clampedScore(totalScore)
        self.sleepComponent = Self.clampedScore(sleepComponent)
        self.recoveryComponent = Self.clampedScore(recoveryComponent)
        self.activityComponent = Self.clampedScore(activityComponent)
        self.bloodPressureComponent = Self.clampedScore(bloodPressureComponent)
        self.bodyMetricComponent = Self.clampedScore(bodyMetricComponent)
        self.dataCompleteness = DailyDataQuality.clampedCompleteness(dataCompleteness)
        self.computedAt = computedAt
    }

    public var dataQuality: DailyDataQuality {
        DailyDataQuality.quality(for: dataCompleteness)
    }

    public static func clampedScore(_ value: Int) -> Int {
        min(max(value, 0), 100)
    }
}
