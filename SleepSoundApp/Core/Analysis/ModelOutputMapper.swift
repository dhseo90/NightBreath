import Foundation

public struct ModelOutputMapper: Sendable {
    public static let knownLabels: [String] = [
        "snore",
        "bruxism_like",
        "breathing_pause_suspected",
        "gasp_like",
        "cough_like",
        "sleep_talk_like",
        "movement_like",
        "environmental_noise",
        "awakening_suspected",
        "unknown"
    ]

    public init() {}

    public func eventType(for label: String) -> SleepEventType {
        switch label {
        case "snore":
            .snore
        case "bruxism_like":
            .bruxismLike
        case "breathing_pause_suspected":
            .breathingPauseSuspected
        case "gasp_like":
            .gaspLike
        case "cough_like":
            .coughLike
        case "sleep_talk_like":
            .sleepTalkLike
        case "movement_like":
            .movementLike
        case "environmental_noise":
            .environmentalNoise
        case "awakening_suspected":
            .awakeningSuspected
        case "unknown":
            .unknown
        default:
            .unknown
        }
    }

    public func makeOutput(
        label: String,
        confidence: Double,
        features: AudioFeatures,
        debugReason: String? = nil
    ) -> DetectorOutput {
        DetectorOutput(
            eventType: eventType(for: label),
            startedAt: features.startedAt,
            endedAt: features.endedAt,
            confidence: confidence,
            intensity: features.rms,
            debugReason: debugReason ?? "Core ML label=\(label)"
        )
    }

    public func makeOutput(
        prediction: ModelPrediction,
        features: AudioFeatures,
        debugReason: String? = nil
    ) -> DetectorOutput {
        makeOutput(
            label: prediction.label,
            confidence: prediction.confidence,
            features: features,
            debugReason: debugReason
        )
    }
}
