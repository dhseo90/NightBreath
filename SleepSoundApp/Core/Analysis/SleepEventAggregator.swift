import Foundation

public struct SleepEventSummary: Equatable {
    public var measurementDuration: TimeInterval
    public var estimatedSleepDuration: TimeInterval
    public var snoreTotalSeconds: TimeInterval
    public var snoreRatio: Double
    public var bruxismLikeCount: Int
    public var suspectedPauseCount: Int
    public var gaspLikeCount: Int
    public var coughLikeCount: Int
    public var sleepTalkLikeCount: Int
    public var environmentalNoiseCount: Int
    public var awakeningSuspectedCount: Int
    public var movementLikeCount: Int
    public var longestSuspectedPause: TimeInterval
    public var mostDisturbedHourRange: String?

    public init(
        measurementDuration: TimeInterval,
        estimatedSleepDuration: TimeInterval,
        snoreTotalSeconds: TimeInterval,
        snoreRatio: Double,
        bruxismLikeCount: Int,
        suspectedPauseCount: Int,
        gaspLikeCount: Int,
        coughLikeCount: Int,
        sleepTalkLikeCount: Int,
        environmentalNoiseCount: Int,
        awakeningSuspectedCount: Int,
        movementLikeCount: Int,
        longestSuspectedPause: TimeInterval,
        mostDisturbedHourRange: String?
    ) {
        self.measurementDuration = measurementDuration
        self.estimatedSleepDuration = estimatedSleepDuration
        self.snoreTotalSeconds = snoreTotalSeconds
        self.snoreRatio = snoreRatio
        self.bruxismLikeCount = bruxismLikeCount
        self.suspectedPauseCount = suspectedPauseCount
        self.gaspLikeCount = gaspLikeCount
        self.coughLikeCount = coughLikeCount
        self.sleepTalkLikeCount = sleepTalkLikeCount
        self.environmentalNoiseCount = environmentalNoiseCount
        self.awakeningSuspectedCount = awakeningSuspectedCount
        self.movementLikeCount = movementLikeCount
        self.longestSuspectedPause = longestSuspectedPause
        self.mostDisturbedHourRange = mostDisturbedHourRange
    }
}

public struct SleepEventAggregator {
    public init() {}

    public func summarize(session: SleepSession, events: [SleepEvent]) -> SleepEventSummary {
        let sessionEvents = normalizedEvents(for: session, events: events)
        let measurementDuration = normalizedMeasurementDuration(for: session)
        let estimatedSleepDuration = normalizedEstimatedSleepDuration(for: session, measurementDuration: measurementDuration)
        let denominator = max(estimatedSleepDuration, 1)
        let snoreTotalSeconds = sessionEvents
            .filter { $0.type == .snore }
            .reduce(0) { $0 + $1.duration }

        let suspectedPauses = sessionEvents.filter { $0.type == .breathingPauseSuspected }

        return SleepEventSummary(
            measurementDuration: measurementDuration,
            estimatedSleepDuration: estimatedSleepDuration,
            snoreTotalSeconds: snoreTotalSeconds,
            snoreRatio: min(max(snoreTotalSeconds / denominator, 0), 1),
            bruxismLikeCount: count(.bruxismLike, in: sessionEvents),
            suspectedPauseCount: suspectedPauses.count,
            gaspLikeCount: count(.gaspLike, in: sessionEvents),
            coughLikeCount: count(.coughLike, in: sessionEvents),
            sleepTalkLikeCount: count(.sleepTalkLike, in: sessionEvents),
            environmentalNoiseCount: count(.environmentalNoise, in: sessionEvents),
            awakeningSuspectedCount: count(.awakeningSuspected, in: sessionEvents),
            movementLikeCount: count(.movementLike, in: sessionEvents),
            longestSuspectedPause: suspectedPauses.map(\.duration).max() ?? 0,
            mostDisturbedHourRange: mostDisturbedHourRange(from: sessionEvents)
        )
    }

    private func normalizedEvents(for session: SleepSession, events: [SleepEvent]) -> [SleepEvent] {
        events.filter { event in
            guard event.sessionId == session.id else { return false }
            guard event.type != .unknown else { return false }

            let rawDuration = event.endedAt.timeIntervalSince(event.startedAt)
            guard rawDuration.isFinite, rawDuration > 0 else { return false }

            return event.startedAt.timeIntervalSinceReferenceDate.isFinite &&
                event.endedAt.timeIntervalSinceReferenceDate.isFinite
        }
    }

    private func normalizedMeasurementDuration(for session: SleepSession) -> TimeInterval {
        if session.measurementDuration.isFinite, session.measurementDuration > 0 {
            return session.measurementDuration
        }

        if let endedAt = session.endedAt {
            let inferredDuration = endedAt.timeIntervalSince(session.startedAt)
            if inferredDuration.isFinite, inferredDuration > 0 {
                return inferredDuration
            }
        }

        return 0
    }

    private func normalizedEstimatedSleepDuration(
        for session: SleepSession,
        measurementDuration: TimeInterval
    ) -> TimeInterval {
        if session.estimatedSleepDuration.isFinite, session.estimatedSleepDuration > 0 {
            return session.estimatedSleepDuration
        }

        if let estimatedSleepStart = session.estimatedSleepStart,
           let estimatedWakeTime = session.estimatedWakeTime {
            let inferredDuration = estimatedWakeTime.timeIntervalSince(estimatedSleepStart)
            if inferredDuration.isFinite, inferredDuration > 0 {
                return inferredDuration
            }
        }

        return measurementDuration
    }

    private func count(_ type: SleepEventType, in events: [SleepEvent]) -> Int {
        events.filter { $0.type == type }.count
    }

    private func mostDisturbedHourRange(from events: [SleepEvent]) -> String? {
        let weightedEvents = events.filter { $0.type != .unknown }
        guard !weightedEvents.isEmpty else { return nil }

        let calendar = Calendar(identifier: .gregorian)
        let scoresByHour = weightedEvents.reduce(into: [Int: Double]()) { partialResult, event in
            guard event.duration.isFinite, event.duration > 0 else { return }
            let hour = calendar.component(.hour, from: event.startedAt)
            partialResult[hour, default: 0] += disturbanceWeight(for: event)
        }

        guard let hour = scoresByHour.max(by: { $0.value < $1.value })?.key else {
            return nil
        }

        return String(format: "%02d:00~%02d:00", hour, (hour + 1) % 24)
    }

    private func disturbanceWeight(for event: SleepEvent) -> Double {
        guard event.duration.isFinite, event.duration > 0 else { return 0 }

        let durationWeight = max(1, event.duration / 60)
        let typeWeight: Double

        switch event.type {
        case .breathingPauseSuspected:
            typeWeight = 2.5
        case .gaspLike, .awakeningSuspected:
            typeWeight = 2
        case .bruxismLike, .movementLike:
            typeWeight = 1.5
        case .snore:
            typeWeight = 1.2
        case .coughLike, .environmentalNoise, .sleepTalkLike:
            typeWeight = 1
        case .unknown:
            typeWeight = 0
        }

        return durationWeight * typeWeight * max(event.confidence, 0.2)
    }
}
