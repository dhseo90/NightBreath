import Foundation

public protocol AudioFeatureExtracting: Sendable {
    func extractFeatures(from chunk: AudioChunk) -> AudioFeatures
}

public struct AudioFeatureExtractor: AudioFeatureExtracting {
    public init() {}

    public func extractFeatures(from chunk: AudioChunk) -> AudioFeatures {
        guard !chunk.samples.isEmpty else {
            let safeRMS = finiteUnit(chunk.rms)
            return AudioFeatures(
                startedAt: chunk.startedAt,
                duration: chunk.duration,
                sampleRate: chunk.sampleRate,
                channelCount: chunk.channelCount,
                frameCount: chunk.frameCount,
                rms: safeRMS,
                energy: safeRMS * safeRMS,
                peak: safeRMS,
                zeroCrossingRate: 0,
                lowFrequencyEnergyRatio: 0,
                highFrequencyActivity: 0,
                spectralCentroid: 0,
                lowBandEnergy: 0,
                midBandEnergy: 0,
                highBandEnergy: 0,
                estimatedNoiseLevel: safeRMS,
                debugSummary: "no retained PCM samples; using chunk rms only",
                isLikelySilence: safeRMS < 0.01
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
        let spectralSummary = estimateSpectralSummary(
            from: chunk.samples,
            sampleRate: chunk.sampleRate
        )
        let estimatedNoiseLevel = estimateNoiseLevel(
            rms: rms,
            zeroCrossingRate: zeroCrossingRate,
            highBandEnergy: spectralSummary.highBandEnergy
        )

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
            lowFrequencyEnergyRatio: spectralSummary.lowBandEnergy,
            highFrequencyActivity: spectralSummary.highBandEnergy,
            spectralCentroid: spectralSummary.spectralCentroid,
            lowBandEnergy: spectralSummary.lowBandEnergy,
            midBandEnergy: spectralSummary.midBandEnergy,
            highBandEnergy: spectralSummary.highBandEnergy,
            estimatedNoiseLevel: estimatedNoiseLevel,
            debugSummary: makeDebugSummary(
                rms: rms,
                energy: squareSum / count,
                zeroCrossingRate: zeroCrossingRate,
                spectralCentroid: spectralSummary.spectralCentroid,
                lowBandEnergy: spectralSummary.lowBandEnergy,
                midBandEnergy: spectralSummary.midBandEnergy,
                highBandEnergy: spectralSummary.highBandEnergy,
                isLikelySilence: rms < 0.01
            ),
            spectralFlatness: nil,
            isLikelySilence: rms < 0.01
        )
    }

    private func estimateSpectralSummary(
        from samples: [Float],
        sampleRate: Double
    ) -> SpectralSummary {
        guard samples.count > 2 else {
            return SpectralSummary()
        }

        let safeSampleRate = max(1, sampleRate)
        let nyquist = safeSampleRate / 2
        var lowPower = 0.0
        var midPower = 0.0
        var highPower = 0.0
        var totalPower = 0.0
        var weightedFrequencyPower = 0.0

        for frequency in sampledBandFrequencies(nyquist: nyquist) {
            let power = estimatePower(samples: samples, sampleRate: safeSampleRate, frequency: frequency)

            totalPower += power
            weightedFrequencyPower += frequency * power

            switch frequency {
            case ..<300:
                lowPower += power
            case ..<2_000:
                midPower += power
            default:
                highPower += power
            }
        }

        guard totalPower > 0, totalPower.isFinite else {
            return SpectralSummary()
        }

        return SpectralSummary(
            spectralCentroid: weightedFrequencyPower / totalPower,
            lowBandEnergy: lowPower / totalPower,
            midBandEnergy: midPower / totalPower,
            highBandEnergy: highPower / totalPower
        )
    }

    private func sampledBandFrequencies(nyquist: Double) -> [Double] {
        [
            60, 75, 90, 95, 105, 120, 135, 160, 200, 250,
            350, 500, 700, 950, 1_300, 1_700,
            2_300, 3_000, 3_200, 4_200, 6_000
        ].filter { $0 < nyquist }
    }

    private func estimatePower(samples: [Float], sampleRate: Double, frequency: Double) -> Double {
        guard sampleRate > 0, frequency > 0 else { return 0 }

        var previous = 0.0
        var previousPrevious = 0.0
        let omega = 2 * Double.pi * frequency / sampleRate
        let coefficient = 2 * cos(omega)

        for index in samples.indices {
            let value = Double(samples[index])
            let current = value + coefficient * previous - previousPrevious
            previousPrevious = previous
            previous = current
        }

        let power = previousPrevious * previousPrevious + previous * previous - coefficient * previous * previousPrevious
        guard power.isFinite else { return 0 }
        return max(0, power)
    }

    private func estimateNoiseLevel(
        rms: Double,
        zeroCrossingRate: Double,
        highBandEnergy: Double
    ) -> Double {
        finiteUnit(rms * (0.7 + 0.2 * finiteUnit(zeroCrossingRate) + 0.3 * finiteUnit(highBandEnergy)))
    }

    private func makeDebugSummary(
        rms: Double,
        energy: Double,
        zeroCrossingRate: Double,
        spectralCentroid: Double,
        lowBandEnergy: Double,
        midBandEnergy: Double,
        highBandEnergy: Double,
        isLikelySilence: Bool
    ) -> String {
        let silenceText = isLikelySilence ? "silence" : "active"
        return String(
            format: "rms=%.4f energy=%.6f zcr=%.4f centroid=%.1fHz low=%.3f mid=%.3f high=%.3f %@",
            rms,
            energy,
            zeroCrossingRate,
            spectralCentroid,
            lowBandEnergy,
            midBandEnergy,
            highBandEnergy,
            silenceText
        )
    }

    private func finiteUnit(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }
}

private struct SpectralSummary {
    var spectralCentroid: Double = 0
    var lowBandEnergy: Double = 0
    var midBandEnergy: Double = 0
    var highBandEnergy: Double = 0
}
