import Foundation
import Testing
@testable import SleepSoundCore

@Suite("Health Metric Unit Conversion")
struct HealthMetricUnitConversionTests {
    @Test
    func bodyFatPercentageConvertsHealthKitFractionToDisplayPercent() {
        let value = HealthMetricUnitConverter.displayValue(
            metricType: .bodyFatPercentage,
            healthKitQuantityValue: 0.214
        )

        #expect(value == 21.4)
    }

    @Test
    func passthroughMetricsKeepHealthKitDisplayUnitValue() {
        #expect(
            HealthMetricUnitConverter.displayValue(
                metricType: .bodyMass,
                healthKitQuantityValue: 71.8
            ) == 71.8
        )
        #expect(
            HealthMetricUnitConverter.displayValue(
                metricType: .systolicBloodPressure,
                healthKitQuantityValue: 120
            ) == 120
        )
    }

    @Test
    func nonFiniteValuesClampToZeroForChartSafety() {
        #expect(
            HealthMetricUnitConverter.displayValue(
                metricType: .bodyMassIndex,
                healthKitQuantityValue: .nan
            ) == 0
        )
        #expect(
            HealthMetricUnitConverter.displayValue(
                metricType: .restingHeartRate,
                healthKitQuantityValue: .infinity
            ) == 0
        )
    }
}
