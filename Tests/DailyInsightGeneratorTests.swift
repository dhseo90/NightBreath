import Foundation
import Testing
@testable import SleepSoundCore

@Suite("DailyInsightGenerator")
struct DailyInsightGeneratorTests {
    @Test
    func generatorCreatesObservationBasedInsights() {
        let fixture = makeFixture(morningRefreshScore: 3, morningFatigueScore: 3)
        let calculation = DailyRhythmScoreCalculator(calendar: calendar).calculate(
            snapshot: fixture.snapshot,
            nightReport: fixture.report,
            morningCheckIn: fixture.morningCheckIn,
            eveningCheckIn: fixture.eveningCheckIn,
            healthMetricSamples: fixture.samples,
            computedAt: referenceDate
        )
        let generator = DailyInsightGenerator(calendar: calendar)

        let insights = generator.generate(
            snapshot: fixture.snapshot,
            scoreCalculation: calculation,
            nightReport: fixture.report,
            morningCheckIn: fixture.morningCheckIn,
            eveningCheckIn: fixture.eveningCheckIn,
            healthMetricSamples: fixture.samples,
            createdAt: referenceDate
        )

        #expect(insights.contains { $0.message == "어젯밤 코골기 시간이 비교적 길게 기록되었습니다." })
        #expect(insights.contains { $0.message == "아침 컨디션은 보통으로 기록되었습니다." })
        #expect(insights.contains { $0.message == "오늘 혈압과 체중 데이터가 함께 기록되었습니다." })
        #expect(insights.contains { $0.message == "오늘 활동 데이터가 기록되어 하루 리듬 카드에서 함께 볼 수 있습니다." })
    }

    @Test
    func insufficientDataInsightComesFirst() {
        let snapshot = DailyHealthSnapshot(
            date: dayStart,
            dataCompletenessScore: 0,
            createdAt: referenceDate
        )
        let calculation = DailyRhythmScoreCalculator(calendar: calendar).calculate(
            snapshot: snapshot,
            computedAt: referenceDate
        )
        let generator = DailyInsightGenerator(calendar: calendar)

        let insights = generator.generate(
            snapshot: snapshot,
            scoreCalculation: calculation,
            createdAt: referenceDate
        )

        #expect(insights.first?.type == .dataQuality)
        #expect(insights.first?.severity == .caution)
        #expect(insights.first?.message == "비교 가능한 데이터가 부족해 일부 리포트가 제한됩니다.")
    }

    @Test
    func lowAudioCoverageUsesLimitedReferenceCopy() {
        let fixture = makeFixture(audioCoverage: 0.40)
        let calculation = DailyRhythmScoreCalculator(calendar: calendar).calculate(
            snapshot: fixture.snapshot,
            nightReport: fixture.report,
            morningCheckIn: fixture.morningCheckIn,
            eveningCheckIn: fixture.eveningCheckIn,
            healthMetricSamples: fixture.samples,
            computedAt: referenceDate
        )
        let generator = DailyInsightGenerator(calendar: calendar)

        let insights = generator.generate(
            snapshot: fixture.snapshot,
            scoreCalculation: calculation,
            nightReport: fixture.report,
            morningCheckIn: fixture.morningCheckIn,
            eveningCheckIn: fixture.eveningCheckIn,
            healthMetricSamples: fixture.samples,
            createdAt: referenceDate
        )

        #expect(insights.contains { $0.message == "수면 소리 측정 범위가 짧아 수면 항목은 참고 범위가 제한됩니다." })
    }

    @Test
    func generatedCopyAvoidsDiagnosisAndCausalityClaims() {
        let fixture = makeFixture()
        let calculation = DailyRhythmScoreCalculator(calendar: calendar).calculate(
            snapshot: fixture.snapshot,
            nightReport: fixture.report,
            morningCheckIn: fixture.morningCheckIn,
            eveningCheckIn: fixture.eveningCheckIn,
            healthMetricSamples: fixture.samples,
            computedAt: referenceDate
        )
        let insights = DailyInsightGenerator(calendar: calendar).generate(
            snapshot: fixture.snapshot,
            scoreCalculation: calculation,
            nightReport: fixture.report,
            morningCheckIn: fixture.morningCheckIn,
            eveningCheckIn: fixture.eveningCheckIn,
            healthMetricSamples: fixture.samples,
            createdAt: referenceDate
        )
        let combinedCopy = insights.flatMap { [$0.title, $0.message] }.joined(separator: " ")
        let restrictedTerms = [
            "고혈압" + "입니다",
            "비만" + "입니다",
            "수면" + "무호흡증 가능성이 높습니다",
            "치료" + "가 필요합니다",
            "때문에",
            "올랐" + "습니다",
            "상승" + "했습니다",
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

    private func makeFixture(
        audioCoverage: Double = 0.95,
        morningRefreshScore: Int = 4,
        morningFatigueScore: Int = 2
    ) -> DailyRhythmFixture {
        let report = NightReport(
            sessionId: UUID(),
            generatedAt: dayStart.addingTimeInterval(8 * hour),
            measurementDuration: 8 * hour,
            estimatedSleepDuration: 7 * hour,
            receivedAudioDuration: 8 * hour * audioCoverage,
            analyzedAudioDuration: 8 * hour * audioCoverage,
            audioCoverageRatio: audioCoverage,
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
            refreshScore: morningRefreshScore,
            fatigueScore: morningFatigueScore,
            createdAt: dayStart.addingTimeInterval(8 * hour)
        )
        let eveningCheckIn = EveningCheckIn(
            date: referenceDate,
            fatigueScore: 2,
            stressScore: 2,
            moodScore: 4,
            caffeine: true,
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
            lifestyleTags: [.caffeine],
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
