import Foundation

public enum DevicePlacement: String, Codable, CaseIterable, Identifiable {
    case bedside
    case mattressSide
    case unknown

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .bedside:
            "침대 옆 협탁"
        case .mattressSide:
            "매트리스 옆"
        case .unknown:
            "미설정"
        }
    }
}

public struct SleepSession: Identifiable, Codable, Equatable {
    public var id: UUID
    public var startedAt: Date
    public var endedAt: Date?
    public var estimatedSleepStart: Date?
    public var estimatedWakeTime: Date?
    public var measurementDuration: TimeInterval
    public var estimatedSleepDuration: TimeInterval
    public var devicePlacement: DevicePlacement
    public var ambientNoiseBaseline: Double?
    public var appVersion: String
    public var modelVersion: String

    public init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date? = nil,
        estimatedSleepStart: Date? = nil,
        estimatedWakeTime: Date? = nil,
        measurementDuration: TimeInterval = 0,
        estimatedSleepDuration: TimeInterval = 0,
        devicePlacement: DevicePlacement = .unknown,
        ambientNoiseBaseline: Double? = nil,
        appVersion: String = "1.0",
        modelVersion: String = "mock-rule-v1"
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.estimatedSleepStart = estimatedSleepStart
        self.estimatedWakeTime = estimatedWakeTime
        self.measurementDuration = measurementDuration
        self.estimatedSleepDuration = estimatedSleepDuration
        self.devicePlacement = devicePlacement
        self.ambientNoiseBaseline = ambientNoiseBaseline
        self.appVersion = appVersion
        self.modelVersion = modelVersion
    }
}
