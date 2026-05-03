import Foundation

public enum HealthMetricTrendPeriod: Int, CaseIterable, Codable, Identifiable, Sendable {
    case sevenDays = 7
    case thirtyDays = 30
    case ninetyDays = 90

    public var id: Int { rawValue }
    public var dayCount: Int { rawValue }

    public var displayName: String {
        switch self {
        case .sevenDays:
            "7일"
        case .thirtyDays:
            "30일"
        case .ninetyDays:
            "90일"
        }
    }

    public func dateRange(endingAt endDate: Date = Date()) -> HealthMetricDateRange {
        .days(dayCount, endingAt: endDate)
    }
}

public struct HealthMetricTrendSummary: Equatable, Sendable {
    public var metricType: HealthMetricType
    public var period: HealthMetricTrendPeriod
    public var average: Double?
    public var latest: HealthMetricSample?
    public var minimum: Double?
    public var maximum: Double?
    public var changeFromPreviousPeriod: Double?
    public var sampleCount: Int

    public init(
        metricType: HealthMetricType,
        period: HealthMetricTrendPeriod,
        average: Double?,
        latest: HealthMetricSample?,
        minimum: Double?,
        maximum: Double?,
        changeFromPreviousPeriod: Double?,
        sampleCount: Int
    ) {
        self.metricType = metricType
        self.period = period
        self.average = average
        self.latest = latest
        self.minimum = minimum
        self.maximum = maximum
        self.changeFromPreviousPeriod = changeFromPreviousPeriod
        self.sampleCount = sampleCount
    }
}

public struct HealthMetricSourceSummary: Equatable, Sendable {
    public var sourceName: String
    public var sourceBundleIdentifier: String
    public var sampleCount: Int
    public var latestMeasuredAt: Date

    public init(
        sourceName: String,
        sourceBundleIdentifier: String,
        sampleCount: Int,
        latestMeasuredAt: Date
    ) {
        self.sourceName = sourceName
        self.sourceBundleIdentifier = sourceBundleIdentifier
        self.sampleCount = sampleCount
        self.latestMeasuredAt = latestMeasuredAt
    }
}

public struct HealthMetricTrendCalculator: Equatable, Sendable {
    public init() {}

    public func samples(
        _ samples: [HealthMetricSample],
        metricType: HealthMetricType,
        period: HealthMetricTrendPeriod,
        endingAt endDate: Date = Date()
    ) -> [HealthMetricSample] {
        samples.filtered(
            metricType: metricType,
            dateRange: period.dateRange(endingAt: endDate)
        )
    }

    public func samples(
        _ samples: [HealthMetricSample],
        metricTypes: [HealthMetricType],
        period: HealthMetricTrendPeriod,
        endingAt endDate: Date = Date()
    ) -> [HealthMetricSample] {
        let metricSet = Set(metricTypes)
        let range = period.dateRange(endingAt: endDate)
        return samples
            .filter { metricSet.contains($0.metricType) && range.contains($0.measuredAt) }
            .sortedByMeasuredAtAscending()
    }

    public func summary(
        samples: [HealthMetricSample],
        metricType: HealthMetricType,
        period: HealthMetricTrendPeriod,
        endingAt endDate: Date = Date()
    ) -> HealthMetricTrendSummary {
        let currentSamples = self.samples(
            samples,
            metricType: metricType,
            period: period,
            endingAt: endDate
        )
        let values = currentSamples.map(\.value)
        let previousSamples = previousPeriodSamples(
            samples,
            metricType: metricType,
            period: period,
            endingAt: endDate
        )

        return HealthMetricTrendSummary(
            metricType: metricType,
            period: period,
            average: average(values),
            latest: currentSamples.latestSample(metricType: metricType),
            minimum: values.min(),
            maximum: values.max(),
            changeFromPreviousPeriod: changeFromPreviousPeriod(
                currentValues: values,
                previousValues: previousSamples.map(\.value)
            ),
            sampleCount: currentSamples.count
        )
    }

    public func sourceSummaries(samples: [HealthMetricSample]) -> [HealthMetricSourceSummary] {
        Dictionary(grouping: samples, by: \.sourceBundleIdentifier)
            .compactMap { bundleIdentifier, samples in
                guard let latest = samples.sortedByMeasuredAtDescending().first else {
                    return nil
                }

                return HealthMetricSourceSummary(
                    sourceName: latest.sourceName,
                    sourceBundleIdentifier: bundleIdentifier,
                    sampleCount: samples.count,
                    latestMeasuredAt: latest.measuredAt
                )
            }
            .sorted { lhs, rhs in
                if lhs.latestMeasuredAt == rhs.latestMeasuredAt {
                    return lhs.sourceName < rhs.sourceName
                }
                return lhs.latestMeasuredAt > rhs.latestMeasuredAt
            }
    }

    private func previousPeriodSamples(
        _ samples: [HealthMetricSample],
        metricType: HealthMetricType,
        period: HealthMetricTrendPeriod,
        endingAt endDate: Date
    ) -> [HealthMetricSample] {
        let currentRange = period.dateRange(endingAt: endDate)
        let previousStart = currentRange.start.addingTimeInterval(-Double(period.dayCount) * 24 * 60 * 60)

        return samples
            .filter { sample in
                sample.metricType == metricType
                    && sample.measuredAt >= previousStart
                    && sample.measuredAt < currentRange.start
            }
            .sortedByMeasuredAtAscending()
    }

    private func changeFromPreviousPeriod(
        currentValues: [Double],
        previousValues: [Double]
    ) -> Double? {
        guard let currentAverage = average(currentValues),
              let previousAverage = average(previousValues) else {
            return nil
        }
        return currentAverage - previousAverage
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}
