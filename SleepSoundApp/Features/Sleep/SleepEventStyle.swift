import SwiftUI

extension SleepEventType {
    var timelineDisplayName: String {
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
            "움직임 의심 소리"
        case .environmentalNoise:
            "환경 소음"
        case .awakeningSuspected:
            "각성 의심 구간"
        case .unknown:
            "알 수 없음"
        }
    }

    var tintColor: Color {
        switch self {
        case .snore:
            NBColor.breath
        case .bruxismLike:
            NBColor.caution
        case .breathingPauseSuspected:
            NBColor.sleep
        case .gaspLike:
            NBColor.mistTeal
        case .coughLike:
            NBColor.warning
        case .sleepTalkLike:
            NBColor.lavender
        case .movementLike:
            NBColor.quietIndigo
        case .environmentalNoise:
            NBColor.neutral
        case .awakeningSuspected:
            NBColor.dawn
        case .unknown:
            NBColor.neutral
        }
    }

    var symbolName: String {
        switch self {
        case .snore:
            "waveform"
        case .bruxismLike:
            "diamond"
        case .breathingPauseSuspected:
            "pause.circle"
        case .gaspLike:
            "wind"
        case .coughLike:
            "waveform.badge.magnifyingglass"
        case .sleepTalkLike:
            "text.bubble"
        case .movementLike:
            "figure.roll"
        case .environmentalNoise:
            "speaker.wave.2"
        case .awakeningSuspected:
            "eye"
        case .unknown:
            "questionmark.circle"
        }
    }
}
