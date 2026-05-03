import Foundation

public struct CompositeSleepEventDetector: SleepEventDetector {
    public var backend: SleepDetectionBackend
    public var ruleBasedDetector: any SleepEventDetector
    public var coreMLDetector: CoreMLSleepEventDetector
    public var multiclassCoreMLDetector: CoreMLSleepEventDetector

    public init(
        backend: SleepDetectionBackend = .ruleBased,
        ruleBasedDetector: any SleepEventDetector = RuleBasedSleepEventDetector(),
        coreMLDetector: CoreMLSleepEventDetector = CoreMLSleepEventDetector(),
        multiclassCoreMLDetector: CoreMLSleepEventDetector = CoreMLSleepEventDetector(
            configuration: .multiclassDefault,
            modelProvider: CoreMLMulticlassEventModelProvider()
        )
    ) {
        self.backend = backend
        self.ruleBasedDetector = ruleBasedDetector
        self.coreMLDetector = coreMLDetector
        self.multiclassCoreMLDetector = multiclassCoreMLDetector
    }

    public static var ruleBasedDefault: CompositeSleepEventDetector {
        CompositeSleepEventDetector(backend: .ruleBased)
    }

    public func detect(features: AudioFeatures) -> [DetectorOutput] {
        switch backend {
        case .ruleBased:
            return ruleBasedDetector.detect(features: features)
        case .coreML:
            return coreMLDetector.detect(features: features)
        case .coreMLMulticlass:
            let multiclassResult = multiclassCoreMLDetector.detectWithStatus(features: features)
            guard !multiclassResult.outputs.isEmpty else {
                let fallbackReason = multiclassResult.status.fallbackReason
                    ?? "Core ML multiclass model did not return a confident event label."
                return ruleBasedDetector.detect(features: features).map { output in
                    withFallbackReason(output, reason: fallbackReason)
                }
            }
            return multiclassResult.outputs
        case .hybrid:
            let coreMLResult = coreMLDetector.detectWithStatus(features: features)

            if let snoreOutput = coreMLResult.outputs.first(where: { $0.eventType == .snore }) {
                return [snoreOutput]
            }

            let fallbackReason = coreMLResult.status.fallbackReason
                ?? "Core ML did not return a confident snore label."

            return ruleBasedDetector.detect(features: features).map { output in
                withFallbackReason(output, reason: fallbackReason)
            }
        }
    }

    private func withFallbackReason(_ output: DetectorOutput, reason: String) -> DetectorOutput {
        let fallbackText = "Core ML unavailable; rule-based fallback: \(reason)"
        let debugReason: String

        if let existingReason = output.debugReason, !existingReason.isEmpty {
            debugReason = existingReason + " / " + fallbackText
        } else {
            debugReason = fallbackText
        }

        return DetectorOutput(
            eventType: output.eventType,
            startedAt: output.startedAt,
            endedAt: output.endedAt,
            confidence: output.confidence,
            intensity: output.intensity,
            debugReason: debugReason
        )
    }
}
