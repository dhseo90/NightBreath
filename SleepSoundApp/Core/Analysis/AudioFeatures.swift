import Foundation

public struct AudioFeatures: Equatable, Sendable {
    public var startedAt: Date
    public var endedAt: Date
    public var sampleRate: Double
    public var channelCount: Int
    public var frameCount: Int
    public var rms: Double
    public var energy: Double
    public var peak: Double
    public var zeroCrossingRate: Double
    public var lowFrequencyEnergyRatio: Double
    public var highFrequencyActivity: Double
    public var spectralCentroid: Double?
    public var spectralFlatness: Double?
    public var isLikelySilence: Bool

    public var duration: TimeInterval {
        max(0, endedAt.timeIntervalSince(startedAt))
    }

    public init(
        startedAt: Date = Date(),
        duration: TimeInterval = 1,
        sampleRate: Double = 16_000,
        channelCount: Int = 1,
        frameCount: Int = 0,
        rms: Double,
        energy: Double? = nil,
        peak: Double,
        zeroCrossingRate: Double,
        lowFrequencyEnergyRatio: Double,
        highFrequencyActivity: Double? = nil,
        spectralCentroid: Double? = nil,
        spectralFlatness: Double? = nil,
        isLikelySilence: Bool? = nil
    ) {
        let safeDuration = max(0, duration)
        let safeRMS = Self.clamp(rms)
        let safeZeroCrossingRate = Self.clamp(zeroCrossingRate)
        let safeLowFrequencyEnergyRatio = Self.clamp(lowFrequencyEnergyRatio)

        self.startedAt = startedAt
        self.endedAt = startedAt.addingTimeInterval(safeDuration)
        self.sampleRate = max(1, sampleRate)
        self.channelCount = max(1, channelCount)
        self.frameCount = max(0, frameCount)
        self.rms = safeRMS
        self.energy = max(0, energy ?? safeRMS * safeRMS)
        self.peak = Self.clamp(peak)
        self.zeroCrossingRate = safeZeroCrossingRate
        self.lowFrequencyEnergyRatio = safeLowFrequencyEnergyRatio
        self.highFrequencyActivity = Self.clamp(highFrequencyActivity ?? safeZeroCrossingRate)
        self.spectralCentroid = spectralCentroid
        self.spectralFlatness = spectralFlatness
        self.isLikelySilence = isLikelySilence ?? (safeRMS < 0.01)
    }

    private static func clamp(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }
}
