import Foundation
import Testing
@testable import SleepSoundCore

@Suite("DailyMeasurementDetail")
struct DailyMeasurementDetailTests {
    private let builder = HealthCalendarBuilder()

    @Test
    func detailSeparatesStandardFitdaysExtendedActivityAndAppComputedSamples() {
        let targetDate = date(2026, 5, 3)
        let detail = builder.detailData(
            for: targetDate,
            samples: [
                sample(.systolicBloodPressure, 118, targetDate, sourceType: .healthKit),
                sample(.diastolicBloodPressure, 76, targetDate.addingTimeInterval(60), sourceType: .healthKit),
                sample(.bodyMass, 71.6, targetDate.addingTimeInterval(120), sourceType: .healthKit),
                sample(.bodyWaterPercentage, 56.8, targetDate.addingTimeInterval(180), sourceType: .fitdaysCSV),
                sample(.stepCount, 6_400, targetDate.addingTimeInterval(240), sourceType: .healthKit),
                sample(.sleepSoundScore, 82, targetDate.addingTimeInterval(300), sourceType: .appComputed),
            ],
            sleepReports: [],
            calendar: calendar
        )

        #expect(detail.bloodPressureSamples.map(\.metricID) == [.systolicBloodPressure, .diastolicBloodPressure])
        #expect(detail.bodyCompositionSamples.map(\.metricID) == [.bodyMass])
        #expect(detail.fitdaysExtendedSamples.map(\.metricID) == [.bodyWaterPercentage])
        #expect(detail.activitySamples.map(\.metricID) == [.stepCount])
        #expect(detail.appComputedSamples.map(\.metricID) == [.sleepSoundScore])
        #expect(detail.fitdaysExtendedSamples.allSatisfy { $0.sourceType == .fitdaysCSV })
        #expect(detail.summary.sourceTypes == [.healthKit, .fitdaysCSV, .appComputed])
    }

    @Test
    func standardMetricsImportedFromFitdaysStayStandardWhileLocalOnlyMetricsStayExtended() {
        let targetDate = date(2026, 5, 3)
        let detail = builder.detailData(
            for: targetDate,
            samples: [
                sample(.bodyMass, 71.8, targetDate.addingTimeInterval(60), sourceType: .fitdaysCSV),
                sample(.bodyFatPercentage, 21.4, targetDate.addingTimeInterval(120), sourceType: .fitdaysCSV),
                sample(.bodyWaterPercentage, 56.8, targetDate.addingTimeInterval(180), sourceType: .fitdaysCSV),
                sample(.skeletalMuscleMass, 31.2, targetDate.addingTimeInterval(240), sourceType: .fitdaysCSV),
            ],
            sleepReports: [],
            calendar: calendar
        )

        #expect(detail.bodyCompositionSamples.map(\.metricID) == [.bodyMass, .bodyFatPercentage])
        #expect(detail.bodyCompositionSamples.allSatisfy { $0.sourceType == .fitdaysCSV })
        #expect(detail.fitdaysExtendedSamples.map(\.metricID) == [.bodyWaterPercentage, .skeletalMuscleMass])
        #expect(detail.fitdaysExtendedSamples.allSatisfy { MetricCatalog.default.isExtendedLocalOnly($0.metricID) })
        #expect(detail.summary.sourceTypes == [.fitdaysCSV])
    }

    @Test
    func rawSampleLookupKeepsOnlyRequestedMetricsAndAscendingTimeOrder() {
        let targetDate = date(2026, 5, 3)
        let detail = builder.detailData(
            for: targetDate,
            samples: [
                sample(.bodyWaterPercentage, 57.0, targetDate.addingTimeInterval(300), sourceType: .fitdaysCSV),
                sample(.bodyMass, 71.6, targetDate.addingTimeInterval(120), sourceType: .healthKit),
                sample(.bodyWaterPercentage, 56.8, targetDate.addingTimeInterval(60), sourceType: .fitdaysCSV),
            ],
            sleepReports: [],
            calendar: calendar
        )

        #expect(detail.samples(for: [.bodyWaterPercentage]).map(\.value) == [56.8, 57.0])
        #expect(detail.samples(for: [.bodyMass, .bodyWaterPercentage]).map(\.value) == [56.8, 71.6, 57.0])
    }

    @Test
    func emptyDetailKeepsNoDataStateAndNoSamples() {
        let detail = builder.detailData(
            for: date(2026, 5, 3),
            samples: [],
            sleepReports: [],
            calendar: calendar
        )

        #expect(!detail.summary.hasAnyData)
        #expect(detail.samples.isEmpty)
        #expect(detail.bloodPressureSamples.isEmpty)
        #expect(detail.bodyCompositionSamples.isEmpty)
        #expect(detail.fitdaysExtendedSamples.isEmpty)
        #expect(detail.activitySamples.isEmpty)
        #expect(detail.appComputedSamples.isEmpty)
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 8) -> Date {
        DateComponents(
            calendar: calendar,
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day,
            hour: hour
        ).date!
    }

    private func sample(
        _ metricID: UnifiedHealthMetricID,
        _ value: Double,
        _ measuredAt: Date,
        sourceType: HealthMetricSourceType
    ) -> UnifiedHealthMetricSample {
        UnifiedHealthMetricSample(
            metricID: metricID,
            value: value,
            unit: MetricCatalog.default.metadata(for: metricID)?.unit ?? "",
            measuredAt: measuredAt,
            sourceType: sourceType,
            sourceName: sourceType.displayName,
            createdAt: measuredAt
        )
    }
}
