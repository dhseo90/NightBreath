import Foundation

public struct HealthDashboardPlaceholder: Equatable {
    public var title: String
    public var message: String
    public var plannedMetrics: [HealthMetricType]

    public init(
        title: String = "건강 데이터 대시보드",
        message: String = "Apple 건강앱 데이터를 read-only로 읽어 로컬 화면에 정리합니다. 건강 데이터 연결을 선택할 때만 권한을 요청합니다.",
        plannedMetrics: [HealthMetricType] = HealthMetricType.allCases
    ) {
        self.title = title
        self.message = message
        self.plannedMetrics = plannedMetrics
    }
}
