import Foundation

public enum CoreMLDetectionStatus: Equatable, Sendable {
    case success
    case modelUnavailable(String)
    case predictionFailed(String)
    case belowConfidenceThreshold(Double)

    public var fallbackReason: String? {
        switch self {
        case .modelUnavailable(let reason), .predictionFailed(let reason):
            reason
        case .belowConfidenceThreshold(let confidence):
            "Core ML confidence below threshold: \(String(format: "%.3f", confidence))"
        case .success:
            nil
        }
    }
}

public struct CoreMLDetectionResult: Equatable, Sendable {
    public var outputs: [DetectorOutput]
    public var status: CoreMLDetectionStatus

    public init(outputs: [DetectorOutput], status: CoreMLDetectionStatus) {
        self.outputs = outputs
        self.status = status
    }
}

public struct CoreMLSleepEventDetector: SleepEventDetector {
    public var configuration: CoreMLDetectorConfiguration
    public var modelProvider: any MLModelProvider
    public var inputAdapter: ModelInputAdapter
    public var outputMapper: ModelOutputMapper

    public init(
        configuration: CoreMLDetectorConfiguration = .default,
        modelProvider: (any MLModelProvider)? = nil,
        inputAdapter: ModelInputAdapter = ModelInputAdapter(),
        outputMapper: ModelOutputMapper = ModelOutputMapper()
    ) {
        self.configuration = configuration
        self.modelProvider = modelProvider ?? CoreMLSnoreModelProvider(modelName: configuration.modelName)
        self.inputAdapter = inputAdapter
        self.outputMapper = outputMapper
    }

    public func detect(features: AudioFeatures) -> [DetectorOutput] {
        detectWithStatus(features: features).outputs
    }

    public func detectWithStatus(features: AudioFeatures) -> CoreMLDetectionResult {
        guard modelProvider.isModelAvailable else {
            return CoreMLDetectionResult(
                outputs: [],
                status: .modelUnavailable(CoreMLDetectorError.modelUnavailable(modelProvider.modelName).message)
            )
        }

        do {
            let input = inputAdapter.makeInput(from: features)
            let prediction = try modelProvider.prediction(for: input)

            guard prediction.confidence >= configuration.confidenceThreshold else {
                return CoreMLDetectionResult(
                    outputs: [],
                    status: .belowConfidenceThreshold(prediction.confidence)
                )
            }

            let output = outputMapper.makeOutput(
                prediction: prediction,
                features: features,
                debugReason: "Core ML snore backend label=\(prediction.label)"
            )

            return CoreMLDetectionResult(outputs: [output], status: .success)
        } catch let error as CoreMLDetectorError {
            return CoreMLDetectionResult(outputs: [], status: .predictionFailed(error.message))
        } catch {
            return CoreMLDetectionResult(outputs: [], status: .predictionFailed(error.localizedDescription))
        }
    }
}
