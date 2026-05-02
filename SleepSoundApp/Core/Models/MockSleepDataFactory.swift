import Foundation

public enum MockSleepDataFactory {
    public static func latestBundle(now: Date = Date()) -> (SleepSession, [SleepEvent], NightReport, MorningCheckIn) {
        let session = sampleSession(now: now)
        let events = sampleEvents(for: session)
        let report = SleepScoreCalculator().makeReport(session: session, events: events)
        let checkIn = MorningCheckIn(
            sessionId: session.id,
            refreshScore: 3,
            fatigueScore: 4,
            headache: false,
            dryMouth: true,
            soreThroat: false,
            rememberedAwakenings: 2,
            memo: "새벽에 두 번 정도 깬 느낌이 있었음"
        )
        return (session, events, report, checkIn)
    }

    public static func sampleSession(now: Date = Date()) -> SleepSession {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: now)
        let startedAt = calendar.date(byAdding: .day, value: -1, to: today)?
            .addingTimeInterval(23 * 60 * 60 + 55 * 60) ?? now.addingTimeInterval(-7.7 * 60 * 60)
        let endedAt = today.addingTimeInterval(7 * 60 * 60 + 37 * 60)
        let estimatedSleepStart = today.addingTimeInterval(18 * 60)
        let estimatedWakeTime = today.addingTimeInterval(7 * 60 * 60 + 16 * 60)

        return SleepSession(
            startedAt: startedAt,
            endedAt: endedAt,
            estimatedSleepStart: estimatedSleepStart,
            estimatedWakeTime: estimatedWakeTime,
            measurementDuration: endedAt.timeIntervalSince(startedAt),
            estimatedSleepDuration: estimatedWakeTime.timeIntervalSince(estimatedSleepStart),
            devicePlacement: .bedside,
            ambientNoiseBaseline: 0.18,
            appVersion: "1.0",
            modelVersion: "mock-rule-v1"
        )
    }

    public static func sampleEvents(for session: SleepSession) -> [SleepEvent] {
        let calendar = Calendar(identifier: .gregorian)
        let startDay = calendar.startOfDay(for: session.startedAt)

        func eventDate(hour: Int, minute: Int, second: Int = 0) -> Date {
            var date = startDay
            if hour < 12 {
                date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            }
            return date.addingTimeInterval(TimeInterval(hour * 60 * 60 + minute * 60 + second))
        }

        func make(
            _ type: SleepEventType,
            hour: Int,
            minute: Int,
            duration: TimeInterval,
            confidence: Double,
            intensity: Double
        ) -> SleepEvent {
            let startedAt = eventDate(hour: hour, minute: minute)
            return SleepEvent(
                sessionId: session.id,
                type: type,
                startedAt: startedAt,
                endedAt: startedAt.addingTimeInterval(duration),
                confidence: confidence,
                intensity: intensity
            )
        }

        var events: [SleepEvent] = [
            make(.snore, hour: 0, minute: 42, duration: 600, confidence: 0.72, intensity: 0.62),
            make(.snore, hour: 1, minute: 8, duration: 480, confidence: 0.69, intensity: 0.58),
            make(.snore, hour: 2, minute: 26, duration: 420, confidence: 0.67, intensity: 0.55),
            make(.snore, hour: 3, minute: 9, duration: 360, confidence: 0.74, intensity: 0.66),
            make(.snore, hour: 3, minute: 38, duration: 420, confidence: 0.76, intensity: 0.64),
            make(.snore, hour: 4, minute: 31, duration: 240, confidence: 0.62, intensity: 0.5),
            make(.bruxismLike, hour: 1, minute: 52, duration: 8, confidence: 0.57, intensity: 0.46),
            make(.bruxismLike, hour: 3, minute: 18, duration: 11, confidence: 0.61, intensity: 0.52),
            make(.bruxismLike, hour: 4, minute: 6, duration: 7, confidence: 0.54, intensity: 0.44),
            make(.breathingPauseSuspected, hour: 2, minute: 58, duration: 14, confidence: 0.5, intensity: 0.35),
            make(.breathingPauseSuspected, hour: 3, minute: 16, duration: 19, confidence: 0.56, intensity: 0.39),
            make(.breathingPauseSuspected, hour: 3, minute: 44, duration: 22, confidence: 0.58, intensity: 0.42),
            make(.breathingPauseSuspected, hour: 4, minute: 12, duration: 16, confidence: 0.52, intensity: 0.34),
            make(.breathingPauseSuspected, hour: 5, minute: 3, duration: 13, confidence: 0.49, intensity: 0.32),
            make(.gaspLike, hour: 3, minute: 17, duration: 4, confidence: 0.55, intensity: 0.5),
            make(.gaspLike, hour: 3, minute: 45, duration: 5, confidence: 0.57, intensity: 0.53),
            make(.awakeningSuspected, hour: 0, minute: 18, duration: 180, confidence: 0.5, intensity: 0.36),
            make(.awakeningSuspected, hour: 2, minute: 59, duration: 240, confidence: 0.56, intensity: 0.41),
            make(.awakeningSuspected, hour: 3, minute: 46, duration: 260, confidence: 0.6, intensity: 0.43),
            make(.awakeningSuspected, hour: 4, minute: 15, duration: 160, confidence: 0.52, intensity: 0.34),
            make(.awakeningSuspected, hour: 5, minute: 5, duration: 180, confidence: 0.51, intensity: 0.36),
            make(.awakeningSuspected, hour: 6, minute: 42, duration: 210, confidence: 0.53, intensity: 0.35),
            make(.movementLike, hour: 3, minute: 14, duration: 42, confidence: 0.64, intensity: 0.47),
            make(.movementLike, hour: 3, minute: 49, duration: 36, confidence: 0.62, intensity: 0.45),
            make(.movementLike, hour: 4, minute: 17, duration: 28, confidence: 0.55, intensity: 0.4),
            make(.sleepTalkLike, hour: 1, minute: 36, duration: 9, confidence: 0.44, intensity: 0.37),
            make(.sleepTalkLike, hour: 5, minute: 28, duration: 12, confidence: 0.46, intensity: 0.35)
        ]

        for minute in [6, 17, 24, 37, 45, 52, 63, 71, 86, 94, 118, 132] {
            let hour = 1 + minute / 60
            events.append(make(.coughLike, hour: hour, minute: minute % 60, duration: 3, confidence: 0.5, intensity: 0.38))
        }

        for minute in [12, 31, 44, 59, 76, 88, 103, 120, 137, 151, 169, 188, 207, 225] {
            let hour = 0 + minute / 60
            events.append(make(.environmentalNoise, hour: hour, minute: minute % 60, duration: 5, confidence: 0.47, intensity: 0.41))
        }

        return events.sorted { $0.startedAt < $1.startedAt }
    }
}
