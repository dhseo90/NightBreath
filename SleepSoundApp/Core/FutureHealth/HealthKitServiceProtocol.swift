import Foundation

public enum HealthMetricPermissionState: String, Codable, Equatable, Sendable {
    case notRequested
    case readRequestCompleted
    case denied
    case unavailable
    case mockDataOnly

    public var displayName: String {
        switch self {
        case .notRequested:
            "요청 전"
        case .readRequestCompleted:
            "읽기 권한 요청 완료"
        case .denied:
            "권한 없음"
        case .unavailable:
            "사용할 수 없음"
        case .mockDataOnly:
            "Mock data only"
        }
    }

    public var canFetchSamples: Bool {
        switch self {
        case .readRequestCompleted, .mockDataOnly:
            true
        case .notRequested, .denied, .unavailable:
            false
        }
    }
}

public struct HealthMetricDateRange: Equatable, Sendable {
    public var start: Date
    public var end: Date

    public init(start: Date, end: Date) {
        if start <= end {
            self.start = start
            self.end = end
        } else {
            self.start = end
            self.end = start
        }
    }

    public func contains(_ date: Date) -> Bool {
        date >= start && date <= end
    }

    public static func days(_ dayCount: Int, endingAt endDate: Date = Date()) -> HealthMetricDateRange {
        let days = max(1, dayCount)
        return HealthMetricDateRange(
            start: endDate.addingTimeInterval(-Double(days) * 24 * 60 * 60),
            end: endDate
        )
    }
}

public protocol HealthKitServiceProtocol: Sendable {
    var isAvailable: Bool { get }
    func authorizationStatusDescription() -> String
    func requestReadPermission() async -> HealthMetricPermissionState
    func fetchSamples(metricType: HealthMetricType, dateRange: HealthMetricDateRange) async -> [HealthMetricSample]
    func fetchLatestSample(metricType: HealthMetricType) async -> HealthMetricSample?
}

public struct DisabledHealthKitService: HealthKitServiceProtocol {
    public var isAvailable: Bool { false }

    public init() {}

    public func authorizationStatusDescription() -> String {
        "이 기기에서는 건강앱 read-only 연결을 사용할 수 없습니다."
    }

    public func requestReadPermission() async -> HealthMetricPermissionState {
        .unavailable
    }

    public func fetchSamples(
        metricType: HealthMetricType,
        dateRange: HealthMetricDateRange
    ) async -> [HealthMetricSample] {
        []
    }

    public func fetchLatestSample(metricType: HealthMetricType) async -> HealthMetricSample? {
        nil
    }
}
