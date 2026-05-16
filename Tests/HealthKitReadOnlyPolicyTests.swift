import Foundation
import Testing
@testable import SleepSoundCore

@Suite("HealthKit Read-Only Policy")
struct HealthKitReadOnlyPolicyTests {
    @Test
    func realHealthKitServiceIsReadOnlyAndProtocolBacked() throws {
        let contents = try sourceContents("SleepSoundApp/Core/FutureHealth/HealthKitService.swift")

        #expect(contents.contains("public final class RealHealthKitService"))
        #expect(contents.contains("HealthKitServiceProtocol"))
        #expect(contents.contains("HealthDataServiceProtocol"))
        #expect(contents.contains("requestAuthorization"))
        #expect(contents.contains("toShare: Set<HKSampleType>()"))
        #expect(contents.contains("HKSampleQuery"))
        #expect(contents.contains("HKStatisticsCollectionQuery"))
        #expect(contents.contains(".cumulativeSum"))
        #expect(contents.contains("metricType.usesDailyCumulativeSum"))

        let forbiddenWriteSignatures = [
            ".save(",
            ".delete(",
            "HKDeletedObject",
            "HKWorkout",
            "HKCategorySample",
        ]

        for signature in forbiddenWriteSignatures {
            #expect(
                !contents.contains(signature),
                "RealHealthKitService must not contain HealthKit write/delete usage: \(signature)"
            )
        }
    }

    @Test
    func healthKitCapabilityAndUsageCopyAreReadOnly() throws {
        let entitlements = try sourceContents("SleepSoundApp/App/SleepSoundApp.entitlements")
        let infoPlist = try sourceContents("SleepSoundApp/App/Info.plist")
        let project = try sourceContents("SleepSoundApp.xcodeproj/project.pbxproj")

        #expect(entitlements.contains("com.apple.developer.healthkit"))
        #expect(project.contains("com.apple.HealthKit"))
        #expect(infoPlist.contains("NSHealthShareUsageDescription"))
        #expect(!infoPlist.contains("NSHealthUpdateUsageDescription"))
        #expect(infoPlist.contains("사용자가 건강 데이터 연결을 선택한 경우에만"))
        #expect(infoPlist.contains("HealthKit에 데이터를 쓰지 않고"))
        #expect(infoPlist.contains("서버로 전송하지 않습니다"))
    }

    @Test
    func healthKitPermissionRequestStaysBehindHealthDashboardConnectAction() throws {
        let expectedPaths: Set<String> = [
            "SleepSoundApp/Core/FutureHealth/HealthKitService.swift",
            "SleepSoundApp/Core/FutureHealth/HealthKitServiceProtocol.swift",
            "SleepSoundApp/Core/FutureHealth/MockHealthKitService.swift",
            "SleepSoundApp/Features/Dashboard/HealthDashboardView.swift",
        ]
        let actualPaths = try swiftFiles(containing: "requestReadPermission", under: "SleepSoundApp")
        let dashboard = try sourceContents("SleepSoundApp/Features/Dashboard/HealthDashboardView.swift")
        let appEntry = try sourceContents("SleepSoundApp/App/SleepSoundApp.swift")
        let sleepStart = try sourceContents("SleepSoundApp/Features/Sleep/SleepStartView.swift")

        #expect(actualPaths == expectedPaths)
        #expect(dashboard.contains("Button {\n          connectHealthData()"))
        #expect(dashboard.contains("let nextPermissionState = await service.requestReadPermission()"))
        #expect(dashboard.contains("버튼을 누를 때만 Apple 건강앱 읽기 권한을 요청합니다"))
        #expect(!appEntry.contains("requestReadPermission"))
        #expect(!sleepStart.contains("requestReadPermission"))
    }

    @Test
    func healthKitManualQARunbookCoversPermissionEvidenceAndNoWritePolicy() throws {
        let qaGuide = try sourceContents("Docs/QA_GUIDE.md")
        let checklist = try sourceContents("QA_CHECKLIST.md")
        let combined = qaGuide + "\n" + checklist

        #expect(qaGuide.contains("실기기 permission flow smoke"))
        #expect(qaGuide.contains("HealthKit sheet appeared on first launch: no"))
        #expect(qaGuide.contains("HealthKit sheet appeared on sleep start: no"))
        #expect(qaGuide.contains("HealthKit sheet appeared after health connect tap: yes / no"))
        #expect(qaGuide.contains("Write categories visible: no"))
        #expect(qaGuide.contains("Sensitive data included in repo: No"))
        #expect(checklist.contains("일부 허용 상태에서는 허용된 항목만 표시"))
        #expect(checklist.contains("HealthKit 권한 거부 후에도 수면 시작/종료"))
        #expect(combined.contains("HealthKit에 데이터를 쓰지 않습니다") || combined.contains("HealthKit save/delete API"))

        let forbiddenClaims = [
            "건강 데이터에 씁니다",
            "HealthKit write를 사용합니다",
            "첫 실행에서 HealthKit 권한을 요청합니다",
            "수면 시작 시 HealthKit 권한을 요청합니다",
        ]

        for claim in forbiddenClaims {
            #expect(!combined.contains(claim), "HealthKit QA runbook should not contain forbidden claim: \(claim)")
        }
    }

    @Test
    func readOnlyMetricsCoverBloodPressureBodyCompositionAndActivity() {
        let metrics = Set(HealthMetricType.readOnlyHealthKitMetrics)

        #expect(metrics.contains(.systolicBloodPressure))
        #expect(metrics.contains(.diastolicBloodPressure))
        #expect(metrics.contains(.bodyMass))
        #expect(metrics.contains(.bodyFatPercentage))
        #expect(metrics.contains(.bodyMassIndex))
        #expect(metrics.contains(.leanBodyMass))
        #expect(metrics.contains(.stepCount))
        #expect(metrics.contains(.activeEnergy))
        #expect(metrics.contains(.heartRate))
        #expect(metrics.contains(.restingHeartRate))
        #expect(metrics.contains(.respiratoryRate))
        #expect(!metrics.contains(.sleepDuration))
    }

    @Test
    func permissionStatesGateFetchBehaviorExplicitly() {
        #expect(!HealthMetricPermissionState.notRequested.canFetchSamples)
        #expect(HealthMetricPermissionState.readRequestCompleted.canFetchSamples)
        #expect(!HealthMetricPermissionState.denied.canFetchSamples)
        #expect(!HealthMetricPermissionState.unavailable.canFetchSamples)
        #expect(HealthMetricPermissionState.mockDataOnly.canFetchSamples)
    }

    @Test
    func disabledHealthKitServiceReturnsSafeUnavailableAndEmptyState() async {
        let service = DisabledHealthKitService()
        let samples = await service.fetchSamples(
            metricType: .bodyMass,
            dateRange: .days(30, endingAt: Date())
        )

        #expect(service.isAvailable == false)
        #expect(await service.requestReadPermission() == .unavailable)
        #expect(samples.isEmpty)
        #expect(await service.fetchLatestSample(metricType: .bodyMass) == nil)
    }

    @Test
    func deniedPermissionStateKeepsSamplesEmpty() async {
        let service = DeniedHealthKitService()
        let samples = await service.fetchSamples(
            metricType: .systolicBloodPressure,
            dateRange: .days(7, endingAt: Date())
        )

        #expect(service.isAvailable)
        #expect(await service.requestReadPermission() == .denied)
        #expect(samples.isEmpty)
    }

    @Test
    func partialReadPermissionStateReturnsOnlyAllowedMetricSamples() async {
        let service = PartialReadCompletedHealthKitService()
        let bloodPressureSamples = await service.fetchSamples(
            metricType: .systolicBloodPressure,
            dateRange: .days(7, endingAt: referenceDate)
        )
        let bodyMassSamples = await service.fetchSamples(
            metricType: .bodyMass,
            dateRange: .days(7, endingAt: referenceDate)
        )

        #expect(service.isAvailable)
        #expect(await service.requestReadPermission() == .readRequestCompleted)
        #expect(bloodPressureSamples.count == 1)
        #expect(bodyMassSamples.isEmpty)
    }

    @Test
    func emptyDataStateKeepsReadRequestCompletedButReturnsNoSamples() async {
        let service = EmptyReadCompletedHealthKitService()
        let samples = await service.fetchSamples(
            metricType: .bodyMass,
            dateRange: .days(7, endingAt: Date())
        )

        #expect(service.isAvailable)
        #expect(await service.requestReadPermission() == .readRequestCompleted)
        #expect(samples.isEmpty)
        #expect(await service.fetchLatestSample(metricType: .bodyMass) == nil)
    }

    @Test
    func healthKitAndFitdaysSamplesRemainDistinctInMixedSourceState() {
        let healthKitSample = HealthMetricSample(
            metricType: .bodyMass,
            value: 71.6,
            unit: "kg",
            measuredAt: referenceDate,
            sourceName: "Apple 건강앱",
            sourceBundleIdentifier: "com.apple.Health"
        ).unifiedSample(sourceType: .healthKit)
        let fitdaysSample = UnifiedHealthMetricSample(
            metricID: .bodyWaterPercentage,
            value: 56.8,
            unit: "%",
            measuredAt: referenceDate,
            sourceType: .fitdaysCSV,
            sourceName: "Fitdays CSV Import",
            importBatchId: "synthetic-batch",
            createdAt: referenceDate
        )
        let summary = HealthCalendarBuilder().summary(
            for: referenceDate,
            samples: [healthKitSample, fitdaysSample],
            sleepReports: [],
            calendar: calendar
        )

        #expect(healthKitSample.sourceType == .healthKit)
        #expect(fitdaysSample.sourceType == .fitdaysCSV)
        #expect(summary.sourceTypes == [.healthKit, .fitdaysCSV])
        #expect(summary.hasBodyComposition)
    }

    @Test
    func healthDashboardDataStateKeepsLocalImportsVisibleWithoutHealthKitSamples() {
        let deniedWithLocalImport = HealthDashboardDataStateSummary.make(
            permissionState: .denied,
            isPreviewData: false,
            healthOrPreviewSampleCount: 0,
            localImportSampleCount: 4,
            appComputedSampleCount: 0
        )
        let emptyAfterPermission = HealthDashboardDataStateSummary.make(
            permissionState: .readRequestCompleted,
            isPreviewData: false,
            healthOrPreviewSampleCount: 0,
            localImportSampleCount: 0,
            appComputedSampleCount: 0
        )
        let mixed = HealthDashboardDataStateSummary.make(
            permissionState: .readRequestCompleted,
            isPreviewData: false,
            healthOrPreviewSampleCount: 3,
            localImportSampleCount: 2,
            appComputedSampleCount: 1
        )
        let previewWithLocal = HealthDashboardDataStateSummary.make(
            permissionState: .notRequested,
            isPreviewData: true,
            healthOrPreviewSampleCount: 12,
            localImportSampleCount: 2,
            appComputedSampleCount: 0
        )

        #expect(deniedWithLocalImport.state == .localImportOnly)
        #expect(!deniedWithLocalImport.shouldShowEmptyState)
        #expect(deniedWithLocalImport.message.contains("Fitdays CSV"))
        #expect(emptyAfterPermission.state == .emptyAfterPermission)
        #expect(emptyAfterPermission.shouldShowEmptyState)
        #expect(mixed.state == .mixedHealthKitAndLocal)
        #expect(mixed.message.contains("출처별로 분리"))
        #expect(previewWithLocal.state == .previewAndLocalImport)
        #expect(previewWithLocal.message.contains("예시 샘플과 Fitdays CSV 로컬 import"))
    }

    @Test
    func healthDashboardViewDocumentsEdgeStatesAndLocalImportOverview() throws {
        let contents = try sourceContents("SleepSoundApp/Features/Dashboard/HealthDashboardView.swift")

        #expect(contents.contains("dataStateSection"))
        #expect(contents.contains("HealthDashboardDataStateSummary.make"))
        #expect(contents.contains("localImportOverviewSection"))
        #expect(contents.contains("로컬 import 최근 값"))
        #expect(contents.contains("Fitdays CSV/text import 값은 HealthKit에 쓰지 않고"))
        #expect(contents.contains("healthKitDashboardLookbackDays = 370"))
        #expect(contents.contains("최근 1년 범위"))
        #expect(contents.contains("원본 앱의 Apple 건강앱 동기화 상태"))
        #expect(contents.contains("hasRequestedHealthKitReadAccess"))
        #expect(contents.contains("refreshHealthDataIfPreviouslyConnected"))
        #expect(contents.contains("HealthKit 읽기 결과"))
        #expect(contents.contains("혈압 HealthKit 샘플"))
        #expect(contents.contains("HealthDataRefreshFeedback"))
        #expect(contents.contains("healthDataRefreshFeedbackView"))
        #expect(contents.contains("healthRefreshFeedbackSummary"))
        #expect(contents.contains("HealthRefreshFeedbackSummary"))
        #expect(contents.contains("startedAt: Date"))
        #expect(contents.contains("NBInlineStatus"))
        #expect(contents.contains("새로고침 완료 ·"))
        #expect(contents.contains("완료되기 전까지 버튼은 비활성화됩니다."))
        #expect(contents.contains("건강앱 읽는 중"))
        #expect(contents.contains("shouldShowPreviewHealthSamples"))
        #expect(contents.contains("sampleCount: importedUnifiedSamples.count"))
        #expect(contents.contains("latestImportedUnifiedDate"))
    }

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_777_680_000)
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func sourceContents(_ relativePath: String) throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
    }

    private func swiftFiles(containing needle: String, under relativePath: String) throws -> Set<String> {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let searchRoot = root.appendingPathComponent(relativePath)
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey]
        let enumerator = try #require(
            FileManager.default.enumerator(
                at: searchRoot,
                includingPropertiesForKeys: resourceKeys
            )
        )
        var matches: Set<String> = []

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "swift" else { continue }
            let values = try fileURL.resourceValues(forKeys: Set(resourceKeys))
            guard values.isRegularFile == true else { continue }

            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            if contents.contains(needle) {
                matches.insert(fileURL.path.replacingOccurrences(of: root.path + "/", with: ""))
            }
        }

        return matches
    }

    private struct DeniedHealthKitService: HealthKitServiceProtocol {
        var isAvailable: Bool { true }

        func authorizationStatusDescription() -> String {
            "건강 데이터 읽기 권한이 필요합니다."
        }

        func requestReadPermission() async -> HealthMetricPermissionState {
            .denied
        }

        func fetchSamples(
            metricType: HealthMetricType,
            dateRange: HealthMetricDateRange
        ) async -> [HealthMetricSample] {
            []
        }

        func fetchLatestSample(metricType: HealthMetricType) async -> HealthMetricSample? {
            nil
        }
    }

    private struct EmptyReadCompletedHealthKitService: HealthKitServiceProtocol {
        var isAvailable: Bool { true }

        func authorizationStatusDescription() -> String {
            "읽기 권한 요청 완료"
        }

        func requestReadPermission() async -> HealthMetricPermissionState {
            .readRequestCompleted
        }

        func fetchSamples(
            metricType: HealthMetricType,
            dateRange: HealthMetricDateRange
        ) async -> [HealthMetricSample] {
            []
        }

        func fetchLatestSample(metricType: HealthMetricType) async -> HealthMetricSample? {
            nil
        }
    }

    private struct PartialReadCompletedHealthKitService: HealthKitServiceProtocol {
        var isAvailable: Bool { true }

        private var sample: HealthMetricSample {
            HealthMetricSample(
                metricType: .systolicBloodPressure,
                value: 118,
                unit: "mmHg",
                measuredAt: Date(timeIntervalSince1970: 1_777_680_000),
                sourceName: "Apple 건강앱",
                sourceBundleIdentifier: "com.apple.Health"
            )
        }

        func authorizationStatusDescription() -> String {
            "일부 항목 읽기 권한 요청 완료"
        }

        func requestReadPermission() async -> HealthMetricPermissionState {
            .readRequestCompleted
        }

        func fetchSamples(
            metricType: HealthMetricType,
            dateRange: HealthMetricDateRange
        ) async -> [HealthMetricSample] {
            guard metricType == sample.metricType, dateRange.contains(sample.measuredAt) else {
                return []
            }
            return [sample]
        }

        func fetchLatestSample(metricType: HealthMetricType) async -> HealthMetricSample? {
            metricType == sample.metricType ? sample : nil
        }
    }
}
