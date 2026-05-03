import Foundation
import Testing
@testable import SleepSoundCore

@Suite("DailyRhythmScoreCalculator")
struct DailyRhythmScoreCalculatorTests {
    @Test
    func completeDataCalculatesSeparatedComponentScoresAndQuality() {
        let fixture = makeFixture()
        let calculator = DailyRhythmScoreCalculator(calendar: calendar)

        let calculation = calculator.calculate(
            snapshot: fixture.snapshot,
            nightReport: fixture.report,
            morningCheckIn: fixture.morningCheckIn,
            eveningCheckIn: fixture.eveningCheckIn,
            healthMetricSamples: fixture.samples,
            computedAt: referenceDate
        )

        #expect(calculation.dataQuality == .excellent)
        #expect(calculation.score.dataCompleteness == 1)
        #expect(calculation.score.totalScore >= 0)
        #expect(calculation.score.totalScore <= 100)
        #expect(calculation.score.sleepComponent > 50)
        #expect(calculation.score.recoveryComponent > 50)
        #expect(calculation.score.activityComponent > 50)
        #expect(calculation.score.bloodPressureComponent > 50)
        #expect(calculation.score.bodyMetricComponent > 50)
    }

    @Test
    func insufficientDataKeepsNeutralScoreAndMarksDataQuality() {
        let snapshot = DailyHealthSnapshot(
            date: dayStart,
            dataCompletenessScore: 0,
            createdAt: referenceDate
        )
        let calculator = DailyRhythmScoreCalculator(calendar: calendar)

        let calculation = calculator.calculate(snapshot: snapshot, computedAt: referenceDate)

        #expect(calculation.dataQuality == .insufficient)
        #expect(calculation.score.totalScore == 50)
        #expect(calculation.score.dataCompleteness == 0)
    }

    @Test
    func lowAudioCoverageReducesSleepComponentConfidence() {
        let highCoverage = makeFixture(audioCoverage: 0.95)
        let lowCoverage = makeFixture(audioCoverage: 0.40)
        let calculator = DailyRhythmScoreCalculator(calendar: calendar)

        let highScore = calculator.calculate(
            snapshot: highCoverage.snapshot,
            nightReport: highCoverage.report,
            morningCheckIn: highCoverage.morningCheckIn,
            eveningCheckIn: highCoverage.eveningCheckIn,
            healthMetricSamples: highCoverage.samples,
            computedAt: referenceDate
        ).score
        let lowScore = calculator.calculate(
            snapshot: lowCoverage.snapshot,
            nightReport: lowCoverage.report,
            morningCheckIn: lowCoverage.morningCheckIn,
            eveningCheckIn: lowCoverage.eveningCheckIn,
            healthMetricSamples: lowCoverage.samples,
            computedAt: referenceDate
        ).score

        #expect(lowScore.sleepComponent < highScore.sleepComponent)
        #expect(lowScore.sleepComponent >= 50)
    }

    @Test
    func missingBloodPressureDataDoesNotCollapseTotalScore() {
        let fixture = makeFixture(excluding: [.systolicBloodPressure, .diastolicBloodPressure])
        let calculator = DailyRhythmScoreCalculator(calendar: calendar)

        let calculation = calculator.calculate(
            snapshot: fixture.snapshot,
            nightReport: fixture.report,
            morningCheckIn: fixture.morningCheckIn,
            eveningCheckIn: fixture.eveningCheckIn,
            healthMetricSamples: fixture.samples,
            computedAt: referenceDate
        )

        #expect(calculation.score.bloodPressureComponent == 50)
        #expect(calculation.score.totalScore > 60)
        #expect(calculation.dataQuality == .good)
    }

    @Test
    func missingBodyMetricDataUsesMissingComponentPlaceholder() {
        let fixture = makeFixture(excluding: [.bodyMass, .bodyFatPercentage, .bodyMassIndex, .leanBodyMass])
        let calculator = DailyRhythmScoreCalculator(calendar: calendar)

        let calculation = calculator.calculate(
            snapshot: fixture.snapshot,
            nightReport: fixture.report,
            morningCheckIn: fixture.morningCheckIn,
            eveningCheckIn: fixture.eveningCheckIn,
            healthMetricSamples: fixture.samples,
            computedAt: referenceDate
        )

        #expect(calculation.score.bodyMetricComponent == 50)
        #expect(calculation.score.totalScore > 60)
        #expect(calculation.dataQuality == .good)
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
        excluding excludedMetricTypes: Set<HealthMetricType> = []
    ) -> DailyRhythmFixture {
        let report = makeNightReport(audioCoverage: audioCoverage)
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
        .filter { !excludedMetricTypes.contains($0.metricType) }
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

    private func makeNightReport(audioCoverage: Double) -> NightReport {
        NightReport(
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
    }

    private struct DailyRhythmFixture {
        var snapshot: DailyHealthSnapshot
        var report: NightReport
        var morningCheckIn: MorningCheckIn
        var eveningCheckIn: EveningCheckIn
        var samples: [HealthMetricSample]
    }
}
