import Foundation
import Testing
@testable import SleepSoundCore

@Suite("ImportBatch")
struct ImportBatchTests {
    @Test
    func importResultCreatesBatchWithCountsAndSamplesShareBatchID() throws {
        let result = try service.parseCSV(csv, fileName: "synthetic_fitdays.csv", importedAt: referenceDate)

        #expect(result.batch.fileName == "synthetic_fitdays.csv")
        #expect(result.batch.rowCount == 2)
        #expect(result.batch.sampleCount == result.samples.count)
        #expect(result.batch.skippedRowCount == 0)
        #expect(result.batch.errorCount == 0)
        #expect(Set(result.samples.compactMap(\.importBatchId)) == [result.batch.id.uuidString])
    }

    @Test
    func repositorySavesAndDeletesBatchSamples() throws {
        let repository = InMemoryUnifiedHealthMetricSampleRepository()
        let result = try service.parseCSV(csv, fileName: "synthetic_fitdays.csv", importedAt: referenceDate)

        try repository.save(batch: result.batch, samples: result.samples)

        #expect(repository.fetchBatches() == [result.batch])
        #expect(repository.fetchSamples(importBatchId: result.batch.id.uuidString) == result.samples)

        try repository.deleteBatch(id: result.batch.id)

        #expect(repository.fetchBatches().isEmpty)
        #expect(repository.fetchSamples().isEmpty)
    }

    @Test
    func duplicateFileImportReplacesPreviousBatchAndSamples() throws {
        let repository = InMemoryUnifiedHealthMetricSampleRepository()
        let firstResult = try service.parseCSV(csv, fileName: "synthetic_fitdays.csv", importedAt: referenceDate)
        let secondResult = try service.parseCSV(
            csv,
            fileName: "synthetic_fitdays.csv",
            importedAt: referenceDate.addingTimeInterval(60)
        )

        try repository.save(batch: firstResult.batch, samples: firstResult.samples)
        try repository.save(batch: secondResult.batch, samples: secondResult.samples)

        #expect(repository.fetchBatches().count == 1)
        #expect(repository.fetchBatches().first?.id == secondResult.batch.id)
        #expect(repository.fetchSamples().count == secondResult.samples.count)
        #expect(Set(repository.fetchSamples().compactMap(\.importBatchId)) == [secondResult.batch.id.uuidString])
    }

    private var service: FitdaysImportService {
        FitdaysImportService(
            calendar: calendar,
            timeZone: TimeZone(secondsFromGMT: 0)!,
            now: { referenceDate }
        )
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_777_680_000)
    }

    private var csv: String {
        """
        Date,Time,Weight,Body Fat,Skeletal Muscle,Body Water,Visceral Fat,BMR
        2026-05-01,07:12,71.8,21.4,31.2,56.8,8,1520
        2026-05-02,07:09,71.6,21.2,31.3,57.0,8,1525
        """
    }
}
