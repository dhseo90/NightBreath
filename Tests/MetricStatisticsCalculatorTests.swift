import Foundation
import Testing
@testable import SleepSoundCore

@Suite("MetricStatisticsCalculator")
struct MetricStatisticsCalculatorTests {
    private let calculator = MetricStatisticsCalculator()

    @Test
    func emptySamplesReturnNilStatisticsAndZeroCount() {
        let summary = calculator.summary(
            samples: [],
            metricID: .bodyWaterPercentage,
            dateRange: .days(30, endingAt: referenceDate)
        )

        #expect(summary.metricID == .bodyWaterPercentage)
        #expect(summary.latestValue == nil)
        #expect(summary.average == nil)
        #expect(summary.min == nil)
        #expect(summary.max == nil)
        #expect(summary.deltaFromPreviousPeriod == nil)
        #expect(summary.sampleCount == 0)
        #expect(summary.firstMeasuredAt == nil)
        #expect(summary.latestMeasuredAt == nil)
    }

    @Test
    func singleSampleUsesSameValueForLatestAverageMinimumAndMaximum() throws {
        let samples = [
            sample(.skeletalMuscleMass, 31.2, daysAgo: 1, sourceType: .fitdaysCSV),
        ]

        let summary = calculator.summary(
            samples: samples,
            metricID: .skeletalMuscleMass,
            dateRange: .days(7, endingAt: referenceDate)
        )

        #expect(summary.sampleCount == 1)
        #expect(summary.latestValue == 31.2)
        #expect(summary.average == 31.2)
        #expect(summary.min == 31.2)
        #expect(summary.max == 31.2)
        #expect(summary.deltaFromPreviousPeriod == nil)
        #expect(try #require(summary.firstMeasuredAt) == samples[0].measuredAt)
        #expect(try #require(summary.latestMeasuredAt) == samples[0].measuredAt)
    }

    @Test
    func dateRangeFilteringKeepsOnlyRequestedMetricAndWindow() {
        let samples = [
            sample(.bodyWaterPercentage, 56.8, daysAgo: 1),
            sample(.bodyWaterPercentage, 57.0, daysAgo: 6),
            sample(.bodyWaterPercentage, 58.0, daysAgo: 20),
            sample(.bodyMass, 71.6, daysAgo: 1),
        ]

        let scoped = calculator.samples(
            samples,
            metricID: .bodyWaterPercentage,
            dateRange: .days(7, endingAt: referenceDate)
        )

        #expect(scoped.map(\.value) == [57.0, 56.8])
    }

    @Test
    func deltaFromPreviousPeriodUsesAverageDifference() throws {
        let samples = [
            sample(.bodyMass, 71.0, daysAgo: 2),
            sample(.bodyMass, 73.0, daysAgo: 1),
            sample(.bodyMass, 70.0, daysAgo: 10),
            sample(.bodyMass, 72.0, daysAgo: 8),
        ]

        let summary = calculator.summary(
            samples: samples,
            metricID: .bodyMass,
            dateRange: .days(7, endingAt: referenceDate)
        )

        let delta = try #require(summary.deltaFromPreviousPeriod)
        #expect(abs(delta - 1.0) < 0.0001)
    }

    @Test
    func multipleSourcesArePreservedInBreakdown() {
        let samples = [
            sample(.bodyMass, 71.4, daysAgo: 4, sourceType: .healthKit, sourceName: "Apple 건강앱"),
            sample(.bodyMass, 71.6, daysAgo: 2, sourceType: .fitdaysCSV, sourceName: "Fitdays CSV Import"),
            sample(.bodyMass, 71.8, daysAgo: 1, sourceType: .manual, sourceName: "수동 입력"),
        ]

        let sources = calculator.sourceBreakdown(
            samples: samples,
            metricID: .bodyMass,
            dateRange: .days(7, endingAt: referenceDate)
        )

        #expect(sources.map(\.sourceType) == [.manual, .fitdaysCSV, .healthKit])
        #expect(sources.map(\.sampleCount) == [1, 1, 1])
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
        daysAgo: Int,
        sourceType: HealthMetricSourceType = .fitdaysCSV,
        sourceName: String = "Fitdays CSV Import"
    ) -> UnifiedHealthMetricSample {
        UnifiedHealthMetricSample(
            metricID: metricID,
            value: value,
            unit: MetricCatalog.default.metadata(for: metricID)?.unit ?? "",
            measuredAt: referenceDate.addingTimeInterval(-Double(daysAgo) * day),
            sourceType: sourceType,
            sourceName: sourceName,
            createdAt: referenceDate
        )
    }
}
