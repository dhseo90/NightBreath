import Foundation

public enum MetricDetailPeriod: String, CaseIterable, Codable, Identifiable, Sendable {
    case sevenDays
    case thirtyDays
    case ninetyDays
    case oneYear
    case all

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .sevenDays:
            "7일"
        case .thirtyDays:
            "30일"
        case .ninetyDays:
            "90일"
        case .oneYear:
            "1년"
        case .all:
            "전체"
        }
    }

    public init(trendPeriod: HealthMetricTrendPeriod) {
        switch trendPeriod {
        case .sevenDays:
            self = .sevenDays
        case .thirtyDays:
            self = .thirtyDays
        case .ninetyDays:
            self = .ninetyDays
        case .oneYear:
            self = .oneYear
        }
    }

    public func dateRange(
        samples: [UnifiedHealthMetricSample],
        metricID: UnifiedHealthMetricID,
        sourceFilter: MetricDetailSourceFilter = .all,
        endingAt endDate: Date = Date()
    ) -> HealthMetricDateRange {
        switch self {
        case .sevenDays:
            .days(7, endingAt: endDate)
        case .thirtyDays:
            .days(30, endingAt: endDate)
        case .ninetyDays:
            .days(90, endingAt: endDate)
        case .oneYear:
            .days(365, endingAt: endDate)
        case .all:
            allSamplesDateRange(
                samples: samples,
                metricID: metricID,
                sourceFilter: sourceFilter,
                endingAt: endDate
            )
        }
    }

    private func allSamplesDateRange(
        samples: [UnifiedHealthMetricSample],
        metricID: UnifiedHealthMetricID,
        sourceFilter: MetricDetailSourceFilter,
        endingAt endDate: Date
    ) -> HealthMetricDateRange {
        let scopedSamples = samples
            .filter { $0.metricID == metricID && sourceFilter.includes($0) }
            .sortedByMeasuredAtAscending()

        guard let firstSample = scopedSamples.first,
              let latestSample = scopedSamples.last else {
            return HealthMetricDateRange(start: endDate, end: endDate)
        }

        return HealthMetricDateRange(
            start: firstSample.measuredAt,
            end: max(endDate, latestSample.measuredAt)
        )
    }
}

public enum MetricDetailSourceFilter: String, CaseIterable, Codable, Identifiable, Sendable {
    case all
    case healthKit
    case fitdaysCSV
    case manual
    case appComputed
    case mock

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .all:
            "전체"
        case .healthKit:
            HealthMetricSourceType.healthKit.displayName
        case .fitdaysCSV:
            HealthMetricSourceType.fitdaysCSV.displayName
        case .manual:
            HealthMetricSourceType.manual.displayName
        case .appComputed:
            HealthMetricSourceType.appComputed.displayName
        case .mock:
            HealthMetricSourceType.mock.displayName
        }
    }

    public var sourceType: HealthMetricSourceType? {
        switch self {
        case .all:
            nil
        case .healthKit:
            .healthKit
        case .fitdaysCSV:
            .fitdaysCSV
        case .manual:
            .manual
        case .appComputed:
            .appComputed
        case .mock:
            .mock
        }
    }

    public func includes(_ sample: UnifiedHealthMetricSample) -> Bool {
        guard let sourceType else {
            return true
        }
        return sample.sourceType == sourceType
    }
}

public enum MetricDetailEmptyStateReason: Equatable, Sendable {
    case noMetricSamples
    case noSamplesForSource
    case noSamplesForPeriod

    public var title: String {
        switch self {
        case .noMetricSamples:
            "표시할 샘플이 없습니다"
        case .noSamplesForSource:
            "선택한 출처의 샘플이 없습니다"
        case .noSamplesForPeriod:
            "선택한 기간의 샘플이 없습니다"
        }
    }

    public var message: String {
        switch self {
        case .noMetricSamples:
            "HealthKit read-only 연결, Fitdays CSV 가져오기 또는 로컬 입력이 추가되면 이 지표의 기록을 볼 수 있습니다."
        case .noSamplesForSource:
            "출처 필터를 바꾸거나 다른 데이터 가져오기 상태를 확인하세요."
        case .noSamplesForPeriod:
            "기간을 넓히거나 전체 기간을 선택해 보세요."
        }
    }
}

public struct MetricDetailExplanation: Equatable, Sendable {
    public var messages: [String]

    public init(messages: [String]) {
        self.messages = messages
    }

    public static func make(for metadata: MetricDisplayMetadata) -> MetricDetailExplanation {
        if metadata.isHealthKitBacked {
            return MetricDetailExplanation(messages: [
                "\(metadata.displayNameKo)는 Apple 건강앱에서 read-only로 읽은 데이터입니다.",
                "앱은 HealthKit에 데이터를 쓰지 않습니다.",
                "sourceName과 측정 시각을 함께 표시합니다.",
            ])
        }

        if metadata.isExtendedLocalOnly {
            return MetricDetailExplanation(messages: [
                "\(metadata.displayNameKo)는 Fitdays CSV import 또는 수동 입력으로 저장된 local-only 지표입니다.",
                "HealthKit 표준 지표가 아니며 import/manual 데이터로만 표시됩니다.",
                "값은 개인 참고용으로만 정리합니다.",
            ])
        }

        if metadata.category == .app || metadata.category == .sleep {
            return MetricDetailExplanation(messages: [
                "\(metadata.displayNameKo)는 밤숨 앱에서 기기 안에서 계산하거나 로컬 기록으로 정리한 지표입니다.",
                "다른 건강 샘플과 함께 볼 수 있지만 인과관계를 의미하지 않습니다.",
                "값은 개인 참고용으로만 정리합니다.",
            ])
        }

        return MetricDetailExplanation(messages: [
            metadata.description,
            metadata.disclaimer ?? "로컬 샘플과 허용된 read-only 샘플을 정리해 표시합니다.",
            "값은 개인 참고용으로만 정리합니다.",
        ])
    }
}

public struct MetricDetailViewModel: Equatable, Sendable {
    public var metricID: UnifiedHealthMetricID
    public var samples: [UnifiedHealthMetricSample]
    public var period: MetricDetailPeriod
    public var sourceFilter: MetricDetailSourceFilter
    public var endDate: Date
    public var catalog: MetricCatalog

    private let calculator = MetricStatisticsCalculator()

    public init(
        metricID: UnifiedHealthMetricID,
        samples: [UnifiedHealthMetricSample],
        period: MetricDetailPeriod = .thirtyDays,
        sourceFilter: MetricDetailSourceFilter = .all,
        endDate: Date = Date(),
        catalog: MetricCatalog = .default
    ) {
        self.metricID = metricID
        self.samples = samples
        self.period = period
        self.sourceFilter = sourceFilter
        self.endDate = endDate
        self.catalog = catalog
    }

    public var metadata: MetricDisplayMetadata? {
        catalog.metadata(for: metricID)
    }

    public var dateRange: HealthMetricDateRange {
        period.dateRange(
            samples: samples,
            metricID: metricID,
            sourceFilter: sourceFilter,
            endingAt: endDate
        )
    }

    public var metricSamples: [UnifiedHealthMetricSample] {
        samples
            .filter { $0.metricID == metricID }
            .sortedByMeasuredAtAscending()
    }

    public var sourceFilteredSamples: [UnifiedHealthMetricSample] {
        metricSamples
            .filter { sourceFilter.includes($0) }
            .sortedByMeasuredAtAscending()
    }

    public var filteredSamples: [UnifiedHealthMetricSample] {
        calculator.samples(
            sourceFilteredSamples,
            metricID: metricID,
            dateRange: dateRange
        )
    }

    public var rawSampleList: [UnifiedHealthMetricSample] {
        filteredSamples.sortedByMeasuredAtDescending()
    }

    public var summary: MetricStatisticsSummary {
        calculator.summary(
            samples: sourceFilteredSamples,
            metricID: metricID,
            dateRange: dateRange
        )
    }

    public var points: [MetricTrendDataPoint] {
        calculator.points(
            samples: sourceFilteredSamples,
            metricID: metricID,
            dateRange: dateRange
        )
    }

    public var sourceBreakdown: [MetricSourceBreakdown] {
        calculator.sourceBreakdown(
            samples: sourceFilteredSamples,
            metricID: metricID,
            dateRange: dateRange
        )
    }

    public var latestSample: UnifiedHealthMetricSample? {
        filteredSamples.sortedByMeasuredAtDescending().first
    }

    public var emptyStateReason: MetricDetailEmptyStateReason? {
        if metricSamples.isEmpty {
            return .noMetricSamples
        }
        if sourceFilteredSamples.isEmpty {
            return .noSamplesForSource
        }
        if filteredSamples.isEmpty {
            return .noSamplesForPeriod
        }
        return nil
    }
}
