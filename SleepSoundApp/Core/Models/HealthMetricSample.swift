import Foundation

public struct HealthMetricSample: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var metricType: HealthMetricType
    public var value: Double
    public var unit: String
    public var measuredAt: Date
    public var sourceName: String
    public var sourceBundleIdentifier: String

    public init(
        id: UUID = UUID(),
        metricType: HealthMetricType,
        value: Double,
        unit: String,
        measuredAt: Date,
        sourceName: String,
        sourceBundleIdentifier: String
    ) {
        self.id = id
        self.metricType = metricType
        self.value = value.isFinite ? value : 0
        self.unit = unit
        self.measuredAt = measuredAt
        self.sourceName = sourceName
        self.sourceBundleIdentifier = sourceBundleIdentifier
    }
}

public extension Array where Element == HealthMetricSample {
    func sortedByMeasuredAtAscending() -> [HealthMetricSample] {
        sorted { lhs, rhs in
            if lhs.measuredAt == rhs.measuredAt {
                return lhs.id.uuidString < rhs.id.uuidString
            }
            return lhs.measuredAt < rhs.measuredAt
        }
    }

    func sortedByMeasuredAtDescending() -> [HealthMetricSample] {
        sorted { lhs, rhs in
            if lhs.measuredAt == rhs.measuredAt {
                return lhs.id.uuidString < rhs.id.uuidString
            }
            return lhs.measuredAt > rhs.measuredAt
        }
    }

    func filtered(metricType: HealthMetricType, dateRange: HealthMetricDateRange) -> [HealthMetricSample] {
        filter { sample in
            sample.metricType == metricType && dateRange.contains(sample.measuredAt)
        }
        .sortedByMeasuredAtAscending()
    }

    func latestSample(metricType: HealthMetricType) -> HealthMetricSample? {
        filter { $0.metricType == metricType }
            .sortedByMeasuredAtDescending()
            .first
    }
}
