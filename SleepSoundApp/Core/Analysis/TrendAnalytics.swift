import Foundation

public enum TrendMetricType: String, CaseIterable, Codable, Identifiable, Sendable {
    case sleepSoundScore
    case audioCoverageRatio
    case snoreTotalSeconds
    case bruxismLikeCount
    case coughLikeCount
    case gaspLikeCount
    case suspectedBreathingPauseCount
    case environmentalNoiseCount
    case awakeningSuspectedCount

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .sleepSoundScore:
            "수면 소리 점수"
        case .audioCoverageRatio:
            "오디오 커버리지"
        case .snoreTotalSeconds:
            "코골기 시간"
        case .bruxismLikeCount:
            "이갈이 의심 소리"
        case .coughLikeCount:
            "기침 의심 소리"
        case .gaspLikeCount:
            "gasp-like 회복 호흡"
        case .suspectedBreathingPauseCount:
            "호흡정지 의심 구간"
        case .environmentalNoiseCount:
            "환경 소음"
        case .awakeningSuspectedCount:
            "각성 의심 구간"
        }
    }

    public var unitLabel: String {
        switch self {
        case .sleepSoundScore:
            "점"
        case .audioCoverageRatio:
            "%"
        case .snoreTotalSeconds:
            "분"
        case .bruxismLikeCount, .coughLikeCount, .gaspLikeCount,
             .suspectedBreathingPauseCount, .environmentalNoiseCount, .awakeningSuspectedCount:
            "회"
        }
    }

    public func value(from report: NightReport) -> Double {
        switch self {
        case .sleepSoundScore:
            Double(report.sleepSoundScore)
        case .audioCoverageRatio:
            report.audioCoverageRatio * 100
        case .snoreTotalSeconds:
            report.snoreTotalSeconds / 60
        case .bruxismLikeCount:
            Double(max(0, report.bruxismLikeCount))
        case .coughLikeCount:
            Double(max(0, report.coughLikeCount))
        case .gaspLikeCount:
            Double(max(0, report.gaspLikeCount))
        case .suspectedBreathingPauseCount:
            Double(report.suspectedBreathingPauseCount)
        case .environmentalNoiseCount:
            Double(max(0, report.environmentalNoiseCount))
        case .awakeningSuspectedCount:
            Double(max(0, report.awakeningSuspectedCount))
        }
    }
}

public struct TrendDataPoint: Identifiable, Equatable, Sendable {
    public var date: Date
    public var metricType: TrendMetricType
    public var value: Double
    public var measurementQuality: MeasurementQuality
    public var sessionId: UUID

    public var id: String {
        "\(sessionId.uuidString)-\(metricType.rawValue)"
    }

    public var isLowMeasurementQuality: Bool {
        measurementQuality == .limited || measurementQuality == .poor
    }

    public init(
        date: Date,
        metricType: TrendMetricType,
        value: Double,
        measurementQuality: MeasurementQuality,
        sessionId: UUID
    ) {
        self.date = date
        self.metricType = metricType
        self.value = Self.safe(value)
        self.measurementQuality = measurementQuality
        self.sessionId = sessionId
    }

    private static func safe(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return max(0, value)
    }
}

public struct TrendSummary: Equatable, Sendable {
    public var metricType: TrendMetricType
    public var periodDays: Int
    public var average: Double?
    public var min: Double?
    public var max: Double?
    public var latest: Double?
    public var changeFromPreviousPeriod: Double?
    public var lowQualityDataCount: Int
    public var dataPointCount: Int
    public var includedDataPointCount: Int

    public init(
        metricType: TrendMetricType,
        periodDays: Int,
        average: Double? = nil,
        min: Double? = nil,
        max: Double? = nil,
        latest: Double? = nil,
        changeFromPreviousPeriod: Double? = nil,
        lowQualityDataCount: Int = 0,
        dataPointCount: Int = 0,
        includedDataPointCount: Int = 0
    ) {
        self.metricType = metricType
        self.periodDays = Swift.max(1, periodDays)
        self.average = Self.safeOptional(average)
        self.min = Self.safeOptional(min)
        self.max = Self.safeOptional(max)
        self.latest = Self.safeOptional(latest)
        self.changeFromPreviousPeriod = changeFromPreviousPeriod?.isFinite == true ? changeFromPreviousPeriod : nil
        self.lowQualityDataCount = Swift.max(0, lowQualityDataCount)
        self.dataPointCount = Swift.max(0, dataPointCount)
        self.includedDataPointCount = Swift.max(0, includedDataPointCount)
    }

    public var hasData: Bool {
        dataPointCount > 0
    }

    private static func safeOptional(_ value: Double?) -> Double? {
        guard let value, value.isFinite else { return nil }
        return Swift.max(0, value)
    }
}

public struct TrendAggregator: Equatable, Sendable {
    public var excludesLowQualityFromSummary: Bool

    public init(excludesLowQualityFromSummary: Bool = true) {
        self.excludesLowQualityFromSummary = excludesLowQualityFromSummary
    }

    public func dataPoints(
        reports: [NightReport],
        metricType: TrendMetricType,
        periodDays: Int,
        referenceDate: Date = Date()
    ) -> [TrendDataPoint] {
        normalizedReports(
            reports,
            from: currentPeriodStart(periodDays: periodDays, referenceDate: referenceDate),
            to: referenceDate
        )
        .map { report in
            TrendDataPoint(
                date: report.generatedAt,
                metricType: metricType,
                value: metricType.value(from: report),
                measurementQuality: report.measurementQuality,
                sessionId: report.sessionId
            )
        }
    }

    public func summary(
        reports: [NightReport],
        metricType: TrendMetricType,
        periodDays: Int,
        referenceDate: Date = Date()
    ) -> TrendSummary {
        let currentStart = currentPeriodStart(periodDays: periodDays, referenceDate: referenceDate)
        let previousStart = currentStart.addingTimeInterval(-Self.daySeconds * Double(max(periodDays, 1)))
        let currentReports = normalizedReports(reports, from: currentStart, to: referenceDate)
        let previousReports = normalizedReports(reports, from: previousStart, to: currentStart)
        let currentPoints = currentReports.map { point(report: $0, metricType: metricType) }
        let previousPoints = previousReports.map { point(report: $0, metricType: metricType) }
        let includedCurrentValues = valuesForSummary(currentPoints)
        let includedPreviousValues = valuesForSummary(previousPoints)
        let currentAverage = average(includedCurrentValues)
        let previousAverage = average(includedPreviousValues)

        return TrendSummary(
            metricType: metricType,
            periodDays: periodDays,
            average: currentAverage,
            min: includedCurrentValues.min(),
            max: includedCurrentValues.max(),
            latest: currentPoints.last?.value,
            changeFromPreviousPeriod: currentAverage.flatMap { current in
                previousAverage.map { current - $0 }
            },
            lowQualityDataCount: currentPoints.filter(\.isLowMeasurementQuality).count,
            dataPointCount: currentPoints.count,
            includedDataPointCount: includedCurrentValues.count
        )
    }

    public func summaries(
        reports: [NightReport],
        metricTypes: [TrendMetricType],
        periodDays: Int,
        referenceDate: Date = Date()
    ) -> [TrendSummary] {
        metricTypes.map { metricType in
            summary(
                reports: reports,
                metricType: metricType,
                periodDays: periodDays,
                referenceDate: referenceDate
            )
        }
    }

    private func normalizedReports(
        _ reports: [NightReport],
        from startDate: Date,
        to endDate: Date
    ) -> [NightReport] {
        let uniqueReports = reports.reduce(into: [UUID: NightReport]()) { result, report in
            guard report.generatedAt >= startDate, report.generatedAt <= endDate else { return }
            if let existing = result[report.sessionId],
               existing.generatedAt > report.generatedAt {
                return
            }
            result[report.sessionId] = report
        }

        return uniqueReports.values.sorted { lhs, rhs in
            if lhs.generatedAt == rhs.generatedAt {
                return lhs.sessionId.uuidString < rhs.sessionId.uuidString
            }
            return lhs.generatedAt < rhs.generatedAt
        }
    }

    private func point(report: NightReport, metricType: TrendMetricType) -> TrendDataPoint {
        TrendDataPoint(
            date: report.generatedAt,
            metricType: metricType,
            value: metricType.value(from: report),
            measurementQuality: report.measurementQuality,
            sessionId: report.sessionId
        )
    }

    private func valuesForSummary(_ points: [TrendDataPoint]) -> [Double] {
        points
            .filter { point in
                !excludesLowQualityFromSummary || !point.isLowMeasurementQuality
            }
            .map(\.value)
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func currentPeriodStart(periodDays: Int, referenceDate: Date) -> Date {
        referenceDate.addingTimeInterval(-Self.daySeconds * Double(max(periodDays, 1)))
    }

    private static let daySeconds: TimeInterval = 24 * 60 * 60
}
