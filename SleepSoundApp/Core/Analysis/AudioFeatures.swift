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
    public var spectralCentroid: Double
    public var lowBandEnergy: Double
    public var midBandEnergy: Double
    public var highBandEnergy: Double
    public var estimatedNoiseLevel: Double
    public var debugSummary: String
    public var spectralFlatness: Double?
    public var isLikelySilence: Bool

    public var timestamp: Date {
        get { startedAt }
        set {
            let currentDuration = duration
            startedAt = newValue
            endedAt = newValue.addingTimeInterval(currentDuration)
        }
    }

    public var duration: TimeInterval {
        max(0, endedAt.timeIntervalSince(startedAt))
    }

    public var lowFrequencyEnergyRatio: Double {
        get { lowBandEnergy }
        set { lowBandEnergy = Self.clamp(newValue) }
    }

    public var highFrequencyActivity: Double {
        get { highBandEnergy }
        set { highBandEnergy = Self.clamp(newValue) }
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
        lowBandEnergy: Double? = nil,
        midBandEnergy: Double? = nil,
        highBandEnergy: Double? = nil,
        estimatedNoiseLevel: Double? = nil,
        debugSummary: String? = nil,
        spectralFlatness: Double? = nil,
        isLikelySilence: Bool? = nil
    ) {
        let safeDuration = max(0, duration)
        let safeRMS = Self.clamp(rms)
        let safeZeroCrossingRate = Self.clamp(zeroCrossingRate)
        let safeLowBandEnergy = Self.clamp(lowBandEnergy ?? lowFrequencyEnergyRatio)
        let safeHighBandEnergy = Self.clamp(highBandEnergy ?? highFrequencyActivity ?? safeZeroCrossingRate)
        let safeMidBandEnergy = Self.clamp(midBandEnergy ?? max(0, 1 - safeLowBandEnergy - safeHighBandEnergy))
        let safeSpectralCentroid = Self.finiteNonNegative(spectralCentroid ?? 0)
        let safeEnergy = Self.finiteNonNegative(energy ?? safeRMS * safeRMS)
        let safeSilence = isLikelySilence ?? (safeRMS < 0.01)

        self.startedAt = startedAt
        self.endedAt = startedAt.addingTimeInterval(safeDuration)
        self.sampleRate = max(1, sampleRate)
        self.channelCount = max(1, channelCount)
        self.frameCount = max(0, frameCount)
        self.rms = safeRMS
        self.energy = safeEnergy
        self.peak = Self.clamp(peak)
        self.zeroCrossingRate = safeZeroCrossingRate
        self.spectralCentroid = safeSpectralCentroid
        self.lowBandEnergy = safeLowBandEnergy
        self.midBandEnergy = safeMidBandEnergy
        self.highBandEnergy = safeHighBandEnergy
        self.estimatedNoiseLevel = Self.clamp(estimatedNoiseLevel ?? safeRMS)
        self.debugSummary = debugSummary ?? Self.makeDebugSummary(
            rms: safeRMS,
            energy: safeEnergy,
            zeroCrossingRate: safeZeroCrossingRate,
            spectralCentroid: safeSpectralCentroid,
            isLikelySilence: safeSilence
        )
        self.spectralFlatness = spectralFlatness
        self.isLikelySilence = safeSilence
    }

    private static func clamp(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }

    private static func finiteNonNegative(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return max(0, value)
    }

    private static func makeDebugSummary(
        rms: Double,
        energy: Double,
        zeroCrossingRate: Double,
        spectralCentroid: Double,
        isLikelySilence: Bool
    ) -> String {
        let silenceText = isLikelySilence ? "silence" : "active"
        return String(
            format: "rms=%.4f energy=%.6f zcr=%.4f centroid=%.1fHz %@",
            rms,
            energy,
            zeroCrossingRate,
            spectralCentroid,
            silenceText
        )
    }
}
