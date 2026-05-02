import Foundation

public struct HealthDashboardPlaceholder: Equatable {
    public var title: String
    public var message: String
    public var plannedMetrics: [HealthMetricType]

    public init(
        title: String = "건강 대시보드 확장 준비",
        message: String = "V1에서는 건강앱 권한을 요청하지 않고, 수면 중 소리 기반 지표에 집중합니다.",
        plannedMetrics: [HealthMetricType] = HealthMetricType.allCases
    ) {
        self.title = title
        self.message = message
        self.plannedMetrics = plannedMetrics
    }
}
