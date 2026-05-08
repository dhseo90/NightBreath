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
        #expect(combined.contains("HealthKit에 없는 Fitdays 고유 지표는 사용자가 직접 입력한 로컬 수동 샘플로 저장할 수 있습니다."))
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
    func previewImportFromActualCommaClipboardTextHandlesTimeFirstDateAndAnnotatedHeaders() throws {
        let pastedText = """
        짜,체중,BMI,체지방률,피하지방,심박수,심박수 지표,내장 지방지수,체내수분량,골격근량 (클릭필수),근육량(클릭필수),골질량,단백질,기초대사량 (BMR),신체나이,
        05:37 2026/06/010,72.40kg,24.6,18.2%,12.8%,--,--,7.0,56.1%,29.3%,50.2kg,3.10kg,18.4%,1520kcal,39
        05:36 2026/06/06,72.10kg,24.5,18.0%,12.6%,--,--,7.0,56.3%,29.4%,50.4kg,3.10kg,18.5%,1524kcal,39,
        07:39 2026/06/04,72.60kg,24.7,18.4%,12.9%,--,--,7.1,55.9%,29.2%,50.0kg,3.10kg,18.3%,1517kcal,39,
        """

        let result = try service.previewImport(fromPastedText: pastedText)

        #expect(result.batch.fileName == "fitdays_pasted_monthly_text.tsv")
        #expect(result.batch.sourceName == "Fitdays 붙여넣기")
        #expect(result.batch.rowCount == 3)
        #expect(result.batch.sampleCount == 36)
        #expect(result.skippedRowCount == 0)
        #expect(result.samples.count == 36)
        #expect(result.rowErrors.isEmpty)
        #expect(result.unknownColumns == ["심박수 지표"])
        #expect(Set(result.samples.map(\.metricID)) == [
            .bodyMass,
            .bodyMassIndex,
            .bodyFatPercentage,
            .subcutaneousFatPercentage,
            .visceralFatLevel,
            .bodyWaterPercentage,
            .skeletalMuscleMass,
            .muscleMass,
            .boneMass,
            .proteinPercentage,
            .basalMetabolicRate,
            .metabolicAge,
        ])
        #expect(!result.samples.contains { $0.metricID == .heartRate })

        let bodyMassDates = result.samples
            .filter { $0.metricID == .bodyMass }
            .map(\.measuredAt)
        let firstDate = try #require(bodyMassDates.first)
        #expect(calendar.component(.year, from: firstDate) == 2026)
        #expect(calendar.component(.month, from: firstDate) == 6)
        #expect(calendar.component(.day, from: firstDate) == 1)
        #expect(calendar.component(.hour, from: firstDate) == 5)
        #expect(calendar.component(.minute, from: firstDate) == 37)
        #expect(result.samples.allSatisfy { $0.sourceType == .fitdaysCSV })
        #expect(result.samples.allSatisfy { $0.sourceName == "Fitdays 붙여넣기" })
    }

    @Test
    func fullMonthPastedCommaTextParsesAndBuildsCalendarQuickly() throws {
        let pastedText = syntheticFullMonthFitdaysCommaText()
        let startedAt = Date()

        let result = try service.previewImport(fromPastedText: pastedText)
        let builder = HealthCalendarBuilder()
        let monthDate = date(2026, 5, 15)
        let summaries = builder.summaries(
            forMonthContaining: monthDate,
            samples: result.samples,
            sleepReports: [],
            calendar: calendar
        )
        let detail = builder.detailData(
            for: monthDate,
            samples: result.samples,
            sleepReports: [],
            calendar: calendar
        )
        let elapsed = Date().timeIntervalSince(startedAt)

        #expect(result.batch.fileName == "fitdays_pasted_monthly_text.tsv")
        #expect(result.batch.sourceName == "Fitdays 붙여넣기")
        #expect(result.batch.rowCount == 31)
        #expect(result.batch.sampleCount == 31 * 12)
        #expect(result.skippedRowCount == 0)
        #expect(result.rowErrors.isEmpty)
        #expect(result.unknownColumns == ["심박수 지표"])
        #expect(Set(result.samples.map(\.metricID)) == [
            .bodyMass,
            .bodyMassIndex,
            .bodyFatPercentage,
            .subcutaneousFatPercentage,
            .visceralFatLevel,
            .bodyWaterPercentage,
            .skeletalMuscleMass,
            .muscleMass,
            .boneMass,
            .proteinPercentage,
            .basalMetabolicRate,
            .metabolicAge,
        ])
        #expect(result.samples.allSatisfy { $0.sourceType == .fitdaysCSV })
        #expect(result.samples.allSatisfy { $0.sourceName == "Fitdays 붙여넣기" })
        #expect(summaries.count == 42)
        #expect(summaries.filter { calendar.component(.month, from: $0.date) == 5 && $0.hasBodyComposition }.count == 31)
        #expect(detail.summary.hasBodyComposition)
        #expect(detail.samples.count == 12)
        #expect(detail.bodyCompositionSamples.count == 3)
        #expect(detail.fitdaysExtendedSamples.count == 9)
        #expect(elapsed < 1.5, "Full-month Fitdays paste preview and calendar build took \(elapsed)s")
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
        #expect(source.contains("FitdaysPastedTextSummary"))
        #expect(source.contains("isPreviewingPaste"))
        #expect(source.contains("clearPastedPreviewState"))
        #expect(source.contains("importResult = nil"))
        #expect(source.contains("UIPasteboard.general.string"))
        #expect(source.contains("클립보드에서 바로 미리보기"))
        #expect(source.contains("클립보드 붙여넣고 미리보기"))
        #expect(source.contains("월별 데이터 붙여넣기"))
        #expect(source.contains("FitdaysImportFallbackGuidance.noImportablePreviewMessage"))
        #expect(source.contains("previewDiagnosticsSection"))
        #expect(source.contains("저장 전 미리보기"))
        #expect(source.contains("lastSaveConfirmation"))
        #expect(source.contains("FitdaysSaveConfirmation"))
        #expect(source.contains("lastSaveConfirmation.displayMessage"))
        #expect(source.contains("savedDetailShortcut(for: lastSaveConfirmation)"))
        #expect(source.contains("가져온 최신 날짜 바로 보기"))
        #expect(source.contains("DailyMeasurementDetailView("))
        #expect(source.contains("HealthCalendarBuilder().detailData"))
        #expect(source.contains("importedDayStarts(from: result.samples)"))
        #expect(source.contains("detailSummaryText"))
        #expect(source.contains("batchDetailShortcut(batch)"))
        #expect(source.contains("이 가져오기 최신 날짜 보기"))
        #expect(source.contains("repository.fetchSamples(importBatchId: batch.id.uuidString)"))
        #expect(source.contains("미리보기 판단"))
        #expect(source.contains("처리한 row"))
        #expect(source.contains("저장 가능"))
        #expect(source.contains("건너뛴 row 해석"))
        #expect(source.contains("지원하지 않는 column"))
        #expect(source.contains("savedBatchesSection"))
        #expect(source.contains("저장된 가져오기"))
        #expect(source.contains("저장 샘플"))
        #expect(source.contains("가져오기 기록 삭제"))
        #expect(source.contains("UnifiedHealthMetricImportDuplicateSummary"))
        #expect(source.contains("값이 다른 중복"))
        #expect(source.contains("새 붙여넣기 기준으로 교체"))
        #expect(source.contains("repository.deleteBatch"))
        #expect(source.contains("reloadSavedImports"))
        #expect(source.contains("실제 파일명이나 local path를 표시하지 않습니다"))
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

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 8) -> Date {
        DateComponents(
            calendar: calendar,
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day,
            hour: hour
        ).date!
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

    private func syntheticFullMonthFitdaysCommaText() -> String {
        let header = "짜,체중,BMI,체지방률,피하지방,심박수,심박수 지표,내장 지방지수,체내수분량,골격근량 (클릭필수),근육량(클릭필수),골질량,단백질,기초대사량 (BMR),신체나이,"
        let rows = (1...31).map { day in
            let hour = 5 + day % 3
            let minute = 20 + day % 30
            let bodyMass = 80.0 + Double(day) * 0.07
            let bmi = 27.0 + Double(day % 4) * 0.1
            let bodyFat = 25.0 + Double(day % 5) * 0.2
            let subcutaneousFat = 20.0 + Double(day % 4) * 0.2
            let visceralFat = 10.0 + Double(day % 3) * 0.1
            let bodyWater = 52.0 + Double(day % 5) * 0.2
            let skeletalMuscle = 33.0 + Double(day % 4) * 0.1
            let muscleMass = 55.0 + Double(day % 5) * 0.2
            let boneMass = 3.00 + Double(day % 2) * 0.01
            let protein = 17.0 + Double(day % 4) * 0.1
            let basalMetabolicRate = 1_600 + day
            let metabolicAge = 39 + day % 3

            return String(
                format: "%02d:%02d 2026/05/%02d,%.2fkg,%.1f,%.1f%%,%.1f%%,--,--,%.1f,%.1f%%,%.1f%%,%.1fkg,%.2fkg,%.1f%%,%dkcal,%d,",
                hour,
                minute,
                day,
                bodyMass,
                bmi,
                bodyFat,
                subcutaneousFat,
                visceralFat,
                bodyWater,
                skeletalMuscle,
                muscleMass,
                boneMass,
                protein,
                basalMetabolicRate,
                metabolicAge
            )
        }
        return ([header] + rows).joined(separator: "\n")
    }

    private func sourceContents(_ relativePath: String) throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
    }
}
