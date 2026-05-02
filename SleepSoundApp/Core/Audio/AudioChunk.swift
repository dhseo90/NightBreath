import Foundation

public struct AudioChunk: Equatable, Sendable, Identifiable {
    public var id: UUID
    public var timestamp: Date
    public var sampleRate: Double
    public var channelCount: Int
    public var frameCount: Int
    public var duration: TimeInterval
    public var rms: Double
    public var samples: [Float]

    public var startedAt: Date {
        timestamp
    }

    public var basicLevel: Double {
        rms
    }

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        sampleRate: Double,
        channelCount: Int,
        frameCount: Int,
        duration: TimeInterval,
        rms: Double,
        samples: [Float] = []
    ) {
        self.id = id
        self.timestamp = timestamp
        self.sampleRate = sampleRate
        self.channelCount = max(1, channelCount)
        self.frameCount = max(0, frameCount)
        self.duration = max(0, duration)
        self.rms = min(max(rms, 0), 1)
        self.samples = samples
    }

    public init(
        id: UUID = UUID(),
        samples: [Float],
        sampleRate: Double,
        startedAt: Date,
        duration: TimeInterval
    ) {
        self.init(
            id: id,
            timestamp: startedAt,
            sampleRate: sampleRate,
            channelCount: 1,
            frameCount: samples.count,
            duration: duration,
            rms: AudioChunk.calculateRMS(samples),
            samples: samples
        )
    }

    public static func calculateRMS(_ samples: [Float]) -> Double {
        guard !samples.isEmpty else { return 0 }

        let squareSum = samples.reduce(0.0) { partialResult, sample in
            let value = Double(sample)
            return partialResult + value * value
        }

        return min(max(sqrt(squareSum / Double(samples.count)), 0), 1)
    }
}
