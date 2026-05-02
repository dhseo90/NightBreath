import Foundation
import Testing
@testable import SleepSoundCore

@Suite("RuleBasedDetectorValidation")
struct RuleBasedDetectorValidationTests {
    @Test
    func syntheticSilenceReturnsNoShortEventCandidate() {
        let features = AudioFeatureExtractor().extractFeatures(
            from: SyntheticDetectorFixture.silence(duration: 1)
        )

        let outputs = RuleBasedSleepEventDetector().detect(features: features)

        #expect(outputs.isEmpty || outputs.allSatisfy { $0.eventType == .unknown })
        #expect(features.isLikelySilence)
    }

    @Test
    func syntheticHighNoiseCanBecomeEnvironmentalNoiseCandidate() {
        let features = AudioFeatureExtractor().extractFeatures(
            from: SyntheticDetectorFixture.highEnergyNoise(duration: 1)
        )

        let outputs = RuleBasedSleepEventDetector().detect(features: features)

        #expect(outputs.map(\.eventType).contains(.environmentalNoise))
        #expect(outputs.allSatisfy { $0.confidence >= 0 && $0.confidence <= 1 })
    }

    @Test
    func veryShortDetectorEventCanBeRemovedBySmoothing() {
        let features = AudioFeatureExtractor().extractFeatures(
            from: SyntheticDetectorFixture.highEnergyNoise(duration: 0.05)
        )
        let rawOutputs = RuleBasedSleepEventDetector().detect(features: features)
        let smoothedOutputs = DetectionSmoothingPolicy(
            minimumEventDuration: 0.2,
            maximumMergeGap: 0.5,
            confidenceThreshold: 0.1
        ).apply(to: rawOutputs)

        #expect(!rawOutputs.isEmpty)
        #expect(smoothedOutputs.isEmpty)
    }

    @Test
    func confidenceAlwaysStaysInsideUnitRange() {
        let extractor = AudioFeatureExtractor()
        let detector = RuleBasedSleepEventDetector()
        let chunks = [
            SyntheticDetectorFixture.silence(duration: 12),
            SyntheticDetectorFixture.highEnergyNoise(duration: 1),
            SyntheticDetectorFixture.lowFrequencySnoreLike(duration: 1),
            SyntheticDetectorFixture.repeatedPulsePattern(duration: 1)
        ]

        let outputs = chunks.flatMap { chunk in
            detector.detect(features: extractor.extractFeatures(from: chunk))
        }

        #expect(!outputs.isEmpty)
        #expect(outputs.allSatisfy { output in
            output.confidence.isFinite &&
                output.confidence >= 0 &&
                output.confidence <= 1 &&
                output.intensity >= 0 &&
                output.intensity <= 1
        })
    }

    @Test
    func featureCSVExportKeepsOnlySummaries() {
        let features = AudioFeatureExtractor().extractFeatures(
            from: SyntheticDetectorFixture.lowFrequencySnoreLike(duration: 1)
        )
        let output = RuleBasedSleepEventDetector().detect(features: features).first

        let csv = FeatureCSVExporter().export(records: [
            FeatureCSVRecord(label: "snore", features: features, detectorOutput: output)
        ])

        #expect(csv.contains("snore"))
        #expect(csv.contains("rms"))
        #expect(!csv.contains("rawPCM"))
        #expect(!csv.contains("samples"))
    }
}

private enum SyntheticDetectorFixture {
    static let sampleRate = 16_000.0
    static let start = Date(timeIntervalSince1970: 1_700_000_100)

    static func silence(duration: TimeInterval) -> AudioChunk {
        makeChunk(samples: Array(repeating: 0, count: frameCount(duration)), duration: duration)
    }

    static func highEnergyNoise(duration: TimeInterval) -> AudioChunk {
        let samples = (0..<frameCount(duration)).map { index -> Float in
            index.isMultiple(of: 2) ? 0.5 : -0.5
        }

        return makeChunk(samples: samples, duration: duration)
    }

    static func lowFrequencySnoreLike(duration: TimeInterval) -> AudioChunk {
        let samples = (0..<frameCount(duration)).map { index -> Float in
            let phase = 2 * Double.pi * 120 * Double(index) / sampleRate
            return Float(sin(phase) * 0.18)
        }

        return makeChunk(samples: samples, duration: duration)
    }

    static func repeatedPulsePattern(duration: TimeInterval) -> AudioChunk {
        let samples = (0..<frameCount(duration)).map { index -> Float in
            let position = index % 500
            if position < 60 {
                return position.isMultiple(of: 2) ? 0.55 : -0.55
            }
            return 0
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
