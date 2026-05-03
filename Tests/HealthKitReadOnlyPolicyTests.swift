import Foundation
import Testing
@testable import SleepSoundCore

@Suite("HealthKit Read-Only Policy")
struct HealthKitReadOnlyPolicyTests {
    @Test
    func actualHealthKitImplementationIsNotPresentYet() throws {
        let contents = try sourceContents("SleepSoundApp/Core/FutureHealth/HealthKitService.swift")
        let entitlements = try sourceContents("SleepSoundApp/App/SleepSoundApp.entitlements")
        let infoPlist = try sourceContents("SleepSoundApp/App/Info.plist")
        let project = try sourceContents("SleepSoundApp.xcodeproj/project.pbxproj")

        let forbiddenHealthKitSignatures = [
            "import HealthKit",
            "HKHealthStore",
            "requestAuthorization",
            "HKSampleQuery",
            "HKAnchoredObjectQuery",
            "HKObserverQuery",
            "HKSampleType",
            "HKQuantityType",
            "HKDeletedObject",
            "HKWorkout",
            "NSHealthShareUsageDescription",
            "com.apple.developer.healthkit",
            "com.apple.HealthKit",
        ]

        for signature in forbiddenHealthKitSignatures {
            #expect(
                !contents.contains(signature),
                "HealthKitService.swift must not contain actual HealthKit implementation: \(signature)"
            )
            #expect(
                !entitlements.contains(signature),
                "Entitlements must not enable HealthKit before the real read-only integration task: \(signature)"
            )
            #expect(
                !infoPlist.contains(signature),
                "Info.plist must not include HealthKit permission copy before the real integration task: \(signature)"
            )
            #expect(
                !project.contains(signature),
                "Xcode project must not enable HealthKit capability before the real integration task: \(signature)"
            )
        }
    }

    @Test
    func readOnlyMetricsCoverBloodPressureAndBodyComposition() {
        let metrics = Set(HealthMetricType.readOnlyHealthKitMetrics)

        #expect(metrics.contains(.systolicBloodPressure))
        #expect(metrics.contains(.diastolicBloodPressure))
        #expect(metrics.contains(.bodyMass))
        #expect(metrics.contains(.bodyFatPercentage))
        #expect(metrics.contains(.bodyMassIndex))
        #expect(metrics.contains(.leanBodyMass))
        #expect(metrics.contains(.restingHeartRate))
        #expect(metrics.contains(.respiratoryRate))
        #expect(!metrics.contains(.sleepDuration))
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

    private func sourceContents(_ relativePath: String) throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
    }
}
