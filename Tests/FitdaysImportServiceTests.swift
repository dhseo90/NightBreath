import Foundation
import Testing
@testable import SleepSoundCore

@Suite("Fitdays Import Service")
struct FitdaysImportServiceTests {
    @Test
    func filePolicyAllowsCSVAndTextExportFilesOnly() {
        #expect(FitdaysImportFilePolicy.isSupportedFileName("fitdays_export.csv"))
        #expect(FitdaysImportFilePolicy.isSupportedFileName("Fitdays Export.TXT"))
        #expect(FitdaysImportFilePolicy.isSupportedContentTypeIdentifier("public.comma-separated-values-text"))
        #expect(FitdaysImportFilePolicy.isSupportedContentTypeIdentifier("public.plain-text"))
        #expect(!FitdaysImportFilePolicy.isSupportedFileName("fitdays_export.pdf"))
        #expect(!FitdaysImportFilePolicy.isSupportedFileName("fitdays_export.json"))
        #expect(!FitdaysImportFilePolicy.isSupportedContentTypeIdentifier("com.adobe.pdf"))
    }

    @Test
    func previewImportDryRunUsesSyntheticFixtureWithoutSaving() throws {
        let repository = InMemoryUnifiedHealthMetricSampleRepository()
        let result = try service.previewImport(from: fixtureURL())

        #expect(repository.fetchBatches().isEmpty)
        #expect(repository.fetchSamples().isEmpty)
        #expect(result.batch.fileName == "sample_fitdays_export.csv")
        #expect(result.batch.sourceType == .fitdaysCSV)
        #expect(result.batch.sampleCount == 26)
        #expect(result.unknownColumns == ["Unknown Wellness Note"])
        #expect(result.rowErrors.isEmpty)
        #expect(Set(result.samples.map(\.sourceType)) == [.fitdaysCSV])

        let bodyMass = try #require(result.samples.first { $0.metricID == .bodyMass })
        let bodyWater = try #require(result.samples.first { $0.metricID == .bodyWaterPercentage })
        #expect(MetricCatalog.default.isHealthKitBacked(bodyMass.metricID))
        #expect(bodyMass.sourceType == .fitdaysCSV)
        #expect(MetricCatalog.default.isExtendedLocalOnly(bodyWater.metricID))
        #expect(bodyWater.sourceType == .fitdaysCSV)
    }

    @Test
    func importFilePersistsSamplesAndDuplicateFileImportReplacesPreviousBatch() throws {
        let repository = InMemoryUnifiedHealthMetricSampleRepository()
        let first = try service.importFile(from: fixtureURL(), repository: repository)
        let second = try service.importFile(from: fixtureURL(), repository: repository)

        #expect(first.batch.fileName == second.batch.fileName)
        #expect(repository.fetchBatches().count == 1)
        #expect(repository.fetchBatches().first?.id == second.batch.id)
        #expect(repository.fetchSamples().count == second.samples.count)
        #expect(Set(repository.fetchSamples().compactMap(\.importBatchId)) == [second.batch.id.uuidString])
    }

    @Test
    func deleteImportBatchRemovesOnlySamplesForThatBatch() throws {
        let repository = InMemoryUnifiedHealthMetricSampleRepository()
        let first = try service.importFile(from: fixtureURL(), repository: repository)
        let second = try service.importFile(from: abbreviationFixtureURL(), repository: repository)

        #expect(repository.fetchBatches().count == 2)
        #expect(repository.fetchSamples(importBatchId: first.batch.id.uuidString).count == first.samples.count)
        #expect(repository.fetchSamples(importBatchId: second.batch.id.uuidString).count == second.samples.count)

        try repository.deleteBatch(id: first.batch.id)

        #expect(repository.fetchBatches().map(\.id) == [second.batch.id])
        #expect(repository.fetchSamples(importBatchId: first.batch.id.uuidString).isEmpty)
        #expect(repository.fetchSamples(importBatchId: second.batch.id.uuidString).count == second.samples.count)
        #expect(Set(repository.fetchSamples().compactMap(\.importBatchId)) == [second.batch.id.uuidString])
    }

    @Test
    func invalidRowsAndUnknownColumnsAreReportedWhileValidSamplesContinue() throws {
        let csv = """
        Date,Time,Weight,Body Water,Device Nickname
        2026-05-03,07:00,not-number,56.4,QA Device
        not-a-date,07:10,71.8,56.8,QA Device
        2026-05-04,07:12,71.6,57.0,QA Device
        """

        let result = try service.parseCSV(csv, fileName: "synthetic_fitdays_invalid_rows.csv", importedAt: referenceDate)

        #expect(result.batch.rowCount == 3)
        #expect(result.batch.skippedRowCount == 1)
        #expect(result.rowErrors.count == 2)
        #expect(result.unknownColumns == ["Device Nickname"])
        #expect(result.samples.map(\.metricID) == [
            .bodyWaterPercentage,
            .bodyMass,
            .bodyWaterPercentage,
        ])
        #expect(result.samples.allSatisfy { $0.sourceType == .fitdaysCSV })
    }

    @Test
    func missingDateColumnFailsBeforeSaving() throws {
        let repository = InMemoryUnifiedHealthMetricSampleRepository()
        let csv = """
        Time,Weight,Body Water
        07:00,71.8,56.4
        """
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("synthetic_missing_date_fitdays.csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)

        #expect(throws: FitdaysImportError.missingDateColumn) {
            try service.importFile(from: url, repository: repository)
        }
        #expect(repository.fetchBatches().isEmpty)
        #expect(repository.fetchSamples().isEmpty)
    }

    @Test
    func unsupportedFileExtensionIsRejectedBeforePreviewParsing() throws {
        let csv = """
        Date,Time,Weight
        2026-05-04,07:00,71.8
        """
        let url = temporaryFileURL(fileName: "synthetic_fitdays_export.json")
        try csv.write(to: url, atomically: true, encoding: .utf8)

        #expect(throws: FitdaysImportError.unsupportedFileType) {
            try service.previewImport(from: url)
        }
    }

    @Test
    func unsupportedTextStructureIsRejectedByPreviewValidation() throws {
        let url = temporaryFileURL(fileName: "synthetic_fitdays_notes.txt")
        try "This is not a Fitdays structured export file.".write(to: url, atomically: true, encoding: .utf8)

        #expect(throws: FitdaysImportError.missingDateColumn) {
            try service.previewImport(from: url)
        }
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

    private func fixtureURL() -> URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Tests/Fixtures/Fitdays/sample_fitdays_export.csv")
    }

    private func abbreviationFixtureURL() -> URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Tests/Fixtures/Fitdays/sample_fitdays_export_abbrev.csv")
    }

    private func temporaryFileURL(fileName: String) -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("\(UUID().uuidString)-\(fileName)")
    }
}
