import Foundation
import Testing
@testable import SleepSoundCore

@Suite("UnifiedHealthMetricSample")
struct UnifiedHealthMetricSampleTests {
    @Test
    func sampleStoresSourceImportAndRecordMetadata() {
        let sample = UnifiedHealthMetricSample(
            id: UUID(uuidString: "41000000-0000-0000-0000-000000000001")!,
            metricID: .skeletalMuscleMass,
            value: 31.2,
            unit: "kg",
            measuredAt: referenceDate,
            sourceType: .fitdaysCSV,
            sourceName: "Fitdays CSV Import",
            externalRecordId: "fitdays-row-10",
            importBatchId: "batch-2026-05",
            notes: "사용자가 가져온 예시 값",
            createdAt: referenceDate
        )

        #expect(sample.metricID == .skeletalMuscleMass)
        #expect(sample.sourceType == .fitdaysCSV)
        #expect(sample.sourceBundleIdentifier == nil)
        #expect(sample.externalRecordId == "fitdays-row-10")
        #expect(sample.importBatchId == "batch-2026-05")
        #expect(sample.notes == "사용자가 가져온 예시 값")
    }

    @Test
    func nonFiniteValuesAreClampedToZero() {
        let sample = UnifiedHealthMetricSample(
            metricID: .bodyWaterPercentage,
            value: .nan,
            unit: "%",
            measuredAt: referenceDate,
            sourceType: .manual,
            sourceName: "수동 입력",
            createdAt: referenceDate
        )

        #expect(sample.value == 0)
    }

    @Test
    func codableRoundTripPreservesExtendedMetricFields() throws {
        let sample = UnifiedHealthMetricSample(
            id: UUID(uuidString: "41000000-0000-0000-0000-000000000002")!,
            metricID: .basalMetabolicRate,
            value: 1_520,
            unit: "kcal/day",
            measuredAt: referenceDate,
            sourceType: .fitdaysCSV,
            sourceName: "Fitdays CSV Import",
            externalRecordId: "row-42",
            importBatchId: "batch-a",
            createdAt: referenceDate
        )

        let encoded = try JSONEncoder().encode(sample)
        let decoded = try JSONDecoder().decode(UnifiedHealthMetricSample.self, from: encoded)

        #expect(decoded == sample)
    }

    @Test
    func sourceTypesExposeExpectedCases() {
        #expect(Set(HealthMetricSourceType.allCases) == [
            .healthKit,
            .fitdaysCSV,
            .manual,
            .appComputed,
            .mock,
        ])
        #expect(HealthMetricSourceType.healthKit.displayName == "Apple 건강앱")
        #expect(HealthMetricSourceType.appComputed.displayName == "앱 계산값")
    }

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_777_680_000)
    }
}
