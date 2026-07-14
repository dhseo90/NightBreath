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
    func coughGaspAndNoiseEventsLowerScoreWithoutDiagnosticLanguage() {
        let quiet = SleepScoreCalculator().calculateScore(summary: makeSummary())
        let result = SleepScoreCalculator().calculateScore(
            summary: makeSummary(
                gaspLikeCount: 2,
                coughLikeCount: 10,
                environmentalNoiseCount: 9
            )
        )
        let forbiddenDiagnosticTerm = "수면" + "무호흡"

        #expect(result.score < quiet.score)
        #expect(result.score <= 90)
        #expect(
            result.mainDisturbanceReason.contains("gasp-like 회복 호흡") ||
                result.mainDisturbanceReason.contains("기침 의심 소리") ||
                result.mainDisturbanceReason.contains("환경 소음")
        )
        #expect(!result.mainDisturbanceReason.contains(forbiddenDiagnosticTerm))
    }

    @Test
    func bruxismLikeEventsLowerScoreModerately() {
        let quiet = SleepScoreCalculator().calculateScore(summary: makeSummary())
        let result = SleepScoreCalculator().calculateScore(
            summary: makeSummary(bruxismLikeCount: 6)
        )

        #expect(result.score < quiet.score)
        #expect(result.score >= 88)
        #expect(result.mainDisturbanceReason.contains("이갈이 의심 소리"))
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
        #expect(report.detectedEventDuration == 330)
        #expect(report.longestSuspectedPause == 18)
        #expect(report.sleepSoundScore >= 0)
        #expect(report.sleepSoundScore <= 100)
        #expect(!report.mainDisturbanceReason.isEmpty)
    }

    @Test
    func makeReportIncludesMeasurementQualityFromCaptureMetrics() {
        let startedAt = Date(timeIntervalSince1970: 1_772_496_000)
        let endedAt = startedAt.addingTimeInterval(100)
        let session = SleepSession(
            startedAt: startedAt,
            endedAt: endedAt,
            measurementDuration: 100,
            estimatedSleepDuration: 90
        )
        let metrics = AudioCaptureMetrics(
            captureStartedAt: startedAt,
            captureStoppedAt: endedAt,
            sessionElapsedSeconds: 100,
            captureActiveSeconds: 100,
            receivedAudioSeconds: 70,
            analyzedAudioSeconds: 68,
            receivedChunkCount: 7,
            analyzedChunkCount: 7,
            totalReceivedFrameCount: 3_360_000,
            totalAnalyzedFrameCount: 3_264_000,
            sampleRate: 48_000,
            interruptionCount: 1,
            longestChunkGapSeconds: 8,
            audioCoverageRatio: 0.7
        )

        let report = SleepScoreCalculator().makeReport(
            session: session,
            events: [],
            captureMetrics: metrics
        )

        #expect(report.measurementDuration == 100)
        #expect(report.savedAudioDuration == 0)
        #expect(report.receivedAudioDuration == 70)
        #expect(report.analyzedAudioDuration == 68)
        #expect(report.audioCoverageRatio == 0.7)
        #expect(report.interruptionCount == 1)
        #expect(report.longestAudioGapSeconds == 8)
        #expect(report.measurementQuality == .limited)
    }

    @Test
    func longLowCoverageZeroEventReportDoesNotReadAsQuietNight() {
        let startedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let endedAt = startedAt.addingTimeInterval(8 * 60 * 60)
        let session = SleepSession(
            startedAt: startedAt,
            endedAt: endedAt,
            measurementDuration: 8 * 60 * 60,
            estimatedSleepDuration: 7.5 * 60 * 60
        )
        let metrics = AudioCaptureMetrics(
            captureStartedAt: startedAt,
            captureStoppedAt: endedAt,
            sessionElapsedSeconds: 8 * 60 * 60,
            captureActiveSeconds: 8 * 60 * 60,
            receivedAudioSeconds: 3.5 * 60 * 60,
            analyzedAudioSeconds: 3.4 * 60 * 60,
            receivedChunkCount: 1_260,
            analyzedChunkCount: 1_224,
            interruptionCount: 2,
            longestChunkGapSeconds: 28 * 60,
            audioCoverageRatio: 3.5 / 8
        )

        let report = SleepScoreCalculator().makeReport(
            session: session,
            events: [],
            captureMetrics: metrics
        )

        #expect(report.measurementDuration == 8 * 60 * 60)
        #expect(report.measurementQuality == .poor)
        #expect(report.interruptionCount == 2)
        #expect(report.longestAudioGapSeconds == 28 * 60)
        #expect(report.mainDisturbanceReason.contains("오디오 커버리지"))
        #expect(report.mainDisturbanceReason.contains("참고 범위"))
        #expect(!report.mainDisturbanceReason.contains("조용하고 안정"))
    }

    @Test
    func longLimitedCoverageZeroEventReportKeepsEnvironmentCaveat() {
        let startedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let endedAt = startedAt.addingTimeInterval(4 * 60 * 60)
        let session = SleepSession(
            startedAt: startedAt,
            endedAt: endedAt,
            measurementDuration: 4 * 60 * 60,
            estimatedSleepDuration: 3.8 * 60 * 60
        )
        let metrics = AudioCaptureMetrics(
            captureStartedAt: startedAt,
            captureStoppedAt: endedAt,
            sessionElapsedSeconds: 4 * 60 * 60,
            captureActiveSeconds: 4 * 60 * 60,
            receivedAudioSeconds: 3 * 60 * 60,
            analyzedAudioSeconds: 2.9 * 60 * 60,
            receivedChunkCount: 1_080,
            analyzedChunkCount: 1_044,
            longestChunkGapSeconds: 11 * 60,
            audioCoverageRatio: 0.75
        )

        let report = SleepScoreCalculator().makeReport(
            session: session,
            events: [],
            captureMetrics: metrics
        )

        #expect(report.measurementQuality == .limited)
        #expect(report.mainDisturbanceReason.contains("최종 이벤트가 없더라도"))
        #expect(report.mainDisturbanceReason.contains("커버리지"))
        #expect(!report.mainDisturbanceReason.contains("조용하고 안정"))
    }

    @Test
    func shortLowCoverageZeroEventReportSeparatesShortDurationFromCoverage() {
        let startedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let endedAt = startedAt.addingTimeInterval(2.5 * 60 * 60)
        let session = SleepSession(
            startedAt: startedAt,
            endedAt: endedAt,
            measurementDuration: 2.5 * 60 * 60,
            estimatedSleepDuration: 2.3 * 60 * 60
        )
        let metrics = AudioCaptureMetrics(
            captureStartedAt: startedAt,
            captureStoppedAt: endedAt,
            sessionElapsedSeconds: 2.5 * 60 * 60,
            captureActiveSeconds: 2.5 * 60 * 60,
            receivedAudioSeconds: 45 * 60,
            analyzedAudioSeconds: 40 * 60,
            receivedChunkCount: 270,
            analyzedChunkCount: 240,
            interruptionCount: 1,
            longestChunkGapSeconds: 18 * 60,
            audioCoverageRatio: 0.3
        )

        let report = SleepScoreCalculator().makeReport(
            session: session,
            events: [],
            captureMetrics: metrics
        )

        #expect(report.measurementQuality == .poor)
        #expect(report.mainDisturbanceReason.contains("측정 시간이 짧"))
        #expect(report.mainDisturbanceReason.contains("오디오 수신도 제한적"))
        #expect(report.mainDisturbanceReason.contains("기록된 구간"))
        #expect(!report.mainDisturbanceReason.contains("조용하고 안정"))
    }

    @Test
    func shortExcellentCoverageInterruptionZeroEventReportDoesNotClaimLimitedAudio() {
        let startedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let endedAt = startedAt.addingTimeInterval(2.7 * 60 * 60)
        let session = SleepSession(
            startedAt: startedAt,
            endedAt: endedAt,
            measurementDuration: 2.7 * 60 * 60,
            estimatedSleepDuration: 2.7 * 60 * 60
        )
        let metrics = AudioCaptureMetrics(
            captureStartedAt: startedAt,
            captureStoppedAt: endedAt,
            sessionElapsedSeconds: 2.7 * 60 * 60,
            captureActiveSeconds: 2.7 * 60 * 60,
            receivedAudioSeconds: 2.68 * 60 * 60,
            analyzedAudioSeconds: 2.68 * 60 * 60,
            receivedChunkCount: 96_400,
            analyzedChunkCount: 96_400,
            interruptionCount: 1,
            longestChunkGapSeconds: 0.02,
            audioCoverageRatio: 0.996
        )

        let report = SleepScoreCalculator().makeReport(
            session: session,
            events: [],
            captureMetrics: metrics
        )

        #expect(report.measurementQuality == .excellent)
        #expect(report.mainDisturbanceReason.contains("측정 시간이 짧"))
        #expect(report.mainDisturbanceReason.contains("중단 기록"))
        #expect(!report.mainDisturbanceReason.contains("오디오 수신도 제한적"))
    }

    @Test
    func legacyShortInterruptionReasonDecodesToInterruptionSpecificCopy() throws {
        let legacyReason = "측정 시간이 짧고 오디오 수신도 제한적이어서 오늘 리포트는 기록된 구간만 참고용으로 확인해 주세요."
        let report = NightReport(
            sessionId: UUID(),
            measurementDuration: 2.7 * 60 * 60,
            estimatedSleepDuration: 2.7 * 60 * 60,
            receivedAudioDuration: 2.68 * 60 * 60,
            analyzedAudioDuration: 2.68 * 60 * 60,
            audioCoverageRatio: 0.996,
            interruptionCount: 1,
            longestAudioGapSeconds: 0.02,
            measurementQuality: .excellent,
            sleepSoundScore: 86,
            snoreTotalSeconds: 0,
            snoreRatio: 0,
            bruxismLikeCount: 0,
            suspectedPauseCount: 0,
            gaspLikeCount: 0,
            coughLikeCount: 0,
            sleepTalkLikeCount: 0,
            environmentalNoiseCount: 0,
            awakeningSuspectedCount: 0,
            longestSuspectedPause: 0,
            mostDisturbedHourRange: nil,
            mainDisturbanceReason: legacyReason
        )

        let data = try JSONEncoder().encode(report)
        let decoded = try JSONDecoder().decode(NightReport.self, from: data)

        #expect(decoded.mainDisturbanceReason.contains("중단 기록"))
        #expect(!decoded.mainDisturbanceReason.contains("오디오 수신도 제한적"))
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
