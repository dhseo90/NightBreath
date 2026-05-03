import Foundation
import Testing
@testable import SleepSoundCore

@Suite("CompositeSleepEventDetector")
struct CompositeSleepEventDetectorTests {
    @Test
    func ruleBasedBackendUsesRuleBasedDetector() {
        let detector = CompositeSleepEventDetector(
            backend: .ruleBased,
            ruleBasedDetector: StubSleepEventDetector(eventType: .snore),
            coreMLDetector: makeCoreMLDetector(label: "cough_like")
        )

        let outputs = detector.detect(features: makeFeatures())

        #expect(outputs.map(\.eventType) == [.snore])
    }

    @Test
    func coreMLBackendUsesCoreMLDetector() {
        let detector = CompositeSleepEventDetector(
            backend: .coreML,
            ruleBasedDetector: StubSleepEventDetector(eventType: .snore),
            coreMLDetector: makeCoreMLDetector(label: "cough_like")
        )

        let outputs = detector.detect(features: makeFeatures())

        #expect(outputs.map(\.eventType) == [.coughLike])
    }

    @Test
    func coreMLMulticlassBackendUsesOptionalMulticlassDetector() {
        let detector = CompositeSleepEventDetector(
            backend: .coreMLMulticlass,
            ruleBasedDetector: StubSleepEventDetector(eventType: .snore),
            multiclassCoreMLDetector: makeCoreMLDetector(label: "environmental_noise")
        )

        let outputs = detector.detect(features: makeFeatures())

        #expect(outputs.map(\.eventType) == [.environmentalNoise])
    }

    @Test
    func coreMLMulticlassBackendFallsBackWhenModelMissing() {
        let detector = CompositeSleepEventDetector(
            backend: .coreMLMulticlass,
            ruleBasedDetector: StubSleepEventDetector(eventType: .movementLike),
            multiclassCoreMLDetector: CoreMLSleepEventDetector(
                configuration: .multiclassDefault,
                modelProvider: UnavailableMLModelProvider(modelName: "MissingMulticlassModel")
            )
        )

        let outputs = detector.detect(features: makeFeatures())

        #expect(outputs.map(\.eventType) == [.movementLike])
        #expect(outputs.first?.debugReason?.contains("fallback") == true)
        #expect(outputs.first?.debugReason?.contains("MissingMulticlassModel") == true)
    }

    @Test
    func hybridBackendFallsBackWhenModelUnavailable() {
        let detector = CompositeSleepEventDetector(
            backend: .hybrid,
            ruleBasedDetector: StubSleepEventDetector(eventType: .environmentalNoise),
            coreMLDetector: CoreMLSleepEventDetector(
                modelProvider: UnavailableMLModelProvider(modelName: "MissingModel")
            )
        )

        let outputs = detector.detect(features: makeFeatures())

        #expect(outputs.map(\.eventType) == [.environmentalNoise])
        #expect(outputs.first?.debugReason?.contains("fallback") == true)
        #expect(outputs.first?.debugReason?.contains("MissingModel") == true)
    }

    @Test
    func hybridBackendPrefersCoreMLWhenAvailable() {
        let detector = CompositeSleepEventDetector(
            backend: .hybrid,
            ruleBasedDetector: StubSleepEventDetector(eventType: .environmentalNoise),
            coreMLDetector: makeCoreMLDetector(label: "snore"),
            multiclassCoreMLDetector: makeCoreMLDetector(label: "cough_like")
        )

        let outputs = detector.detect(features: makeFeatures())

        #expect(outputs.map(\.eventType) == [.snore])
        #expect(outputs.first?.debugReason?.contains("Core ML") == true)
    }

    @Test
    func hybridBackendFallsBackWhenCoreMLConfidenceIsLow() {
        let detector = CompositeSleepEventDetector(
            backend: .hybrid,
            ruleBasedDetector: StubSleepEventDetector(eventType: .environmentalNoise),
            coreMLDetector: makeCoreMLDetector(label: "snore", confidence: 0.2, threshold: 0.8)
        )

        let outputs = detector.detect(features: makeFeatures())

        #expect(outputs.map(\.eventType) == [.environmentalNoise])
        #expect(outputs.first?.debugReason?.contains("confidence below threshold") == true)
    }

    @Test
    func hybridBackendFallsBackWhenCoreMLReturnsNonSnoreLabel() {
        let detector = CompositeSleepEventDetector(
            backend: .hybrid,
            ruleBasedDetector: StubSleepEventDetector(eventType: .movementLike),
            coreMLDetector: makeCoreMLDetector(label: "non_snore")
        )

        let outputs = detector.detect(features: makeFeatures())

        #expect(outputs.map(\.eventType) == [.movementLike])
        #expect(outputs.first?.debugReason?.contains("confident snore") == true)
    }

    @Test
    func sleepAnalyzerDependsOnDetectorProtocol() {
        let session = SleepSession(startedAt: Date(timeIntervalSince1970: 0))
        let chunk = AudioChunk(
            samples: [0.2, -0.2, 0.2, -0.2],
            sampleRate: 16_000,
            startedAt: Date(timeIntervalSince1970: 1),
            duration: 1
        )
        let analyzer = SleepAnalyzer(
            detector: StubSleepEventDetector(eventType: .movementLike),
            smoothingPolicy: DetectionSmoothingPolicy(
                minimumEventDuration: 0.1,
                maximumMergeGap: 1,
                confidenceThreshold: 0.1
            )
        )

        let events = analyzer.analyze(session: session, chunks: [chunk])

        #expect(events.count == 1)
        #expect(events.first?.type == .movementLike)
    }

    private func makeCoreMLDetector(
        label: String,
        confidence: Double = 0.9,
        threshold: Double = 0.5
    ) -> CoreMLSleepEventDetector {
        CoreMLSleepEventDetector(
            configuration: CoreMLDetectorConfiguration(confidenceThreshold: threshold),
            modelProvider: CompositeMockModelProvider(
                prediction: ModelPrediction(label: label, confidence: confidence)
            )
        )
    }

    private func makeFeatures() -> AudioFeatures {
        AudioFeatures(
            startedAt: Date(timeIntervalSince1970: 30),
            duration: 1,
            rms: 0.3,
            peak: 0.5,
            zeroCrossingRate: 0.2,
            lowFrequencyEnergyRatio: 0.4
        )
    }
}

private struct StubSleepEventDetector: SleepEventDetector {
    var eventType: SleepEventType

    func detect(features: AudioFeatures) -> [DetectorOutput] {
        [
            DetectorOutput(
                eventType: eventType,
                startedAt: features.startedAt,
                endedAt: features.endedAt,
                confidence: 0.8,
                intensity: features.rms,
                debugReason: "stub detector"
            )
        ]
    }
}

private struct CompositeMockModelProvider: MLModelProvider {
    var modelName: String = "CompositeMockModel"
    var prediction: ModelPrediction

    var isModelAvailable: Bool {
        true
    }

    func prediction(for input: ModelInput) throws -> ModelPrediction {
        prediction
    }
}
