import Foundation

public protocol AudioFeatureExtracting: Sendable {
    func extractFeatures(from chunk: AudioChunk) -> AudioFeatures
}

public struct AudioFeatureExtractor: AudioFeatureExtracting {
    public init() {}

    public func extractFeatures(from chunk: AudioChunk) -> AudioFeatures {
        guard !chunk.samples.isEmpty else {
            return AudioFeatures(
                startedAt: chunk.startedAt,
                duration: chunk.duration,
                sampleRate: chunk.sampleRate,
                channelCount: chunk.channelCount,
                frameCount: chunk.frameCount,
                rms: chunk.rms,
                peak: chunk.rms,
                zeroCrossingRate: 0,
                lowFrequencyEnergyRatio: 0,
                highFrequencyActivity: 0,
                isLikelySilence: chunk.rms < 0.01
            )
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
        let rms = sqrt(squareSum / count)
        let zeroCrossingRate = Double(zeroCrossings) / max(count - 1, 1)
        let lowFrequencyEnergyRatio = estimateLowFrequencyRatio(from: chunk.samples)

        // log-mel spectrogram/MFCC/Core ML 입력은 이 타입에 feature를 추가해서 붙일 예정입니다.
        return AudioFeatures(
            startedAt: chunk.startedAt,
            duration: chunk.duration,
            sampleRate: chunk.sampleRate,
            channelCount: chunk.channelCount,
            frameCount: chunk.frameCount,
            rms: rms,
            energy: squareSum / count,
            peak: peak,
            zeroCrossingRate: zeroCrossingRate,
            lowFrequencyEnergyRatio: lowFrequencyEnergyRatio,
            highFrequencyActivity: min(max(zeroCrossingRate * (1 - lowFrequencyEnergyRatio), 0), 1),
            spectralCentroid: nil,
            spectralFlatness: nil,
            isLikelySilence: rms < 0.01
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
