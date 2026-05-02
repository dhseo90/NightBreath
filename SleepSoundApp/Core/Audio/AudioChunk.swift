import Foundation

public struct AudioChunk: Equatable {
    public var id: UUID
    public var samples: [Float]
    public var sampleRate: Double
    public var startedAt: Date
    public var duration: TimeInterval

    public init(
        id: UUID = UUID(),
        samples: [Float],
        sampleRate: Double,
        startedAt: Date,
        duration: TimeInterval
    ) {
        self.id = id
        self.samples = samples
        self.sampleRate = sampleRate
        self.startedAt = startedAt
        self.duration = duration
    }
}
