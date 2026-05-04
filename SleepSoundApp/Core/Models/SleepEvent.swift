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

public struct SleepEvent: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var sessionId: UUID
    public var type: SleepEventType
    public var startedAt: Date
    public var endedAt: Date
    public var confidence: Double
    public var intensity: Double
    public var reviewedByUser: Bool
    public var audioSnippetFileName: String?
    public var audioSnippetDuration: TimeInterval?

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
        reviewedByUser: Bool = false,
        audioSnippetFileName: String? = nil,
        audioSnippetDuration: TimeInterval? = nil
    ) {
        self.id = id
        self.sessionId = sessionId
        self.type = type
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.confidence = min(max(confidence, 0), 1)
        self.intensity = min(max(intensity, 0), 1)
        self.reviewedByUser = reviewedByUser
        self.audioSnippetFileName = audioSnippetFileName
        if let audioSnippetDuration, audioSnippetDuration.isFinite, audioSnippetDuration > 0 {
            self.audioSnippetDuration = audioSnippetDuration
        } else {
            self.audioSnippetDuration = nil
        }
    }
}

public enum EventFeedbackSelection: String, CaseIterable, Identifiable, Sendable {
    case correct
    case incorrect
    case unsure

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .correct:
            "맞음"
        case .incorrect:
            "아님"
        case .unsure:
            "모르겠음"
        }
    }
}

extension EventFeedbackSelection: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        switch rawValue {
        case Self.correct.rawValue, "soundsLikeBruxism":
            self = .correct
        case Self.incorrect.rawValue, "notBruxism":
            self = .incorrect
        case Self.unsure.rawValue:
            self = .unsure
        default:
            self = .unsure
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public typealias SleepEventFeedbackSelection = EventFeedbackSelection

public enum EventFeedbackCorrectedLabel: String, Codable, CaseIterable, Identifiable, Sendable {
    case snore
    case bruxismLike
    case breathingPauseSuspected
    case gaspLike
    case coughLike
    case sleepTalkLike
    case movementLike
    case environmentalNoise
    case unknown

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .snore:
            SleepEventType.snore.displayName
        case .bruxismLike:
            SleepEventType.bruxismLike.displayName
        case .breathingPauseSuspected:
            SleepEventType.breathingPauseSuspected.displayName
        case .gaspLike:
            SleepEventType.gaspLike.displayName
        case .coughLike:
            SleepEventType.coughLike.displayName
        case .sleepTalkLike:
            SleepEventType.sleepTalkLike.displayName
        case .movementLike:
            SleepEventType.movementLike.displayName
        case .environmentalNoise:
            SleepEventType.environmentalNoise.displayName
        case .unknown:
            SleepEventType.unknown.displayName
        }
    }

    public var sleepEventType: SleepEventType {
        SleepEventType(rawValue: rawValue) ?? .unknown
    }
}

public struct EventFeedback: Identifiable, Codable, Equatable, Sendable {
    public static let unknownSessionId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    public var id: UUID
    public var eventId: UUID
    public var sessionId: UUID
    public var eventType: SleepEventType
    public var selectedFeedback: EventFeedbackSelection
    public var correctedLabel: EventFeedbackCorrectedLabel?
    public var createdAt: Date
    public var note: String?
    public var hasAudioSample: Bool
    public var audioSampleId: String?

    public init(
        id: UUID = UUID(),
        eventId: UUID,
        sessionId: UUID,
        eventType: SleepEventType,
        selectedFeedback: EventFeedbackSelection,
        correctedLabel: EventFeedbackCorrectedLabel? = nil,
        createdAt: Date = Date(),
        note: String? = nil,
        hasAudioSample: Bool = false,
        audioSampleId: String? = nil
    ) {
        self.id = id
        self.eventId = eventId
        self.sessionId = sessionId
        self.eventType = eventType
        self.selectedFeedback = selectedFeedback
        self.correctedLabel = correctedLabel
        self.createdAt = createdAt
        self.note = note
        self.hasAudioSample = hasAudioSample
        self.audioSampleId = audioSampleId?.isEmpty == false ? audioSampleId : nil
    }

    public init(
        id: UUID = UUID(),
        eventId: UUID,
        selectedFeedback: EventFeedbackSelection,
        createdAt: Date = Date(),
        note: String? = nil
    ) {
        self.init(
            id: id,
            eventId: eventId,
            sessionId: Self.unknownSessionId,
            eventType: .unknown,
            selectedFeedback: selectedFeedback,
            createdAt: createdAt,
            note: note
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case eventId
        case sessionId
        case eventType
        case selectedFeedback
        case correctedLabel
        case createdAt
        case note
        case hasAudioSample
        case audioSampleId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        eventId = try container.decode(UUID.self, forKey: .eventId)
        sessionId = try container.decodeIfPresent(UUID.self, forKey: .sessionId) ?? Self.unknownSessionId
        eventType = try container.decodeIfPresent(SleepEventType.self, forKey: .eventType) ?? .unknown
        selectedFeedback = try container.decodeIfPresent(EventFeedbackSelection.self, forKey: .selectedFeedback) ?? .unsure
        correctedLabel = try container.decodeIfPresent(EventFeedbackCorrectedLabel.self, forKey: .correctedLabel)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        note = try container.decodeIfPresent(String.self, forKey: .note)
        hasAudioSample = try container.decodeIfPresent(Bool.self, forKey: .hasAudioSample) ?? false
        audioSampleId = try container.decodeIfPresent(String.self, forKey: .audioSampleId)
    }
}

public typealias SleepEventFeedback = EventFeedback
