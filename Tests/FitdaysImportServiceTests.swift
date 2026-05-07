import Foundation
import Testing
@testable import SleepSoundCore

@Suite("Fitdays Import Service")
struct FitdaysImportServiceTests {
    @Test
    func filePolicyAllowsCSVAndTextExportFilesOnly() {
        #expect(FitdaysImportFilePolicy.isSupportedFileName("fitdays_export.csv"))
        #expect(FitdaysImportFilePolicy.isSupportedFileName("fitdays_export.tsv"))
        #expect(FitdaysImportFilePolicy.isSupportedFileName("Fitdays Export.TXT"))
        #expect(FitdaysImportFilePolicy.isSupportedContentTypeIdentifier("public.comma-separated-values-text"))
        #expect(FitdaysImportFilePolicy.isSupportedContentTypeIdentifier("public.tab-separated-values-text"))
        #expect(FitdaysImportFilePolicy.isSupportedContentTypeIdentifier("public.plain-text"))
        #expect(!FitdaysImportFilePolicy.isSupportedFileName("fitdays_export.pdf"))
        #expect(!FitdaysImportFilePolicy.isSupportedFileName("fitdays_export.json"))
        #expect(!FitdaysImportFilePolicy.isSupportedFileName("fitdays_export.xlsx"))
        #expect(!FitdaysImportFilePolicy.isSupportedFileName("fitdays_export.zip"))
        #expect(!FitdaysImportFilePolicy.isSupportedContentTypeIdentifier("com.adobe.pdf"))
    }

    @Test
    func fallbackGuidanceKeepsExportOptionalAndReadOnly() {
        let combined = (
            FitdaysImportFallbackGuidance.privacyMessages
            + [FitdaysImportFallbackGuidance.emptyStateMessage]
            + [FitdaysImportFallbackGuidance.supportedFileSummary]
            + [FitdaysImportFallbackGuidance.supportedPasteSummary]
            + [FitdaysImportFallbackGuidance.noImportablePreviewMessage]
            + [FitdaysImportFallbackGuidance.importErrorRecoveryMessage]
            + [FitdaysImportFallbackGuidance.exportUnavailableTitle]
            + FitdaysImportFallbackGuidance.exportUnavailableSteps
            + [FitdaysImportFallbackGuidance.healthDashboardFallbackTitle]
            + [FitdaysImportFallbackGuidance.localOnlyFollowUpTitle]
            + FitdaysImportFallbackGuidance.prohibitedApproaches
        ).joined(separator: "\n")

        #expect(combined.contains("CSV/export가 보이지 않으면 Apple 건강앱 read-only 지표만 사용합니다."))
        #expect(combined.contains("파일이 없어도 Apple 건강앱 read-only 지표와 수면 소리 리포트는 계속 사용할 수 있습니다."))
        #expect(combined.contains("지원 파일: .csv, .tsv, .txt"))
        #expect(combined.contains("월별 데이터 복사 텍스트"))
        #expect(combined.contains("저장 가능한 샘플이 없습니다."))
        #expect(combined.contains("파일 구조를 확인하거나"))
        #expect(combined.contains("Fitdays 앱을 더 파고들거나 로그인/API 연결을 만들지 않습니다."))
        #expect(combined.contains("HealthKit에 없는 Fitdays 고유 지표는 수동 입력 또는 로컬 입력 후속 기능으로 분리합니다."))
        #expect(combined.contains("private QA note"))
        #expect(FitdaysImportFallbackGuidance.prohibitedApproaches.contains("Fitdays 서버/API 직접 연결"))
        #expect(FitdaysImportFallbackGuidance.prohibitedApproaches.contains("UI scraping"))

        let forbiddenClaims = [
            "Fitdays 서버/API에 직접 연결합니다",
            "비공식 연결 방식을 구현합니다",
            "자동 동기화를 구현합니다",
            "HealthKit에 Fitdays import 값을 씁니다",
        ]

        for claim in forbiddenClaims {
            #expect(!combined.contains(claim), "Fallback guidance should not promise forbidden behavior: \(claim)")
        }
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
    func previewImportFromPastedMonthlyTextUsesLocalFitdaysSourceWithoutFile() throws {
        let pastedText = """
        측정일\t측정시간\t체중\t체수분률\t내장지방 레벨
        2026.05.01\t07:20\t71.8 kg\t56.4%\t8
        2026.05.02\t07:25\t71.6 kg\t56.8%\t8
        """

        let result = try service.previewImport(fromPastedText: pastedText)

        #expect(result.batch.fileName == "fitdays_pasted_monthly_text.tsv")
        #expect(result.batch.sourceName == "Fitdays 붙여넣기")
        #expect(result.batch.sourceType == .fitdaysCSV)
        #expect(result.batch.rowCount == 2)
        #expect(result.batch.sampleCount == 6)
        #expect(result.samples.count == 6)
        #expect(result.rowErrors.isEmpty)
        #expect(Set(result.samples.map(\.sourceType)) == [.fitdaysCSV])
        #expect(Set(result.samples.map(\.sourceName)) == ["Fitdays 붙여넣기"])
        #expect(result.samples.allSatisfy { $0.notes?.contains("붙여넣은 Fitdays 월별 데이터") == true })
        #expect(result.samples.allSatisfy { $0.externalRecordId?.contains("fitdays_pasted_monthly_text.tsv") == true })
    }

    @Test
    func previewImportFromPastedMonthlyTextHandlesKoreanAMPMRows() throws {
        let pastedText = """
        측정일\t측정시간\t체중\t체지방률\t체수분률
        2026. 5. 1.\t오전 7:20\t71.8 kg\t18.4%\t56.4%
        2026. 5. 2.\t오후 9:05\t71.6 kg\t18.2%\t56.8%
        """

        let result = try service.previewImport(fromPastedText: pastedText)

        #expect(result.batch.rowCount == 2)
        #expect(result.batch.sampleCount == 6)
        #expect(result.skippedRowCount == 0)
        #expect(result.rowErrors.isEmpty)
        #expect(Set(result.samples.map(\.metricID)) == [.bodyMass, .bodyFatPercentage, .bodyWaterPercentage])
    }

    @Test
    func previewImportFromLooseFitdaysMonthlyClipboardTextCreatesSamples() throws {
        let pastedText = """
        2026년 5월
        5월 1일 오전 7:20
        체중 71.8kg
        BMI 23.1
        체지방률 18.4%
        체수분률
        56.4%
        내장지방 레벨 8
        5월 2일 오후 9:05
        체중
        71.6 kg
        체수분률 56.8%
        """

        let result = try service.previewImport(fromPastedText: pastedText)

        #expect(result.batch.fileName == "fitdays_pasted_monthly_text.tsv")
        #expect(result.batch.sourceName == "Fitdays 붙여넣기")
        #expect(result.batch.rowCount == 12)
        #expect(result.batch.sampleCount == 7)
        #expect(result.samples.count == 7)
        #expect(result.rowErrors.isEmpty)
        #expect(result.unknownColumns.isEmpty)
        #expect(Set(result.samples.map(\.metricID)) == [
            .bodyMass,
            .bodyMassIndex,
            .bodyFatPercentage,
            .bodyWaterPercentage,
            .visceralFatLevel,
        ])
        #expect(result.samples.allSatisfy { $0.sourceType == .fitdaysCSV })
        #expect(result.samples.allSatisfy { $0.sourceName == "Fitdays 붙여넣기" })
    }

    @Test
    func previewImportFromActualLikeMonthlyClipboardTextHandlesCompactDatesAndAliases() throws {
        let pastedText = """
        2026년 5월
        5/1 07:20
        몸무게：71.8kg
        수분 56.4%
        골격근 29.2kg
        내장지방등급 8
        기초대사 1540kcal
        신체점수 82
        체나이 43
        비만등급 2
        5.2 오후 9:05
        몸무게 71.6kg
        체지방 18.2%
        피하지방 12.4%
        """

        let result = try service.previewImport(fromPastedText: pastedText)

        #expect(result.batch.fileName == "fitdays_pasted_monthly_text.tsv")
        #expect(result.batch.sourceName == "Fitdays 붙여넣기")
        #expect(result.rowErrors.isEmpty)
        #expect(result.samples.count == 11)
        #expect(Set(result.samples.map(\.metricID)) == [
            .bodyMass,
            .bodyWaterPercentage,
            .skeletalMuscleMass,
            .visceralFatLevel,
            .basalMetabolicRate,
            .bodyScore,
            .metabolicAge,
            .obesityLevel,
            .bodyFatPercentage,
            .subcutaneousFatPercentage,
        ])
        #expect(result.samples.allSatisfy { $0.sourceType == .fitdaysCSV })
        #expect(result.samples.allSatisfy { $0.sourceName == "Fitdays 붙여넣기" })
    }

    @Test
    func looseDateParserDoesNotTreatMetricDecimalsAsMeasurementDates() throws {
        let pastedText = """
        BMI 23.1
        5/1 07:20
        몸무게 71.8kg
        BMI 23.1
        """

        let result = try service.previewImport(fromPastedText: pastedText)

        #expect(result.rowErrors.map(\.rowNumber) == [1])
        #expect(result.samples.map(\.metricID) == [.bodyMass, .bodyMassIndex])
    }

    @Test
    func importPastedTextPersistsSamplesAndRejectsEmptyPaste() throws {
        let repository = InMemoryUnifiedHealthMetricSampleRepository()
        let pastedText = """
        Date\tTime\tWeight\tBody Water
        2026-05-01\t07:20\t71.8\t56.4
        """

        let result = try service.importPastedText(pastedText, repository: repository)

        #expect(repository.fetchBatches().map(\.id) == [result.batch.id])
        #expect(repository.fetchSamples().count == 2)
        #expect(throws: FitdaysImportError.emptyFile) {
            try service.importPastedText(" \n\t ", repository: repository)
        }
        #expect(repository.fetchBatches().count == 1)
        #expect(repository.fetchSamples().count == 2)
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

    @Test
    func dateOnlyTextWithoutMappedMetricsIsRejectedBeforeSaving() throws {
        let repository = InMemoryUnifiedHealthMetricSampleRepository()
        let csv = """
        Date,Time,Comment
        2026-05-04,07:00,Export menu not available
        """
        let url = temporaryFileURL(fileName: "synthetic_fitdays_history.txt")
        try csv.write(to: url, atomically: true, encoding: .utf8)

        #expect(throws: FitdaysImportError.noSupportedMetricColumns) {
            try service.importFile(from: url, repository: repository)
        }
        #expect(repository.fetchBatches().isEmpty)
        #expect(repository.fetchSamples().isEmpty)
    }

    @Test
    func importFileDoesNotPersistEmptyPreviewResult() throws {
        let repository = InMemoryUnifiedHealthMetricSampleRepository()
        let csv = """
        Date,Time,Weight,Body Water
        2026-05-04,07:00,,
        """
        let url = temporaryFileURL(fileName: "synthetic_fitdays_empty_metrics.csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)

        let preview = try service.previewImport(from: url)
        #expect(preview.samples.isEmpty)
        #expect(preview.skippedRowCount == 1)
        #expect(throws: FitdaysImportError.noImportableSamples) {
            try service.importFile(from: url, repository: repository)
        }
        #expect(repository.fetchBatches().isEmpty)
        #expect(repository.fetchSamples().isEmpty)
    }

    @Test
    func fitdaysImportViewExplainsTSVEmptyPreviewAndRecoveryWithoutServerFallback() throws {
        let source = try sourceContents("SleepSoundApp/Features/Dashboard/FitdaysImportView.swift")
        let infoPlist = try sourceContents("SleepSoundApp/App/Info.plist")

        #expect(source.contains("FitdaysImportFallbackGuidance.supportedFileSummary"))
        #expect(source.contains("FitdaysImportFallbackGuidance.supportedPasteSummary"))
        #expect(source.contains("TextEditor(text: pastedTextBinding)"))
        #expect(source.contains("previewPastedText"))
        #expect(source.contains("pasteClipboardTextAndPreview"))
        #expect(source.contains("clearPastedPreviewState"))
        #expect(source.contains("importResult = nil"))
        #expect(source.contains("UIPasteboard.general.string"))
        #expect(source.contains("클립보드 붙여넣고 미리보기"))
        #expect(source.contains("월별 데이터 붙여넣기"))
        #expect(source.contains("FitdaysImportFallbackGuidance.noImportablePreviewMessage"))
        #expect(source.contains("userFacingImportErrorMessage"))
        #expect(source.contains("FitdaysImportFallbackGuidance.importErrorRecoveryMessage"))
        #expect(infoPlist.contains("public.tab-separated-values-text"))
        #expect(!source.contains("URLSession"))
        #expect(!source.contains("Fitdays 서버/API에 직접 연결합니다"))
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

    private func sourceContents(_ relativePath: String) throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
    }
}
