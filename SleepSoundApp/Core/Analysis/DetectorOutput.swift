import Foundation

public struct DetectorOutput: Equatable, Sendable {
    public var eventType: SleepEventType
    public var startedAt: Date
    public var endedAt: Date
    public var confidence: Double
    public var intensity: Double
    public var debugReason: String?

    public var type: SleepEventType {
        get { eventType }
        set { eventType = newValue }
    }

    public var duration: TimeInterval {
        max(0, endedAt.timeIntervalSince(startedAt))
    }

    public init(
        eventType: SleepEventType,
        startedAt: Date,
        endedAt: Date,
        confidence: Double,
        intensity: Double,
        debugReason: String? = nil
    ) {
        self.eventType = eventType
        self.startedAt = startedAt
        self.endedAt = max(startedAt, endedAt)
        self.confidence = min(max(confidence, 0), 1)
        self.intensity = min(max(intensity, 0), 1)
        self.debugReason = debugReason
    }

    public init(
        type: SleepEventType,
        startedAt: Date,
        endedAt: Date,
        confidence: Double,
        intensity: Double,
        debugReason: String? = nil
    ) {
        self.init(
            eventType: type,
            startedAt: startedAt,
            endedAt: endedAt,
            confidence: confidence,
            intensity: intensity,
            debugReason: debugReason
        )
    }

    public func makeEvent(sessionId: UUID) -> SleepEvent {
        DetectorOutputMapper.makeEvent(from: self, sessionId: sessionId)
    }
}

public enum DetectorOutputMapper {
    public static func makeEvent(from output: DetectorOutput, sessionId: UUID) -> SleepEvent {
        SleepEvent(
            sessionId: sessionId,
            type: output.eventType,
            startedAt: output.startedAt,
            endedAt: output.endedAt,
            confidence: output.confidence,
            intensity: output.intensity
        )
    }

    public static func makeEvents(from outputs: [DetectorOutput], sessionId: UUID) -> [SleepEvent] {
        outputs.map { output in
            makeEvent(from: output, sessionId: sessionId)
        }
    }
}
