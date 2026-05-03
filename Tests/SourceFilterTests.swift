import Foundation
import Testing
@testable import SleepSoundCore

@Suite("SourceFilter")
struct SourceFilterTests {
    @Test
    func allFilterIncludesEverySourceType() {
        let samples = HealthMetricSourceType.allCases.map { sourceType in
            sample(.bodyMass, Double(sourceType.rawValue.count), sourceType: sourceType)
        }

        #expect(samples.allSatisfy { MetricDetailSourceFilter.all.includes($0) })
    }

    @Test
    func specificFiltersIncludeOnlyMatchingSourceType() {
        let healthKitSample = sample(.bodyMass, 71.6, sourceType: .healthKit)
        let fitdaysSample = sample(.bodyMass, 71.8, sourceType: .fitdaysCSV)
        let manualSample = sample(.bodyMass, 71.7, sourceType: .manual)

        #expect(MetricDetailSourceFilter.healthKit.includes(healthKitSample))
        #expect(!MetricDetailSourceFilter.healthKit.includes(fitdaysSample))
        #expect(MetricDetailSourceFilter.fitdaysCSV.includes(fitdaysSample))
        #expect(!MetricDetailSourceFilter.fitdaysCSV.includes(manualSample))
    }

    @Test
    func viewModelSourceFilterKeepsSummaryRawListAndBreakdownScoped() {
        let samples = [
            sample(.bodyMass, 71.6, daysAgo: 1, sourceType: .healthKit, sourceName: "Apple 건강앱"),
            sample(.bodyMass, 71.8, daysAgo: 2, sourceType: .fitdaysCSV, sourceName: "Fitdays CSV Import"),
            sample(.bodyMass, 71.7, daysAgo: 3, sourceType: .manual, sourceName: "수동 입력"),
        ]

        let viewModel = MetricDetailViewModel(
            metricID: .bodyMass,
            samples: samples,
            period: .thirtyDays,
            sourceFilter: .fitdaysCSV,
            endDate: referenceDate
        )

        #expect(viewModel.summary.sampleCount == 1)
        #expect(viewModel.rawSampleList.map(\.sourceType) == [.fitdaysCSV])
        #expect(viewModel.sourceBreakdown.map(\.sourceType) == [.fitdaysCSV])
        #expect(viewModel.emptyStateReason == nil)
    }

    @Test
    func displayNamesMirrorSourceTypeCopy() {
        #expect(MetricDetailSourceFilter.healthKit.displayName == HealthMetricSourceType.healthKit.displayName)
        #expect(MetricDetailSourceFilter.fitdaysCSV.displayName == HealthMetricSourceType.fitdaysCSV.displayName)
        #expect(MetricDetailSourceFilter.appComputed.displayName == HealthMetricSourceType.appComputed.displayName)
    }

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_777_680_000)
    }

    private var day: TimeInterval {
        24 * 60 * 60
    }

    private func sample(
        _ metricID: UnifiedHealthMetricID,
        _ value: Double,
        daysAgo: Int = 1,
        sourceType: HealthMetricSourceType,
        sourceName: String? = nil
    ) -> UnifiedHealthMetricSample {
        UnifiedHealthMetricSample(
            metricID: metricID,
            value: value,
            unit: MetricCatalog.default.metadata(for: metricID)?.unit ?? "",
            measuredAt: referenceDate.addingTimeInterval(-Double(daysAgo) * day),
            sourceType: sourceType,
            sourceName: sourceName ?? sourceType.displayName,
            createdAt: referenceDate
        )
    }
}
