import Foundation

public struct DetectionSmoothingPolicy: Equatable, Sendable {
    public var minimumEventDuration: TimeInterval
    public var maximumMergeGap: TimeInterval
    public var confidenceThreshold: Double
    public var mergeSameTypeEvents: Bool

    public init(
        minimumEventDuration: TimeInterval = 0.2,
        maximumMergeGap: TimeInterval = 1.0,
        confidenceThreshold: Double = 0.35,
        mergeSameTypeEvents: Bool = true
    ) {
        self.minimumEventDuration = max(0, minimumEventDuration)
        self.maximumMergeGap = max(0, maximumMergeGap)
        self.confidenceThreshold = min(max(confidenceThreshold, 0), 1)
        self.mergeSameTypeEvents = mergeSameTypeEvents
    }

    public func apply(to outputs: [DetectorOutput]) -> [DetectorOutput] {
        let filteredOutputs = outputs
            .filter { output in
                output.confidence >= confidenceThreshold &&
                    output.duration >= minimumEventDuration &&
                    output.duration.isFinite
            }
            .sorted { lhs, rhs in
                if lhs.startedAt == rhs.startedAt {
                    return lhs.eventType.rawValue < rhs.eventType.rawValue
                }
                return lhs.startedAt < rhs.startedAt
            }

        guard mergeSameTypeEvents else {
            return filteredOutputs
        }

        return filteredOutputs.reduce(into: [DetectorOutput]()) { partialResult, output in
            guard let lastOutput = partialResult.last,
                  lastOutput.eventType == output.eventType,
                  output.startedAt.timeIntervalSince(lastOutput.endedAt) <= maximumMergeGap else {
                partialResult.append(output)
                return
            }

            partialResult[partialResult.count - 1] = merge(lastOutput, output)
        }
    }

    private func merge(_ lhs: DetectorOutput, _ rhs: DetectorOutput) -> DetectorOutput {
        let startedAt = min(lhs.startedAt, rhs.startedAt)
        let endedAt = max(lhs.endedAt, rhs.endedAt)
        let confidence = max(lhs.confidence, rhs.confidence)
        let intensity = max(lhs.intensity, rhs.intensity)
        let reasons: [String] = [lhs.debugReason, rhs.debugReason].compactMap { reason -> String? in
            guard let reason, !reason.isEmpty else { return nil }
            return reason
        }

        return DetectorOutput(
            eventType: lhs.eventType,
            startedAt: startedAt,
            endedAt: endedAt,
            confidence: confidence,
            intensity: intensity,
            debugReason: reasons.isEmpty ? nil : reasons.joined(separator: " / ")
        )
    }
}
