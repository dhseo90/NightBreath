import Foundation

public struct CompositeSleepEventDetector: SleepEventDetector {
    public var backend: SleepDetectionBackend
    public var ruleBasedDetector: any SleepEventDetector
    public var coreMLDetector: CoreMLSleepEventDetector

    public init(
        backend: SleepDetectionBackend = .ruleBased,
        ruleBasedDetector: any SleepEventDetector = RuleBasedSleepEventDetector(),
        coreMLDetector: CoreMLSleepEventDetector = CoreMLSleepEventDetector()
    ) {
        self.backend = backend
        self.ruleBasedDetector = ruleBasedDetector
        self.coreMLDetector = coreMLDetector
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
        case .hybrid:
            let coreMLResult = coreMLDetector.detectWithStatus(features: features)

            if !coreMLResult.outputs.isEmpty {
                return coreMLResult.outputs
            }

            guard let fallbackReason = coreMLResult.status.fallbackReason else {
                return []
            }

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
