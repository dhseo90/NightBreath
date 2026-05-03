import Foundation
import Testing
@testable import SleepSoundCore

@Suite("MockHealthKitService")
struct MockHealthKitServiceTests {
    @Test
    func mockServiceReturnsSamples() async {
        let service = MockHealthKitService(samples: makeSamples())

        let samples = await service.fetchSamples(
            metricType: .bodyMass,
            dateRange: HealthMetricDateRange.days(30, endingAt: referenceDate)
        )

        #expect(samples.count == 3)
        #expect(samples.allSatisfy { $0.metricType == .bodyMass })
        #expect(await service.requestReadPermission() == .mockDataOnly)
    }

    @Test
    func healthMetricSampleSortingUsesMeasuredAtAscending() {
        let samples = makeSamples().shuffled()

        let sorted = samples.sortedByMeasuredAtAscending()

        #expect(sorted.map(\.measuredAt) == sorted.map(\.measuredAt).sorted())
        #expect(sorted.first?.measuredAt == referenceDate.addingTimeInterval(-3 * day))
        #expect(sorted.last?.measuredAt == referenceDate)
    }

    @Test
    func latestSampleCalculationUsesNewestSampleForMetric() async throws {
        let service = MockHealthKitService(samples: makeSamples())

        let latest = try #require(await service.fetchLatestSample(metricType: .systolicBloodPressure))

        #expect(latest.value == 120)
        #expect(latest.measuredAt == referenceDate)
    }

    @Test
    func dateRangeFilteringOnlyReturnsSamplesInsideRange() async {
        let service = MockHealthKitService(samples: makeSamples())
        let range = HealthMetricDateRange(
            start: referenceDate.addingTimeInterval(-1.5 * day),
            end: referenceDate
        )

        let samples = await service.fetchSamples(metricType: .bodyMass, dateRange: range)

        #expect(samples.map(\.value) == [72.0, 71.8])
    }

    @Test
    func chartDataGenerationSortsPointsAndCalculatesLatestChange() {
        let builder = HealthMetricChartDataBuilder()
        let samples = makeSamples().shuffled()

        let points = builder.points(samples: samples, metricType: .bodyMass)
        let change = builder.latestChange(samples: samples, metricType: .bodyMass)

        #expect(points.map(\.value) == [72.3, 72.0, 71.8])
        #expect(abs((change ?? 0) - -0.2) < 0.0001)
    }

    @Test
    func defaultMockDataContainsExpectedSources() {
        let samples = MockHealthKitService.makeDefaultSamples(referenceDate: referenceDate)
        let sourceNames = Set(samples.map(\.sourceName))

        #expect(sourceNames.contains("Omron Connect"))
        #expect(sourceNames.contains("Fitdays"))
        #expect(sourceNames.contains("Apple 건강앱 예시"))
    }

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_777_680_000)
    }

    private var day: TimeInterval {
        24 * 60 * 60
    }

    private func makeSamples() -> [HealthMetricSample] {
        [
            sample(.bodyMass, 72.3, daysAgo: 3, sourceName: "Fitdays", bundle: "com.fitdays.app"),
            sample(.bodyMass, 72.0, daysAgo: 1, sourceName: "Fitdays", bundle: "com.fitdays.app"),
            sample(.bodyMass, 71.8, daysAgo: 0, sourceName: "Fitdays", bundle: "com.fitdays.app"),
            sample(.systolicBloodPressure, 124, daysAgo: 3, sourceName: "Omron Connect", bundle: "com.omronhealthcare.omronconnect"),
            sample(.systolicBloodPressure, 121, daysAgo: 1, sourceName: "Omron Connect", bundle: "com.omronhealthcare.omronconnect"),
            sample(.systolicBloodPressure, 120, daysAgo: 0, sourceName: "Omron Connect", bundle: "com.omronhealthcare.omronconnect"),
        ]
    }

    private func sample(
        _ metricType: HealthMetricType,
        _ value: Double,
        daysAgo: Int,
        sourceName: String,
        bundle: String
    ) -> HealthMetricSample {
        HealthMetricSample(
            metricType: metricType,
            value: value,
            unit: metricType.unitLabel,
            measuredAt: referenceDate.addingTimeInterval(-Double(daysAgo) * day),
            sourceName: sourceName,
            sourceBundleIdentifier: bundle
        )
    }
}
