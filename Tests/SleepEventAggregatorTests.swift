import Foundation
import Testing
@testable import SleepSoundCore

@Suite("SleepEventAggregator")
struct SleepEventAggregatorTests {
    @Test
    func aggregatorSummarizesCountsDurationsAndRatios() {
        let calendar = Calendar(identifier: .gregorian)
        let startedAt = calendar.date(from: DateComponents(year: 2026, month: 5, day: 1, hour: 23, minute: 0))!
        let session = SleepSession(
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(8 * 60 * 60),
            measurementDuration: 8 * 60 * 60,
            estimatedSleepDuration: 7 * 60 * 60,
            devicePlacement: .bedside
        )
        let otherSessionId = UUID()

        func makeEvent(
            _ type: SleepEventType,
            hour: Int,
            minute: Int,
            duration: TimeInterval,
            sessionId: UUID = session.id,
            confidence: Double = 0.8
        ) -> SleepEvent {
            let date = calendar.date(from: DateComponents(year: 2026, month: 5, day: 2, hour: hour, minute: minute))!
            return SleepEvent(
                sessionId: sessionId,
                type: type,
                startedAt: date,
                endedAt: date.addingTimeInterval(duration),
                confidence: confidence,
                intensity: 0.5
            )
        }

        var events: [SleepEvent] = []
        events.append(makeEvent(.snore, hour: 1, minute: 0, duration: 60))
        events.append(makeEvent(.snore, hour: 1, minute: 20, duration: 30))
        events.append(makeEvent(.breathingPauseSuspected, hour: 2, minute: 3, duration: 20, confidence: 0.9))
        events.append(makeEvent(.breathingPauseSuspected, hour: 2, minute: 30, duration: 12, confidence: 0.7))
        events.append(makeEvent(.gaspLike, hour: 2, minute: 4, duration: 5))
        events.append(makeEvent(.environmentalNoise, hour: 4, minute: 10, duration: 8))
        events.append(makeEvent(.snore, hour: 1, minute: 40, duration: 600, sessionId: otherSessionId))

        let summary = SleepEventAggregator().summarize(session: session, events: events)
        let expectedRatio = 90.0 / Double(7 * 60 * 60)

        #expect(summary.snoreTotalSeconds == 90)
        #expect(abs(summary.snoreRatio - expectedRatio) < 0.0001)
        #expect(summary.suspectedPauseCount == 2)
        #expect(summary.gaspLikeCount == 1)
        #expect(summary.environmentalNoiseCount == 1)
        #expect(summary.longestSuspectedPause == 20)
        #expect(summary.mostDisturbedHourRange == "02:00~03:00")
    }

    @Test
    func aggregatorReturnsEmptyDisturbedRangeWhenNoEventsExist() {
        let session = SleepSession(
            startedAt: Date(),
            measurementDuration: 8 * 60 * 60,
            estimatedSleepDuration: 7 * 60 * 60
        )

        let summary = SleepEventAggregator().summarize(session: session, events: [])

        #expect(summary.snoreTotalSeconds == 0)
        #expect(summary.snoreRatio == 0)
        #expect(summary.mostDisturbedHourRange == nil)
    }
}
