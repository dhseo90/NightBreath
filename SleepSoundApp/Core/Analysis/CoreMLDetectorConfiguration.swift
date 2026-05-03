import Foundation

public enum CoreMLComputeUnitsPreference: String, Codable, CaseIterable, Sendable {
    case all
    case cpuOnly
    case cpuAndNeuralEngine
}

public struct CoreMLDetectorConfiguration: Equatable, Sendable {
    public var modelName: String
    public var modelVersion: String
    public var confidenceThreshold: Double
    public var inputWindowDuration: TimeInterval
    public var overlapRatio: Double
    public var labels: [String]
    public var useSoundAnalysisIfAvailable: Bool
    public var computeUnitsPreference: CoreMLComputeUnitsPreference

    public static let `default` = CoreMLDetectorConfiguration()
    public static let multiclassDefault = CoreMLDetectorConfiguration(
        modelName: "SleepEventClassifier",
        modelVersion: "Multiclass Event Classifier v0",
        confidenceThreshold: 0.5,
        labels: ModelOutputMapper.multiclassEventLabels
    )

    public init(
        modelName: String = "SnoreDetector",
        modelVersion: String = "Snore ML v0",
        confidenceThreshold: Double = 0.5,
        inputWindowDuration: TimeInterval = 1.0,
        overlapRatio: Double = 0.5,
        labels: [String] = ModelOutputMapper.knownLabels,
        useSoundAnalysisIfAvailable: Bool = false,
        computeUnitsPreference: CoreMLComputeUnitsPreference = .all
    ) {
        self.modelName = modelName
        self.modelVersion = modelVersion
        self.confidenceThreshold = Self.clamp(confidenceThreshold)
        self.inputWindowDuration = max(0.1, inputWindowDuration)
        self.overlapRatio = Self.clamp(overlapRatio)
        self.labels = labels
        self.useSoundAnalysisIfAvailable = useSoundAnalysisIfAvailable
        self.computeUnitsPreference = computeUnitsPreference
    }

    private static func clamp(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }
}
