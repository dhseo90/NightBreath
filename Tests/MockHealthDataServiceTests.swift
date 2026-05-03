import Foundation
import Testing
@testable import SleepSoundCore

@Suite("MockHealthDataService")
struct MockHealthDataServiceTests {
    @Test
    func defaultMockDataContainsDailyRhythmMetricsAndSources() async {
        let service = makeService()
        let samples = await service.fetchSamplesForDay(referenceDate, calendar: calendar)
        let sourcesByName = Dictionary(grouping: samples, by: \.sourceName)

        #expect(Set(samples.map(\.metricType)) == Set(HealthMetricType.dailyRhythmMockMetrics))
        #expect(samples.count == HealthMetricType.dailyRhythmMockMetrics.count)
        #expect(Set(sourcesByName["Omron Connect"]?.map(\.metricType) ?? []) == [
            .systolicBloodPressure,
            .diastolicBloodPressure,
        ])
        #expect(Set(sourcesByName["Fitdays"]?.map(\.metricType) ?? []) == [
            .bodyMass,
            .bodyFatPercentage,
            .bodyMassIndex,
            .leanBodyMass,
        ])
        #expect(Set(sourcesByName["Apple 건강앱 예시"]?.map(\.metricType) ?? []) == [
            .stepCount,
            .activeEnergy,
            .heartRate,
            .restingHeartRate,
            .sleepDuration,
            .respiratoryRate,
        ])
    }

    @Test
    func dateRangeFilteringOnlyReturnsSamplesInsideRange() async {
        let service = makeService()
        let range = HealthMetricDateRange(
            start: dayStart.addingTimeInterval(7 * hour + 30 * minute),
            end: dayStart.addingTimeInterval(8 * hour + 30 * minute)
        )

        let systolicSamples = await service.fetchSamples(
            metricType: .systolicBloodPressure,
            dateRange: range
        )
        let bodyMassSamples = await service.fetchSamples(
            metricType: .bodyMass,
            dateRange: range
        )

        #expect(systolicSamples.count == 1)
        #expect(bodyMassSamples.isEmpty)
        #expect(systolicSamples.first?.sourceName == "Omron Connect")
    }

    @Test
    func latestSampleUsesNewestSampleForMetric() async throws {
        let service = makeService()

        let latestBodyMass = try #require(await service.fetchLatestSample(metricType: .bodyMass))

        #expect(calendar.isDate(latestBodyMass.measuredAt, inSameDayAs: referenceDate))
        #expect(latestBodyMass.sourceName == "Fitdays")
    }

    @Test
    func dailySummarySortsSamplesAndReportsSources() async {
        let service = makeService()

        let summary = await service.fetchDailySummary(date: referenceDate, calendar: calendar)

        #expect(summary.date == dayStart)
        #expect(summary.sampleCount == HealthMetricType.dailyRhythmMockMetrics.count)
        #expect(Set(summary.metricTypes) == Set(HealthMetricType.dailyRhythmMockMetrics))
        #expect(summary.sourceNames == ["Apple 건강앱 예시", "Fitdays", "Omron Connect"])
        #expect(summary.samples == summary.samples.sortedByMeasuredAtAscending())
    }

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_777_680_000)
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private var dayStart: Date {
        calendar.startOfDay(for: referenceDate)
    }

    private var hour: TimeInterval {
        60 * 60
    }

    private var minute: TimeInterval {
        60
    }

    private func makeService() -> MockHealthDataService {
        MockHealthDataService(
            samples: MockHealthDataService.makeDefaultSamples(
                referenceDate: referenceDate,
                calendar: calendar
            )
        )
    }
}
