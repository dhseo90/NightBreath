import Foundation
import Testing
@testable import SleepSoundCore

@Suite("CalendarDaySummary")
struct CalendarDaySummaryTests {
    private let builder = HealthCalendarBuilder()

    @Test
    func monthGenerationCreatesSixWeekGridAroundSelectedMonth() throws {
        let days = builder.monthGrid(containing: date(2026, 5, 15), calendar: calendar)

        #expect(days.count == 42)
        #expect(try #require(days.first) == date(2026, 4, 26, hour: 0))
        #expect(try #require(days.last) == date(2026, 6, 6, hour: 0))
    }

    @Test
    func dayDataGroupingSetsCategoryFlagsAndQuality() {
        let sessionID = UUID(uuidString: "43000000-0000-0000-0000-000000000001")!
        let targetDate = date(2026, 5, 3)
        let samples = [
            sample(.systolicBloodPressure, 118, targetDate, sourceType: .healthKit, sourceName: "Omron Connect"),
            sample(.diastolicBloodPressure, 76, targetDate, sourceType: .healthKit, sourceName: "Omron Connect"),
            sample(.bodyWaterPercentage, 56.8, targetDate, sourceType: .fitdaysCSV, sourceName: "Fitdays CSV Import"),
            sample(.stepCount, 6_400, targetDate, sourceType: .healthKit, sourceName: "Apple 건강앱"),
        ]

        let summary = builder.summary(
            for: targetDate,
            samples: samples,
            sleepReports: [report(sessionID: sessionID, generatedAt: targetDate)],
            morningCheckIns: [MorningCheckIn(sessionId: sessionID, createdAt: targetDate)],
            eveningCheckIns: [EveningCheckIn(date: targetDate)],
            calendar: calendar
        )

        #expect(summary.hasSleepReport)
        #expect(summary.hasBloodPressure)
        #expect(summary.hasBodyComposition)
        #expect(summary.hasActivity)
        #expect(summary.hasMorningCheckIn)
        #expect(summary.hasEveningCheckIn)
        #expect(summary.sampleCount == 4)
        #expect(summary.sourceTypes == [.healthKit, .fitdaysCSV])
        #expect(summary.dataQuality == .good)
    }

    @Test
    func selectedDateDetailOnlyIncludesThatDay() {
        let selectedDate = date(2026, 5, 3)
        let otherDate = date(2026, 5, 4)
        let selectedSessionID = UUID(uuidString: "43000000-0000-0000-0000-000000000002")!
        let otherSessionID = UUID(uuidString: "43000000-0000-0000-0000-000000000003")!

        let detail = builder.detailData(
            for: selectedDate,
            samples: [
                sample(.bodyMass, 71.6, selectedDate),
                sample(.bodyMass, 71.4, otherDate),
            ],
            sleepReports: [
                report(sessionID: selectedSessionID, generatedAt: selectedDate),
                report(sessionID: otherSessionID, generatedAt: otherDate),
            ],
            morningCheckIns: [
                MorningCheckIn(sessionId: selectedSessionID, createdAt: selectedDate),
                MorningCheckIn(sessionId: otherSessionID, createdAt: otherDate),
            ],
            calendar: calendar
        )

        #expect(detail.samples.map(\.value) == [71.6])
        #expect(detail.sleepReports.map(\.sessionId) == [selectedSessionID])
        #expect(detail.morningCheckIns.map(\.sessionId) == [selectedSessionID])
        #expect(detail.summary.hasBodyComposition)
    }

    @Test
    func emptyDayStateHasNoFlagsAndInsufficientQuality() {
        let summary = builder.summary(
            for: date(2026, 5, 10),
            samples: [],
            sleepReports: [],
            calendar: calendar
        )

        #expect(!summary.hasAnyData)
        #expect(!summary.hasSleepReport)
        #expect(!summary.hasBloodPressure)
        #expect(!summary.hasBodyComposition)
        #expect(!summary.hasActivity)
        #expect(summary.sampleCount == 0)
        #expect(summary.sourceTypes.isEmpty)
        #expect(summary.dataQuality == .insufficient)
    }

    @Test
    func sourceGroupingUsesStableSourceTypeOrder() {
        let targetDate = date(2026, 5, 3)
        let summary = builder.summary(
            for: targetDate,
            samples: [
                sample(.bodyMass, 71.6, targetDate, sourceType: .manual, sourceName: "수동 입력"),
                sample(.bodyMassIndex, 23.0, targetDate, sourceType: .fitdaysCSV, sourceName: "Fitdays CSV Import"),
                sample(.stepCount, 6_400, targetDate, sourceType: .healthKit, sourceName: "Apple 건강앱"),
                sample(.sleepSoundScore, 82, targetDate, sourceType: .appComputed, sourceName: "밤숨 앱"),
            ],
            sleepReports: [],
            calendar: calendar
        )

        #expect(summary.sourceTypes == [.healthKit, .fitdaysCSV, .manual, .appComputed])
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 1
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
        sourceType: HealthMetricSourceType = .fitdaysCSV,
        sourceName: String = "Fitdays CSV Import"
    ) -> UnifiedHealthMetricSample {
        UnifiedHealthMetricSample(
            metricID: metricID,
            value: value,
            unit: MetricCatalog.default.metadata(for: metricID)?.unit ?? "",
            measuredAt: measuredAt,
            sourceType: sourceType,
            sourceName: sourceName,
            createdAt: measuredAt
        )
    }

    private func report(sessionID: UUID, generatedAt: Date) -> NightReport {
        NightReport(
            sessionId: sessionID,
            generatedAt: generatedAt,
            measurementDuration: 8 * 60 * 60,
            estimatedSleepDuration: 7.2 * 60 * 60,
            receivedAudioDuration: 7.9 * 60 * 60,
            audioCoverageRatio: 0.94,
            sleepSoundScore: 82,
            snoreTotalSeconds: 18 * 60,
            snoreRatio: 0.04,
            bruxismLikeCount: 2,
            suspectedPauseCount: 1,
            gaspLikeCount: 0,
            coughLikeCount: 1,
            sleepTalkLikeCount: 0,
            environmentalNoiseCount: 3,
            awakeningSuspectedCount: 1,
            longestSuspectedPause: 8,
            mostDisturbedHourRange: nil,
            mainDisturbanceReason: "수면 소리 지표가 기록되었습니다."
        )
    }
}
