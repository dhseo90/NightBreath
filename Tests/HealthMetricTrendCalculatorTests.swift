import Foundation
import Testing
@testable import SleepSoundCore

@Suite("HealthMetricTrendCalculator")
struct HealthMetricTrendCalculatorTests {
    private let calculator = HealthMetricTrendCalculator()

    @Test
    func dateRangeFilteringUsesSelectedPeriod() {
        let samples = [
            sample(.bodyMass, 72, daysAgo: 1),
            sample(.bodyMass, 73, daysAgo: 6),
            sample(.bodyMass, 74, daysAgo: 8),
            sample(.bodyFatPercentage, 21, daysAgo: 1),
        ]

        let sevenDaySamples = calculator.samples(
            samples,
            metricType: .bodyMass,
            period: .sevenDays,
            endingAt: referenceDate
        )
        let thirtyDaySamples = calculator.samples(
            samples,
            metricType: .bodyMass,
            period: .thirtyDays,
            endingAt: referenceDate
        )

        #expect(sevenDaySamples.map(\.value) == [73, 72])
        #expect(thirtyDaySamples.map(\.value) == [74, 73, 72])
    }

    @Test
    func emptyDataSummaryReturnsNilStatsAndZeroCount() {
        let summary = calculator.summary(
            samples: [],
            metricType: .bodyMass,
            period: .sevenDays,
            endingAt: referenceDate
        )

        #expect(summary.sampleCount == 0)
        #expect(summary.average == nil)
        #expect(summary.latest == nil)
        #expect(summary.minimum == nil)
        #expect(summary.maximum == nil)
        #expect(summary.changeFromPreviousPeriod == nil)
    }

    @Test
    func singleSampleSummaryUsesSameValueForAverageMinimumMaximumAndLatest() throws {
        let samples = [sample(.bodyMassIndex, 23.1, daysAgo: 0)]

        let summary = calculator.summary(
            samples: samples,
            metricType: .bodyMassIndex,
            period: .sevenDays,
            endingAt: referenceDate
        )

        #expect(summary.sampleCount == 1)
        #expect(summary.average == 23.1)
        #expect(summary.minimum == 23.1)
        #expect(summary.maximum == 23.1)
        #expect(try #require(summary.latest).value == 23.1)
    }

    @Test
    func changeFromPreviousPeriodUsesAverageDifference() throws {
        let samples = [
            sample(.bodyMass, 72, daysAgo: 2),
            sample(.bodyMass, 70, daysAgo: 1),
            sample(.bodyMass, 76, daysAgo: 12),
            sample(.bodyMass, 74, daysAgo: 8),
        ]

        let summary = calculator.summary(
            samples: samples,
            metricType: .bodyMass,
            period: .sevenDays,
            endingAt: referenceDate
        )

        let change = try #require(summary.changeFromPreviousPeriod)
        #expect(abs(change - -4) < 0.0001)
    }

    @Test
    func sourceGroupingCountsSamplesAndSortsByLatestDate() throws {
        let samples = [
            sample(.systolicBloodPressure, 120, daysAgo: 4, source: ("Omron Connect", "omron")),
            sample(.diastolicBloodPressure, 78, daysAgo: 4, source: ("Omron Connect", "omron")),
            sample(.bodyMass, 71, daysAgo: 1, source: ("Fitdays", "fitdays")),
        ]

        let sources = calculator.sourceSummaries(samples: samples)

        #expect(sources.map(\.sourceName) == ["Fitdays", "Omron Connect"])
        #expect(try #require(sources.first).sampleCount == 1)
        #expect(try #require(sources.last).sampleCount == 2)
    }

    @Test
    func summariesBuildMultipleMetricRowsInRequestedOrder() throws {
        let samples = [
            sample(.systolicBloodPressure, 122, daysAgo: 1),
            sample(.diastolicBloodPressure, 79, daysAgo: 1),
            sample(.bodyMass, 71, daysAgo: 1),
        ]

        let summaries = calculator.summaries(
            samples: samples,
            metricTypes: [.diastolicBloodPressure, .systolicBloodPressure],
            period: .sevenDays,
            endingAt: referenceDate
        )

        #expect(summaries.map(\.metricType) == [.diastolicBloodPressure, .systolicBloodPressure])
        #expect(try #require(summaries.first).latest?.value == 79)
        #expect(try #require(summaries.last).latest?.value == 122)
    }

    @Test
    func periodSummariesExposeSevenThirtyAndNinetyDayWindows() {
        let samples = [
            sample(.bodyMass, 70, daysAgo: 1),
            sample(.bodyMass, 71, daysAgo: 15),
            sample(.bodyMass, 72, daysAgo: 60),
        ]

        let summaries = calculator.periodSummaries(
            samples: samples,
            metricType: .bodyMass,
            endingAt: referenceDate
        )

        #expect(summaries.map(\.period) == [.sevenDays, .thirtyDays, .ninetyDays])
        #expect(summaries.map(\.sampleCount) == [1, 2, 3])
    }

    @Test
    func scopedSourceGroupingFiltersByMetricAndPeriod() throws {
        let samples = [
            sample(.systolicBloodPressure, 120, daysAgo: 1, source: ("Omron Connect", "omron")),
            sample(.diastolicBloodPressure, 77, daysAgo: 1, source: ("Omron Connect", "omron")),
            sample(.bodyMass, 71, daysAgo: 1, source: ("Fitdays", "fitdays")),
            sample(.systolicBloodPressure, 122, daysAgo: 20, source: ("Old BP", "old-bp")),
        ]

        let sources = calculator.sourceSummaries(
            samples: samples,
            metricTypes: [.systolicBloodPressure, .diastolicBloodPressure],
            period: .sevenDays,
            endingAt: referenceDate
        )

        #expect(sources.map(\.sourceName) == ["Omron Connect"])
        #expect(try #require(sources.first).sampleCount == 2)
    }

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_777_680_000)
    }

    private var day: TimeInterval {
        24 * 60 * 60
    }

    private func sample(
        _ metricType: HealthMetricType,
        _ value: Double,
        daysAgo: Int,
        source: (name: String, bundleIdentifier: String) = ("Apple Health", "apple")
    ) -> HealthMetricSample {
        HealthMetricSample(
            metricType: metricType,
            value: value,
            unit: metricType.unitLabel,
            measuredAt: referenceDate.addingTimeInterval(-Double(daysAgo) * day),
            sourceName: source.name,
            sourceBundleIdentifier: source.bundleIdentifier
        )
    }
}
