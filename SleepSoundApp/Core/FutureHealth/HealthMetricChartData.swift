import Foundation

public struct HealthMetricChartDataPoint: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var date: Date
    public var value: Double
    public var unit: String
    public var sourceName: String

    public init(sample: HealthMetricSample) {
        self.id = sample.id
        self.date = sample.measuredAt
        self.value = sample.value.isFinite ? sample.value : 0
        self.unit = sample.unit
        self.sourceName = sample.sourceName
    }
}

public struct HealthMetricChartDataBuilder: Equatable, Sendable {
    public init() {}

    public func points(samples: [HealthMetricSample], metricType: HealthMetricType) -> [HealthMetricChartDataPoint] {
        samples
            .filter { $0.metricType == metricType }
            .sortedByMeasuredAtAscending()
            .map(HealthMetricChartDataPoint.init(sample:))
    }

    public func latestChange(samples: [HealthMetricSample], metricType: HealthMetricType) -> Double? {
        let points = self.points(samples: samples, metricType: metricType)
        guard points.count >= 2,
              let latest = points.last,
              let previous = points.dropLast().last else {
            return nil
        }
        return latest.value - previous.value
    }
}
