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
        let chunk = AudioChunk(
            samples: [0.001, -0.001, 0.001],
            sampleRate: 16_000,
            startedAt: Date(timeIntervalSince1970: 0),
            duration: 0.1
        )

        let features = AudioFeatureExtractor().extractFeatures(from: chunk)

        #expect(features.rms < 0.01)
        #expect(features.isLikelySilence)
    }
}
