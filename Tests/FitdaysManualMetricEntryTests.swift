import Foundation
import Testing
@testable import SleepSoundCore

@Suite("Fitdays Manual Metric Entry")
struct FitdaysManualMetricEntryTests {
    @Test
    func supportedManualMetricsAreFitdaysLocalOnlyAndNotHealthKitBacked() {
        let catalog = MetricCatalog.default
        let metadata = FitdaysManualMetricEntryBuilder.supportedMetadata(catalog: catalog)

        #expect(!metadata.isEmpty)
        #expect(metadata.allSatisfy { $0.isExtendedLocalOnly })
        #expect(metadata.allSatisfy { !$0.isHealthKitBacked })
        #expect(metadata.contains { $0.metricID == .bodyWaterPercentage })
        #expect(metadata.contains { $0.metricID == .visceralFatLevel })
        #expect(!FitdaysManualMetricEntryBuilder.supportedMetricIDs.contains(.bodyMass))
        #expect(!FitdaysManualMetricEntryBuilder.supportedMetricIDs.contains(.sleepSoundScore))
    }

    @Test
    func manualSampleUsesManualSourceAndDoesNotCreateHealthKitWritePath() throws {
        let measuredAt = Date(timeIntervalSince1970: 1_800_000_000)

        let sample = try FitdaysManualMetricEntryBuilder.makeSample(
            metricID: .bodyWaterPercentage,
            value: 41.5,
            measuredAt: measuredAt,
            notes: "  "
        )
        let batch = FitdaysManualMetricEntryBuilder.makeBatch(for: sample, importedAt: measuredAt)

        #expect(sample.metricID == .bodyWaterPercentage)
        #expect(sample.value == 41.5)
        #expect(sample.unit == "%")
        #expect(sample.sourceType == .manual)
        #expect(sample.sourceName == FitdaysManualMetricEntryBuilder.sourceName)
        #expect(sample.notes == nil)
        #expect(sample.sourceBundleIdentifier == nil)
        #expect(sample.importBatchId == nil)
        #expect(batch.sourceType == .manual)
        #expect(batch.sourceName == FitdaysManualMetricEntryBuilder.sourceName)
        #expect(batch.sampleCount == 1)
        #expect(batch.fileName.contains(FitdaysManualMetricEntryBuilder.batchFileNamePrefix))
    }

    @Test
    func manualSampleRejectsHealthKitBackedAndNegativeValues() {
        #expect(throws: FitdaysManualMetricEntryError.unsupportedMetric) {
            try FitdaysManualMetricEntryBuilder.makeSample(
                metricID: .bodyMass,
                value: 107.2,
                measuredAt: Date()
            )
        }

        #expect(throws: FitdaysManualMetricEntryError.invalidValue) {
            try FitdaysManualMetricEntryBuilder.makeSample(
                metricID: .bodyWaterPercentage,
                value: -1,
                measuredAt: Date()
            )
        }
    }

    @Test
    func manualSamplesUseImportDuplicateSummaryForSameTimestampConflicts() throws {
        let measuredAt = Date(timeIntervalSince1970: 1_800_000_000)
        let existing = try FitdaysManualMetricEntryBuilder.makeSample(
            metricID: .bodyWaterPercentage,
            value: 41.5,
            measuredAt: measuredAt
        )
        let incoming = try FitdaysManualMetricEntryBuilder.makeSample(
            metricID: .bodyWaterPercentage,
            value: 42.1,
            measuredAt: measuredAt
        )

        let summary = UnifiedHealthMetricImportDuplicateSummary(
            existingSamples: [existing],
            incomingSamples: [incoming]
        )

        #expect(summary.hasChangedDuplicates)
        #expect(summary.changedDuplicateCount == 1)
    }

    @Test
    func manualBatchCanBeFetchedAndDeletedWithRepository() throws {
        let repository = InMemoryUnifiedHealthMetricSampleRepository()
        var sample = try FitdaysManualMetricEntryBuilder.makeSample(
            metricID: .visceralFatLevel,
            value: 21,
            measuredAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
        let batch = FitdaysManualMetricEntryBuilder.makeBatch(for: sample)
        sample.importBatchId = batch.id.uuidString

        try repository.save(batch: batch, samples: [sample])

        #expect(repository.fetchBatches() == [batch])
        #expect(repository.fetchSamples(importBatchId: batch.id.uuidString) == [sample])

        try repository.deleteBatch(id: batch.id)

        #expect(repository.fetchBatches().isEmpty)
        #expect(repository.fetchSamples().isEmpty)
    }

    @Test
    func fitdaysImportViewExposesManualInputWithoutForbiddenIntegrations() throws {
        let viewSource = try sourceContents("SleepSoundApp/Features/Dashboard/FitdaysImportView.swift")
        let serviceSource = try sourceContents("SleepSoundApp/Core/HealthImport/FitdaysImportService.swift")
        let docs = try sourceContents("Docs/HEALTH_DATA_GUIDE.md")

        #expect(viewSource.contains("Fitdays 고유 지표 수동 입력"))
        #expect(viewSource.contains("FitdaysManualMetricEntryBuilder.makeSample"))
        #expect(viewSource.contains("수동 입력 저장 완료"))
        #expect(viewSource.contains("수동 입력 저장 완료 안 됨"))
        #expect(viewSource.contains("source로만 저장되며 HealthKit에 쓰지 않습니다"))
        #expect(serviceSource.contains("sourceType: .manual"))
        #expect(docs.contains("사용자가 직접 입력한 로컬 샘플"))

        let combined = [viewSource, serviceSource].joined(separator: "\n")
        #expect(!combined.contains("URLSession"))
        #expect(!combined.contains("URLRequest"))
        #expect(!combined.contains("HKHealthStore().save"))
    }

    private func sourceContents(_ relativePath: String) throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
    }
}
