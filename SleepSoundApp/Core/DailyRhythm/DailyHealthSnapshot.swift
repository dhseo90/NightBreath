import Foundation

public struct DailyHealthSnapshot: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var date: Date
    public var sleepReportId: UUID?
    public var morningCheckInId: UUID?
    public var eveningCheckInId: UUID?
    public var healthMetricSampleIds: [UUID]
    public var lifestyleTags: [LifestyleTag]
    public var dataCompletenessScore: Double
    public var createdAt: Date
    public var updatedAt: Date

    public var dataQuality: DailyDataQuality {
        DailyDataQuality.quality(for: dataCompletenessScore)
    }

    public init(
        id: UUID = UUID(),
        date: Date,
        sleepReportId: UUID? = nil,
        morningCheckInId: UUID? = nil,
        eveningCheckInId: UUID? = nil,
        healthMetricSampleIds: [UUID] = [],
        lifestyleTags: [LifestyleTag] = [],
        dataCompletenessScore: Double = 0,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.sleepReportId = sleepReportId
        self.morningCheckInId = morningCheckInId
        self.eveningCheckInId = eveningCheckInId
        self.healthMetricSampleIds = Self.uniqueIDs(healthMetricSampleIds)
        self.lifestyleTags = Self.uniqueTags(lifestyleTags)
        self.dataCompletenessScore = DailyDataQuality.clampedCompleteness(dataCompletenessScore)
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }

    private static func uniqueIDs(_ ids: [UUID]) -> [UUID] {
        var seen = Set<UUID>()
        return ids.filter { seen.insert($0).inserted }
    }

    private static func uniqueTags(_ tags: [LifestyleTag]) -> [LifestyleTag] {
        var seen = Set<LifestyleTag>()
        return tags.filter { seen.insert($0).inserted }
    }
}
