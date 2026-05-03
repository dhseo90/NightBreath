import Foundation

public struct MetricTrendDataPoint: Identifiable, Equatable, Sendable {
    public var id: UUID { sampleId }
    public var date: Date
    public var value: Double
    public var sourceType: HealthMetricSourceType
    public var sourceName: String
    public var sampleId: UUID
    public var dataQuality: DailyDataQuality?

    public init(
        date: Date,
        value: Double,
        sourceType: HealthMetricSourceType,
        sourceName: String,
        sampleId: UUID,
        dataQuality: DailyDataQuality? = nil
    ) {
        self.date = date
        self.value = value.isFinite ? value : 0
        self.sourceType = sourceType
        self.sourceName = sourceName
        self.sampleId = sampleId
        self.dataQuality = dataQuality
    }

    public init(sample: UnifiedHealthMetricSample, dataQuality: DailyDataQuality? = nil) {
        self.init(
            date: sample.measuredAt,
            value: sample.value,
            sourceType: sample.sourceType,
            sourceName: sample.sourceName,
            sampleId: sample.id,
            dataQuality: dataQuality
        )
    }
}

public struct MetricStatisticsSummary: Equatable, Sendable {
    public var metricID: UnifiedHealthMetricID
    public var latestValue: Double?
    public var average: Double?
    public var min: Double?
    public var max: Double?
    public var deltaFromPreviousPeriod: Double?
    public var sampleCount: Int
    public var firstMeasuredAt: Date?
    public var latestMeasuredAt: Date?

    public init(
        metricID: UnifiedHealthMetricID,
        latestValue: Double?,
        average: Double?,
        min: Double?,
        max: Double?,
        deltaFromPreviousPeriod: Double?,
        sampleCount: Int,
        firstMeasuredAt: Date?,
        latestMeasuredAt: Date?
    ) {
        self.metricID = metricID
        self.latestValue = latestValue
        self.average = average
        self.min = min
        self.max = max
        self.deltaFromPreviousPeriod = deltaFromPreviousPeriod
        self.sampleCount = sampleCount
        self.firstMeasuredAt = firstMeasuredAt
        self.latestMeasuredAt = latestMeasuredAt
    }
}

public struct MetricSourceBreakdown: Identifiable, Equatable, Sendable {
    public var id: String { "\(sourceType.rawValue)|\(sourceName)" }
    public var sourceType: HealthMetricSourceType
    public var sourceName: String
    public var sampleCount: Int
    public var latestMeasuredAt: Date

    public init(
        sourceType: HealthMetricSourceType,
        sourceName: String,
        sampleCount: Int,
        latestMeasuredAt: Date
    ) {
        self.sourceType = sourceType
        self.sourceName = sourceName
        self.sampleCount = sampleCount
        self.latestMeasuredAt = latestMeasuredAt
    }
}

public struct MetricStatisticsCalculator: Equatable, Sendable {
    public init() {}

    public func samples(
        _ samples: [UnifiedHealthMetricSample],
        metricID: UnifiedHealthMetricID,
        dateRange: HealthMetricDateRange
    ) -> [UnifiedHealthMetricSample] {
        samples
            .filter { $0.metricID == metricID && dateRange.contains($0.measuredAt) }
            .sortedByMeasuredAtAscending()
    }

    public func samples(
        _ samples: [UnifiedHealthMetricSample],
        metricIDs: [UnifiedHealthMetricID],
        dateRange: HealthMetricDateRange
    ) -> [UnifiedHealthMetricSample] {
        let metricSet = Set(metricIDs)
        return samples
            .filter { metricSet.contains($0.metricID) && dateRange.contains($0.measuredAt) }
            .sortedByMeasuredAtAscending()
    }

    public func points(
        samples: [UnifiedHealthMetricSample],
        metricID: UnifiedHealthMetricID,
        dateRange: HealthMetricDateRange
    ) -> [MetricTrendDataPoint] {
        self.samples(samples, metricID: metricID, dateRange: dateRange)
            .map { MetricTrendDataPoint(sample: $0) }
    }

    public func summary(
        samples: [UnifiedHealthMetricSample],
        metricID: UnifiedHealthMetricID,
        dateRange: HealthMetricDateRange
    ) -> MetricStatisticsSummary {
        let currentSamples = self.samples(samples, metricID: metricID, dateRange: dateRange)
        let values = currentSamples.map(\.value)
        let previousSamples = previousPeriodSamples(
            samples,
            metricID: metricID,
            dateRange: dateRange
        )

        return MetricStatisticsSummary(
            metricID: metricID,
            latestValue: currentSamples.last?.value,
            average: average(values),
            min: values.min(),
            max: values.max(),
            deltaFromPreviousPeriod: changeFromPreviousPeriod(
                currentValues: values,
                previousValues: previousSamples.map(\.value)
            ),
            sampleCount: currentSamples.count,
            firstMeasuredAt: currentSamples.first?.measuredAt,
            latestMeasuredAt: currentSamples.last?.measuredAt
        )
    }

    public func sourceBreakdown(
        samples: [UnifiedHealthMetricSample],
        metricID: UnifiedHealthMetricID,
        dateRange: HealthMetricDateRange
    ) -> [MetricSourceBreakdown] {
        let scopedSamples = self.samples(samples, metricID: metricID, dateRange: dateRange)

        return Dictionary(grouping: scopedSamples) { sample in
            "\(sample.sourceType.rawValue)|\(sample.sourceName)"
        }
        .compactMap { _, samples in
            guard let latest = samples.sortedByMeasuredAtDescending().first else {
                return nil
            }

            return MetricSourceBreakdown(
                sourceType: latest.sourceType,
                sourceName: latest.sourceName,
                sampleCount: samples.count,
                latestMeasuredAt: latest.measuredAt
            )
        }
        .sorted { lhs, rhs in
            if lhs.latestMeasuredAt == rhs.latestMeasuredAt {
                if lhs.sourceType.rawValue == rhs.sourceType.rawValue {
                    return lhs.sourceName < rhs.sourceName
                }
                return lhs.sourceType.rawValue < rhs.sourceType.rawValue
            }
            return lhs.latestMeasuredAt > rhs.latestMeasuredAt
        }
    }

    private func previousPeriodSamples(
        _ samples: [UnifiedHealthMetricSample],
        metricID: UnifiedHealthMetricID,
        dateRange: HealthMetricDateRange
    ) -> [UnifiedHealthMetricSample] {
        let duration = max(dateRange.end.timeIntervalSince(dateRange.start), 1)
        let previousRange = HealthMetricDateRange(
            start: dateRange.start.addingTimeInterval(-duration),
            end: dateRange.start
        )

        return samples
            .filter { sample in
                sample.metricID == metricID
                    && sample.measuredAt >= previousRange.start
                    && sample.measuredAt < previousRange.end
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

public enum UnifiedHealthMetricOverviewGroupID: String, Codable, CaseIterable, Identifiable, Sendable {
    case bloodPressure
    case bodyComposition
    case activity
    case sleepAndApp
    case fitdaysExtended

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .bloodPressure:
            "혈압"
        case .bodyComposition:
            "체성분"
        case .activity:
            "활동"
        case .sleepAndApp:
            "수면/앱 지표"
        case .fitdaysExtended:
            "Fitdays 확장 지표"
        }
    }
}

public struct UnifiedHealthMetricOverviewGroup: Identifiable, Equatable, Sendable {
    public var id: UnifiedHealthMetricOverviewGroupID
    public var title: String
    public var metricIDs: [UnifiedHealthMetricID]

    public init(
        id: UnifiedHealthMetricOverviewGroupID,
        title: String,
        metricIDs: [UnifiedHealthMetricID]
    ) {
        self.id = id
        self.title = title
        self.metricIDs = metricIDs
    }
}

public struct UnifiedHealthMetricOverviewGrouping: Equatable, Sendable {
    public static let fitdaysExtendedMetricIDs: [UnifiedHealthMetricID] = [
        .visceralFatLevel,
        .visceralFatPercentage,
        .bodyWaterPercentage,
        .boneMass,
        .mineralMass,
        .skeletalMuscleMass,
        .muscleMass,
        .basalMetabolicRate,
        .proteinPercentage,
        .subcutaneousFatPercentage,
        .metabolicAge,
        .bodyScore,
        .obesityLevel,
    ]

    private let catalog: MetricCatalog

    public init(catalog: MetricCatalog = .default) {
        self.catalog = catalog
    }

    public func groups() -> [UnifiedHealthMetricOverviewGroup] {
        [
            UnifiedHealthMetricOverviewGroup(
                id: .bloodPressure,
                title: UnifiedHealthMetricOverviewGroupID.bloodPressure.displayName,
                metricIDs: catalog.metrics(in: .bloodPressure).map(\.metricID)
            ),
            UnifiedHealthMetricOverviewGroup(
                id: .bodyComposition,
                title: UnifiedHealthMetricOverviewGroupID.bodyComposition.displayName,
                metricIDs: catalog.metrics(in: .bodyComposition)
                    .map(\.metricID)
                    .filter { !Self.fitdaysExtendedMetricIDs.contains($0) }
            ),
            UnifiedHealthMetricOverviewGroup(
                id: .activity,
                title: UnifiedHealthMetricOverviewGroupID.activity.displayName,
                metricIDs: catalog.metrics(in: .activity).map(\.metricID)
            ),
            UnifiedHealthMetricOverviewGroup(
                id: .sleepAndApp,
                title: UnifiedHealthMetricOverviewGroupID.sleepAndApp.displayName,
                metricIDs: (catalog.metrics(in: .sleep) + catalog.metrics(in: .app))
                    .map(\.metricID)
                    .filter { !Self.fitdaysExtendedMetricIDs.contains($0) }
            ),
            UnifiedHealthMetricOverviewGroup(
                id: .fitdaysExtended,
                title: UnifiedHealthMetricOverviewGroupID.fitdaysExtended.displayName,
                metricIDs: Self.fitdaysExtendedMetricIDs.filter { catalog.metadata(for: $0) != nil }
            ),
        ]
    }
}
