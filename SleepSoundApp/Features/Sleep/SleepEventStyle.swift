import SwiftUI

extension SleepEventType {
    var tintColor: Color {
        switch self {
        case .snore:
            Color.blue
        case .bruxismLike:
            Color.orange
        case .breathingPauseSuspected:
            Color.red
        case .gaspLike:
            Color.pink
        case .coughLike:
            Color.green
        case .sleepTalkLike:
            Color.purple
        case .movementLike:
            Color.teal
        case .environmentalNoise:
            Color.gray
        case .awakeningSuspected:
            Color.indigo
        case .unknown:
            Color.secondary
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
