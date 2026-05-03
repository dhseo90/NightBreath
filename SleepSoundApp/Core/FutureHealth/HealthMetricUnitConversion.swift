import Foundation

public enum HealthMetricUnitConverter {
    public static func displayValue(
        metricType: HealthMetricType,
        healthKitQuantityValue: Double
    ) -> Double {
        guard healthKitQuantityValue.isFinite else { return 0 }

        switch metricType {
        case .bodyFatPercentage:
            return healthKitQuantityValue * 100
        default:
            return healthKitQuantityValue
        }
    }
}
