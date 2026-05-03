import Foundation
import Testing
@testable import SleepSoundCore

@Suite("DailyRhythmReportBuilder")
struct DailyRhythmReportBuilderTests {
    @Test
    func builderCombinesScoreDataQualityAndInsights() {
        let fixture = makeFixture()
        let report = DailyRhythmReportBuilder(calendar: calendar).build(
            id: UUID(uuidString: "60000000-0000-0000-0000-000000000001")!,
            snapshot: fixture.snapshot,
            nightReport: fixture.report,
            morningCheckIn: fixture.morningCheckIn,
            eveningCheckIn: fixture.eveningCheckIn,
            healthMetricSamples: fixture.samples,
            createdAt: referenceDate
        )

        #expect(report.date == fixture.snapshot.date)
        #expect(report.dataQuality == .excellent)
        #expect(report.dailyRhythmScore.computedAt == referenceDate)
        #expect(report.sleepComponentScore == report.dailyRhythmScore.sleepComponent)
        #expect(report.recoveryComponentScore == report.dailyRhythmScore.recoveryComponent)
        #expect(report.activityComponentScore == report.dailyRhythmScore.activityComponent)
        #expect(report.bloodPressureComponentScore == report.dailyRhythmScore.bloodPressureComponent)
        #expect(report.bodyMetricComponentScore == report.dailyRhythmScore.bodyMetricComponent)
        #expect(!report.insights.isEmpty)
        #expect(report.isMedicalDisclaimerRequired)
    }

    @Test
    func builderHandlesInsufficientDataSafely() {
        let snapshot = DailyHealthSnapshot(
            date: dayStart,
            dataCompletenessScore: 0,
            createdAt: referenceDate
        )

        let report = DailyRhythmReportBuilder(calendar: calendar).build(
            snapshot: snapshot,
            createdAt: referenceDate
        )

        #expect(report.dataQuality == .insufficient)
        #expect(report.dailyRhythmScore.totalScore == 50)
        #expect(report.insights.first?.type == .dataQuality)
        #expect(report.insights.first?.severity == .caution)
    }

    @Test
    func reportCopyAvoidsDiagnosisAndCausalityClaims() {
        let fixture = makeFixture()
        let report = DailyRhythmReportBuilder(calendar: calendar).build(
            snapshot: fixture.snapshot,
            nightReport: fixture.report,
            morningCheckIn: fixture.morningCheckIn,
            eveningCheckIn: fixture.eveningCheckIn,
            healthMetricSamples: fixture.samples,
            createdAt: referenceDate
        )
        let combinedCopy = ([report.cautionText] + report.insights.flatMap { [$0.title, $0.message] })
            .joined(separator: " ")
        let restrictedTerms = [
            "고혈압" + "입니다",
            "비만" + "입니다",
            "수면" + "무호흡증 가능성이 높습니다",
            "치료" + "가 필요합니다",
            "코골기" + " 때문에 혈압",
            "건강" + "진단" + "점수",
            "의학적" + "판정",
            "원인",
            "유발",
            "정상",
            "비정상",
        ]

        #expect(restrictedTerms.allSatisfy { !combinedCopy.contains($0) })
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

    private func makeFixture() -> DailyRhythmFixture {
        let report = NightReport(
            sessionId: UUID(),
            generatedAt: dayStart.addingTimeInterval(8 * hour),
            measurementDuration: 8 * hour,
            estimatedSleepDuration: 7 * hour,
            sleepSoundScore: 88,
            snoreTotalSeconds: 18 * 60,
            snoreRatio: 0.04,
            bruxismLikeCount: 0,
            suspectedPauseCount: 0,
            gaspLikeCount: 0,
            coughLikeCount: 1,
            sleepTalkLikeCount: 0,
            environmentalNoiseCount: 1,
            awakeningSuspectedCount: 1,
            longestSuspectedPause: 0,
            mostDisturbedHourRange: nil,
            mainDisturbanceReason: "수면 소리 기록"
        )
        let morningCheckIn = MorningCheckIn(
            sessionId: report.id,
            refreshScore: 4,
            fatigueScore: 2,
            createdAt: dayStart.addingTimeInterval(8 * hour)
        )
        let eveningCheckIn = EveningCheckIn(
            date: referenceDate,
            fatigueScore: 2,
            stressScore: 2,
            moodScore: 4,
            exercise: true,
            createdAt: dayStart.addingTimeInterval(21 * hour)
        )
        let samples = MockHealthDataService.makeDefaultSamples(
            referenceDate: referenceDate,
            calendar: calendar
        )
        .filter { calendar.isDate($0.measuredAt, inSameDayAs: referenceDate) }
        let snapshot = DailyHealthSnapshotBuilder(calendar: calendar).build(
            date: referenceDate,
            sleepReport: report,
            morningCheckIn: morningCheckIn,
            eveningCheckIn: eveningCheckIn,
            healthMetricSamples: samples,
            createdAt: referenceDate
        )

        return DailyRhythmFixture(
            snapshot: snapshot,
            report: report,
            morningCheckIn: morningCheckIn,
            eveningCheckIn: eveningCheckIn,
            samples: samples
        )
    }

    private struct DailyRhythmFixture {
        var snapshot: DailyHealthSnapshot
        var report: NightReport
        var morningCheckIn: MorningCheckIn
        var eveningCheckIn: EveningCheckIn
        var samples: [HealthMetricSample]
    }
}
