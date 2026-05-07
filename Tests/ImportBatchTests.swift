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

    @Test
    func duplicateSampleKeysFromDifferentFilesKeepNewestSampleWhilePreservingBatchRecords() throws {
        let repository = InMemoryUnifiedHealthMetricSampleRepository()
        let firstBatch = ImportBatch(
            sourceName: "Fitdays CSV",
            sourceType: .fitdaysCSV,
            importedAt: referenceDate,
            fileName: "synthetic_fitdays_a.csv",
            rowCount: 1,
            sampleCount: 1,
            skippedRowCount: 0,
            errorCount: 0
        )
        let secondBatch = ImportBatch(
            sourceName: "Fitdays CSV",
            sourceType: .fitdaysCSV,
            importedAt: referenceDate.addingTimeInterval(60),
            fileName: "synthetic_fitdays_b.csv",
            rowCount: 1,
            sampleCount: 1,
            skippedRowCount: 0,
            errorCount: 0
        )
        let duplicateRecordId = "device-record-2026-05-01-bodyMass"
        let firstSample = importedSample(
            value: 71.8,
            batchID: firstBatch.id,
            externalRecordId: duplicateRecordId
        )
        let secondSample = importedSample(
            value: 71.6,
            batchID: secondBatch.id,
            externalRecordId: duplicateRecordId
        )

        try repository.save(batch: firstBatch, samples: [firstSample])
        try repository.save(batch: secondBatch, samples: [secondSample])

        #expect(repository.fetchBatches().map(\.id) == [secondBatch.id, firstBatch.id])
        #expect(repository.fetchSamples().map(\.value) == [71.6])
        #expect(repository.fetchSamples().map(\.importBatchId) == [secondBatch.id.uuidString])
        #expect(repository.fetchSamples(importBatchId: firstBatch.id.uuidString).isEmpty)
    }

    @Test
    func sameMetricAndTimestampDuplicateReplacesEvenWhenExternalRecordIdChanges() throws {
        let repository = InMemoryUnifiedHealthMetricSampleRepository()
        let firstBatch = ImportBatch(
            sourceName: "Fitdays CSV",
            sourceType: .fitdaysCSV,
            importedAt: referenceDate,
            fileName: "synthetic_fitdays_first.csv",
            rowCount: 1,
            sampleCount: 1,
            skippedRowCount: 0,
            errorCount: 0
        )
        let secondBatch = ImportBatch(
            sourceName: "Fitdays CSV",
            sourceType: .fitdaysCSV,
            importedAt: referenceDate.addingTimeInterval(60),
            fileName: "synthetic_fitdays_second.csv",
            rowCount: 1,
            sampleCount: 1,
            skippedRowCount: 0,
            errorCount: 0
        )

        try repository.save(
            batch: firstBatch,
            samples: [
                importedSample(value: 71.8, batchID: firstBatch.id, externalRecordId: "first-row-body-mass"),
            ]
        )
        try repository.save(
            batch: secondBatch,
            samples: [
                importedSample(value: 71.6, batchID: secondBatch.id, externalRecordId: "second-row-body-mass"),
            ]
        )

        #expect(repository.fetchSamples().map(\.value) == [71.6])
        #expect(repository.fetchSamples().map(\.importBatchId) == [secondBatch.id.uuidString])
    }

    @Test
    func duplicateSummarySeparatesSameValueAndChangedValueOverlaps() throws {
        let existingBodyMass = importedSample(value: 71.8, batchID: UUID(), externalRecordId: "existing-body-mass")
        let existingBodyFat = importedSample(
            metricID: .bodyFatPercentage,
            value: 21.4,
            unit: "%",
            batchID: UUID(),
            externalRecordId: "existing-body-fat"
        )
        let incomingSameBodyMass = importedSample(value: 71.8, batchID: UUID(), externalRecordId: "incoming-body-mass")
        let incomingChangedBodyFat = importedSample(
            metricID: .bodyFatPercentage,
            value: 21.1,
            unit: "%",
            batchID: UUID(),
            externalRecordId: "incoming-body-fat"
        )
        let incomingNewWater = importedSample(
            metricID: .bodyWaterPercentage,
            value: 56.8,
            unit: "%",
            batchID: UUID(),
            externalRecordId: "incoming-body-water"
        )

        let summary = UnifiedHealthMetricImportDuplicateSummary(
            existingSamples: [existingBodyMass, existingBodyFat],
            incomingSamples: [incomingSameBodyMass, incomingChangedBodyFat, incomingNewWater]
        )

        #expect(summary.incomingSampleCount == 3)
        #expect(summary.newSampleCount == 1)
        #expect(summary.duplicateSampleCount == 2)
        #expect(summary.unchangedDuplicateCount == 1)
        #expect(summary.changedDuplicateCount == 1)
        #expect(summary.hasDuplicates)
        #expect(summary.hasChangedDuplicates)
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

    private func importedSample(
        metricID: UnifiedHealthMetricID = .bodyMass,
        value: Double,
        unit: String = "kg",
        batchID: UUID,
        externalRecordId: String
    ) -> UnifiedHealthMetricSample {
        UnifiedHealthMetricSample(
            metricID: metricID,
            value: value,
            unit: unit,
            measuredAt: referenceDate,
            sourceType: .fitdaysCSV,
            sourceName: "Fitdays CSV",
            externalRecordId: externalRecordId,
            importBatchId: batchID.uuidString,
            createdAt: referenceDate
        )
    }
}
