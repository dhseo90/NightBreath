import Foundation

public struct ModelOutputMapper: Sendable {
    public static let knownLabels: [String] = [
        "snore",
        "1",
        "non_snore",
        "0",
        "bruxism_like",
        "breathing_pause_suspected",
        "gasp_like",
        "cough_like",
        "sleep_talk_like",
        "movement_like",
        "environmental_noise",
        "noise",
        "awakening_suspected",
        "unknown"
    ]

    public init() {}

    public static func normalizedLabel(_ label: String) -> String {
        let normalizedSeparators = label
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")

        var output = ""
        var previousWasLowercaseOrDigit = false

        for scalar in normalizedSeparators.unicodeScalars {
            if CharacterSet.uppercaseLetters.contains(scalar) {
                if previousWasLowercaseOrDigit, output.last != "_" {
                    output.append("_")
                }
                output.append(String(scalar).lowercased())
                previousWasLowercaseOrDigit = false
            } else {
                output.append(String(scalar).lowercased())
                previousWasLowercaseOrDigit =
                    CharacterSet.lowercaseLetters.contains(scalar) ||
                    CharacterSet.decimalDigits.contains(scalar)
            }
        }

        while output.contains("__") {
            output = output.replacingOccurrences(of: "__", with: "_")
        }

        return output.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    }

    public func eventType(for label: String) -> SleepEventType {
        switch Self.normalizedLabel(label) {
        case "snore", "1":
            .snore
        case "non_snore", "0":
            .unknown
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
        case "noise":
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
