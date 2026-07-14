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

public enum KoreanBMIReferenceCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case belowReference
    case reference
    case preObesity
    case obesityStage1
    case obesityStage2
    case obesityStage3

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .belowReference:
            "저체중 참고 범위"
        case .reference:
            "참고 범위"
        case .preObesity:
            "비만 전 단계 참고 범위"
        case .obesityStage1:
            "1단계 비만 참고 범위"
        case .obesityStage2:
            "2단계 비만 참고 범위"
        case .obesityStage3:
            "3단계 비만 참고 범위"
        }
    }

    public var lowerBound: Double? {
        switch self {
        case .belowReference:
            nil
        case .reference:
            18.5
        case .preObesity:
            23
        case .obesityStage1:
            25
        case .obesityStage2:
            30
        case .obesityStage3:
            35
        }
    }

    public var upperBound: Double? {
        switch self {
        case .belowReference:
            18.5
        case .reference:
            23
        case .preObesity:
            25
        case .obesityStage1:
            30
        case .obesityStage2:
            35
        case .obesityStage3:
            nil
        }
    }

    public static func category(for bmi: Double) -> KoreanBMIReferenceCategory? {
        guard bmi.isFinite, bmi > 0 else {
            return nil
        }

        switch bmi {
        case ..<18.5:
            return .belowReference
        case 18.5..<23:
            return .reference
        case 23..<25:
            return .preObesity
        case 25..<30:
            return .obesityStage1
        case 30..<35:
            return .obesityStage2
        default:
            return .obesityStage3
        }
    }
}

public enum BodyCompositionReferenceBoundaryKind: String, Codable, Sendable {
    case lowerReference
    case upperReference
}

public struct BodyCompositionReferenceBoundary: Equatable, Sendable {
    public var kind: BodyCompositionReferenceBoundaryKind
    public var bmiBoundary: Double
    public var boundaryWeightKg: Double
    public var deltaKg: Double

    public init(
        kind: BodyCompositionReferenceBoundaryKind,
        bmiBoundary: Double,
        boundaryWeightKg: Double,
        deltaKg: Double
    ) {
        self.kind = kind
        self.bmiBoundary = bmiBoundary
        self.boundaryWeightKg = boundaryWeightKg
        self.deltaKg = deltaKg
    }
}

public enum BodyCompositionTrendNoticeKind: String, Codable, Sendable {
    case muscleDecrease
    case bodyFatIncrease
    case weightAndMuscleDecrease
    case consecutiveDecrease
    case insufficientSamples
}

public struct BodyCompositionTrendNotice: Identifiable, Equatable, Sendable {
    public var id: String
    public var kind: BodyCompositionTrendNoticeKind
    public var metricID: UnifiedHealthMetricID?
    public var title: String
    public var message: String
    public var changeValue: Double?
    public var unit: String

    public init(
        id: String,
        kind: BodyCompositionTrendNoticeKind,
        metricID: UnifiedHealthMetricID?,
        title: String,
        message: String,
        changeValue: Double? = nil,
        unit: String = ""
    ) {
        self.id = id
        self.kind = kind
        self.metricID = metricID
        self.title = title
        self.message = message
        self.changeValue = changeValue
        self.unit = unit
    }
}

public struct BodyCompositionReferenceSummary: Equatable, Sendable {
    public var latestWeightKg: Double?
    public var latestBMI: Double?
    public var latestBodyFatPercentage: Double?
    public var latestSkeletalMuscleMassKg: Double?
    public var latestMuscleMassKg: Double?
    public var bmiCategory: KoreanBMIReferenceCategory?
    public var trendNotices: [BodyCompositionTrendNotice]
    public var sampleCount: Int
    public var latestMeasuredAt: Date?

    public init(
        latestWeightKg: Double?,
        latestBMI: Double?,
        latestBodyFatPercentage: Double?,
        latestSkeletalMuscleMassKg: Double?,
        latestMuscleMassKg: Double?,
        bmiCategory: KoreanBMIReferenceCategory?,
        trendNotices: [BodyCompositionTrendNotice],
        sampleCount: Int,
        latestMeasuredAt: Date?
    ) {
        self.latestWeightKg = latestWeightKg
        self.latestBMI = latestBMI
        self.latestBodyFatPercentage = latestBodyFatPercentage
        self.latestSkeletalMuscleMassKg = latestSkeletalMuscleMassKg
        self.latestMuscleMassKg = latestMuscleMassKg
        self.bmiCategory = bmiCategory
        self.trendNotices = trendNotices
        self.sampleCount = sampleCount
        self.latestMeasuredAt = latestMeasuredAt
    }
}

public struct BodyCompositionReferenceAnalyzer: Equatable, Sendable {
    public static let metricIDs: [UnifiedHealthMetricID] = [
        .bodyMass,
        .bodyMassIndex,
        .bodyFatPercentage,
        .leanBodyMass,
        .skeletalMuscleMass,
        .muscleMass,
        .bodyWaterPercentage,
        .visceralFatLevel,
        .visceralFatPercentage,
        .subcutaneousFatPercentage,
        .proteinPercentage,
        .boneMass,
        .mineralMass,
        .basalMetabolicRate,
        .metabolicAge,
        .bodyScore,
        .obesityLevel,
    ]

    private static let bodyCompositionMetricSet = Set(metricIDs)
    private let trendWindowDays: Int

    public init(trendWindowDays: Int = 30) {
        self.trendWindowDays = max(7, trendWindowDays)
    }

    public func summary(
        samples: [UnifiedHealthMetricSample],
        endingAt endDate: Date = Date()
    ) -> BodyCompositionReferenceSummary {
        let bodyCompositionSamples = samples
            .filter { Self.bodyCompositionMetricSet.contains($0.metricID) }
            .sortedByMeasuredAtAscending()
        let latestBMI = latestValue(.bodyMassIndex, in: bodyCompositionSamples)
        let latestWeight = latestValue(.bodyMass, in: bodyCompositionSamples)
        let bmiCategory = latestBMI.flatMap(KoreanBMIReferenceCategory.category(for:))

        return BodyCompositionReferenceSummary(
            latestWeightKg: latestWeight,
            latestBMI: latestBMI,
            latestBodyFatPercentage: latestValue(.bodyFatPercentage, in: bodyCompositionSamples),
            latestSkeletalMuscleMassKg: latestValue(.skeletalMuscleMass, in: bodyCompositionSamples),
            latestMuscleMassKg: latestValue(.muscleMass, in: bodyCompositionSamples),
            bmiCategory: bmiCategory,
            trendNotices: trendNotices(samples: bodyCompositionSamples, endingAt: endDate),
            sampleCount: bodyCompositionSamples.count,
            latestMeasuredAt: bodyCompositionSamples.last?.measuredAt
        )
    }

    public func referenceBoundary(
        weightKg: Double?,
        heightMeters: Double?,
        bmiCategory: KoreanBMIReferenceCategory?
    ) -> BodyCompositionReferenceBoundary? {
        guard let weightKg,
              let heightMeters,
              let bmiCategory,
              weightKg.isFinite,
              heightMeters.isFinite,
              weightKg > 0,
              heightMeters > 0 else {
            return nil
        }

        let boundaryBMI: Double
        let kind: BodyCompositionReferenceBoundaryKind

        switch bmiCategory {
        case .belowReference:
            boundaryBMI = 18.5
            kind = .lowerReference
        case .reference, .preObesity, .obesityStage1, .obesityStage2, .obesityStage3:
            boundaryBMI = 23
            kind = .upperReference
        }

        let boundaryWeight = boundaryBMI * heightMeters * heightMeters
        return BodyCompositionReferenceBoundary(
            kind: kind,
            bmiBoundary: boundaryBMI,
            boundaryWeightKg: boundaryWeight,
            deltaKg: weightKg - boundaryWeight
        )
    }

    public func trendNotices(
        samples: [UnifiedHealthMetricSample],
        endingAt endDate: Date = Date()
    ) -> [BodyCompositionTrendNotice] {
        let notices = [
            combinedWeightAndMuscleNotice(samples: samples, endingAt: endDate),
            muscleNotice(metricID: .skeletalMuscleMass, samples: samples, endingAt: endDate),
            muscleNotice(metricID: .muscleMass, samples: samples, endingAt: endDate),
            bodyFatNotice(samples: samples, endingAt: endDate),
            consecutiveDecreaseNotice(metricID: .skeletalMuscleMass, samples: samples),
            consecutiveDecreaseNotice(metricID: .muscleMass, samples: samples),
        ]
        .compactMap { $0 }

        if notices.isEmpty {
            return [
                BodyCompositionTrendNotice(
                    id: "insufficient-body-composition-samples",
                    kind: .insufficientSamples,
                    metricID: nil,
                    title: "변화 알림 대기 중",
                    message: "최근 30일과 이전 30일을 비교할 샘플이 더 쌓이면 근육량과 체지방률 변화를 표시합니다."
                ),
            ]
        }

        return Array(notices.prefix(3))
    }

    private func latestSample(
        _ metricID: UnifiedHealthMetricID,
        in samples: [UnifiedHealthMetricSample]
    ) -> UnifiedHealthMetricSample? {
        samples
            .filter { $0.metricID == metricID }
            .sortedByMeasuredAtDescending()
            .first
    }

    private func latestValue(
        _ metricID: UnifiedHealthMetricID,
        in samples: [UnifiedHealthMetricSample]
    ) -> Double? {
        latestSample(metricID, in: samples)?.value
    }

    private func combinedWeightAndMuscleNotice(
        samples: [UnifiedHealthMetricSample],
        endingAt endDate: Date
    ) -> BodyCompositionTrendNotice? {
        guard let weightChange = recentChange(metricID: .bodyMass, samples: samples, endingAt: endDate),
              weightChange <= -1 else {
            return nil
        }

        let muscleChange = recentChange(metricID: .skeletalMuscleMass, samples: samples, endingAt: endDate)
            ?? recentChange(metricID: .muscleMass, samples: samples, endingAt: endDate)
            ?? recentChange(metricID: .leanBodyMass, samples: samples, endingAt: endDate)

        guard let muscleChange,
              muscleChange <= -0.5 else {
            return nil
        }

        return BodyCompositionTrendNotice(
            id: "weight-and-muscle-decrease",
            kind: .weightAndMuscleDecrease,
            metricID: nil,
            title: "체중과 근육량이 함께 내려가는 흐름",
            message: "최근 30일 평균 기준으로 체중과 근육량 계열이 함께 낮아졌습니다.",
            changeValue: muscleChange,
            unit: "kg"
        )
    }

    private func muscleNotice(
        metricID: UnifiedHealthMetricID,
        samples: [UnifiedHealthMetricSample],
        endingAt endDate: Date
    ) -> BodyCompositionTrendNotice? {
        guard let change = recentChange(metricID: metricID, samples: samples, endingAt: endDate),
              change <= -0.5 else {
            return nil
        }

        let title = metricID == .skeletalMuscleMass ? "골격근량 감소 추세" : "근육량 감소 추세"
        let metricName = metricID == .skeletalMuscleMass ? "골격근량" : "근육량"
        return BodyCompositionTrendNotice(
            id: "\(metricID.rawValue)-recent-decrease",
            kind: .muscleDecrease,
            metricID: metricID,
            title: title,
            message: "최근 30일 평균 \(metricName)이 이전 30일보다 낮습니다.",
            changeValue: change,
            unit: "kg"
        )
    }

    private func bodyFatNotice(
        samples: [UnifiedHealthMetricSample],
        endingAt endDate: Date
    ) -> BodyCompositionTrendNotice? {
        guard let change = recentChange(metricID: .bodyFatPercentage, samples: samples, endingAt: endDate),
              change >= 0.7 else {
            return nil
        }

        return BodyCompositionTrendNotice(
            id: "body-fat-recent-increase",
            kind: .bodyFatIncrease,
            metricID: .bodyFatPercentage,
            title: "체지방률 상승 추세",
            message: "최근 30일 평균 체지방률이 이전 30일보다 높습니다.",
            changeValue: change,
            unit: "%"
        )
    }

    private func consecutiveDecreaseNotice(
        metricID: UnifiedHealthMetricID,
        samples: [UnifiedHealthMetricSample]
    ) -> BodyCompositionTrendNotice? {
        let recent = samples
            .filter { $0.metricID == metricID }
            .sortedByMeasuredAtAscending()
            .suffix(3)

        guard recent.count == 3 else {
            return nil
        }

        let values = recent.map(\.value)
        guard values[0] > values[1], values[1] > values[2] else {
            return nil
        }

        let change = values[2] - values[0]
        let metricName = metricID == .skeletalMuscleMass ? "골격근량" : "근육량"
        return BodyCompositionTrendNotice(
            id: "\(metricID.rawValue)-three-sample-decrease",
            kind: .consecutiveDecrease,
            metricID: metricID,
            title: "\(metricName) 연속 감소",
            message: "최근 3회 측정에서 \(metricName)이 연속으로 낮아졌습니다.",
            changeValue: change,
            unit: "kg"
        )
    }

    private func recentChange(
        metricID: UnifiedHealthMetricID,
        samples: [UnifiedHealthMetricSample],
        endingAt endDate: Date
    ) -> Double? {
        let day: TimeInterval = 24 * 60 * 60
        let window = Double(trendWindowDays) * day
        let recentStart = endDate.addingTimeInterval(-window)
        let previousStart = recentStart.addingTimeInterval(-window)

        let metricSamples = samples.filter { $0.metricID == metricID }
        let recentValues = metricSamples
            .filter { $0.measuredAt >= recentStart && $0.measuredAt <= endDate }
            .map(\.value)
        let previousValues = metricSamples
            .filter { $0.measuredAt >= previousStart && $0.measuredAt < recentStart }
            .map(\.value)

        guard recentValues.count >= 2,
              previousValues.count >= 2,
              let recentAverage = average(recentValues),
              let previousAverage = average(previousValues) else {
            return nil
        }

        return recentAverage - previousAverage
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else {
            return nil
        }
        return values.reduce(0, +) / Double(values.count)
    }
}
