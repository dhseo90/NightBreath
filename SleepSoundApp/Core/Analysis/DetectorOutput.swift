import Foundation

public struct DetectorOutput: Equatable {
    public var type: SleepEventType
    public var startedAt: Date
    public var endedAt: Date
    public var confidence: Double
    public var intensity: Double

    public init(
        type: SleepEventType,
        startedAt: Date,
        endedAt: Date,
        confidence: Double,
        intensity: Double
    ) {
        self.type = type
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.confidence = min(max(confidence, 0), 1)
        self.intensity = min(max(intensity, 0), 1)
    }

    public func makeEvent(sessionId: UUID) -> SleepEvent {
        SleepEvent(
            sessionId: sessionId,
            type: type,
            startedAt: startedAt,
            endedAt: endedAt,
            confidence: confidence,
            intensity: intensity
        )
    }
}
