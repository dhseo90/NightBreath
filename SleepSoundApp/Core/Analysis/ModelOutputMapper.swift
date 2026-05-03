import Foundation

public struct ModelOutputMapper: Sendable {
    public static let multiclassEventLabels: [String] = [
        "snore",
        "bruxismLike",
        "gaspLike",
        "coughLike",
        "movementLike",
        "environmentalNoise",
        "sleepTalkLike",
        "unknown",
        "silence"
    ]

    public static let knownLabels: [String] = [
        "snore",
        "1",
        "non_snore",
        "0",
        "silence",
        "bruxism_like",
        "bruxismLike",
        "bruxism",
        "breathing_pause_suspected",
        "gasp_like",
        "gaspLike",
        "gasp",
        "cough_like",
        "coughLike",
        "cough",
        "sleep_talk_like",
        "sleepTalkLike",
        "sleep_talk",
        "movement_like",
        "movementLike",
        "movement",
        "environmental_noise",
        "environmentalNoise",
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
        case "non_snore", "0", "silence":
            .unknown
        case "bruxism_like", "bruxism":
            .bruxismLike
        case "breathing_pause_suspected":
            .breathingPauseSuspected
        case "gasp_like", "gasp":
            .gaspLike
        case "cough_like", "cough":
            .coughLike
        case "sleep_talk_like", "sleep_talk":
            .sleepTalkLike
        case "movement_like", "movement":
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
