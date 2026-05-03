import Foundation

public enum LifestyleTag: String, Codable, CaseIterable, Identifiable, Equatable, Sendable {
    case caffeine
    case alcohol
    case lateMeal
    case stress
    case nap
    case exercise
    case illness
    case travel
    case lateScreenUse

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .caffeine:
            "카페인"
        case .alcohol:
            "음주"
        case .lateMeal:
            "늦은 식사"
        case .stress:
            "스트레스"
        case .nap:
            "낮잠"
        case .exercise:
            "운동"
        case .illness:
            "컨디션 저하"
        case .travel:
            "이동/여행"
        case .lateScreenUse:
            "늦은 화면 사용"
        }
    }
}
