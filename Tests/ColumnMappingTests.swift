import Testing
@testable import SleepSoundCore

@Suite("Fitdays Column Mapping")
struct ColumnMappingTests {
    @Test
    func defaultMappingCoversFitdaysExtendedMetrics() throws {
        let mapping = FitdaysCSVColumnMapping.fitdaysDefault

        #expect(mapping.metricID(for: "Weight") == .bodyMass)
        #expect(mapping.metricID(for: "BMI") == .bodyMassIndex)
        #expect(mapping.metricID(for: "Body Fat") == .bodyFatPercentage)
        #expect(mapping.metricID(for: "Muscle Mass") == .muscleMass)
        #expect(mapping.metricID(for: "Skeletal Muscle") == .skeletalMuscleMass)
        #expect(mapping.metricID(for: "Body Water") == .bodyWaterPercentage)
        #expect(mapping.metricID(for: "Visceral Fat") == .visceralFatLevel)
        #expect(mapping.metricID(for: "Bone Mass") == .boneMass)
        #expect(mapping.metricID(for: "Mineral") == .mineralMass)
        #expect(mapping.metricID(for: "BMR") == .basalMetabolicRate)
        #expect(mapping.metricID(for: "Protein") == .proteinPercentage)
        #expect(mapping.metricID(for: "Subcutaneous Fat") == .subcutaneousFatPercentage)
        #expect(mapping.metricID(for: "Body Age") == .metabolicAge)
    }

    @Test
    func defaultMappingCanAlsoMapStandardMetricsFromCSV() {
        let mapping = FitdaysCSVColumnMapping.fitdaysDefault

        #expect(mapping.metricID(for: "Systolic BP") == .systolicBloodPressure)
        #expect(mapping.metricID(for: "Diastolic BP") == .diastolicBloodPressure)
        #expect(mapping.metricID(for: "Heart Rate") == .heartRate)
    }

    @Test
    func mappingNormalizationIgnoresCaseSpacesAndPunctuation() {
        let mapping = FitdaysCSVColumnMapping.fitdaysDefault

        #expect(mapping.metricID(for: " body fat % ") == .bodyFatPercentage)
        #expect(mapping.metricID(for: "SKELETAL-MUSCLE") == .skeletalMuscleMass)
        #expect(mapping.isDateColumn(" measurement date "))
        #expect(mapping.isTimeColumn("MEASUREMENT_TIME"))
    }

    @Test
    func customMappingCanRemapVendorSpecificColumnNames() {
        let mapping = FitdaysCSVColumnMapping(
            dateColumnNames: ["recorded_on"],
            timeColumnNames: ["recorded_at"],
            metricColumnAliases: [
                .bodyWaterPercentage: ["hydration"],
            ],
            unitOverrides: [
                .bodyWaterPercentage: "%",
            ]
        )

        #expect(mapping.isDateColumn("Recorded On"))
        #expect(mapping.isTimeColumn("recorded-at"))
        #expect(mapping.metricID(for: "Hydration") == .bodyWaterPercentage)
        #expect(mapping.unit(for: .bodyWaterPercentage, columnName: "Hydration") == "%")
    }
}
