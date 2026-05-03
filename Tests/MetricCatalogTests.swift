import Foundation
import Testing
@testable import SleepSoundCore

@Suite("MetricCatalog")
struct MetricCatalogTests {
    @Test
    func catalogContainsEveryUnifiedMetric() {
        let catalog = MetricCatalog.default
        let metadata = catalog.allMetrics()

        #expect(Set(metadata.map(\.metricID)) == Set(UnifiedHealthMetricID.allCases))
        #expect(metadata.count == UnifiedHealthMetricID.allCases.count)
    }

    @Test
    func healthKitBackedMetricsMatchCurrentReadOnlyServiceScope() {
        let catalog = MetricCatalog.default
        let healthKitBacked = Set(catalog.allMetrics().filter(\.isHealthKitBacked).map(\.metricID))
        let expected = Set(HealthMetricType.readOnlyHealthKitMetrics.map(UnifiedHealthMetricID.init(healthMetricType:)))

        #expect(healthKitBacked == expected)
        #expect(catalog.isHealthKitBacked(.systolicBloodPressure))
        #expect(catalog.isHealthKitBacked(.bodyFatPercentage))
        #expect(!catalog.isHealthKitBacked(.sleepDuration))
        #expect(!catalog.isHealthKitBacked(.visceralFatLevel))
    }

    @Test
    func fitdaysExtendedMetricsAreLocalOnlyBodyCompositionMetrics() throws {
        let catalog = MetricCatalog.default
        let extendedIDs: [UnifiedHealthMetricID] = [
            .visceralFatLevel,
            .visceralFatPercentage,
            .bodyWaterPercentage,
            .boneMass,
            .mineralMass,
            .skeletalMuscleMass,
            .muscleMass,
            .proteinPercentage,
            .subcutaneousFatPercentage,
            .metabolicAge,
            .bodyScore,
            .obesityLevel,
        ]

        for metricID in extendedIDs {
            let metadata = try #require(catalog.metadata(for: metricID))
            #expect(metadata.category == .bodyComposition)
            #expect(metadata.isExtendedLocalOnly)
            #expect(!metadata.isHealthKitBacked)
            #expect(metadata.disclaimer?.contains("HealthKit에서 직접 읽지 않고") == true)
        }

        let basalMetabolicRate = try #require(catalog.metadata(for: .basalMetabolicRate))
        #expect(basalMetabolicRate.category == .recovery)
        #expect(basalMetabolicRate.isExtendedLocalOnly)
    }

    @Test
    func fitdaysOverviewMetricsStayLocalOnlyAndOutsideHealthKitBackedScope() throws {
        let catalog = MetricCatalog.default
        let fitdaysMetricIDs = UnifiedHealthMetricOverviewGrouping.fitdaysExtendedMetricIDs

        #expect(!fitdaysMetricIDs.isEmpty)
        for metricID in fitdaysMetricIDs {
            let metadata = try #require(catalog.metadata(for: metricID))
            #expect(metadata.isExtendedLocalOnly, "\(metricID.rawValue) should stay local-only")
            #expect(!metadata.isHealthKitBacked, "\(metricID.rawValue) must not become HealthKit-backed")
            #expect(metricID.healthMetricType == nil, "\(metricID.rawValue) should not map to a HealthKit standard type")
        }

        #expect(!fitdaysMetricIDs.contains(.bodyMass))
        #expect(!fitdaysMetricIDs.contains(.bodyFatPercentage))
        #expect(!fitdaysMetricIDs.contains(.dailyRhythmScore))
        #expect(!fitdaysMetricIDs.contains(.sleepSoundScore))
    }

    @Test
    func categoryLookupKeepsBloodPressureActivityAndAppMetricsSeparated() {
        let catalog = MetricCatalog.default

        #expect(catalog.metrics(in: .bloodPressure).map(\.metricID) == [
            .systolicBloodPressure,
            .diastolicBloodPressure,
        ])
        #expect(Set(catalog.metrics(in: .activity).map(\.metricID)) == [
            .stepCount,
            .activeEnergy,
        ])
        #expect(Set(catalog.metrics(in: .app).map(\.metricID)) == [
            .sleepSoundScore,
            .dailyRhythmScore,
        ])
    }
}
