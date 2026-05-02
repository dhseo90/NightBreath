import Foundation

public struct HealthMetricSample: Identifiable, Codable, Equatable {
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
        self.value = value
        self.unit = unit
        self.measuredAt = measuredAt
        self.sourceName = sourceName
        self.sourceBundleIdentifier = sourceBundleIdentifier
    }
}
