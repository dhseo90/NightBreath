import Foundation
import Testing
@testable import SleepSoundCore

@Suite("Fitdays CSV Parser")
struct FitdaysCSVParserTests {
    @Test
    func syntheticFixtureImportsFitdaysAndHealthKitStandardMetricsAsFitdaysCSVSource() throws {
        let result = try service.parseCSV(
            fixtureContents(),
            fileName: "sample_fitdays_export.csv",
            importedAt: referenceDate
        )

        #expect(result.batch.sourceName == "Fitdays CSV")
        #expect(result.batch.sourceType == .fitdaysCSV)
        #expect(result.batch.rowCount == 2)
        #expect(result.batch.sampleCount == 26)
        #expect(result.samples.count == 26)
        #expect(result.unknownColumns == ["Unknown Wellness Note"])
        #expect(result.rowErrors.isEmpty)

        let bodyMass = try #require(result.samples.first { $0.metricID == .bodyMass })
        let bmi = try #require(result.samples.first { $0.metricID == .bodyMassIndex })
        let bodyFat = try #require(result.samples.first { $0.metricID == .bodyFatPercentage })
        let skeletalMuscle = try #require(result.samples.first { $0.metricID == .skeletalMuscleMass })
        let mineral = try #require(result.samples.first { $0.metricID == .mineralMass })
        let metabolicRate = try #require(result.samples.first { $0.metricID == .basalMetabolicRate })

        #expect(bodyMass.sourceType == .fitdaysCSV)
        #expect(bmi.sourceType == .fitdaysCSV)
        #expect(bodyFat.sourceType == .fitdaysCSV)
        #expect(bodyMass.value == 71.8)
        #expect(bodyMass.unit == "kg")
        #expect(MetricCatalog.default.isHealthKitBacked(bodyMass.metricID))
        #expect(MetricCatalog.default.isHealthKitBacked(bodyFat.metricID))
        #expect(skeletalMuscle.value == 31.2)
        #expect(skeletalMuscle.unit == "kg")
        #expect(skeletalMuscle.sourceType == .fitdaysCSV)
        #expect(MetricCatalog.default.isExtendedLocalOnly(skeletalMuscle.metricID))
        #expect(mineral.value == 3.1)
        #expect(metabolicRate.value == 1_520)
        #expect(metabolicRate.unit == "kcal/day")
    }

    @Test
    func invalidDateRowsAreSkippedWithoutFailingTheWholeImport() throws {
        let csv = """
        Date,Time,Weight,Body Water
        not-a-date,07:10,72.0,56.0
        2026-05-02,07:11,71.8,56.2
        """

        let result = try service.parseCSV(csv, fileName: "synthetic_invalid_rows.csv", importedAt: referenceDate)

        #expect(result.batch.rowCount == 2)
        #expect(result.batch.skippedRowCount == 1)
        #expect(result.rowErrors.count == 1)
        #expect(result.samples.count == 2)
        #expect(Set(result.samples.map(\.metricID)) == [.bodyMass, .bodyWaterPercentage])
    }

    @Test
    func dateParserAcceptsSeparatedDateAndTimeFormats() throws {
        let csv = """
        Measurement Date,Measurement Time,Weight
        2026/05/03,07:45,71.4
        05/04/2026,08:10,71.3
        """

        let result = try service.parseCSV(csv, fileName: "synthetic_dates.csv", importedAt: referenceDate)
        let timestamps = result.samples.map(\.measuredAt)

        #expect(result.samples.count == 2)
        #expect(timestamps[0] < timestamps[1])
    }

    @Test
    func quotedCSVFieldsAndCommaSeparatedValuesAreParsed() throws {
        let csv = """
        Date,Time,Weight,Body Fat,Unknown
        2026-05-03,07:45,"1,071.4","21.3%","memo, with comma"
        """

        let result = try service.parseCSV(csv, fileName: "synthetic_quoted.csv", importedAt: referenceDate)
        let bodyMass = try #require(result.samples.first { $0.metricID == .bodyMass })
        let bodyFat = try #require(result.samples.first { $0.metricID == .bodyFatPercentage })

        #expect(bodyMass.value == 1_071.4)
        #expect(bodyFat.value == 21.3)
        #expect(result.unknownColumns == ["Unknown"])
    }

    private var service: FitdaysImportService {
        FitdaysImportService(
            calendar: calendar,
            timeZone: TimeZone(secondsFromGMT: 0)!,
            now: { referenceDate }
        )
    }

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_777_680_000)
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func fixtureContents() throws -> String {
        let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Tests/Fixtures/Fitdays/sample_fitdays_export.csv")
        return try String(contentsOf: url, encoding: .utf8)
    }
}
