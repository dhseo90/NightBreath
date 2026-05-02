import Foundation
import Testing
@testable import SleepSoundCore

@Suite("AudioFeatureExtractor")
struct AudioFeatureExtractorTests {
    @Test
    func extractsBasicEnergyAndZeroCrossingFeatures() {
        let chunk = AudioChunk(
            samples: [0.5, -0.5, 0.5, -0.5],
            sampleRate: 16_000,
            startedAt: Date(timeIntervalSince1970: 0),
            duration: 0.25
        )

        let features = AudioFeatureExtractor().extractFeatures(from: chunk)

        #expect(abs(features.rms - 0.5) < 0.0001)
        #expect(abs(features.energy - 0.25) < 0.0001)
        #expect(features.zeroCrossingRate == 1)
        #expect(features.lowFrequencyEnergyRatio < 0.2)
        #expect(!features.isLikelySilence)
    }

    @Test
    func usesChunkLevelWhenSamplesAreNotRetained() {
        let chunk = AudioChunk(
            timestamp: Date(timeIntervalSince1970: 10),
            sampleRate: 16_000,
            channelCount: 1,
            frameCount: 1_600,
            duration: 0.1,
            rms: 0.07,
            samples: []
        )

        let features = AudioFeatureExtractor().extractFeatures(from: chunk)

        #expect(features.startedAt == chunk.startedAt)
        #expect(abs(features.duration - chunk.duration) < 0.0001)
        #expect(features.rms == 0.07)
        #expect(features.energy > 0)
        #expect(features.zeroCrossingRate == 0)
    }

    @Test
    func marksVeryLowRMSAsLikelySilence() {
        let chunk = SyntheticAudioFixture.silence(duration: 0.1)

        let features = AudioFeatureExtractor().extractFeatures(from: chunk)

        #expect(features.rms < 0.01)
        #expect(features.isLikelySilence)
    }

    @Test
    func silenceHasLowRMSAndFiniteFeatures() {
        let features = AudioFeatureExtractor().extractFeatures(
            from: SyntheticAudioFixture.silence(duration: 1)
        )

        #expect(features.rms < 0.001)
        #expect(features.energy < 0.000001)
        #expect(features.isLikelySilence)
        #expect(features.allNumericValuesAreFinite)
    }

    @Test
    func highEnergySampleHasHigherRMS() {
        let extractor = AudioFeatureExtractor()
        let lowEnergy = extractor.extractFeatures(
            from: SyntheticAudioFixture.lowEnergyNoise(duration: 1)
        )
        let highEnergy = extractor.extractFeatures(
            from: SyntheticAudioFixture.highEnergyNoise(duration: 1)
        )

        #expect(highEnergy.rms > lowEnergy.rms)
        #expect(highEnergy.energy > lowEnergy.energy)
        #expect(highEnergy.rms > 0.2)
        #expect(highEnergy.allNumericValuesAreFinite)
    }

    @Test
    func shortBurstIncreasesEnergyAboveSilence() {
        let extractor = AudioFeatureExtractor()
        let silence = extractor.extractFeatures(from: SyntheticAudioFixture.silence(duration: 0.5))
        let burst = extractor.extractFeatures(from: SyntheticAudioFixture.shortBurst(duration: 0.5))

        #expect(burst.energy > silence.energy)
        #expect(burst.peak > 0.7)
        #expect(burst.allNumericValuesAreFinite)
    }

    @Test
    func zeroCrossingRateDoesNotBecomeNaN() {
        let fixtures = [
            SyntheticAudioFixture.silence(duration: 0.2),
            SyntheticAudioFixture.lowEnergyNoise(duration: 0.2),
            SyntheticAudioFixture.highEnergyNoise(duration: 0.2),
            SyntheticAudioFixture.shortBurst(duration: 0.2),
            SyntheticAudioFixture.repeatedPulsePattern(duration: 0.5)
        ]

        for chunk in fixtures {
            let features = AudioFeatureExtractor().extractFeatures(from: chunk)

            #expect(features.zeroCrossingRate.isFinite)
            #expect(features.zeroCrossingRate >= 0)
            #expect(features.zeroCrossingRate <= 1)
            #expect(features.allNumericValuesAreFinite)
        }
    }

    @Test
    func lowFrequencyToneProducesMoreLowBandEnergyThanHighTone() {
        let extractor = AudioFeatureExtractor()
        let lowTone = extractor.extractFeatures(
            from: SyntheticAudioFixture.sineWave(frequency: 120, amplitude: 0.4, duration: 1)
        )
        let highTone = extractor.extractFeatures(
            from: SyntheticAudioFixture.sineWave(frequency: 3_000, amplitude: 0.4, duration: 1)
        )

        #expect(lowTone.lowBandEnergy > lowTone.highBandEnergy)
        #expect(highTone.highBandEnergy > highTone.lowBandEnergy)
        #expect(lowTone.spectralCentroid < highTone.spectralCentroid)
    }

    @Test
    func featureCSVExporterWritesSummaryOnly() {
        let chunk = SyntheticAudioFixture.highEnergyNoise(duration: 0.2)
        let features = AudioFeatureExtractor().extractFeatures(from: chunk)
        let output = DetectorOutput(
            eventType: .environmentalNoise,
            startedAt: features.startedAt,
            endedAt: features.endedAt,
            confidence: 0.7,
            intensity: features.rms,
            debugReason: "test"
        )

        let csv = FeatureCSVExporter.makeCSV(records: [
            FeatureCSVRecord(label: "syntheticNoise", features: features, detectorOutput: output)
        ])

        #expect(csv.contains("timestamp,label,rms,energy,zeroCrossingRate,spectralCentroid,lowBandEnergy,midBandEnergy,highBandEnergy,detectorOutput,confidence"))
        #expect(csv.contains("syntheticNoise"))
        #expect(csv.contains("environmentalNoise"))
        #expect(!csv.contains("samples"))
    }
}

private extension AudioFeatures {
    var allNumericValuesAreFinite: Bool {
        [
            rms,
            energy,
            peak,
            zeroCrossingRate,
            spectralCentroid,
            lowBandEnergy,
            midBandEnergy,
            highBandEnergy,
            estimatedNoiseLevel
        ].allSatisfy(\.isFinite)
    }
}

private enum SyntheticAudioFixture {
    static let sampleRate = 16_000.0
    static let start = Date(timeIntervalSince1970: 1_700_000_000)

    static func silence(duration: TimeInterval) -> AudioChunk {
        makeChunk(samples: Array(repeating: 0, count: frameCount(duration)), duration: duration)
    }

    static func lowEnergyNoise(duration: TimeInterval) -> AudioChunk {
        let samples = (0..<frameCount(duration)).map { index -> Float in
            Float(((index * 17) % 13) - 6) / 2_000
        }

        return makeChunk(samples: samples, duration: duration)
    }

    static func highEnergyNoise(duration: TimeInterval) -> AudioChunk {
        let samples = (0..<frameCount(duration)).map { index -> Float in
            index.isMultiple(of: 2) ? 0.45 : -0.45
        }

        return makeChunk(samples: samples, duration: duration)
    }

    static func shortBurst(duration: TimeInterval) -> AudioChunk {
        var samples = Array(repeating: Float(0), count: frameCount(duration))
        let burstStart = min(120, max(0, samples.count - 1))
        let burstEnd = min(samples.count, burstStart + 160)

        for index in burstStart..<burstEnd {
            samples[index] = index.isMultiple(of: 2) ? 0.85 : -0.85
        }

        return makeChunk(samples: samples, duration: duration)
    }

    static func repeatedPulsePattern(duration: TimeInterval) -> AudioChunk {
        let samples = (0..<frameCount(duration)).map { index -> Float in
            let position = index % 800
            if position < 80 {
                return position.isMultiple(of: 2) ? 0.5 : -0.5
            }
            return 0
        }

        return makeChunk(samples: samples, duration: duration)
    }

    static func sineWave(frequency: Double, amplitude: Double, duration: TimeInterval) -> AudioChunk {
        let samples = (0..<frameCount(duration)).map { index -> Float in
            let phase = 2 * Double.pi * frequency * Double(index) / sampleRate
            return Float(sin(phase) * amplitude)
        }

        return makeChunk(samples: samples, duration: duration)
    }

    private static func frameCount(_ duration: TimeInterval) -> Int {
        max(1, Int(sampleRate * duration))
    }

    private static func makeChunk(samples: [Float], duration: TimeInterval) -> AudioChunk {
        AudioChunk(
            samples: samples,
            sampleRate: sampleRate,
            startedAt: start,
            duration: duration
        )
    }
}
