import Foundation
import Testing
@testable import SleepSoundCore

@Suite("HealthMetricSample sorting")
struct HealthMetricSampleSortingTests {
    @Test
    func sortingUsesMeasuredAtAndDeterministicIDTieBreak() {
        let samples = [
            sample(id: "40000000-0000-0000-0000-000000000003", value: 3, offset: -hour),
            sample(id: "40000000-0000-0000-0000-000000000002", value: 2, offset: 0),
            sample(id: "40000000-0000-0000-0000-000000000001", value: 1, offset: 0),
        ]

        let ascending = samples.sortedByMeasuredAtAscending()
        let descending = samples.sortedByMeasuredAtDescending()

        #expect(ascending.map(\.value) == [3, 1, 2])
        #expect(descending.map(\.value) == [1, 2, 3])
    }

    @Test
    func latestSampleReturnsNewestSampleForRequestedMetric() throws {
        let newestID = UUID(uuidString: "40000000-0000-0000-0000-000000000011")!
        let samples = [
            sample(id: "40000000-0000-0000-0000-000000000010", metricType: .heartRate, value: 70, offset: -hour),
            sample(id: newestID.uuidString, metricType: .heartRate, value: 72, offset: 0),
            sample(id: "40000000-0000-0000-0000-000000000012", metricType: .bodyMass, value: 71.8, offset: hour),
        ]

        let latestHeartRate = try #require(samples.latestSample(metricType: .heartRate))

        #expect(latestHeartRate.id == newestID)
        #expect(latestHeartRate.value == 72)
    }

    @Test
    func dateRangeFilteringKeepsOnlyMetricSamplesInsideInclusiveRange() {
        let samples = [
            sample(metricType: .bodyMass, value: 72.4, offset: -2 * hour),
            sample(metricType: .bodyMass, value: 72.1, offset: -hour),
            sample(metricType: .bodyMass, value: 71.9, offset: 0),
            sample(metricType: .bodyFatPercentage, value: 21.4, offset: -hour),
        ]
        let range = HealthMetricDateRange(
            start: referenceDate.addingTimeInterval(-hour),
            end: referenceDate
        )

        let filtered = samples.filtered(metricType: .bodyMass, dateRange: range)

        #expect(filtered.map(\.value) == [72.1, 71.9])
    }

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_777_680_000)
    }

    private var hour: TimeInterval {
        60 * 60
    }

    private func sample(
        id: String = UUID().uuidString,
        metricType: HealthMetricType = .bodyMass,
        value: Double,
        offset: TimeInterval
    ) -> HealthMetricSample {
        HealthMetricSample(
            id: UUID(uuidString: id)!,
            metricType: metricType,
            value: value,
            unit: metricType.unitLabel,
            measuredAt: referenceDate.addingTimeInterval(offset),
            sourceName: "Apple 건강앱 예시",
            sourceBundleIdentifier: "com.apple.Health.mock"
        )
    }
}
