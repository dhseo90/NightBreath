import Foundation

public enum SampleLabel: String, Codable, CaseIterable, Identifiable, Sendable {
    case snore
    case bruxismLike
    case breathingPauseSuspected
    case gaspLike
    case coughLike
    case sleepTalkLike
    case movementLike
    case environmentalNoise
    case awakeningSuspected
    case unknown

    public var id: String {
        rawValue
    }

    public var eventType: SleepEventType {
        switch self {
        case .snore:
            .snore
        case .bruxismLike:
            .bruxismLike
        case .breathingPauseSuspected:
            .breathingPauseSuspected
        case .gaspLike:
            .gaspLike
        case .coughLike:
            .coughLike
        case .sleepTalkLike:
            .sleepTalkLike
        case .movementLike:
            .movementLike
        case .environmentalNoise:
            .environmentalNoise
        case .awakeningSuspected:
            .awakeningSuspected
        case .unknown:
            .unknown
        }
    }

    public var displayName: String {
        eventType.displayName
    }

    public var captureGuide: String {
        switch self {
        case .snore:
            "낮고 반복적인 코골기 후보를 짧게 수집합니다."
        case .bruxismLike:
            "짧고 날카로운 마찰음 또는 반복적인 고주파 패턴 후보를 수집합니다."
        case .breathingPauseSuspected:
            "긴 저에너지 구간 후보입니다. 상태를 확정하는 라벨이 아닙니다."
        case .gaspLike:
            "회복 호흡으로 의심되는 짧고 강한 소리 후보를 수집합니다."
        case .coughLike:
            "짧고 강한 burst 형태의 기침 의심 소리 후보를 수집합니다."
        case .sleepTalkLike:
            "말소리 여부만 라벨링하고 내용을 텍스트로 기록하지 않습니다."
        case .movementLike:
            "침구 마찰이나 기기 주변 움직임 의심 소리 후보를 수집합니다."
        case .environmentalNoise:
            "생활 소음, 외부 소리, 너무 큰 broadband noise 후보를 수집합니다."
        case .awakeningSuspected:
            "큰 소리나 움직임 뒤 각성 가능성이 있는 후보입니다."
        case .unknown:
            "분류하기 어려운 소리 후보를 안전하게 unknown으로 둡니다."
        }
    }
}
