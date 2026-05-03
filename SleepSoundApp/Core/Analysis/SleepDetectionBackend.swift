import Foundation

public enum SleepDetectionBackend: String, CaseIterable, Codable, Sendable {
    case ruleBased
    case coreML
    case coreMLMulticlass
    case hybrid

    public var displayName: String {
        switch self {
        case .ruleBased:
            "Rule-based"
        case .coreML:
            "Core ML"
        case .coreMLMulticlass:
            "Core ML Multiclass"
        case .hybrid:
            "Hybrid"
        }
    }
}
