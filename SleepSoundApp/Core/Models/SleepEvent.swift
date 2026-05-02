import Foundation

public enum SleepEventType: String, Codable, CaseIterable, Identifiable, Sendable {
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

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .snore:
            "코골기"
        case .bruxismLike:
            "이갈이 의심 소리"
        case .breathingPauseSuspected:
            "호흡정지 의심 구간"
        case .gaspLike:
            "gasp-like 회복 호흡"
        case .coughLike:
            "기침 의심 소리"
        case .sleepTalkLike:
            "잠꼬대/말소리 의심"
        case .movementLike:
            "침구 마찰/움직임 의심 소리"
        case .environmentalNoise:
            "환경 소음"
        case .awakeningSuspected:
            "각성 의심 구간"
        case .unknown:
            "알 수 없는 소리"
        }
    }
}

public struct SleepEvent: Identifiable, Codable, Equatable {
    public var id: UUID
    public var sessionId: UUID
    public var type: SleepEventType
    public var startedAt: Date
    public var endedAt: Date
    public var confidence: Double
    public var intensity: Double
    public var reviewedByUser: Bool

    public var duration: TimeInterval {
        max(0, endedAt.timeIntervalSince(startedAt))
    }

    public init(
        id: UUID = UUID(),
        sessionId: UUID,
        type: SleepEventType,
        startedAt: Date,
        endedAt: Date,
        confidence: Double,
        intensity: Double,
        reviewedByUser: Bool = false
    ) {
        self.id = id
        self.sessionId = sessionId
        self.type = type
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.confidence = min(max(confidence, 0), 1)
        self.intensity = min(max(intensity, 0), 1)
        self.reviewedByUser = reviewedByUser
    }
}
