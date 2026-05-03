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
