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
    func healthKitStandardMetricImportedFromFitdaysKeepsFitdaysSourceMetadata() throws {
        let sample = UnifiedHealthMetricSample(
            id: UUID(uuidString: "41000000-0000-0000-0000-000000000003")!,
            metricID: .bodyMass,
            value: 71.8,
            unit: "kg",
            measuredAt: referenceDate,
            sourceType: .fitdaysCSV,
            sourceName: "Fitdays CSV Import",
            sourceBundleIdentifier: nil,
            externalRecordId: "synthetic-file#row2#bodyMass",
            importBatchId: "synthetic-batch",
            createdAt: referenceDate
        )

        let displayModel = try #require(sample.displayModel())

        #expect(MetricCatalog.default.isHealthKitBacked(sample.metricID))
        #expect(sample.sourceType == .fitdaysCSV)
        #expect(displayModel.metadata.isHealthKitBacked)
        #expect(displayModel.sourceText.contains("Fitdays CSV"))
        #expect(!displayModel.sourceText.contains("Apple 건강앱"))
    }

    @Test
    func healthMetricSampleMapperDefaultsToHealthKitButCanPreserveExplicitImportSource() {
        let healthSample = HealthMetricSample(
            metricType: .bodyFatPercentage,
            value: 21.4,
            unit: "%",
            measuredAt: referenceDate,
            sourceName: "Fitdays CSV Import",
            sourceBundleIdentifier: "synthetic.fitdays.export"
        )

        let defaultMapped = healthSample.unifiedSample(createdAt: referenceDate)
        let importMapped = healthSample.unifiedSample(
            sourceType: .fitdaysCSV,
            externalRecordId: "synthetic-row",
            importBatchId: "synthetic-batch",
            createdAt: referenceDate
        )

        #expect(defaultMapped.sourceType == .healthKit)
        #expect(importMapped.metricID == .bodyFatPercentage)
        #expect(importMapped.sourceType == .fitdaysCSV)
        #expect(importMapped.importBatchId == "synthetic-batch")
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
