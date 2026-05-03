import Foundation

public enum DailyDataQuality: String, Codable, CaseIterable, Identifiable, Equatable, Sendable {
    case excellent
    case good
    case limited
    case poor
    case insufficient

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .excellent:
            "매우 충분"
        case .good:
            "충분"
        case .limited:
            "제한적"
        case .poor:
            "부족"
        case .insufficient:
            "매우 부족"
        }
    }

    public static func quality(for completenessScore: Double) -> DailyDataQuality {
        let score = clampedCompleteness(completenessScore)

        switch score {
        case 0.9...1:
            return .excellent
        case 0.7..<0.9:
            return .good
        case 0.45..<0.7:
            return .limited
        case 0.2..<0.45:
            return .poor
        default:
            return .insufficient
        }
    }

    public static func clampedCompleteness(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }
}
