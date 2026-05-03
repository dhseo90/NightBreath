import Foundation

public enum CrossMetricDataQuality: String, Codable, Equatable, Sendable {
    case sufficient
    case limited
    case insufficientData

    public var displayName: String {
        switch self {
        case .sufficient:
            "비교 가능"
        case .limited:
            "일부 제외"
        case .insufficientData:
            "데이터 부족"
        }
    }
}

public enum CrossMetricMatchingStrategy: String, Codable, Equatable, Sendable {
    case nextMorning
    case sameCalendarDay

    public var displayName: String {
        switch self {
        case .nextMorning:
            "다음날 아침"
        case .sameCalendarDay:
            "같은 날짜"
        }
    }
}

public struct CrossMetricMatchedPoint: Identifiable, Equatable, Sendable {
    public var id: String
    public var sleepMetric: TrendMetricType
    public var healthMetric: HealthMetricType
    public var sleepReportDate: Date
    public var healthSampleDate: Date
    public var sleepValue: Double
    public var healthValue: Double
    public var sleepMeasurementQuality: MeasurementQuality
    public var audioCoverageRatio: Double
    public var healthSourceName: String
    public var healthSourceBundleIdentifier: String
    public var matchingStrategy: CrossMetricMatchingStrategy
    public var isIncludedInSummary: Bool
    public var matchingWindowDescription: String

    public var isLowMeasurementQuality: Bool {
        !isIncludedInSummary
    }

    public init(
        id: String,
        sleepMetric: TrendMetricType,
        healthMetric: HealthMetricType,
        sleepReportDate: Date,
        healthSampleDate: Date,
        sleepValue: Double,
        healthValue: Double,
        sleepMeasurementQuality: MeasurementQuality,
        audioCoverageRatio: Double,
        healthSourceName: String,
        healthSourceBundleIdentifier: String,
        matchingStrategy: CrossMetricMatchingStrategy,
        isIncludedInSummary: Bool,
        matchingWindowDescription: String
    ) {
        self.id = id
        self.sleepMetric = sleepMetric
        self.healthMetric = healthMetric
        self.sleepReportDate = sleepReportDate
        self.healthSampleDate = healthSampleDate
        self.sleepValue = Self.safe(sleepValue)
        self.healthValue = Self.safe(healthValue)
        self.sleepMeasurementQuality = sleepMeasurementQuality
        self.audioCoverageRatio = min(max(audioCoverageRatio.isFinite ? audioCoverageRatio : 0, 0), 1)
        self.healthSourceName = healthSourceName
        self.healthSourceBundleIdentifier = healthSourceBundleIdentifier
        self.matchingStrategy = matchingStrategy
        self.isIncludedInSummary = isIncludedInSummary
        self.matchingWindowDescription = matchingWindowDescription
    }

    private static func safe(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return max(0, value)
    }
}

public struct CrossMetricSummary: Equatable, Sendable {
    public var sleepMetric: TrendMetricType
    public var healthMetric: HealthMetricType
    public var matchedSampleCount: Int
    public var trendDescription: String
    public var dataQuality: CrossMetricDataQuality
    public var cautionText: String
    public var totalMatchedSampleCount: Int
    public var lowQualityExcludedCount: Int
    public var matchingStrategy: CrossMetricMatchingStrategy
    public var healthSourceNames: [String]
    public var sourceSummaries: [HealthMetricSourceSummary]
    public var matchingWindowDescription: String

    public init(
        sleepMetric: TrendMetricType,
        healthMetric: HealthMetricType,
        matchedSampleCount: Int,
        trendDescription: String,
        dataQuality: CrossMetricDataQuality,
        cautionText: String,
        totalMatchedSampleCount: Int,
        lowQualityExcludedCount: Int,
        matchingStrategy: CrossMetricMatchingStrategy,
        healthSourceNames: [String],
        sourceSummaries: [HealthMetricSourceSummary],
        matchingWindowDescription: String
    ) {
        self.sleepMetric = sleepMetric
        self.healthMetric = healthMetric
        self.matchedSampleCount = max(0, matchedSampleCount)
        self.trendDescription = trendDescription
        self.dataQuality = dataQuality
        self.cautionText = cautionText
        self.totalMatchedSampleCount = max(0, totalMatchedSampleCount)
        self.lowQualityExcludedCount = max(0, lowQualityExcludedCount)
        self.matchingStrategy = matchingStrategy
        self.healthSourceNames = healthSourceNames
        self.sourceSummaries = sourceSummaries
        self.matchingWindowDescription = matchingWindowDescription
    }

    public var hasEnoughData: Bool {
        dataQuality != .insufficientData
    }
}

public struct CrossMetricAnalyzer: Equatable, Sendable {
    public static let supportedSleepMetrics: [TrendMetricType] = [
        .sleepSoundScore,
        .snoreTotalSeconds,
        .bruxismLikeCount,
        .suspectedBreathingPauseCount,
        .coughLikeCount,
        .environmentalNoiseCount,
        .audioCoverageRatio,
    ]

    public static let supportedHealthMetrics: [HealthMetricType] = [
        .systolicBloodPressure,
        .diastolicBloodPressure,
        .bodyMass,
        .bodyFatPercentage,
        .bodyMassIndex,
        .restingHeartRate,
    ]

    public static let cautionText = "개인 패턴을 살펴보기 위한 참고용 보기입니다. 인과관계를 의미하지 않습니다."

    public var calendar: Calendar
    public var minimumMatchedSampleCount: Int
    public var minimumAudioCoverageRatio: Double

    public init(
        calendar: Calendar = .current,
        minimumMatchedSampleCount: Int = 3,
        minimumAudioCoverageRatio: Double = 0.85
    ) {
        self.calendar = calendar
        self.minimumMatchedSampleCount = max(1, minimumMatchedSampleCount)
        self.minimumAudioCoverageRatio = min(max(minimumAudioCoverageRatio.isFinite ? minimumAudioCoverageRatio : 0.85, 0), 1)
    }

    public func matchedPoints(
        reports: [NightReport],
        samples: [HealthMetricSample],
        sleepMetric: TrendMetricType,
        healthMetric: HealthMetricType,
        period: HealthMetricTrendPeriod,
        endingAt endDate: Date = Date()
    ) -> [CrossMetricMatchedPoint] {
        guard Self.supportedSleepMetrics.contains(sleepMetric),
              Self.supportedHealthMetrics.contains(healthMetric) else {
            return []
        }

        let reports = normalizedReports(reports, period: period, endingAt: endDate)
        let healthSamples = samples
            .filter { $0.metricType == healthMetric }
            .sortedByMeasuredAtAscending()

        return reports.compactMap { report in
            let matchWindow = matchingWindow(for: report.generatedAt, healthMetric: healthMetric)
            guard let sample = firstSample(in: matchWindow.range, samples: healthSamples) else {
                return nil
            }

            let included = report.audioCoverageRatio >= minimumAudioCoverageRatio
                && report.measurementQuality != .limited
                && report.measurementQuality != .poor

            return CrossMetricMatchedPoint(
                id: "\(report.sessionId.uuidString)-\(sample.id.uuidString)-\(sleepMetric.rawValue)-\(healthMetric.rawValue)",
                sleepMetric: sleepMetric,
                healthMetric: healthMetric,
                sleepReportDate: report.generatedAt,
                healthSampleDate: sample.measuredAt,
                sleepValue: sleepMetric.value(from: report),
                healthValue: sample.value,
                sleepMeasurementQuality: report.measurementQuality,
                audioCoverageRatio: report.audioCoverageRatio,
                healthSourceName: sample.sourceName,
                healthSourceBundleIdentifier: sample.sourceBundleIdentifier,
                matchingStrategy: matchWindow.strategy,
                isIncludedInSummary: included,
                matchingWindowDescription: matchingWindowDescription(for: healthMetric)
            )
        }
    }

    public func summary(
        reports: [NightReport],
        samples: [HealthMetricSample],
        sleepMetric: TrendMetricType,
        healthMetric: HealthMetricType,
        period: HealthMetricTrendPeriod,
        endingAt endDate: Date = Date()
    ) -> CrossMetricSummary {
        let points = matchedPoints(
            reports: reports,
            samples: samples,
            sleepMetric: sleepMetric,
            healthMetric: healthMetric,
            period: period,
            endingAt: endDate
        )
        let includedPoints = points.filter(\.isIncludedInSummary)
        let excludedCount = max(0, points.count - includedPoints.count)
        let quality = dataQuality(includedCount: includedPoints.count, excludedCount: excludedCount)
        let sourceSummaries = sourceSummaries(for: includedPoints)

        return CrossMetricSummary(
            sleepMetric: sleepMetric,
            healthMetric: healthMetric,
            matchedSampleCount: includedPoints.count,
            trendDescription: trendDescription(
                sleepMetric: sleepMetric,
                healthMetric: healthMetric,
                includedCount: includedPoints.count,
                excludedCount: excludedCount,
                quality: quality
            ),
            dataQuality: quality,
            cautionText: Self.cautionText,
            totalMatchedSampleCount: points.count,
            lowQualityExcludedCount: excludedCount,
            matchingStrategy: matchingStrategy(for: healthMetric),
            healthSourceNames: sourceSummaries.map(\.sourceName),
            sourceSummaries: sourceSummaries,
            matchingWindowDescription: matchingWindowDescription(for: healthMetric)
        )
    }

    public func matchingWindowDescription(for healthMetric: HealthMetricType) -> String {
        switch matchingStrategy(for: healthMetric) {
        case .nextMorning:
            "수면 리포트 날짜 다음날 04:00부터 12:00까지의 \(healthMetric.displayName) 샘플을 찾습니다."
        case .sameCalendarDay:
            "수면 리포트와 같은 날짜의 \(healthMetric.displayName) 샘플을 찾습니다."
        }
    }

    public func matchingStrategy(for healthMetric: HealthMetricType) -> CrossMetricMatchingStrategy {
        switch healthMetric {
        case .systolicBloodPressure, .diastolicBloodPressure:
            .nextMorning
        case .bodyMass, .bodyFatPercentage, .bodyMassIndex, .leanBodyMass,
             .stepCount, .activeEnergy, .heartRate, .restingHeartRate,
             .sleepDuration, .respiratoryRate:
            .sameCalendarDay
        }
    }

    private func dataQuality(includedCount: Int, excludedCount: Int) -> CrossMetricDataQuality {
        guard includedCount >= minimumMatchedSampleCount else {
            return .insufficientData
        }

        return excludedCount > 0 ? .limited : .sufficient
    }

    private func trendDescription(
        sleepMetric: TrendMetricType,
        healthMetric: HealthMetricType,
        includedCount: Int,
        excludedCount: Int,
        quality: CrossMetricDataQuality
    ) -> String {
        guard quality != .insufficientData else {
            return "비교 가능한 데이터가 아직 부족합니다."
        }

        let baseText = "\(sleepMetric.referencePhrase)와 \(healthMetric.displayName) 샘플 \(includedCount)개를 날짜 기준으로 함께 표시합니다."
        guard excludedCount > 0 else {
            return baseText
        }

        return "\(baseText) 측정 품질 낮음으로 표시된 수면 리포트 \(excludedCount)개는 요약에서 제외했습니다."
    }

    private func normalizedReports(
        _ reports: [NightReport],
        period: HealthMetricTrendPeriod,
        endingAt endDate: Date
    ) -> [NightReport] {
        let range = HealthMetricDateRange.days(period.dayCount, endingAt: endDate)
        let uniqueReports = reports.reduce(into: [UUID: NightReport]()) { result, report in
            guard range.contains(report.generatedAt) else { return }
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

    private func matchingWindow(
        for reportDate: Date,
        healthMetric: HealthMetricType
    ) -> (range: HealthMetricDateRange, strategy: CrossMetricMatchingStrategy) {
        let strategy = matchingStrategy(for: healthMetric)
        let reportDayStart = calendar.startOfDay(for: reportDate)

        switch strategy {
        case .nextMorning:
            let nextDayStart = calendar.date(byAdding: .day, value: 1, to: reportDayStart) ?? reportDayStart
            let start = calendar.date(bySettingHour: 4, minute: 0, second: 0, of: nextDayStart) ?? nextDayStart
            let end = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: nextDayStart)
                ?? nextDayStart.addingTimeInterval(12 * 60 * 60)
            return (HealthMetricDateRange(start: start, end: end), strategy)
        case .sameCalendarDay:
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: reportDayStart)
                ?? reportDayStart.addingTimeInterval(24 * 60 * 60)
            return (HealthMetricDateRange(start: reportDayStart, end: dayEnd.addingTimeInterval(-0.001)), strategy)
        }
    }

    private func firstSample(
        in range: HealthMetricDateRange,
        samples: [HealthMetricSample]
    ) -> HealthMetricSample? {
        samples.first { sample in
            range.contains(sample.measuredAt)
        }
    }

    private func sourceSummaries(for points: [CrossMetricMatchedPoint]) -> [HealthMetricSourceSummary] {
        Dictionary(grouping: points, by: \.healthSourceBundleIdentifier)
            .compactMap { bundleIdentifier, points in
                guard let latest = points.sorted(by: { lhs, rhs in
                    if lhs.healthSampleDate == rhs.healthSampleDate {
                        return lhs.id < rhs.id
                    }
                    return lhs.healthSampleDate > rhs.healthSampleDate
                }).first else {
                    return nil
                }

                return HealthMetricSourceSummary(
                    sourceName: latest.healthSourceName,
                    sourceBundleIdentifier: bundleIdentifier,
                    sampleCount: points.count,
                    latestMeasuredAt: latest.healthSampleDate
                )
            }
            .sorted { lhs, rhs in
                if lhs.latestMeasuredAt == rhs.latestMeasuredAt {
                    return lhs.sourceName < rhs.sourceName
                }
                return lhs.latestMeasuredAt > rhs.latestMeasuredAt
            }
    }
}

private extension TrendMetricType {
    var referencePhrase: String {
        switch self {
        case .sleepSoundScore:
            "수면 소리 점수가 기록된 날"
        case .audioCoverageRatio:
            "오디오 커버리지가 기록된 날"
        case .snoreTotalSeconds:
            "코골기 시간이 기록된 날"
        case .bruxismLikeCount:
            "이갈이 의심 소리가 기록된 날"
        case .coughLikeCount:
            "기침 의심 소리가 기록된 날"
        case .gaspLikeCount:
            "gasp-like 회복 호흡이 기록된 날"
        case .suspectedBreathingPauseCount:
            "호흡정지 의심 구간이 기록된 날"
        case .environmentalNoiseCount:
            "환경 소음이 기록된 날"
        case .awakeningSuspectedCount:
            "각성 의심 구간이 기록된 날"
        }
    }
}
