import Foundation

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
