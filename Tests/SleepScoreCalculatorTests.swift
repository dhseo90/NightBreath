import Foundation
import Testing
@testable import SleepSoundCore

@Suite("SleepScoreCalculator")
struct SleepScoreCalculatorTests {
    @Test
    func quietNightKeepsHighScoreAndStableReason() {
        let result = SleepScoreCalculator().calculateScore(summary: makeSummary())

        #expect(result.score >= 95)
        #expect(result.score <= 100)
        #expect(result.mainDisturbanceReason.contains("조용"))
        #expect(result.mainDisturbanceReason.contains("안정"))
    }

    @Test
    func highSnoreRatioLowersScoreAndCreatesKoreanReason() {
        let quiet = SleepScoreCalculator().calculateScore(summary: makeSummary())
        let result = SleepScoreCalculator().calculateScore(
            summary: makeSummary(snoreTotalSeconds: 2.5 * 60 * 60, snoreRatio: 0.35)
        )

        #expect(result.score < quiet.score)
        #expect(result.score <= 85)
        #expect(result.mainDisturbanceReason.contains("코골기"))
        #expect(result.mainDisturbanceReason.contains("어젯밤"))
    }

    @Test
    func manySuspectedPauseAndGaspLikeEventsLowerScore() {
        let result = SleepScoreCalculator().calculateScore(
            summary: makeSummary(suspectedPauseCount: 8, gaspLikeCount: 4, longestSuspectedPause: 38)
        )

        #expect(result.score <= 80)
        #expect(result.mainDisturbanceReason.contains("호흡정지 의심 구간"))
        #expect(result.mainDisturbanceReason.contains("gasp-like 회복 호흡"))
    }

    @Test
    func environmentalNoiseAndAwakeningEventsLowerScore() {
        let result = SleepScoreCalculator().calculateScore(
            summary: makeSummary(environmentalNoiseCount: 24, awakeningSuspectedCount: 8)
        )

        #expect(result.score <= 85)
        #expect(result.mainDisturbanceReason.contains("환경 소음"))
        #expect(result.mainDisturbanceReason.contains("각성 의심 구간"))
    }

    @Test
    func shortMeasurementDurationLowersScore() {
        let quiet = SleepScoreCalculator().calculateScore(summary: makeSummary())
        let result = SleepScoreCalculator().calculateScore(
            summary: makeSummary(measurementDuration: 2.5 * 60 * 60, estimatedSleepDuration: 2.5 * 60 * 60)
        )

        #expect(result.score < quiet.score)
        #expect(result.mainDisturbanceReason.contains("측정 시간"))
    }

    @Test
    func scoreIsClampedBetweenZeroAndOneHundred() {
        let clean = SleepScoreCalculator().calculateScore(summary: makeSummary())
        let extreme = SleepScoreCalculator().calculateScore(
            summary: makeSummary(
                measurementDuration: 60 * 60,
                estimatedSleepDuration: 60 * 60,
                snoreTotalSeconds: 60 * 60,
                snoreRatio: 1,
                bruxismLikeCount: 100,
                suspectedPauseCount: 100,
                gaspLikeCount: 100,
                coughLikeCount: 100,
                sleepTalkLikeCount: 100,
                environmentalNoiseCount: 100,
                awakeningSuspectedCount: 100,
                movementLikeCount: 100,
                longestSuspectedPause: 120
            )
        )

        #expect(clean.score == 100)
        #expect(extreme.score == 0)
    }

    @Test
    func makeReportUsesAggregatorCountsAndScore() {
        let calendar = Calendar(identifier: .gregorian)
        let startedAt = calendar.date(from: DateComponents(year: 2026, month: 5, day: 1, hour: 23))!
        let session = SleepSession(
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(8 * 60 * 60),
            measurementDuration: 8 * 60 * 60,
            estimatedSleepDuration: 7 * 60 * 60
        )

        func event(_ type: SleepEventType, minuteOffset: TimeInterval, duration: TimeInterval) -> SleepEvent {
            let eventStart = startedAt.addingTimeInterval(minuteOffset * 60)
            return SleepEvent(
                sessionId: session.id,
                type: type,
                startedAt: eventStart,
                endedAt: eventStart.addingTimeInterval(duration),
                confidence: 0.8,
                intensity: 0.5
            )
        }

        let events = [
            event(.breathingPauseSuspected, minuteOffset: 180, duration: 18),
            event(.snore, minuteOffset: 60, duration: 120),
            event(.bruxismLike, minuteOffset: 120, duration: 8),
            event(.snore, minuteOffset: 90, duration: 180),
            event(.gaspLike, minuteOffset: 181, duration: 4)
        ]

        let report = SleepScoreCalculator().makeReport(session: session, events: events)

        #expect(report.snoreTotalSeconds == 300)
        #expect(report.bruxismLikeCount == 1)
        #expect(report.suspectedPauseCount == 1)
        #expect(report.gaspLikeCount == 1)
        #expect(report.longestSuspectedPause == 18)
        #expect(report.sleepSoundScore >= 0)
        #expect(report.sleepSoundScore <= 100)
        #expect(!report.mainDisturbanceReason.isEmpty)
    }

    @Test
    func mockReportUsesNonDiagnosticLanguage() {
        let bundle = MockSleepDataFactory.latestBundle(now: Date(timeIntervalSince1970: 1_772_496_000))
        let report = bundle.2
        let forbiddenDiagnosticTerm = "수면" + "무호흡"

        #expect(Int(report.snoreTotalSeconds) == 2_520)
        #expect(report.bruxismLikeCount == 3)
        #expect(report.suspectedPauseCount == 5)
        #expect(report.gaspLikeCount == 2)
        #expect(report.coughLikeCount == 12)
        #expect(report.environmentalNoiseCount == 14)
        #expect(report.sleepSoundScore >= 0)
        #expect(report.sleepSoundScore <= 100)
        #expect(!report.mainDisturbanceReason.contains(forbiddenDiagnosticTerm))
    }

    private func makeSummary(
        measurementDuration: TimeInterval = 8 * 60 * 60,
        estimatedSleepDuration: TimeInterval = 7.5 * 60 * 60,
        snoreTotalSeconds: TimeInterval = 0,
        snoreRatio: Double = 0,
        bruxismLikeCount: Int = 0,
        suspectedPauseCount: Int = 0,
        gaspLikeCount: Int = 0,
        coughLikeCount: Int = 0,
        sleepTalkLikeCount: Int = 0,
        environmentalNoiseCount: Int = 0,
        awakeningSuspectedCount: Int = 0,
        movementLikeCount: Int = 0,
        longestSuspectedPause: TimeInterval = 0,
        mostDisturbedHourRange: String? = nil
    ) -> SleepEventSummary {
        SleepEventSummary(
            measurementDuration: measurementDuration,
            estimatedSleepDuration: estimatedSleepDuration,
            snoreTotalSeconds: snoreTotalSeconds,
            snoreRatio: snoreRatio,
            bruxismLikeCount: bruxismLikeCount,
            suspectedPauseCount: suspectedPauseCount,
            gaspLikeCount: gaspLikeCount,
            coughLikeCount: coughLikeCount,
            sleepTalkLikeCount: sleepTalkLikeCount,
            environmentalNoiseCount: environmentalNoiseCount,
            awakeningSuspectedCount: awakeningSuspectedCount,
            movementLikeCount: movementLikeCount,
            longestSuspectedPause: longestSuspectedPause,
            mostDisturbedHourRange: mostDisturbedHourRange
        )
    }
}
