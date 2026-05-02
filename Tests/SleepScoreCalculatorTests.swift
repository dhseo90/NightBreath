import Foundation
import Testing
@testable import SleepSoundCore

@Suite("SleepScoreCalculator")
struct SleepScoreCalculatorTests {
    @Test
    func cleanNightKeepsPerfectScore() {
        let summary = SleepEventSummary(
            measurementDuration: 8 * 60 * 60,
            estimatedSleepDuration: 7.5 * 60 * 60,
            snoreTotalSeconds: 0,
            snoreRatio: 0,
            bruxismLikeCount: 0,
            suspectedPauseCount: 0,
            gaspLikeCount: 0,
            coughLikeCount: 0,
            sleepTalkLikeCount: 0,
            environmentalNoiseCount: 0,
            awakeningSuspectedCount: 0,
            movementLikeCount: 0,
            longestSuspectedPause: 0,
            mostDisturbedHourRange: nil
        )

        let result = SleepScoreCalculator().calculateScore(summary: summary)

        #expect(result.score == 100)
        #expect(result.mainDisturbanceReason.contains("안정"))
    }

    @Test
    func noisyNightClampsScoreAtZeroAndExplainsMainReason() {
        let summary = SleepEventSummary(
            measurementDuration: 3 * 60 * 60,
            estimatedSleepDuration: 2.5 * 60 * 60,
            snoreTotalSeconds: 2 * 60 * 60,
            snoreRatio: 0.8,
            bruxismLikeCount: 30,
            suspectedPauseCount: 30,
            gaspLikeCount: 20,
            coughLikeCount: 60,
            sleepTalkLikeCount: 10,
            environmentalNoiseCount: 60,
            awakeningSuspectedCount: 30,
            movementLikeCount: 30,
            longestSuspectedPause: 45,
            mostDisturbedHourRange: "03:00~04:00"
        )

        let result = SleepScoreCalculator().calculateScore(summary: summary)

        #expect(result.score == 0)
        #expect(result.mainDisturbanceReason.contains("호흡정지 의심 구간"))
        let forbiddenDiagnosticTerm = "수면" + "무호흡"
        #expect(!result.mainDisturbanceReason.contains(forbiddenDiagnosticTerm))
    }

    @Test
    func reportUsesMockMetricsWithoutDiagnosticLanguage() {
        let bundle = MockSleepDataFactory.latestBundle(now: Date(timeIntervalSince1970: 1_772_496_000))
        let report = bundle.2

        #expect(Int(report.snoreTotalSeconds) == 2_520)
        #expect(report.bruxismLikeCount == 3)
        #expect(report.suspectedPauseCount == 5)
        #expect(report.gaspLikeCount == 2)
        #expect(report.coughLikeCount == 12)
        #expect(report.environmentalNoiseCount == 14)
        #expect(report.sleepSoundScore > 50)
        #expect(report.sleepSoundScore <= 100)
        let forbiddenDiagnosticTerm = "수면" + "무호흡"
        #expect(!report.mainDisturbanceReason.contains(forbiddenDiagnosticTerm))
    }
}
