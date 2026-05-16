import Foundation

public struct MetricTrendDataPoint: Identifiable, Equatable, Sendable {
    public var id: UUID { sampleId }
    public var date: Date
    public var value: Double
    public var sourceType: HealthMetricSourceType
    public var sourceName: String
    public var sampleId: UUID
    public var dataQuality: DailyDataQuality?
    public var contributingSampleCount: Int

    public init(
        date: Date,
        value: Double,
        sourceType: HealthMetricSourceType,
        sourceName: String,
        sampleId: UUID,
        dataQuality: DailyDataQuality? = nil,
        contributingSampleCount: Int = 1
    ) {
        self.date = date
        self.value = value.isFinite ? value : 0
        self.sourceType = sourceType
        self.sourceName = sourceName
        self.sampleId = sampleId
        self.dataQuality = dataQuality
        self.contributingSampleCount = max(0, contributingSampleCount)
    }

    public init(sample: UnifiedHealthMetricSample, dataQuality: DailyDataQuality? = nil) {
        self.init(
            date: sample.measuredAt,
            value: sample.value,
            sourceType: sample.sourceType,
            sourceName: sample.sourceName,
            sampleId: sample.id,
            dataQuality: dataQuality,
            contributingSampleCount: 1
        )
    }
}

public enum MetricAggregationInterval: String, CaseIterable, Codable, Identifiable, Sendable {
    case day
    case week
    case month

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .day:
            "일"
        case .week:
            "주"
        case .month:
            "월"
        }
    }

    public var averageTitle: String {
        "\(displayName) 평균"
    }

    public init(trendPeriod: HealthMetricTrendPeriod) {
        switch trendPeriod {
        case .sevenDays, .thirtyDays:
            self = .day
        case .ninetyDays:
            self = .week
        case .oneYear:
            self = .month
        }
    }

    public func dateRange(anchorDate: Date = Date(), calendar: Calendar = .current) -> HealthMetricDateRange {
        switch self {
        case .day:
            let start = calendar.dateInterval(of: .month, for: anchorDate)?.start
                ?? calendar.startOfDay(for: anchorDate)
            let end = calendar.date(byAdding: .month, value: 1, to: start)
                ?? start.addingTimeInterval(31 * 24 * 60 * 60)
            return HealthMetricDateRange(start: start, end: end.addingTimeInterval(-0.001))
        case .week:
            let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: anchorDate)?.start
                ?? calendar.startOfDay(for: anchorDate)
            let start = calendar.date(byAdding: .weekOfYear, value: -11, to: currentWeekStart)
                ?? currentWeekStart.addingTimeInterval(-77 * 24 * 60 * 60)
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart)
                ?? currentWeekStart.addingTimeInterval(7 * 24 * 60 * 60)
            return HealthMetricDateRange(start: start, end: end.addingTimeInterval(-0.001))
        case .month:
            let currentMonthStart = calendar.dateInterval(of: .month, for: anchorDate)?.start
                ?? calendar.startOfDay(for: anchorDate)
            let start = calendar.date(byAdding: .month, value: -11, to: currentMonthStart)
                ?? currentMonthStart.addingTimeInterval(-365 * 24 * 60 * 60)
            let end = calendar.date(byAdding: .month, value: 1, to: currentMonthStart)
                ?? currentMonthStart.addingTimeInterval(31 * 24 * 60 * 60)
            return HealthMetricDateRange(start: start, end: end.addingTimeInterval(-0.001))
        }
    }

    public func bucketStart(for date: Date, calendar: Calendar = .current) -> Date {
        switch self {
        case .day:
            calendar.startOfDay(for: date)
        case .week:
            calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
        case .month:
            calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
        }
    }

    public func movingAnchor(_ anchorDate: Date, byPageOffset offset: Int, calendar: Calendar = .current) -> Date {
        switch self {
        case .day:
            return calendar.date(byAdding: .month, value: offset, to: anchorDate) ?? anchorDate
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: offset * 12, to: anchorDate) ?? anchorDate
        case .month:
            return calendar.date(byAdding: .month, value: offset * 12, to: anchorDate) ?? anchorDate
        }
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

    public func aggregatedPoints(
        samples: [UnifiedHealthMetricSample],
        metricID: UnifiedHealthMetricID,
        dateRange: HealthMetricDateRange,
        interval: MetricAggregationInterval,
        calendar: Calendar = .current
    ) -> [MetricTrendDataPoint] {
        let scopedSamples = self.samples(samples, metricID: metricID, dateRange: dateRange)
        guard !scopedSamples.isEmpty else {
            return []
        }

        if metricID.usesDailyCumulativeSum {
            let dailyTotals = aggregateDailyCumulativeSamples(scopedSamples, calendar: calendar)
            guard interval != .day else {
                return dailyTotals
            }
            return aggregatePoints(dailyTotals, interval: interval, calendar: calendar)
        }

        return aggregateSamples(scopedSamples, interval: interval, calendar: calendar)
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

    public func aggregatedSummary(
        samples: [UnifiedHealthMetricSample],
        metricID: UnifiedHealthMetricID,
        dateRange: HealthMetricDateRange,
        interval: MetricAggregationInterval,
        calendar: Calendar = .current
    ) -> MetricStatisticsSummary {
        let currentPoints = aggregatedPoints(
            samples: samples,
            metricID: metricID,
            dateRange: dateRange,
            interval: interval,
            calendar: calendar
        )
        let previousRange = previousDateRange(for: dateRange)
        let previousPoints = aggregatedPoints(
            samples: samples,
            metricID: metricID,
            dateRange: previousRange,
            interval: interval,
            calendar: calendar
        )
        let currentValues = currentPoints.map(\.value)

        return MetricStatisticsSummary(
            metricID: metricID,
            latestValue: currentPoints.last?.value,
            average: average(currentValues),
            min: currentValues.min(),
            max: currentValues.max(),
            deltaFromPreviousPeriod: changeFromPreviousPeriod(
                currentValues: currentValues,
                previousValues: previousPoints.map(\.value)
            ),
            sampleCount: currentPoints.count,
            firstMeasuredAt: currentPoints.first?.date,
            latestMeasuredAt: currentPoints.last?.date
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
        let previousRange = previousDateRange(for: dateRange)

        return samples
            .filter { sample in
                sample.metricID == metricID
                    && sample.measuredAt >= previousRange.start
                    && sample.measuredAt < previousRange.end
            }
            .sortedByMeasuredAtAscending()
    }

    private func previousDateRange(for dateRange: HealthMetricDateRange) -> HealthMetricDateRange {
        let duration = max(dateRange.end.timeIntervalSince(dateRange.start), 1)
        return HealthMetricDateRange(
            start: dateRange.start.addingTimeInterval(-duration),
            end: dateRange.start
        )
    }

    private func aggregateDailyCumulativeSamples(
        _ samples: [UnifiedHealthMetricSample],
        calendar: Calendar
    ) -> [MetricTrendDataPoint] {
        Dictionary(grouping: samples) { sample in
            calendar.startOfDay(for: sample.measuredAt)
        }
        .compactMap { dayStart, samples in
            makePoint(
                date: dayStart,
                samples: samples,
                value: samples.map(\.value).reduce(0, +)
            )
        }
        .sorted { $0.date < $1.date }
    }

    private func aggregateSamples(
        _ samples: [UnifiedHealthMetricSample],
        interval: MetricAggregationInterval,
        calendar: Calendar
    ) -> [MetricTrendDataPoint] {
        Dictionary(grouping: samples) { sample in
            interval.bucketStart(for: sample.measuredAt, calendar: calendar)
        }
        .compactMap { bucketStart, samples in
            makePoint(date: bucketStart, samples: samples, value: average(samples.map(\.value)))
        }
        .sorted { $0.date < $1.date }
    }

    private func aggregatePoints(
        _ points: [MetricTrendDataPoint],
        interval: MetricAggregationInterval,
        calendar: Calendar
    ) -> [MetricTrendDataPoint] {
        Dictionary(grouping: points) { point in
            interval.bucketStart(for: point.date, calendar: calendar)
        }
        .compactMap { bucketStart, points in
            let values = points.map(\.value)
            guard let averageValue = average(values),
                  let firstPoint = points.sorted(by: { $0.date < $1.date }).first else {
                return nil
            }
            return MetricTrendDataPoint(
                date: bucketStart,
                value: averageValue,
                sourceType: sourceType(for: points),
                sourceName: sourceName(for: points),
                sampleId: firstPoint.sampleId,
                contributingSampleCount: points.reduce(0) { $0 + $1.contributingSampleCount }
            )
        }
        .sorted { $0.date < $1.date }
    }

    private func makePoint(
        date: Date,
        samples: [UnifiedHealthMetricSample],
        value: Double?
    ) -> MetricTrendDataPoint? {
        let orderedSamples = samples.sortedByMeasuredAtAscending()
        guard let firstSample = orderedSamples.first,
              let value else {
            return nil
        }
        return MetricTrendDataPoint(
            date: date,
            value: value,
            sourceType: sourceType(for: orderedSamples),
            sourceName: sourceName(for: orderedSamples),
            sampleId: firstSample.id,
            contributingSampleCount: orderedSamples.count
        )
    }

    private func sourceType(for samples: [UnifiedHealthMetricSample]) -> HealthMetricSourceType {
        let uniqueSourceTypes = Set(samples.map(\.sourceType))
        if uniqueSourceTypes.count == 1, let sourceType = uniqueSourceTypes.first {
            return sourceType
        }
        return samples.sortedByMeasuredAtDescending().first?.sourceType ?? .appComputed
    }

    private func sourceName(for samples: [UnifiedHealthMetricSample]) -> String {
        let uniqueSourceNames = Set(samples.map(\.sourceName))
        if uniqueSourceNames.count == 1, let sourceName = uniqueSourceNames.first {
            return sourceName
        }
        return "여러 출처"
    }

    private func sourceType(for points: [MetricTrendDataPoint]) -> HealthMetricSourceType {
        let uniqueSourceTypes = Set(points.map(\.sourceType))
        if uniqueSourceTypes.count == 1, let sourceType = uniqueSourceTypes.first {
            return sourceType
        }
        return points.sorted { $0.date > $1.date }.first?.sourceType ?? .appComputed
    }

    private func sourceName(for points: [MetricTrendDataPoint]) -> String {
        let uniqueSourceNames = Set(points.map(\.sourceName))
        if uniqueSourceNames.count == 1, let sourceName = uniqueSourceNames.first {
            return sourceName
        }
        return "여러 출처"
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
    case recovery
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
        case .recovery:
            "회복 지표"
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
                id: .recovery,
                title: UnifiedHealthMetricOverviewGroupID.recovery.displayName,
                metricIDs: catalog.metrics(in: .recovery)
                    .map(\.metricID)
                    .filter { !Self.fitdaysExtendedMetricIDs.contains($0) }
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
