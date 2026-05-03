import Foundation

public enum DailyHealthCardTemplate: String, Codable, CaseIterable, Identifiable, Equatable, Sendable {
    case simple
    case sleepFocused
    case healthSummary
    case privacyMinimal

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .simple:
            "기본"
        case .sleepFocused:
            "수면"
        case .healthSummary:
            "건강 요약"
        case .privacyMinimal:
            "프라이버시"
        }
    }

    public var shortDisplayName: String {
        switch self {
        case .simple:
            "기본"
        case .sleepFocused:
            "수면"
        case .healthSummary:
            "건강"
        case .privacyMinimal:
            "보호"
        }
    }

    public var summaryText: String {
        switch self {
        case .simple:
            "오늘의 리듬을 간단히 정리하는 카드입니다."
        case .sleepFocused:
            "지난밤 수면 소리와 오늘 리듬을 함께 정리하는 카드입니다."
        case .healthSummary:
            "수면, 활동, 컨디션, 건강 데이터를 사용 가능한 범위에서 함께 정리하는 카드입니다."
        case .privacyMinimal:
            "민감 수치를 줄이고 점수와 요약 중심으로 보여주는 카드입니다."
        }
    }

    public var effectivePrivacyLevel: DailyHealthCardPrivacyLevel? {
        self == .privacyMinimal ? .minimal : nil
    }
}

public enum DailyHealthCardPrivacyLevel: String, Codable, CaseIterable, Identifiable, Equatable, Sendable {
    case minimal
    case standard
    case detailed

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .minimal:
            "최소"
        case .standard:
            "표준"
        case .detailed:
            "상세"
        }
    }

    public var description: String {
        switch self {
        case .minimal:
            "오늘의 리듬 점수와 한 줄 요약만 표시합니다."
        case .standard:
            "주요 지표 값을 표시하고 source 세부 정보는 줄입니다."
        case .detailed:
            "주요 지표 값과 mock source, 기록 시간을 함께 표시합니다."
        }
    }

    public var includesSensitiveValues: Bool {
        self != .minimal
    }

    public var includesSourceDetails: Bool {
        self == .detailed
    }
}

public enum DailyHealthCardMetricSensitivity: String, Codable, Equatable, Sendable {
    case general
    case sleep
    case sensitiveHealth
}
