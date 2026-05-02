import Foundation

public struct AudioFeatures: Equatable {
    public var rms: Double
    public var peak: Double
    public var zeroCrossingRate: Double
    public var lowFrequencyEnergyRatio: Double

    public init(
        rms: Double,
        peak: Double,
        zeroCrossingRate: Double,
        lowFrequencyEnergyRatio: Double
    ) {
        self.rms = rms
        self.peak = peak
        self.zeroCrossingRate = zeroCrossingRate
        self.lowFrequencyEnergyRatio = lowFrequencyEnergyRatio
    }
}

public protocol AudioFeatureExtracting {
    func extractFeatures(from chunk: AudioChunk) -> AudioFeatures
}

public struct AudioFeatureExtractor: AudioFeatureExtracting {
    public init() {}

    public func extractFeatures(from chunk: AudioChunk) -> AudioFeatures {
        guard !chunk.samples.isEmpty else {
            return AudioFeatures(rms: 0, peak: 0, zeroCrossingRate: 0, lowFrequencyEnergyRatio: 0)
        }

        var squareSum = 0.0
        var peak = 0.0
        var zeroCrossings = 0
        var previousSample = chunk.samples[0]

        for sample in chunk.samples {
            let value = Double(sample)
            squareSum += value * value
            peak = max(peak, abs(value))

            if (sample >= 0 && previousSample < 0) || (sample < 0 && previousSample >= 0) {
                zeroCrossings += 1
            }
            previousSample = sample
        }

        let count = Double(chunk.samples.count)
        return AudioFeatures(
            rms: sqrt(squareSum / count),
            peak: peak,
            zeroCrossingRate: Double(zeroCrossings) / count,
            lowFrequencyEnergyRatio: estimateLowFrequencyRatio(from: chunk.samples)
        )
    }

    private func estimateLowFrequencyRatio(from samples: [Float]) -> Double {
        guard samples.count > 1 else { return 0 }

        var smoothEnergy = 0.0
        var totalEnergy = 0.0
        var previous = Double(samples[0])

        for sample in samples.dropFirst() {
            let value = Double(sample)
            let smoothed = (previous + value) / 2
            smoothEnergy += smoothed * smoothed
            totalEnergy += value * value
            previous = value
        }

        guard totalEnergy > 0 else { return 0 }
        return min(max(smoothEnergy / totalEnergy, 0), 1)
    }
}
