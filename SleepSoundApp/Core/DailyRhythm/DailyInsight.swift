import Foundation

public enum DailyInsightType: String, Codable, CaseIterable, Identifiable, Equatable, Sendable {
    case sleep
    case recovery
    case activity
    case bloodPressure
    case bodyComposition
    case lifestyle
    case dataQuality

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .sleep:
            "수면"
        case .recovery:
            "회복 리듬"
        case .activity:
            "활동"
        case .bloodPressure:
            "혈압"
        case .bodyComposition:
            "체성분"
        case .lifestyle:
            "생활 태그"
        case .dataQuality:
            "데이터 품질"
        }
    }
}

public enum DailyInsightSeverity: String, Codable, CaseIterable, Identifiable, Equatable, Sendable {
    case neutral
    case positive
    case caution

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .neutral:
            "참고"
        case .positive:
            "좋음"
        case .caution:
            "확인"
        }
    }
}

public struct DailyInsight: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var type: DailyInsightType
    public var severity: DailyInsightSeverity
    public var title: String
    public var message: String
    public var relatedHealthMetricSampleIds: [UUID]
    public var relatedLifestyleTags: [LifestyleTag]
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        type: DailyInsightType,
        severity: DailyInsightSeverity = .neutral,
        title: String,
        message: String,
        relatedHealthMetricSampleIds: [UUID] = [],
        relatedLifestyleTags: [LifestyleTag] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.severity = severity
        self.title = title
        self.message = message
        self.relatedHealthMetricSampleIds = Self.uniqueIDs(relatedHealthMetricSampleIds)
        self.relatedLifestyleTags = Self.uniqueTags(relatedLifestyleTags)
        self.createdAt = createdAt
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
