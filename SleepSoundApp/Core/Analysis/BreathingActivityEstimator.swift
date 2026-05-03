import Foundation

public struct BreathingActivityEstimate: Equatable, Sendable {
    public var startedAt: Date
    public var endedAt: Date
    public var breathingActivityScore: Double
    public var isLowActivity: Bool
    public var isNoiseContaminated: Bool
    public var debugReason: String
    public var isLikelySilence: Bool

    public var duration: TimeInterval {
        max(0, endedAt.timeIntervalSince(startedAt))
    }

    public init(
        startedAt: Date,
        endedAt: Date,
        breathingActivityScore: Double,
        isLowActivity: Bool,
        isNoiseContaminated: Bool,
        debugReason: String,
        isLikelySilence: Bool = false
    ) {
        self.startedAt = startedAt
        self.endedAt = max(startedAt, endedAt)
        self.breathingActivityScore = Self.clamp(breathingActivityScore)
        self.isLowActivity = isLowActivity
        self.isNoiseContaminated = isNoiseContaminated
        self.debugReason = debugReason
        self.isLikelySilence = isLikelySilence
    }

    private static func clamp(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }
}

public struct BreathingActivityEstimator: Equatable, Sendable {
    public var silenceRMS: Double
    public var snoreRMS: Double
    public var noiseRMS: Double
    public var lowActivityScoreThreshold: Double

    public init(
        silenceRMS: Double = RuleBasedDetectionThresholds.default.silenceRMS,
        snoreRMS: Double = RuleBasedDetectionThresholds.default.snoreRMS,
        noiseRMS: Double = RuleBasedDetectionThresholds.default.noiseRMS,
        lowActivityScoreThreshold: Double = 0.22
    ) {
        self.silenceRMS = Self.clamp(silenceRMS)
        self.snoreRMS = max(Self.clamp(snoreRMS), self.silenceRMS + 0.001)
        self.noiseRMS = max(Self.clamp(noiseRMS), self.snoreRMS + 0.001)
        self.lowActivityScoreThreshold = Self.clamp(lowActivityScoreThreshold)
    }

    public func estimate(features: AudioFeatures) -> BreathingActivityEstimate {
        let rmsActivity = normalized(features.rms, lowerBound: silenceRMS, upperBound: snoreRMS)
        let peakActivity = normalized(features.peak, lowerBound: silenceRMS * 1.5, upperBound: snoreRMS * 2)
        let lowBandActivity = features.lowFrequencyEnergyRatio
        let score = Self.clamp(
            rmsActivity * 0.62 +
            peakActivity * 0.18 +
            lowBandActivity * 0.20
        )
        let noiseContaminated = isNoiseContaminated(features)
        let lowActivity = features.isLikelySilence || features.rms <= silenceRMS || score <= lowActivityScoreThreshold

        let activityText = lowActivity ? "저활동" : "활동 있음"
        let noiseText = noiseContaminated ? "소음 영향 있음" : "소음 영향 낮음"
        let reason = String(
            format: "%@, %@, activityScore=%.3f rms=%.4f noise=%.4f",
            activityText,
            noiseText,
            score,
            features.rms,
            features.estimatedNoiseLevel
        )

        return BreathingActivityEstimate(
            startedAt: features.startedAt,
            endedAt: features.endedAt,
            breathingActivityScore: score,
            isLowActivity: lowActivity,
            isNoiseContaminated: noiseContaminated,
            debugReason: reason,
            isLikelySilence: features.isLikelySilence
        )
    }

    private func isNoiseContaminated(_ features: AudioFeatures) -> Bool {
        if features.estimatedNoiseLevel >= noiseRMS * 0.70 {
            return true
        }

        if features.rms >= noiseRMS * 0.55,
           features.zeroCrossingRate >= 0.32 || features.highBandEnergy >= 0.38 {
            return true
        }

        return features.spectralCentroid >= 2_200 &&
            features.highBandEnergy >= 0.32 &&
            features.lowFrequencyEnergyRatio <= 0.45
    }

    private func normalized(
        _ value: Double,
        lowerBound: Double,
        upperBound: Double
    ) -> Double {
        guard value.isFinite else { return 0 }
        let range = max(upperBound - lowerBound, 0.001)
        return Self.clamp((value - lowerBound) / range)
    }

    private static func clamp(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }
}
