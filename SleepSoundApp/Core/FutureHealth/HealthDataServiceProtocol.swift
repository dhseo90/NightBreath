import Foundation

public struct HealthDailySummary: Codable, Equatable, Sendable {
    public var date: Date
    public var samples: [HealthMetricSample]

    public var sampleCount: Int {
        samples.count
    }

    public var metricTypes: [HealthMetricType] {
        var seen = Set<HealthMetricType>()
        return samples
            .sortedByMeasuredAtAscending()
            .map(\.metricType)
            .filter { seen.insert($0).inserted }
    }

    public var sourceNames: [String] {
        Array(Set(samples.map(\.sourceName))).sorted()
    }

    public init(date: Date, samples: [HealthMetricSample]) {
        self.date = date
        self.samples = samples.sortedByMeasuredAtAscending()
    }

    public func latestSample(metricType: HealthMetricType) -> HealthMetricSample? {
        samples.latestSample(metricType: metricType)
    }
}

public protocol HealthDataServiceProtocol: Sendable {
    func fetchSamples(
        metricType: HealthMetricType,
        dateRange: HealthMetricDateRange
    ) async -> [HealthMetricSample]

    func fetchLatestSample(metricType: HealthMetricType) async -> HealthMetricSample?

    func fetchSamplesForDay(
        _ date: Date,
        calendar: Calendar
    ) async -> [HealthMetricSample]

    func fetchDailySummary(
        date: Date,
        calendar: Calendar
    ) async -> HealthDailySummary
}

public extension HealthDataServiceProtocol {
    func fetchSamplesForDay(
        _ date: Date,
        calendar: Calendar = .current
    ) async -> [HealthMetricSample] {
        await fetchSamplesForDay(date, calendar: calendar)
    }

    func fetchDailySummary(
        date: Date,
        calendar: Calendar = .current
    ) async -> HealthDailySummary {
        await fetchDailySummary(date: date, calendar: calendar)
    }
}
