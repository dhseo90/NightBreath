import Foundation

public final class HealthKitService: HealthKitServiceProtocol, @unchecked Sendable {
    public init() {}

    public var isAvailable: Bool {
        false
    }

    public func authorizationStatusDescription() -> String {
        "건강앱 연결은 아직 준비 중입니다. 현재 화면은 mock data로만 동작합니다."
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
