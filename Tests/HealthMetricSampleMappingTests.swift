import Foundation
import Testing
@testable import SleepSoundCore

@Suite("HealthMetricSample mapping")
struct HealthMetricSampleMappingTests {
    @Test
    func healthMetricSampleMapsToUnifiedSampleWithHealthKitSource() {
        let sample = makeSample(metricType: .systolicBloodPressure, value: 120, unit: "mmHg")

        let unified = sample.unifiedSample(createdAt: referenceDate)

        #expect(unified.metricID == .systolicBloodPressure)
        #expect(unified.value == 120)
        #expect(unified.unit == "mmHg")
        #expect(unified.measuredAt == referenceDate)
        #expect(unified.sourceType == .healthKit)
        #expect(unified.sourceName == "Apple Health")
        #expect(unified.sourceBundleIdentifier == "com.apple.Health")
    }

    @Test
    func healthMetricSampleMappingCanOverrideSourceForMockOrManualImports() {
        let sample = makeSample(metricType: .bodyMass, value: 71.5, unit: "kg")

        let unified = sample.unifiedSample(
            sourceType: .mock,
            externalRecordId: "mock-row-1",
            importBatchId: "mock-batch",
            notes: "Preview sample",
            createdAt: referenceDate
        )

        #expect(unified.metricID == .bodyMass)
        #expect(unified.sourceType == .mock)
        #expect(unified.externalRecordId == "mock-row-1")
        #expect(unified.importBatchId == "mock-batch")
        #expect(unified.notes == "Preview sample")
    }

    @Test
    func everyExistingHealthMetricTypeHasUnifiedMetricIDMapping() {
        for metricType in HealthMetricType.allCases {
            let metricID = UnifiedHealthMetricID(healthMetricType: metricType)
            #expect(metricID.healthMetricType == metricType)
        }
    }

    @Test
    func unifiedSampleBuildsDisplayModelFromCatalogMetadata() throws {
        let sample = UnifiedHealthMetricSample(
            metricID: .visceralFatPercentage,
            value: 11.4,
            unit: "%",
            measuredAt: referenceDate,
            sourceType: .fitdaysCSV,
            sourceName: "Fitdays CSV Import",
            createdAt: referenceDate
        )

        let displayModel = try #require(sample.displayModel())

        #expect(displayModel.metadata.metricID == .visceralFatPercentage)
        #expect(displayModel.metadata.displayNameKo == "복부지방률")
        #expect(displayModel.metadata.isExtendedLocalOnly)
        #expect(displayModel.valueText == "11.4 %")
        #expect(displayModel.sourceText == "Fitdays CSV · Fitdays CSV Import")
    }

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_777_680_000)
    }

    private func makeSample(
        metricType: HealthMetricType,
        value: Double,
        unit: String
    ) -> HealthMetricSample {
        HealthMetricSample(
            id: UUID(uuidString: "42000000-0000-0000-0000-000000000001")!,
            metricType: metricType,
            value: value,
            unit: unit,
            measuredAt: referenceDate,
            sourceName: "Apple Health",
            sourceBundleIdentifier: "com.apple.Health"
        )
    }
}
