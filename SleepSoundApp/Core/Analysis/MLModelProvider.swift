import Foundation
#if canImport(CoreML)
import CoreML
#endif

public enum CoreMLDetectorError: Error, Equatable, Sendable {
    case modelUnavailable(String)
    case predictionFailed(String)

    public var message: String {
        switch self {
        case .modelUnavailable(let modelName):
            "Core ML model is not installed: \(modelName)"
        case .predictionFailed(let reason):
            "Core ML prediction failed: \(reason)"
        }
    }
}

public struct ModelPrediction: Equatable, Sendable {
    public var label: String
    public var confidence: Double
    public var scores: [String: Double]

    public init(label: String, confidence: Double, scores: [String: Double] = [:]) {
        self.label = label
        self.confidence = Self.clamp(confidence)
        self.scores = scores.mapValues(Self.clamp)
    }

    private static func clamp(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }
}

public protocol MLModelProvider: Sendable {
    var modelName: String { get }
    var isModelAvailable: Bool { get }
    func prediction(for input: ModelInput) throws -> ModelPrediction
}

public struct UnavailableMLModelProvider: MLModelProvider {
    public var modelName: String

    public var isModelAvailable: Bool {
        false
    }

    public init(modelName: String = CoreMLDetectorConfiguration.default.modelName) {
        self.modelName = modelName
    }

    public func prediction(for input: ModelInput) throws -> ModelPrediction {
        throw CoreMLDetectorError.modelUnavailable(modelName)
    }
}

public struct BundleMLModelProvider: MLModelProvider, @unchecked Sendable {
    public var modelName: String
    public var bundle: Bundle

    public var isModelAvailable: Bool {
        modelURL != nil
    }

    public init(modelName: String, bundle: Bundle = .main) {
        self.modelName = modelName
        self.bundle = bundle
    }

    public func prediction(for input: ModelInput) throws -> ModelPrediction {
        guard let modelURL else {
            throw CoreMLDetectorError.modelUnavailable(modelName)
        }

        #if canImport(CoreML)
        do {
            let model = try MLModel(contentsOf: modelURL)
            let featureProvider = try makeFeatureProvider(from: input)
            let output = try model.prediction(from: featureProvider)
            return try makePrediction(from: output)
        } catch let error as CoreMLDetectorError {
            throw error
        } catch {
            throw CoreMLDetectorError.predictionFailed(error.localizedDescription)
        }
        #else
        throw CoreMLDetectorError.predictionFailed("Core ML is not available on this platform.")
        #endif
    }

    private var modelURL: URL? {
        ["mlmodelc", "mlpackage", "mlmodel"].lazy.compactMap {
            bundle.url(forResource: modelName, withExtension: $0)
        }.first
    }

    #if canImport(CoreML)
    private func makeFeatureProvider(from input: ModelInput) throws -> MLFeatureProvider {
        var values: [String: MLFeatureValue] = [:]

        for (name, value) in zip(input.featureNames, input.featureVector) {
            values[name] = MLFeatureValue(double: value)
        }

        if let featureArray = try? MLMultiArray(
            shape: [NSNumber(value: input.featureVector.count)],
            dataType: .double
        ) {
            for (index, value) in input.featureVector.enumerated() {
                featureArray[index] = NSNumber(value: value)
            }
            values[ModelInputAdapter.featureVectorInputName] = MLFeatureValue(multiArray: featureArray)
        }

        return try MLDictionaryFeatureProvider(dictionary: values)
    }

    private func makePrediction(from output: MLFeatureProvider) throws -> ModelPrediction {
        let scores = scoreDictionary(from: output)
        let label = preferredLabel(from: output) ?? scores.max { lhs, rhs in
            lhs.value < rhs.value
        }?.key

        guard let label else {
            throw CoreMLDetectorError.predictionFailed("Model output did not contain a label.")
        }

        let confidence = scores[label] ?? scores[ModelOutputMapper.normalizedLabel(label)] ?? 1
        return ModelPrediction(label: label, confidence: confidence, scores: scores)
    }

    private func preferredLabel(from output: MLFeatureProvider) -> String? {
        for name in ["label", "classLabel", "class_label", "target", "prediction"] {
            guard let value = output.featureValue(for: name) else {
                continue
            }
            if let label = labelString(from: value) {
                return label
            }
        }

        for name in output.featureNames {
            guard let value = output.featureValue(for: name) else {
                continue
            }
            if let label = labelString(from: value) {
                return label
            }
        }

        return nil
    }

    private func labelString(from value: MLFeatureValue) -> String? {
        switch value.type {
        case .string:
            return value.stringValue
        case .int64:
            return String(value.int64Value)
        case .double:
            return String(value.doubleValue)
        default:
            return nil
        }
    }

    private func scoreDictionary(from output: MLFeatureProvider) -> [String: Double] {
        for name in ["labelProbability", "classProbability", "probabilities", "scores"] {
            guard let value = output.featureValue(for: name), value.type == .dictionary else {
                continue
            }
            return value.dictionaryValue.reduce(into: [String: Double]()) { result, entry in
                let label = String(describing: entry.key)
                result[label] = entry.value.doubleValue
            }
        }

        return [:]
    }
    #endif
}

public struct CoreMLSnoreModelProvider: MLModelProvider, @unchecked Sendable {
    private var provider: BundleMLModelProvider

    public var modelName: String {
        provider.modelName
    }

    public var isModelAvailable: Bool {
        provider.isModelAvailable
    }

    public init(modelName: String = "SnoreDetector", bundle: Bundle = .main) {
        self.provider = BundleMLModelProvider(modelName: modelName, bundle: bundle)
    }

    public func prediction(for input: ModelInput) throws -> ModelPrediction {
        try provider.prediction(for: input)
    }
}

public struct CoreMLMulticlassEventModelProvider: MLModelProvider, @unchecked Sendable {
    private var provider: BundleMLModelProvider

    public var modelName: String {
        provider.modelName
    }

    public var isModelAvailable: Bool {
        provider.isModelAvailable
    }

    public init(modelName: String = "SleepEventClassifier", bundle: Bundle = .main) {
        self.provider = BundleMLModelProvider(modelName: modelName, bundle: bundle)
    }

    public func prediction(for input: ModelInput) throws -> ModelPrediction {
        try provider.prediction(for: input)
    }
}
