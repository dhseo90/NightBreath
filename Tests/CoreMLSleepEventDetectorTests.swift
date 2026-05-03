import Foundation
import Testing
@testable import SleepSoundCore

@Suite("CoreMLSleepEventDetector")
struct CoreMLSleepEventDetectorTests {
    @Test
    func modelUnavailableDoesNotCrash() {
        let detector = CoreMLSleepEventDetector(
            configuration: CoreMLDetectorConfiguration(modelName: "MissingModel"),
            modelProvider: UnavailableMLModelProvider(modelName: "MissingModel")
        )

        let result = detector.detectWithStatus(features: makeFeatures())

        #expect(result.outputs.isEmpty)
        if case .modelUnavailable(let reason) = result.status {
            #expect(reason.contains("MissingModel"))
        } else {
            Issue.record("Expected modelUnavailable status")
        }
    }

    @Test
    func snoreModelProviderReportsMissingBundleModel() {
        let provider = CoreMLSnoreModelProvider(modelName: "DefinitelyMissingNightBreathSnoreModel")

        #expect(provider.isModelAvailable == false)

        do {
            _ = try provider.prediction(for: ModelInputAdapter().makeInput(from: makeFeatures()))
            Issue.record("Expected missing Core ML model to throw")
        } catch let error as CoreMLDetectorError {
            #expect(error.message.contains("DefinitelyMissingNightBreathSnoreModel"))
        } catch {
            Issue.record("Expected CoreMLDetectorError")
        }
    }

    @Test
    func mockProviderPredictionCreatesDetectorOutput() {
        let detector = CoreMLSleepEventDetector(
            configuration: CoreMLDetectorConfiguration(confidenceThreshold: 0.5),
            modelProvider: MockModelProvider(
                prediction: ModelPrediction(label: "cough_like", confidence: 0.78)
            )
        )

        let result = detector.detectWithStatus(features: makeFeatures())

        #expect(result.status == .success)
        #expect(result.outputs.count == 1)
        #expect(result.outputs.first?.eventType == .coughLike)
        #expect(result.outputs.first?.confidence == 0.78)
    }

    @Test
    func numericSnorePredictionMapsToSnoreOutput() {
        let detector = CoreMLSleepEventDetector(
            configuration: CoreMLDetectorConfiguration(confidenceThreshold: 0.5),
            modelProvider: MockModelProvider(
                prediction: ModelPrediction(label: "1", confidence: 0.82)
            )
        )

        let result = detector.detectWithStatus(features: makeFeatures())

        #expect(result.status == .success)
        #expect(result.outputs.first?.eventType == .snore)
        #expect(result.outputs.first?.confidence == 0.82)
    }

    @Test
    func snoreModelOutputMappingAcceptsStringLabels() {
        let detector = CoreMLSleepEventDetector(
            configuration: CoreMLDetectorConfiguration(confidenceThreshold: 0.5),
            modelProvider: MockModelProvider(
                prediction: ModelPrediction(label: "snore", confidence: 0.73)
            )
        )

        let result = detector.detectWithStatus(features: makeFeatures())

        #expect(result.status == .success)
        #expect(result.outputs.first?.eventType == .snore)
    }

    @Test
    func nonSnoreModelOutputMapsToUnknown() {
        let detector = CoreMLSleepEventDetector(
            configuration: CoreMLDetectorConfiguration(confidenceThreshold: 0.5),
            modelProvider: MockModelProvider(
                prediction: ModelPrediction(label: "non_snore", confidence: 0.91)
            )
        )

        let result = detector.detectWithStatus(features: makeFeatures())

        #expect(result.status == .success)
        #expect(result.outputs.first?.eventType == .unknown)
    }

    @Test
    func modelPredictionConfidenceAndScoresAreClamped() {
        let prediction = ModelPrediction(
            label: "snore",
            confidence: 2,
            scores: ["snore": 1.4, "non_snore": -0.2]
        )

        #expect(prediction.confidence == 1)
        #expect(prediction.scores["snore"] == 1)
        #expect(prediction.scores["non_snore"] == 0)
    }

    @Test
    func inputAdapterUsesSnoreMLV0FeatureSchema() {
        let features = makeFeatures()
        let input = ModelInputAdapter().makeInput(from: features)

        #expect(input.featureNames == [
            "rms",
            "energy",
            "zeroCrossingRate",
            "spectralCentroid",
            "lowBandEnergy",
            "midBandEnergy",
            "highBandEnergy",
            "duration"
        ])
        #expect(input.featureVector.count == input.featureNames.count)
        #expect(input.featureVector.last == features.duration)
    }

    @Test
    func lowConfidencePredictionReturnsEmptyOutput() {
        let detector = CoreMLSleepEventDetector(
            configuration: CoreMLDetectorConfiguration(confidenceThreshold: 0.8),
            modelProvider: MockModelProvider(
                prediction: ModelPrediction(label: "snore", confidence: 0.3)
            )
        )

        let result = detector.detectWithStatus(features: makeFeatures())

        #expect(result.outputs.isEmpty)
        #expect(result.status == .belowConfidenceThreshold(0.3))
    }

    @Test
    func predictionFailureDoesNotCrash() {
        let detector = CoreMLSleepEventDetector(
            modelProvider: MockFailingProvider()
        )

        let result = detector.detectWithStatus(features: makeFeatures())

        #expect(result.outputs.isEmpty)
        if case .predictionFailed(let reason) = result.status {
            #expect(reason.contains("mock failure"))
        } else {
            Issue.record("Expected predictionFailed status")
        }
    }

    private func makeFeatures() -> AudioFeatures {
        AudioFeatures(
            startedAt: Date(timeIntervalSince1970: 20),
            duration: 1,
            rms: 0.2,
            peak: 0.4,
            zeroCrossingRate: 0.2,
            lowFrequencyEnergyRatio: 0.4
        )
    }
}

private struct MockModelProvider: MLModelProvider {
    var modelName: String = "MockModel"
    var prediction: ModelPrediction

    var isModelAvailable: Bool {
        true
    }

    func prediction(for input: ModelInput) throws -> ModelPrediction {
        prediction
    }
}

private struct MockFailingProvider: MLModelProvider {
    var modelName: String = "MockFailingModel"

    var isModelAvailable: Bool {
        true
    }

    func prediction(for input: ModelInput) throws -> ModelPrediction {
        throw CoreMLDetectorError.predictionFailed("mock failure")
    }
}
