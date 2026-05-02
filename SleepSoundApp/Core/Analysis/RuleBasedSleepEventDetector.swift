import Foundation

public protocol SleepEventDetecting {
    func detect(features: AudioFeatures, startedAt: Date, duration: TimeInterval) -> [DetectorOutput]
}

public struct RuleBasedSleepEventDetector: SleepEventDetecting {
    public var silenceRMS: Double
    public var snoreRMS: Double
    public var noiseRMS: Double

    public init(
        silenceRMS: Double = 0.01,
        snoreRMS: Double = 0.05,
        noiseRMS: Double = 0.24
    ) {
        self.silenceRMS = silenceRMS
        self.snoreRMS = snoreRMS
        self.noiseRMS = noiseRMS
    }

    public func detect(features: AudioFeatures, startedAt: Date, duration: TimeInterval) -> [DetectorOutput] {
        let endedAt = startedAt.addingTimeInterval(duration)

        if features.rms < silenceRMS && duration >= 10 {
            return [
                DetectorOutput(
                    type: .breathingPauseSuspected,
                    startedAt: startedAt,
                    endedAt: endedAt,
                    confidence: 0.48,
                    intensity: 0.2
                )
            ]
        }

        if features.rms >= noiseRMS {
            return [
                DetectorOutput(
                    type: .environmentalNoise,
                    startedAt: startedAt,
                    endedAt: endedAt,
                    confidence: 0.55,
                    intensity: min(features.rms, 1)
                )
            ]
        }

        if features.rms >= snoreRMS && features.lowFrequencyEnergyRatio > 0.55 {
            return [
                DetectorOutput(
                    type: .snore,
                    startedAt: startedAt,
                    endedAt: endedAt,
                    confidence: 0.58,
                    intensity: min(features.rms * 2, 1)
                )
            ]
        }

        return []
    }
}
