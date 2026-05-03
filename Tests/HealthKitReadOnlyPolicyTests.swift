import Foundation
import Testing
@testable import SleepSoundCore

@Suite("HealthKit Read-Only Policy")
struct HealthKitReadOnlyPolicyTests {
    @Test
    func healthKitServiceRequestsReadOnlyAuthorization() throws {
        let contents = try sourceContents("SleepSoundApp/Core/FutureHealth/HealthKitService.swift")

        #expect(contents.contains("toShare: Set<HKSampleType>()"))

        let forbiddenWriteSignatures = [
            ".save(",
            ".delete(",
            "HKDeletedObject",
            "HKWorkout",
        ]

        for signature in forbiddenWriteSignatures {
            #expect(
                !contents.contains(signature),
                "HealthKitService.swift must not contain HealthKit write/delete usage: \(signature)"
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
