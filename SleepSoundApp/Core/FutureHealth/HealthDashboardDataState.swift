import Foundation

public enum HealthDashboardDataOriginState: String, Codable, Equatable, Sendable {
    case previewOnly
    case previewAndLocalImport
    case healthKitOnly
    case mixedHealthKitAndLocal
    case localImportOnly
    case appComputedOnly
    case emptyAfterPermission
    case permissionBlockedNoLocalData
    case unavailableNoLocalData
    case waitingForConnection
}

public struct HealthDashboardDataStateSummary: Equatable, Sendable {
    public var state: HealthDashboardDataOriginState
    public var title: String
    public var message: String
    public var healthOrPreviewSampleCount: Int
    public var localImportSampleCount: Int
    public var appComputedSampleCount: Int
    public var shouldShowEmptyState: Bool

    public init(
        state: HealthDashboardDataOriginState,
        title: String,
        message: String,
        healthOrPreviewSampleCount: Int,
        localImportSampleCount: Int,
        appComputedSampleCount: Int,
        shouldShowEmptyState: Bool
    ) {
        self.state = state
        self.title = title
        self.message = message
        self.healthOrPreviewSampleCount = max(0, healthOrPreviewSampleCount)
        self.localImportSampleCount = max(0, localImportSampleCount)
        self.appComputedSampleCount = max(0, appComputedSampleCount)
        self.shouldShowEmptyState = shouldShowEmptyState
    }

    public static func make(
        permissionState: HealthMetricPermissionState,
        isPreviewData: Bool,
        healthOrPreviewSampleCount: Int,
        localImportSampleCount: Int,
        appComputedSampleCount: Int
    ) -> HealthDashboardDataStateSummary {
        let healthCount = max(0, healthOrPreviewSampleCount)
        let localCount = max(0, localImportSampleCount)
        let appCount = max(0, appComputedSampleCount)

        if isPreviewData && localCount > 0 {
            return HealthDashboardDataStateSummary(
                state: .previewAndLocalImport,
                title: "예시 + 로컬 import",
                message: "건강 데이터 연결 전 예시 샘플과 Fitdays CSV 로컬 import 샘플을 함께 표시합니다.",
                healthOrPreviewSampleCount: healthCount,
                localImportSampleCount: localCount,
                appComputedSampleCount: appCount,
                shouldShowEmptyState: false
            )
        }

        if isPreviewData && healthCount > 0 {
            return HealthDashboardDataStateSummary(
                state: .previewOnly,
                title: "예시 미리보기",
                message: "건강 데이터 연결 전에는 예시 샘플로 화면 구조를 먼저 보여줍니다.",
                healthOrPreviewSampleCount: healthCount,
                localImportSampleCount: localCount,
                appComputedSampleCount: appCount,
                shouldShowEmptyState: false
            )
        }

        if healthCount > 0 && localCount > 0 {
            return HealthDashboardDataStateSummary(
                state: .mixedHealthKitAndLocal,
                title: "Apple 건강앱 + 로컬 import",
                message: "Apple 건강앱 read-only 샘플과 Fitdays CSV 로컬 import 샘플을 출처별로 분리해 표시합니다.",
                healthOrPreviewSampleCount: healthCount,
                localImportSampleCount: localCount,
                appComputedSampleCount: appCount,
                shouldShowEmptyState: false
            )
        }

        if healthCount > 0 {
            return HealthDashboardDataStateSummary(
                state: .healthKitOnly,
                title: "Apple 건강앱 read-only",
                message: "허용된 Apple 건강앱 샘플만 읽어 표시합니다. 앱은 HealthKit에 데이터를 쓰지 않습니다.",
                healthOrPreviewSampleCount: healthCount,
                localImportSampleCount: localCount,
                appComputedSampleCount: appCount,
                shouldShowEmptyState: false
            )
        }

        if localCount > 0 {
            return HealthDashboardDataStateSummary(
                state: .localImportOnly,
                title: "로컬 import만 표시",
                message: "Apple 건강앱 샘플이 없어도 Fitdays CSV로 가져온 로컬 샘플은 전체 건강 지표와 건강 캘린더에서 볼 수 있습니다.",
                healthOrPreviewSampleCount: healthCount,
                localImportSampleCount: localCount,
                appComputedSampleCount: appCount,
                shouldShowEmptyState: false
            )
        }

        if appCount > 0 {
            return HealthDashboardDataStateSummary(
                state: .appComputedOnly,
                title: "앱 계산 지표만 표시",
                message: "수면 소리 점수와 오디오 커버리지처럼 밤숨 앱에서 계산한 로컬 지표만 표시합니다.",
                healthOrPreviewSampleCount: healthCount,
                localImportSampleCount: localCount,
                appComputedSampleCount: appCount,
                shouldShowEmptyState: false
            )
        }

        switch permissionState {
        case .readRequestCompleted:
            return HealthDashboardDataStateSummary(
                state: .emptyAfterPermission,
                title: "표시할 건강 지표 샘플이 없습니다",
                message: "권한이 허용되었더라도 항목별 권한 또는 데이터 유무에 따라 값이 비어 있을 수 있습니다.",
                healthOrPreviewSampleCount: healthCount,
                localImportSampleCount: localCount,
                appComputedSampleCount: appCount,
                shouldShowEmptyState: true
            )
        case .denied:
            return HealthDashboardDataStateSummary(
                state: .permissionBlockedNoLocalData,
                title: "건강 데이터 읽기 권한이 없습니다",
                message: "권한이 없어도 수면 소리 기능은 계속 사용할 수 있고, Fitdays CSV 로컬 import는 사용자가 직접 선택한 파일로만 진행합니다.",
                healthOrPreviewSampleCount: healthCount,
                localImportSampleCount: localCount,
                appComputedSampleCount: appCount,
                shouldShowEmptyState: true
            )
        case .unavailable:
            return HealthDashboardDataStateSummary(
                state: .unavailableNoLocalData,
                title: "건강 데이터 읽기를 사용할 수 없습니다",
                message: "지원되는 iPhone 실기기에서 Apple 건강앱 연결을 확인하거나, 로컬 import 가능한 CSV/text 파일만 직접 선택해 추가합니다.",
                healthOrPreviewSampleCount: healthCount,
                localImportSampleCount: localCount,
                appComputedSampleCount: appCount,
                shouldShowEmptyState: true
            )
        case .notRequested, .mockDataOnly:
            return HealthDashboardDataStateSummary(
                state: .waitingForConnection,
                title: "건강 데이터 연결 전입니다",
                message: "연결 버튼을 선택할 때만 읽기 권한을 요청합니다.",
                healthOrPreviewSampleCount: healthCount,
                localImportSampleCount: localCount,
                appComputedSampleCount: appCount,
                shouldShowEmptyState: false
            )
        }
    }
}
