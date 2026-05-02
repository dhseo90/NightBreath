import Foundation
import Testing
@testable import SleepSoundCore

@Suite("SleepEventAggregator")
struct SleepEventAggregatorTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test
    func aggregatesUnsortedEventsAndIgnoresInvalidDurations() {
        let session = makeSession()
        let otherSessionId = UUID()

        let events = [
            makeEvent(.environmentalNoise, session: session, hour: 4, minute: 10, duration: 8),
            makeEvent(.snore, session: session, hour: 1, minute: 20, duration: 30),
            makeEvent(.breathingPauseSuspected, session: session, hour: 2, minute: 3, duration: 20),
            makeEvent(.bruxismLike, session: session, hour: 3, minute: 4, duration: 6),
            makeEvent(.sleepTalkLike, session: session, hour: 5, minute: 5, duration: 10),
            makeEvent(.gaspLike, session: session, hour: 2, minute: 4, duration: 5),
            makeEvent(.coughLike, session: session, hour: 6, minute: 0, duration: 4),
            makeEvent(.awakeningSuspected, session: session, hour: 6, minute: 10, duration: 120),
            makeEvent(.movementLike, session: session, hour: 6, minute: 12, duration: 20),
            makeEvent(.snore, session: session, hour: 1, minute: 0, duration: 60),
            makeEvent(.snore, session: session, hour: 1, minute: 40, duration: 600, sessionId: otherSessionId),
            makeEvent(.snore, session: session, hour: 1, minute: 50, duration: -30),
            makeEvent(.unknown, session: session, hour: 1, minute: 55, duration: 30)
        ]

        let summary = SleepEventAggregator().summarize(session: session, events: events)
        let expectedRatio = 90.0 / Double(7 * 60 * 60)

        #expect(summary.measurementDuration == 8 * 60 * 60)
        #expect(summary.estimatedSleepDuration == 7 * 60 * 60)
        #expect(summary.snoreTotalSeconds == 90)
        #expect(abs(summary.snoreRatio - expectedRatio) < 0.0001)
        #expect(summary.bruxismLikeCount == 1)
        #expect(summary.suspectedPauseCount == 1)
        #expect(summary.gaspLikeCount == 1)
        #expect(summary.coughLikeCount == 1)
        #expect(summary.sleepTalkLikeCount == 1)
        #expect(summary.environmentalNoiseCount == 1)
        #expect(summary.awakeningSuspectedCount == 1)
        #expect(summary.movementLikeCount == 1)
        #expect(summary.detectedEventDuration == 283)
    }

    @Test
    func calculatesLongestSuspectedPauseFromMixedOrderEvents() {
        let session = makeSession()
        let events = [
            makeEvent(.breathingPauseSuspected, session: session, hour: 3, minute: 20, duration: 18),
            makeEvent(.breathingPauseSuspected, session: session, hour: 2, minute: 10, duration: 42),
            makeEvent(.breathingPauseSuspected, session: session, hour: 4, minute: 10, duration: 12),
            makeEvent(.breathingPauseSuspected, session: session, hour: 5, minute: 10, duration: -60)
        ]

        let summary = SleepEventAggregator().summarize(session: session, events: events)

        #expect(summary.suspectedPauseCount == 3)
        #expect(summary.longestSuspectedPause == 42)
    }

    @Test
    func countsCoughGaspAndEnvironmentalNoiseSeparately() {
        let session = makeSession()
        let events = [
            makeEvent(.coughLike, session: session, hour: 1, minute: 0, duration: 1),
            makeEvent(.coughLike, session: session, hour: 1, minute: 2, duration: 1),
            makeEvent(.gaspLike, session: session, hour: 2, minute: 0, duration: 2),
            makeEvent(.environmentalNoise, session: session, hour: 3, minute: 0, duration: 10),
            makeEvent(.environmentalNoise, session: session, hour: 3, minute: 5, duration: 8),
            makeEvent(.environmentalNoise, session: session, hour: 3, minute: 10, duration: 6),
            makeEvent(.unknown, session: session, hour: 4, minute: 0, duration: 5)
        ]

        let summary = SleepEventAggregator().summarize(session: session, events: events)

        #expect(summary.coughLikeCount == 2)
        #expect(summary.gaspLikeCount == 1)
        #expect(summary.environmentalNoiseCount == 3)
    }

    @Test
    func countsBruxismLikeEventsSeparately() {
        let session = makeSession()
        let events = [
            makeEvent(.bruxismLike, session: session, hour: 1, minute: 0, duration: 1),
            makeEvent(.bruxismLike, session: session, hour: 1, minute: 5, duration: 1),
            makeEvent(.movementLike, session: session, hour: 2, minute: 0, duration: 4),
            makeEvent(.unknown, session: session, hour: 2, minute: 5, duration: 2)
        ]

        let summary = SleepEventAggregator().summarize(session: session, events: events)

        #expect(summary.bruxismLikeCount == 2)
        #expect(summary.movementLikeCount == 1)
    }

    @Test
    func detectedEventDurationMergesOverlappingEvents() {
        let session = makeSession()
        let events = [
            makeEvent(.coughLike, session: session, hour: 1, minute: 0, duration: 10),
            makeEvent(.snore, session: session, hour: 1, minute: 0, duration: 15),
            makeEvent(.movementLike, session: session, hour: 1, minute: 1, duration: 5),
            makeEvent(.unknown, session: session, hour: 1, minute: 2, duration: 20)
        ]

        let summary = SleepEventAggregator().summarize(session: session, events: events)

        #expect(summary.detectedEventDuration == 20)
    }

    @Test
    func returnsEmptySummaryWhenThereAreNoValidEvents() {
        let session = makeSession()
        let events = [
            makeEvent(.snore, session: session, hour: 1, minute: 0, duration: -10),
            makeEvent(.unknown, session: session, hour: 1, minute: 10, duration: 10)
        ]

        let summary = SleepEventAggregator().summarize(session: session, events: events)

        #expect(summary.snoreTotalSeconds == 0)
        #expect(summary.snoreRatio == 0)
        #expect(summary.suspectedPauseCount == 0)
        #expect(summary.longestSuspectedPause == 0)
        #expect(summary.mostDisturbedHourRange == nil)
    }

    @Test
    func infersDurationsWhenSessionDurationFieldsAreMissing() {
        let startedAt = date(day: 1, hour: 23, minute: 0)
        let endedAt = startedAt.addingTimeInterval(6 * 60 * 60)
        let sleepStart = startedAt.addingTimeInterval(30 * 60)
        let wakeTime = startedAt.addingTimeInterval(5.5 * 60 * 60)
        let session = SleepSession(
            startedAt: startedAt,
            endedAt: endedAt,
            estimatedSleepStart: sleepStart,
            estimatedWakeTime: wakeTime,
            measurementDuration: -1,
            estimatedSleepDuration: -1
        )

        let summary = SleepEventAggregator().summarize(session: session, events: [])

        #expect(summary.measurementDuration == 6 * 60 * 60)
        #expect(summary.estimatedSleepDuration == 5 * 60 * 60)
    }

    private func makeSession() -> SleepSession {
        let startedAt = date(day: 1, hour: 23, minute: 0)
        return SleepSession(
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(8 * 60 * 60),
            measurementDuration: 8 * 60 * 60,
            estimatedSleepDuration: 7 * 60 * 60,
            devicePlacement: .bedside
        )
    }

    private func makeEvent(
        _ type: SleepEventType,
        session: SleepSession,
        hour: Int,
        minute: Int,
        duration: TimeInterval,
        sessionId: UUID? = nil,
        confidence: Double = 0.8
    ) -> SleepEvent {
        let startedAt = date(day: 2, hour: hour, minute: minute)
        return SleepEvent(
            sessionId: sessionId ?? session.id,
            type: type,
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(duration),
            confidence: confidence,
            intensity: 0.5
        )
    }

    private func date(day: Int, hour: Int, minute: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 5, day: day, hour: hour, minute: minute))!
    }
}
