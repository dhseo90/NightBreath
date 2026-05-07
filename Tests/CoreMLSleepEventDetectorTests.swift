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

    @Test
    func appTargetModelIntegrationStaysExplicitlyGated() throws {
        let root = repositoryRoot()
        let integrationGuide = try sourceContents("Docs/CORE_ML_MODEL_INTEGRATION.md")
        let snoreMLGuide = try sourceContents("Docs/SNORE_ML_V0.md")
        let trainingGuide = try sourceContents("Tools/Training/README.md")
        let gateScript = try sourceContents("Tools/Training/validate_coreml_integration_gate.sh")
        let project = try sourceContents("SleepSoundApp.xcodeproj/project.pbxproj")
        let modelArtifacts = try modelArtifacts(in: [
            root.appendingPathComponent("SleepSoundApp"),
            root.appendingPathComponent("Models")
        ], root: root)

        #expect(modelArtifacts.isEmpty, "Real Core ML model artifacts should not be committed before target integration gate: \(modelArtifacts)")
        #expect(!project.contains("SnoreDetector.mlmodel"))
        #expect(!project.contains("SnoreDetector.mlmodelc"))
        #expect(!project.contains("SleepEventClassifier.mlmodel"))
        #expect(integrationGuide.contains("Core ML Model Integration Gate"))
        #expect(integrationGuide.contains("실제 모델 artifact는 아직 앱 target에 포함하지 않습니다."))
        #expect(integrationGuide.contains("modelInstalled == false"))
        #expect(integrationGuide.contains("fallbackUsed"))
        #expect(integrationGuide.contains("rule-based fallback"))
        #expect(integrationGuide.contains("--filter CoreMLSleepEventDetector"))
        #expect(integrationGuide.contains("--filter CompositeSleepEventDetector"))
        #expect(integrationGuide.contains("--backends ruleBased,coreML,hybrid"))
        #expect(integrationGuide.contains("sensitive/verySensitive profile을 Release 기본값으로 올리지 않습니다"))
        #expect(integrationGuide.contains("전체 밤 원본 오디오 저장 기능을 추가하지 않습니다"))
        #expect(integrationGuide.contains("서버 업로드, 클라우드 처리, 외부 API 호출, 외부 분석 SDK를 추가하지 않습니다"))
        #expect(snoreMLGuide.contains("Docs/CORE_ML_MODEL_INTEGRATION.md"))
        #expect(trainingGuide.contains("Docs/CORE_ML_MODEL_INTEGRATION.md"))
        #expect(trainingGuide.contains("validate_coreml_integration_gate.sh"))
        #expect(gateScript.contains("KNOWN_MODEL_REFERENCES"))
        #expect(gateScript.contains("SnoreDetector.mlmodel"))
        #expect(gateScript.contains("SleepEventClassifier.mlmodel"))
        #expect(gateScript.contains("rule-based fallback"))
    }

    @Test
    func coreMLIntegrationGateScriptRunsWithoutModelArtifacts() throws {
        let root = repositoryRoot()
        let script = root.appendingPathComponent("Tools/Training/validate_coreml_integration_gate.sh")

        #expect(FileManager.default.fileExists(atPath: script.path))

        let process = Process()
        let output = Pipe()
        process.executableURL = script
        process.currentDirectoryURL = root
        process.standardOutput = output
        process.standardError = output

        try process.run()
        process.waitUntilExit()

        let data = output.fileHandleForReading.readDataToEndOfFile()
        let outputText = String(data: data, encoding: .utf8) ?? ""

        #expect(process.terminationStatus == 0, "Script failed: \(outputText)")
        #expect(outputText.contains("Core ML integration gate passed."))
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

    private func repositoryRoot() -> URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }

    private func sourceContents(_ relativePath: String) throws -> String {
        try String(contentsOf: repositoryRoot().appendingPathComponent(relativePath), encoding: .utf8)
    }

    private func modelArtifacts(in roots: [URL], root repositoryRoot: URL) throws -> [String] {
        let extensions: Set<String> = ["mlmodel", "mlmodelc", "mlpackage"]
        var results: [String] = []

        for root in roots where FileManager.default.fileExists(atPath: root.path) {
            guard let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }

            for case let url as URL in enumerator where extensions.contains(url.pathExtension.lowercased()) {
                results.append(url.path.replacingOccurrences(of: repositoryRoot.path + "/", with: ""))
            }
        }

        return results.sorted()
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
