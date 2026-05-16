import Foundation

public struct ImportBatch: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var sourceName: String
    public var sourceType: HealthMetricSourceType
    public var importedAt: Date
    public var fileName: String
    public var rowCount: Int
    public var sampleCount: Int
    public var skippedRowCount: Int
    public var errorCount: Int
    public var notes: String?

    public init(
        id: UUID = UUID(),
        sourceName: String,
        sourceType: HealthMetricSourceType,
        importedAt: Date = Date(),
        fileName: String,
        rowCount: Int,
        sampleCount: Int,
        skippedRowCount: Int,
        errorCount: Int,
        notes: String? = nil
    ) {
        self.id = id
        self.sourceName = sourceName
        self.sourceType = sourceType
        self.importedAt = importedAt
        self.fileName = fileName
        self.rowCount = rowCount
        self.sampleCount = sampleCount
        self.skippedRowCount = skippedRowCount
        self.errorCount = errorCount
        self.notes = notes
    }
}

public struct FitdaysImportRowError: Identifiable, Codable, Equatable, Sendable {
    public var id: String { "\(rowNumber)-\(message)" }
    public var rowNumber: Int
    public var message: String

    public init(rowNumber: Int, message: String) {
        self.rowNumber = rowNumber
        self.message = message
    }
}

public struct FitdaysImportResult: Codable, Equatable, Sendable {
    public var batch: ImportBatch
    public var samples: [UnifiedHealthMetricSample]
    public var unknownColumns: [String]
    public var rowErrors: [FitdaysImportRowError]

    public var importedSampleCount: Int { samples.count }
    public var skippedRowCount: Int { batch.skippedRowCount }
    public var errorCount: Int { rowErrors.count }

    public init(
        batch: ImportBatch,
        samples: [UnifiedHealthMetricSample],
        unknownColumns: [String],
        rowErrors: [FitdaysImportRowError]
    ) {
        self.batch = batch
        self.samples = samples
        self.unknownColumns = unknownColumns
        self.rowErrors = rowErrors
    }
}

public enum FitdaysImportError: LocalizedError, Equatable, Sendable {
    case unsupportedFileType
    case unreadableFile
    case emptyFile
    case missingDateColumn
    case noSupportedMetricColumns
    case noImportableSamples

    public var errorDescription: String? {
        switch self {
        case .unsupportedFileType:
            "CSV, TSV 또는 text 기반 export 파일만 가져올 수 있습니다."
        case .unreadableFile:
            "선택한 파일을 읽을 수 없습니다."
        case .emptyFile:
            "가져올 CSV 데이터가 없습니다."
        case .missingDateColumn:
            "측정일 열을 찾을 수 없습니다."
        case .noSupportedMetricColumns:
            "가져올 수 있는 건강 지표 열을 찾을 수 없습니다."
        case .noImportableSamples:
            "저장할 수 있는 건강 지표 샘플이 없습니다."
        }
    }
}

public enum FitdaysManualMetricEntryError: LocalizedError, Equatable, Sendable {
    case unsupportedMetric
    case invalidValue

    public var errorDescription: String? {
        switch self {
        case .unsupportedMetric:
            "Fitdays 고유 지표로 분리된 항목만 수동 입력할 수 있습니다."
        case .invalidValue:
            "0 이상의 숫자 값을 입력해 주세요."
        }
    }
}

public enum FitdaysManualMetricEntryBuilder {
    public static let sourceName = "Fitdays 수동 입력"
    public static let batchFileNamePrefix = "fitdays-manual"

    public static let supportedMetricIDs: [UnifiedHealthMetricID] = [
        .bodyWaterPercentage,
        .visceralFatLevel,
        .visceralFatPercentage,
        .skeletalMuscleMass,
        .muscleMass,
        .boneMass,
        .mineralMass,
        .basalMetabolicRate,
        .proteinPercentage,
        .subcutaneousFatPercentage,
        .metabolicAge,
        .bodyScore,
        .obesityLevel,
    ]

    public static func supportedMetadata(catalog: MetricCatalog = .default) -> [MetricDisplayMetadata] {
        supportedMetricIDs.compactMap { metadata in
            catalog.metadata(for: metadata)
        }
    }

    public static func makeSample(
        metricID: UnifiedHealthMetricID,
        value: Double,
        measuredAt: Date,
        notes: String? = nil,
        catalog: MetricCatalog = .default,
        createdAt: Date = Date()
    ) throws -> UnifiedHealthMetricSample {
        guard supportedMetricIDs.contains(metricID),
              let metadata = catalog.metadata(for: metricID),
              metadata.isExtendedLocalOnly,
              !metadata.isHealthKitBacked else {
            throw FitdaysManualMetricEntryError.unsupportedMetric
        }

        guard value.isFinite, value >= 0 else {
            throw FitdaysManualMetricEntryError.invalidValue
        }

        return UnifiedHealthMetricSample(
            metricID: metricID,
            value: value,
            unit: metadata.unit,
            measuredAt: measuredAt,
            sourceType: .manual,
            sourceName: sourceName,
            externalRecordId: manualRecordID(metricID: metricID, measuredAt: measuredAt),
            notes: notes?.nilIfBlank,
            createdAt: createdAt
        )
    }

    public static func makeBatch(
        for sample: UnifiedHealthMetricSample,
        importedAt: Date = Date()
    ) -> ImportBatch {
        ImportBatch(
            sourceName: sourceName,
            sourceType: .manual,
            importedAt: importedAt,
            fileName: "\(batchFileNamePrefix)-\(sample.metricID.rawValue)-\(Int(sample.measuredAt.timeIntervalSince1970))",
            rowCount: 1,
            sampleCount: 1,
            skippedRowCount: 0,
            errorCount: 0,
            notes: "사용자가 직접 입력한 Fitdays 고유 지표입니다. HealthKit에 쓰지 않습니다."
        )
    }

    private static func manualRecordID(metricID: UnifiedHealthMetricID, measuredAt: Date) -> String {
        "\(batchFileNamePrefix)-\(metricID.rawValue)-\(Int((measuredAt.timeIntervalSince1970 * 1_000).rounded()))"
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

public enum FitdaysImportFilePolicy {
    public static let supportedFileExtensions = ["csv", "tsv", "txt"]
    public static let supportedContentTypeIdentifiers = [
        "public.comma-separated-values-text",
        "public.tab-separated-values-text",
        "public.plain-text",
        "public.utf8-plain-text",
        "public.text",
    ]

    public static func isSupportedFileName(_ fileName: String) -> Bool {
        let pathExtension = URL(fileURLWithPath: fileName)
            .pathExtension
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return supportedFileExtensions.contains(pathExtension)
    }

    public static func isSupportedContentTypeIdentifier(_ identifier: String) -> Bool {
        supportedContentTypeIdentifiers.contains(identifier)
    }
}

public enum FitdaysImportFallbackGuidance {
    public static let privacyMessages = [
        "Fitdays 서버나 비공식 API에 연결하지 않습니다.",
        "선택한 파일은 기기 안에서만 parsing합니다.",
        "CSV/export가 보이지 않으면 Apple 건강앱 read-only 지표만 사용합니다.",
        "HealthKit에 데이터를 쓰지 않습니다.",
        "가져온 값은 개인 참고용 보기로만 표시합니다.",
    ]

    public static let emptyStateMessage = "위에서 클립보드 붙여넣기나 파일 선택을 하면 저장할 데이터가 이 자리에 표시됩니다. 파일이 없어도 Apple 건강앱 read-only 지표와 수면 소리 리포트는 계속 사용할 수 있습니다."
    public static let supportedFileSummary = "지원 파일: .csv, .tsv, .txt"
    public static let supportedPasteSummary = "Fitdays 월별 데이터 복사 텍스트도 붙여넣어 확인할 수 있습니다."
    public static let noImportablePreviewMessage = "저장 가능한 샘플이 없습니다. 측정일과 지원 지표 열이 있는 짧은 CSV/TSV export인지 확인해 주세요."
    public static let importErrorRecoveryMessage = "파일 구조를 확인하거나, export 메뉴를 찾지 못했다면 Apple 건강앱 read-only 경로를 먼저 사용해 주세요."

    public static let exportUnavailableTitle = "CSV/export 메뉴를 찾지 못한 경우"

    public static let exportUnavailableSteps = [
        "Fitdays 앱을 더 파고들거나 로그인/API 연결을 만들지 않습니다.",
        "Apple 건강앱에 동기화된 표준 지표를 HealthKit read-only로 먼저 봅니다.",
        "HealthKit에 없는 Fitdays 고유 지표는 사용자가 직접 입력한 로컬 수동 샘플로 저장할 수 있습니다.",
        "실제 메뉴 경로, 파일명, 계정 정보는 repository가 아니라 private QA note에만 기록합니다.",
    ]

    public static let healthDashboardFallbackTitle = "Apple 건강앱 read-only로 계속 보기"
    public static let localOnlyFollowUpTitle = "Fitdays 고유 지표는 로컬 수동 입력으로 저장"
    public static let prohibitedApproaches = [
        "Fitdays 서버/API 직접 연결",
        "Fitdays 계정 로그인",
        "자동 동기화",
        "비공식 연결 방식",
        "UI scraping",
    ]
}

public struct FitdaysCSVColumnMapping: Codable, Equatable, Sendable {
    public var dateColumnNames: [String]
    public var timeColumnNames: [String]
    public var metricColumnAliases: [UnifiedHealthMetricID: [String]]
    public var unitOverrides: [UnifiedHealthMetricID: String]

    public init(
        dateColumnNames: [String],
        timeColumnNames: [String],
        metricColumnAliases: [UnifiedHealthMetricID: [String]],
        unitOverrides: [UnifiedHealthMetricID: String] = [:]
    ) {
        self.dateColumnNames = dateColumnNames
        self.timeColumnNames = timeColumnNames
        self.metricColumnAliases = metricColumnAliases
        self.unitOverrides = unitOverrides
    }

    public static let fitdaysDefault = FitdaysCSVColumnMapping(
        dateColumnNames: [
            "Date",
            "Measure Date",
            "Measurement Date",
            "Measured Date",
            "Record Date",
            "Recorded At",
            "Measured At",
            "Measurement Timestamp",
            "Timestamp",
            "Date Time",
            "Datetime",
            "측정일",
            "측정 날짜",
            "측정일시",
            "측정 일시",
            "날짜",
            "짜",
            "일자",
            "기록일",
        ],
        timeColumnNames: [
            "Time",
            "Measure Time",
            "Measurement Time",
            "Measured Time",
            "Record Time",
            "Recorded Time",
            "측정시간",
            "측정 시간",
            "시간",
            "기록시간",
        ],
        metricColumnAliases: [
            .bodyMass: ["Weight", "Body Weight", "Wt", "WT", "Weight kg", "Weight(kg)", "체중", "몸무게", "몸무게 kg"],
            .bodyMassIndex: ["BMI", "Body Mass Index"],
            .bodyFatPercentage: ["Body Fat", "Body Fat %", "Body Fat Percentage", "BF", "BF%", "Fat %", "체지방률", "체지방율", "체지방"],
            .muscleMass: ["Muscle Mass", "Muscle", "Muscle kg", "Muscle(kg)", "MM", "근육량", "근육량 kg", "근육량(kg)", "근육"],
            .skeletalMuscleMass: ["Skeletal Muscle", "Skeletal Muscle Mass", "SMM", "Skeletal Muscle kg", "Skeletal Muscle(kg)", "골격근량", "골격근", "골격근 kg", "골격근(kg)"],
            .bodyWaterPercentage: ["Body Water", "Body Water %", "Body Water Percentage", "Body Water Rate", "BW%", "Water", "Water %", "체수분", "체수분률", "체수분율", "체내수분", "체내 수분", "체내수분량", "체내 수분량", "수분", "수분률", "수분율"],
            .visceralFatLevel: ["Visceral Fat", "Visceral Fat Level", "Visceral Fat Rating", "Visceral Fat Index", "VF", "VFL", "내장지방", "내장 지방", "내장지방 레벨", "내장 지방 레벨", "내장지방 지수", "내장 지방 지수", "내장지방등급", "내장 지방 등급"],
            .visceralFatPercentage: ["Visceral Fat %", "Visceral Fat Percentage", "복부지방률", "복부지방율"],
            .boneMass: ["Bone Mass", "Bone", "Bone kg", "Bone(kg)", "골량", "골질량", "뼈질량"],
            .leanBodyMass: ["Lean Body Mass", "Lean Mass", "Fat Free Mass", "Fat-Free Body Weight", "Fat Free Body Weight", "FFM", "제지방량", "제지방", "제지방 체중"],
            .mineralMass: ["Mineral", "Mineral Mass", "Minerals", "Mineral kg", "Mineral(kg)", "무기질"],
            .basalMetabolicRate: ["BMR", "BMR kcal", "BMR(kcal)", "Basal Metabolic Rate", "기초대사량", "기초 대사량", "기초대사", "기초 대사"],
            .proteinPercentage: ["Protein", "Protein %", "Protein Percentage", "Protein%", "Protein Rate", "단백질률", "단백질율", "단백질"],
            .subcutaneousFatPercentage: ["Subcutaneous Fat", "Subcutaneous Fat %", "Subcutaneous Fat Percentage", "SubQ Fat", "Subcutaneous Fat Rate", "피하지방", "피하 지방", "피하지방률", "피하지방율", "피하 지방률", "피하 지방율"],
            .metabolicAge: ["Body Age", "BodyAge", "Metabolic Age", "Age of Body", "대사 나이", "신체 나이", "신체나이", "몸 나이", "몸나이", "체나이"],
            .bodyScore: ["Body Score", "Fitdays Body Score", "바디 점수", "몸 점수", "신체 점수", "신체점수"],
            .obesityLevel: ["Obesity Level", "Body Type Level", "체형 레벨", "비만 레벨", "비만도", "비만등급", "비만 등급"],
            .systolicBloodPressure: ["Systolic", "Systolic BP", "SYS", "수축기 혈압"],
            .diastolicBloodPressure: ["Diastolic", "Diastolic BP", "DIA", "이완기 혈압"],
            .heartRate: ["Heart Rate", "Pulse", "심박수"],
        ],
        unitOverrides: [
            .basalMetabolicRate: "kcal/day",
            .visceralFatLevel: "level",
            .obesityLevel: "level",
            .metabolicAge: "years",
        ]
    )

    public func metricID(for columnName: String) -> UnifiedHealthMetricID? {
        let comparableColumn = Self.headerComparableText(columnName)
        let trimmedColumn = comparableColumn.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        for (metricID, aliases) in metricColumnAliases {
            if aliases.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedColumn }) {
                return metricID
            }
        }

        let normalizedColumn = Self.normalized(comparableColumn)
        for (metricID, aliases) in metricColumnAliases {
            if aliases.contains(where: { Self.normalized($0) == normalizedColumn }) {
                return metricID
            }
        }
        return nil
    }

    public func isDateColumn(_ columnName: String) -> Bool {
        contains(columnName, in: dateColumnNames)
    }

    public func isTimeColumn(_ columnName: String) -> Bool {
        contains(columnName, in: timeColumnNames)
    }

    public func unit(
        for metricID: UnifiedHealthMetricID,
        columnName: String,
        catalog: MetricCatalog = .default
    ) -> String {
        if let override = unitOverrides[metricID] {
            return override
        }
        if columnName.contains("%") {
            return "%"
        }
        return catalog.metadata(for: metricID)?.unit ?? ""
    }

    private func contains(_ columnName: String, in aliases: [String]) -> Bool {
        let normalizedColumn = Self.normalized(Self.headerComparableText(columnName))
        return aliases.contains { Self.normalized($0) == normalizedColumn }
    }

    public static func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }

    public static func headerComparableText(_ value: String) -> String {
        var text = value
            .replacingOccurrences(of: "（", with: "(")
            .replacingOccurrences(of: "）", with: ")")
            .replacingOccurrences(of: "：", with: ":")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let regex = try? NSRegularExpression(pattern: #"\([^)]*\)"#) {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            text = regex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
        }

        return text
            .replacingOccurrences(of: "클릭필수", with: "")
            .replacingOccurrences(of: "클릭 필수", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public struct FitdaysImportService: Sendable {
    public var mapping: FitdaysCSVColumnMapping
    public var catalog: MetricCatalog
    public var calendar: Calendar
    public var timeZone: TimeZone
    public var now: @Sendable () -> Date

    public init(
        mapping: FitdaysCSVColumnMapping = .fitdaysDefault,
        catalog: MetricCatalog = .default,
        calendar: Calendar = .current,
        timeZone: TimeZone = .current,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.mapping = mapping
        self.catalog = catalog
        self.calendar = calendar
        self.timeZone = timeZone
        self.now = now
    }

    public func previewImport(from fileURL: URL) throws -> FitdaysImportResult {
        guard FitdaysImportFilePolicy.isSupportedFileName(fileURL.lastPathComponent) else {
            throw FitdaysImportError.unsupportedFileType
        }
        guard let csv = try? String(contentsOf: fileURL, encoding: .utf8) else {
            throw FitdaysImportError.unreadableFile
        }
        return try parseCSV(
            csv,
            fileName: fileURL.lastPathComponent,
            importedAt: now()
        )
    }

    public func previewImport(fromPastedText pastedText: String) throws -> FitdaysImportResult {
        let trimmedText = pastedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw FitdaysImportError.emptyFile
        }

        let importedAt = now()
        let pasteContext = FitdaysPasteImportContext(
            fileName: "fitdays_pasted_monthly_text.tsv",
            importedAt: importedAt,
            sourceName: "Fitdays 붙여넣기",
            sampleNotes: "사용자가 붙여넣은 Fitdays 월별 데이터 복사 텍스트에서 가져온 값입니다.",
            batchNotes: "서버/API 연동 없이 사용자가 붙여넣은 Fitdays 월별 데이터에서 가져온 batch입니다."
        )

        do {
            let tableResult = try parseCSV(
                trimmedText,
                fileName: pasteContext.fileName,
                importedAt: importedAt,
                sourceName: pasteContext.sourceName,
                sampleNotes: pasteContext.sampleNotes,
                batchNotes: pasteContext.batchNotes
            )
            if !tableResult.samples.isEmpty {
                return tableResult
            }

            let whitespaceTableResult = parseWhitespaceTablePastedText(trimmedText, context: pasteContext)
            if !whitespaceTableResult.samples.isEmpty {
                return whitespaceTableResult
            }

            let looseResult = parseLoosePastedText(trimmedText, context: pasteContext)
            return looseResult.samples.isEmpty ? tableResult : looseResult
        } catch FitdaysImportError.emptyFile {
            throw FitdaysImportError.emptyFile
        } catch {
            let whitespaceTableResult = parseWhitespaceTablePastedText(trimmedText, context: pasteContext)
            if !whitespaceTableResult.samples.isEmpty {
                return whitespaceTableResult
            }

            let looseResult = parseLoosePastedText(trimmedText, context: pasteContext)
            if looseResult.samples.isEmpty {
                throw error
            }
            return looseResult
        }
    }

    @discardableResult
    public func importFile(
        from fileURL: URL,
        repository: UnifiedHealthMetricSampleRepositoryProtocol
    ) throws -> FitdaysImportResult {
        let result = try previewImport(from: fileURL)
        guard !result.samples.isEmpty else {
            throw FitdaysImportError.noImportableSamples
        }
        try repository.save(batch: result.batch, samples: result.samples)
        return result
    }

    @discardableResult
    public func importPastedText(
        _ pastedText: String,
        repository: UnifiedHealthMetricSampleRepositoryProtocol
    ) throws -> FitdaysImportResult {
        let result = try previewImport(fromPastedText: pastedText)
        guard !result.samples.isEmpty else {
            throw FitdaysImportError.noImportableSamples
        }
        try repository.save(batch: result.batch, samples: result.samples)
        return result
    }

    public func parseCSV(
        _ csv: String,
        fileName: String = "fitdays_export.csv",
        importedAt: Date? = nil,
        sourceName: String = "Fitdays CSV",
        sampleNotes: String = "사용자가 선택한 Fitdays export 파일에서 가져온 값입니다.",
        batchNotes: String = "서버/API 연동 없이 사용자가 선택한 로컬 파일에서 가져온 batch입니다."
    ) throws -> FitdaysImportResult {
        let importedAt = importedAt ?? now()
        let rows = CSVTableParser.rows(from: csv)
        guard let header = rows.first, !header.isEmpty else {
            throw FitdaysImportError.emptyFile
        }

        let dataRows = Array(rows.dropFirst())
        let dateIndex = header.firstIndex(where: mapping.isDateColumn)
        guard let dateIndex else {
            throw FitdaysImportError.missingDateColumn
        }

        let timeIndex = header.firstIndex(where: mapping.isTimeColumn)
        let metricColumns = header.enumerated().compactMap { index, columnName -> MetricColumn? in
            guard let metricID = mapping.metricID(for: columnName) else { return nil }
            return MetricColumn(index: index, name: columnName, metricID: metricID)
        }
        guard !metricColumns.isEmpty else {
            throw FitdaysImportError.noSupportedMetricColumns
        }
        let knownIndexes = Set(([dateIndex] + [timeIndex].compactMap { $0 } + metricColumns.map(\.index)))
        let unknownColumns = header.enumerated()
            .filter { index, column in !knownIndexes.contains(index) && !column.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map(\.element)

        let batchID = UUID()
        let importBatchId = batchID.uuidString
        var samples: [UnifiedHealthMetricSample] = []
        var rowErrors: [FitdaysImportRowError] = []
        var skippedRows = 0

        for (offset, row) in dataRows.enumerated() {
            let rowNumber = offset + 2
            guard row.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
                skippedRows += 1
                continue
            }
            guard let measuredAt = parseMeasuredAt(
                dateText: value(at: dateIndex, in: row),
                timeText: timeIndex.map { value(at: $0, in: row) }
            ) else {
                skippedRows += 1
                rowErrors.append(FitdaysImportRowError(rowNumber: rowNumber, message: "측정일/시간을 해석할 수 없습니다."))
                continue
            }

            let rowSampleStartCount = samples.count
            for metricColumn in metricColumns {
                let rawValue = value(at: metricColumn.index, in: row)
                guard !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    continue
                }
                if isMissingMetricPlaceholder(rawValue) {
                    continue
                }
                guard let parsedValue = parseMetricValue(rawValue) else {
                    rowErrors.append(FitdaysImportRowError(rowNumber: rowNumber, message: "\(metricColumn.name) 값을 숫자로 해석할 수 없습니다."))
                    continue
                }

                samples.append(
                    UnifiedHealthMetricSample(
                        metricID: metricColumn.metricID,
                        value: parsedValue,
                        unit: mapping.unit(for: metricColumn.metricID, columnName: metricColumn.name, catalog: catalog),
                        measuredAt: measuredAt,
                        sourceType: .fitdaysCSV,
                        sourceName: sourceName,
                        externalRecordId: "\(fileName)#row\(rowNumber)#\(metricColumn.metricID.rawValue)",
                        importBatchId: importBatchId,
                        notes: sampleNotes,
                        createdAt: importedAt
                    )
                )
            }

            if samples.count == rowSampleStartCount {
                skippedRows += 1
            }
        }

        let batch = ImportBatch(
            id: batchID,
            sourceName: sourceName,
            sourceType: .fitdaysCSV,
            importedAt: importedAt,
            fileName: fileName,
            rowCount: dataRows.count,
            sampleCount: samples.count,
            skippedRowCount: skippedRows,
            errorCount: rowErrors.count,
            notes: batchNotes
        )

        return FitdaysImportResult(
            batch: batch,
            samples: samples.sorted { lhs, rhs in
                if lhs.measuredAt == rhs.measuredAt {
                    return lhs.metricID.rawValue < rhs.metricID.rawValue
                }
                return lhs.measuredAt < rhs.measuredAt
            },
            unknownColumns: Array(Set(unknownColumns)).sorted(),
            rowErrors: rowErrors
        )
    }

    private func value(at index: Int, in row: [String]) -> String {
        guard row.indices.contains(index) else { return "" }
        return row[index].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseMeasuredAt(dateText: String, timeText: String?) -> Date? {
        let trimmedDate = dateText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTime = timeText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let combined = trimmedTime.isEmpty ? trimmedDate : "\(trimmedDate) \(trimmedTime)"

        if let date = parseISO8601Date(combined) {
            return date
        }

        if let date = parseReversedTimeLooseDate(in: combined) {
            return date
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = timeZone

        let formats = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd h:mm a",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm",
            "yyyy/MM/dd HH:mm:ss",
            "yyyy/MM/dd HH:mm",
            "yyyy/MM/dd h:mm a",
            "yyyy.MM.dd HH:mm:ss",
            "yyyy.MM.dd HH:mm",
            "MM/dd/yyyy HH:mm:ss",
            "MM/dd/yyyy HH:mm",
            "M/d/yyyy h:mm a",
            "dd/MM/yyyy HH:mm:ss",
            "dd/MM/yyyy HH:mm",
            "d/M/yyyy h:mm a",
            "dd.MM.yyyy HH:mm:ss",
            "dd.MM.yyyy HH:mm",
            "dd-MM-yyyy HH:mm:ss",
            "dd-MM-yyyy HH:mm",
            "yyyyMMdd HHmmss",
            "yyyyMMdd HHmm",
            "HH:mm:ss yyyy-MM-dd",
            "HH:mm yyyy-MM-dd",
            "HH:mm:ss yyyy/M/d",
            "HH:mm yyyy/M/d",
            "HH:mm:ss yyyy/MM/dd",
            "HH:mm yyyy/MM/dd",
            "HH:mm:ss yyyy.M.d",
            "HH:mm yyyy.M.d",
            "yyyy-MM-dd a h:mm:ss",
            "yyyy-MM-dd a h:mm",
            "yyyy/M/d a h:mm:ss",
            "yyyy/M/d a h:mm",
            "yyyy. M. d. a h:mm:ss",
            "yyyy. M. d. a h:mm",
            "yyyy.M.d a h:mm:ss",
            "yyyy.M.d a h:mm",
            "yyyy년 M월 d일 a h:mm:ss",
            "yyyy년 M월 d일 a h:mm",
            "yyyy-MM-dd",
            "yyyy/MM/dd",
            "yyyy.MM.dd",
            "yyyy. M. d.",
            "MM/dd/yyyy",
            "dd/MM/yyyy",
            "dd.MM.yyyy",
            "dd-MM-yyyy",
            "yyyyMMdd",
            "yyyy년 M월 d일 HH:mm",
            "yyyy년 M월 d일",
        ]

        for locale in [Locale(identifier: "en_US_POSIX"), Locale(identifier: "ko_KR")] {
            formatter.locale = locale
            for format in formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: combined) {
                    return date
                }
            }
        }

        return parseLooseYearMonthDay(in: combined)
    }

    private func parseISO8601Date(_ text: String) -> Date? {
        for options in [
            ISO8601DateFormatter.Options.withInternetDateTime,
            [.withInternetDateTime, .withFractionalSeconds],
        ] {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = options
            formatter.timeZone = timeZone
            if let date = formatter.date(from: text) {
                return date
            }
        }
        return nil
    }

    private func parseMetricValue(_ rawValue: String) -> Double? {
        let cleaned = rawValue
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: "kg", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "kcal/day", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "kcal", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "mmHg", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "bpm", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "years", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "year", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "level", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "\u{00a0}", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { return nil }
        return Double(normalizedDecimalText(cleaned))
    }

    private func isMissingMetricPlaceholder(_ rawValue: String) -> Bool {
        let normalized = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return [
            "",
            "-",
            "--",
            "---",
            "n/a",
            "na",
            "null",
            "없음",
            "미측정",
        ].contains(normalized)
    }

    private func normalizedDecimalText(_ text: String) -> String {
        let compact = text.filter { !$0.isWhitespace }
        guard compact.contains(",") else {
            return compact
        }

        if compact.contains(".") {
            if let lastComma = compact.lastIndex(of: ","),
               let lastDot = compact.lastIndex(of: "."),
               lastComma > lastDot {
                return compact
                    .replacingOccurrences(of: ".", with: "")
                    .replacingOccurrences(of: ",", with: ".")
            }
            return compact.replacingOccurrences(of: ",", with: "")
        }

        let parts = compact.split(separator: ",", omittingEmptySubsequences: false)
        guard parts.count == 2 else {
            return compact.replacingOccurrences(of: ",", with: "")
        }

        let decimalDigits = parts[1].count
        if decimalDigits == 3, parts[0].count > 1 {
            return compact.replacingOccurrences(of: ",", with: "")
        }
        return compact.replacingOccurrences(of: ",", with: ".")
    }

    private func parseLoosePastedText(
        _ text: String,
        context: FitdaysPasteImportContext
    ) -> FitdaysImportResult {
        let batchID = UUID()
        let importBatchId = batchID.uuidString
        let defaultYear = calendar.component(.year, from: context.importedAt)
        let lines = text
            .split(whereSeparator: \.isNewline)
            .enumerated()
            .map { index, line in
                LoosePasteLine(
                    number: index + 1,
                    text: String(line).trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            .filter { !$0.text.isEmpty }

        var currentMeasuredAt: Date?
        var monthContext: LooseMonthContext?
        var pendingMetric: PendingLooseMetric?
        var samples: [UnifiedHealthMetricSample] = []
        var rowErrors: [FitdaysImportRowError] = []
        var skippedRows = 0
        var didUseImportDateFallback = false
        let allowsImportDateFallback = !containsAnyLooseMeasurementDate(lines, defaultYear: defaultYear)

        for line in lines {
            if let parsedMonthContext = parseLooseMonthContext(line.text, defaultYear: defaultYear) {
                monthContext = parsedMonthContext
                pendingMetric = nil
                continue
            }

            let measuredAtInLine = parseLooseMeasuredAt(
                line.text,
                defaultYear: defaultYear,
                monthContext: monthContext
            )
            if let measuredAtInLine {
                currentMeasuredAt = measuredAtInLine
                pendingMetric = nil
            }

            let pairs = looseMetricPairs(in: line.text)
            if !pairs.isEmpty {
                if let measuredAt = currentMeasuredAt {
                    for pair in pairs {
                        samples.append(
                            looseSample(
                                metricID: pair.metricID,
                                label: pair.label,
                                value: pair.value,
                                measuredAt: measuredAt,
                                lineNumber: line.number,
                                batchID: importBatchId,
                                context: context
                            )
                        )
                    }
                    continue
                }

                if allowsImportDateFallback {
                    if !didUseImportDateFallback {
                        rowErrors.append(
                            FitdaysImportRowError(
                                rowNumber: line.number,
                                message: "측정일을 찾지 못해 가져오기 시각으로 임시 처리했습니다."
                            )
                        )
                        didUseImportDateFallback = true
                    }
                    for pair in pairs {
                        samples.append(
                            looseSample(
                                metricID: pair.metricID,
                                label: pair.label,
                                value: pair.value,
                                measuredAt: context.importedAt,
                                lineNumber: line.number,
                                batchID: importBatchId,
                                context: context
                            )
                        )
                    }
                    continue
                }

                rowErrors.append(
                    FitdaysImportRowError(
                        rowNumber: line.number,
                        message: "측정일을 먼저 찾지 못해 지표 값을 건너뛰었습니다."
                    )
                )
                continue
            }

            if let pendingMetricValue = pendingMetric,
               let valueText = firstNumericToken(in: line.text),
               let value = parseMetricValue(valueText) {
                let measuredAt = currentMeasuredAt ?? (allowsImportDateFallback ? context.importedAt : nil)
                guard let measuredAt else {
                    rowErrors.append(
                        FitdaysImportRowError(
                            rowNumber: line.number,
                            message: "측정일을 먼저 찾지 못해 지표 값을 건너뛰었습니다."
                        )
                    )
                    pendingMetric = nil
                    continue
                }
                if currentMeasuredAt == nil, !didUseImportDateFallback {
                    rowErrors.append(
                        FitdaysImportRowError(
                            rowNumber: pendingMetricValue.lineNumber,
                            message: "측정일을 찾지 못해 가져오기 시각으로 임시 처리했습니다."
                        )
                    )
                    didUseImportDateFallback = true
                }
                samples.append(
                    looseSample(
                        metricID: pendingMetricValue.metricID,
                        label: pendingMetricValue.label,
                        value: value,
                        measuredAt: measuredAt,
                        lineNumber: line.number,
                        batchID: importBatchId,
                        context: context
                    )
                )
                pendingMetric = nil
                continue
            }

            if measuredAtInLine != nil {
                continue
            }

            if let metric = looseMetricLabel(in: line.text) {
                pendingMetric = PendingLooseMetric(
                    metricID: metric.metricID,
                    label: metric.label,
                    lineNumber: line.number
                )
                continue
            }

            if currentMeasuredAt == nil, lineMayContainMetric(line.text) {
                rowErrors.append(
                    FitdaysImportRowError(
                        rowNumber: line.number,
                        message: "측정일을 먼저 찾지 못해 지표 값을 건너뛰었습니다."
                    )
                )
            } else {
                skippedRows += 1
            }
        }

        let batch = ImportBatch(
            id: batchID,
            sourceName: context.sourceName,
            sourceType: .fitdaysCSV,
            importedAt: context.importedAt,
            fileName: context.fileName,
            rowCount: lines.count,
            sampleCount: samples.count,
            skippedRowCount: skippedRows,
            errorCount: rowErrors.count,
            notes: context.batchNotes
        )

        return FitdaysImportResult(
            batch: batch,
            samples: samples.sorted { lhs, rhs in
                if lhs.measuredAt == rhs.measuredAt {
                    return lhs.metricID.rawValue < rhs.metricID.rawValue
                }
                return lhs.measuredAt < rhs.measuredAt
            },
            unknownColumns: [],
            rowErrors: rowErrors
        )
    }

    private func looseSample(
        metricID: UnifiedHealthMetricID,
        label: String,
        value: Double,
        measuredAt: Date,
        lineNumber: Int,
        batchID: String,
        context: FitdaysPasteImportContext
    ) -> UnifiedHealthMetricSample {
        UnifiedHealthMetricSample(
            metricID: metricID,
            value: value,
            unit: mapping.unit(for: metricID, columnName: label, catalog: catalog),
            measuredAt: measuredAt,
            sourceType: .fitdaysCSV,
            sourceName: context.sourceName,
            externalRecordId: "\(context.fileName)#line\(lineNumber)#\(metricID.rawValue)",
            importBatchId: batchID,
            notes: context.sampleNotes,
            createdAt: context.importedAt
        )
    }

    private func parseWhitespaceTablePastedText(
        _ text: String,
        context: FitdaysPasteImportContext
    ) -> FitdaysImportResult {
        let batchID = UUID()
        let importBatchId = batchID.uuidString
        let defaultYear = calendar.component(.year, from: context.importedAt)
        let lines = text
            .split(whereSeparator: \.isNewline)
            .enumerated()
            .map { index, line in
                LoosePasteLine(
                    number: index + 1,
                    text: String(line).trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            .filter { !$0.text.isEmpty }

        var monthContext: LooseMonthContext?
        var schema: WhitespaceTableSchema?
        var samples: [UnifiedHealthMetricSample] = []
        var rowErrors: [FitdaysImportRowError] = []
        var skippedRows = 0

        for line in lines {
            if let parsedMonthContext = parseLooseMonthContext(line.text, defaultYear: defaultYear) {
                monthContext = parsedMonthContext
                continue
            }

            let tokens = whitespaceTokens(in: line.text)
            guard tokens.count >= 2 else {
                skippedRows += 1
                continue
            }

            if let parsedSchema = whitespaceTableSchema(from: tokens) {
                schema = parsedSchema
                continue
            }

            guard let schema else {
                skippedRows += 1
                continue
            }

            let dateText = value(at: schema.dateIndex, in: tokens)
            let timeText = schema.timeIndex.map { value(at: $0, in: tokens) }
            let combinedDateText = [dateText, timeText].compactMap { $0 }.joined(separator: " ")
            guard let measuredAt = parseMeasuredAt(dateText: dateText, timeText: timeText)
                    ?? parseLooseMeasuredAt(
                        combinedDateText,
                        defaultYear: defaultYear,
                        monthContext: monthContext
                    ) else {
                skippedRows += 1
                rowErrors.append(
                    FitdaysImportRowError(rowNumber: line.number, message: "측정일/시간을 해석할 수 없습니다.")
                )
                continue
            }

            let sampleStartCount = samples.count
            for metricColumn in schema.metricColumns {
                let rawValue = value(at: metricColumn.index, in: tokens)
                guard !rawValue.isEmpty,
                      !isMissingMetricPlaceholder(rawValue),
                      let value = parseMetricValue(rawValue) else {
                    continue
                }
                samples.append(
                    looseSample(
                        metricID: metricColumn.metricID,
                        label: metricColumn.name,
                        value: value,
                        measuredAt: measuredAt,
                        lineNumber: line.number,
                        batchID: importBatchId,
                        context: context
                    )
                )
            }

            if samples.count == sampleStartCount {
                skippedRows += 1
            }
        }

        let batch = ImportBatch(
            id: batchID,
            sourceName: context.sourceName,
            sourceType: .fitdaysCSV,
            importedAt: context.importedAt,
            fileName: context.fileName,
            rowCount: lines.count,
            sampleCount: samples.count,
            skippedRowCount: skippedRows,
            errorCount: rowErrors.count,
            notes: context.batchNotes
        )

        return FitdaysImportResult(
            batch: batch,
            samples: samples.sorted { lhs, rhs in
                if lhs.measuredAt == rhs.measuredAt {
                    return lhs.metricID.rawValue < rhs.metricID.rawValue
                }
                return lhs.measuredAt < rhs.measuredAt
            },
            unknownColumns: [],
            rowErrors: rowErrors
        )
    }

    private func parseLooseMeasuredAt(
        _ text: String,
        defaultYear: Int,
        monthContext: LooseMonthContext?
    ) -> Date? {
        if let date = parseMeasuredAt(dateText: text, timeText: nil) {
            return date
        }

        if let date = parseLooseYearMonthDay(in: text) {
            return date
        }

        if let date = parseLooseMonthDay(in: text, defaultYear: defaultYear) {
            return date
        }

        if let monthContext,
           let date = parseLooseDayOnly(in: text, monthContext: monthContext) {
            return date
        }

        return parseLooseNumericMonthDay(in: text, defaultYear: defaultYear)
    }

    private func parseReversedTimeLooseDate(in text: String) -> Date? {
        let pattern = #"(?<!\d)(\d{1,2}):(\d{2})(?::(\d{2}))?\s+(20\d{2})[./-](\d{1,2})[./-](\d{1,3})(?!\d)"#
        guard let match = firstMatch(pattern: pattern, in: text),
              let hour = intCapture(1, in: match, text: text),
              let minute = intCapture(2, in: match, text: text),
              let year = intCapture(4, in: match, text: text),
              let month = intCapture(5, in: match, text: text),
              let dayText = stringCapture(6, in: match, text: text),
              let day = normalizedDay(from: dayText) else {
            return nil
        }
        let second = intCapture(3, in: match, text: text)
        return date(year: year, month: month, day: day, meridiem: nil, hour: hour, minute: minute, second: second)
    }

    private func containsAnyLooseMeasurementDate(_ lines: [LoosePasteLine], defaultYear: Int) -> Bool {
        var monthContext: LooseMonthContext?
        for line in lines {
            if let parsedMonthContext = parseLooseMonthContext(line.text, defaultYear: defaultYear) {
                monthContext = parsedMonthContext
                continue
            }
            if parseLooseMeasuredAt(line.text, defaultYear: defaultYear, monthContext: monthContext) != nil {
                return true
            }
        }
        return false
    }

    private func parseLooseMonthContext(_ text: String, defaultYear: Int) -> LooseMonthContext? {
        let patterns = [
            #"(?<!\d)(20\d{2})\s*년\s*(\d{1,2})\s*월(?!\s*\d{1,2}\s*일)"#,
            #"(?<!\d)(20\d{2})[./-](\d{1,2})(?![./-]\d{1,2})"#,
            #"(?<!\d)(\d{1,2})\s*월(?!\s*\d{1,2}\s*일)"#,
        ]

        for pattern in patterns {
            guard let match = firstMatch(pattern: pattern, in: text) else { continue }
            let year: Int
            let month: Int
            if match.numberOfRanges >= 3,
               let first = intCapture(1, in: match, text: text),
               let second = intCapture(2, in: match, text: text) {
                year = first > 1900 ? first : defaultYear
                month = first > 1900 ? second : first
            } else if let monthOnly = intCapture(1, in: match, text: text) {
                year = defaultYear
                month = monthOnly
            } else {
                continue
            }

            guard (1...12).contains(month) else { continue }
            return LooseMonthContext(year: year, month: month)
        }

        return nil
    }

    private func parseLooseYearMonthDay(in text: String) -> Date? {
        let pattern = #"(?<!\d)(20\d{2})\s*[년./-]?\s*(\d{1,2})\s*[월./-]?\s*(\d{1,3})\s*[일.]?(?:\s*(오전|오후|AM|PM|am|pm)?\s*(\d{1,2})[:시]\s*(\d{2})(?:[:분]\s*(\d{2}))?)?"#
        guard let match = firstMatch(pattern: pattern, in: text),
              let year = intCapture(1, in: match, text: text),
              let month = intCapture(2, in: match, text: text),
              let dayText = stringCapture(3, in: match, text: text),
              let day = normalizedDay(from: dayText) else {
            return nil
        }
        let meridiem = stringCapture(4, in: match, text: text)
        let hour = intCapture(5, in: match, text: text)
        let minute = intCapture(6, in: match, text: text)
        let second = intCapture(7, in: match, text: text)
        return date(year: year, month: month, day: day, meridiem: meridiem, hour: hour, minute: minute, second: second)
    }

    private func parseLooseMonthDay(in text: String, defaultYear: Int) -> Date? {
        let pattern = #"(?<!\d)(\d{1,2})\s*월\s*(\d{1,2})\s*일(?:\s*(오전|오후|AM|PM|am|pm)?\s*(\d{1,2})[:시]\s*(\d{2})(?:[:분]\s*(\d{2}))?)?"#
        guard let match = firstMatch(pattern: pattern, in: text),
              let month = intCapture(1, in: match, text: text),
              let day = intCapture(2, in: match, text: text) else {
            return nil
        }
        let meridiem = stringCapture(3, in: match, text: text)
        let hour = intCapture(4, in: match, text: text)
        let minute = intCapture(5, in: match, text: text)
        let second = intCapture(6, in: match, text: text)
        return date(year: defaultYear, month: month, day: day, meridiem: meridiem, hour: hour, minute: minute, second: second)
    }

    private func normalizedDay(from text: String) -> Int? {
        let digits = text.filter { $0.isNumber }
        if digits.count == 3, digits.first == "0" {
            let twoDigitPrefix = String(digits.prefix(2))
            if let day = Int(twoDigitPrefix), (1...31).contains(day) {
                return day
            }
        }
        guard let day = Int(digits), (1...31).contains(day) else {
            return nil
        }
        return day
    }

    private func parseLooseNumericMonthDay(in text: String, defaultYear: Int) -> Date? {
        let pattern = #"(?<!\d)(\d{1,2})[./-](\d{1,2})(?!\d)(?:\s*(오전|오후|AM|PM|am|pm)?\s*(\d{1,2})[:시]\s*(\d{2})(?:[:분]\s*(\d{2}))?)?"#
        guard let match = firstMatch(pattern: pattern, in: text),
              let month = intCapture(1, in: match, text: text),
              let day = intCapture(2, in: match, text: text) else {
            return nil
        }
        let meridiem = stringCapture(3, in: match, text: text)
        let hour = intCapture(4, in: match, text: text)
        let minute = intCapture(5, in: match, text: text)
        let second = intCapture(6, in: match, text: text)
        return date(year: defaultYear, month: month, day: day, meridiem: meridiem, hour: hour, minute: minute, second: second)
    }

    private func parseLooseDayOnly(in text: String, monthContext: LooseMonthContext) -> Date? {
        let pattern = #"^\s*(\d{1,2})(?:일|[.)])?(?![.,]\d)(?:\s+(오전|오후|AM|PM|am|pm)?\s*(\d{1,2})[:시]\s*(\d{2})(?:[:분]\s*(\d{2}))?)?"#
        guard let match = firstMatch(pattern: pattern, in: text),
              let day = intCapture(1, in: match, text: text) else {
            return nil
        }
        let meridiem = stringCapture(2, in: match, text: text)
        let hour = intCapture(3, in: match, text: text)
        let minute = intCapture(4, in: match, text: text)
        let second = intCapture(5, in: match, text: text)
        return date(
            year: monthContext.year,
            month: monthContext.month,
            day: day,
            meridiem: meridiem,
            hour: hour,
            minute: minute,
            second: second
        )
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        meridiem: String?,
        hour: Int?,
        minute: Int?,
        second: Int?
    ) -> Date? {
        guard (1...12).contains(month), (1...31).contains(day) else {
            return nil
        }
        if let hour {
            if meridiem == nil {
                guard (0...23).contains(hour) else { return nil }
            } else {
                guard (1...12).contains(hour) else { return nil }
            }
        }
        if let minute {
            guard (0...59).contains(minute) else { return nil }
        }
        if let second {
            guard (0...59).contains(second) else { return nil }
        }

        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = timeZone
        components.year = year
        components.month = month
        components.day = day

        let normalizedMeridiem = meridiem?.lowercased()
        var resolvedHour = hour ?? 0
        if normalizedMeridiem == "오후" || normalizedMeridiem == "pm" {
            if resolvedHour < 12 {
                resolvedHour += 12
            }
        } else if normalizedMeridiem == "오전" || normalizedMeridiem == "am" {
            if resolvedHour == 12 {
                resolvedHour = 0
            }
        }
        components.hour = resolvedHour
        components.minute = minute ?? 0
        components.second = second ?? 0
        return calendar.date(from: components)
    }

    private func looseMetricPairs(in text: String) -> [LooseMetricPair] {
        var pairs: [LooseMetricPair] = []
        var seenMetricIDs = Set<UnifiedHealthMetricID>()
        for alias in metricAliasesSortedByLength() {
            guard let valueText = valueText(near: alias.label, in: text),
                  let value = parseMetricValue(valueText) else {
                continue
            }
            guard !seenMetricIDs.contains(alias.metricID) else { continue }
            seenMetricIDs.insert(alias.metricID)
            pairs.append(LooseMetricPair(metricID: alias.metricID, label: alias.label, value: value))
        }
        return pairs
    }

    private func looseMetricLabel(in text: String) -> (metricID: UnifiedHealthMetricID, label: String)? {
        guard firstNumericToken(in: text) == nil else { return nil }
        let normalizedText = FitdaysCSVColumnMapping.normalized(text)
        return metricAliasesSortedByLength().first { alias in
            FitdaysCSVColumnMapping.normalized(alias.label) == normalizedText
        }
        .map { ($0.metricID, $0.label) }
    }

    private func lineMayContainMetric(_ text: String) -> Bool {
        let normalizedText = FitdaysCSVColumnMapping.normalized(text)
        return metricAliasesSortedByLength().contains { alias in
            let normalizedAlias = FitdaysCSVColumnMapping.normalized(alias.label)
            return !normalizedAlias.isEmpty && normalizedText.contains(normalizedAlias)
        }
    }

    private func metricAliasesSortedByLength() -> [(metricID: UnifiedHealthMetricID, label: String)] {
        mapping.metricColumnAliases
            .flatMap { metricID, aliases in
                aliases.map { (metricID: metricID, label: $0) }
            }
            .sorted {
                FitdaysCSVColumnMapping.normalized($0.label).count > FitdaysCSVColumnMapping.normalized($1.label).count
            }
    }

    private func valueText(near label: String, in text: String) -> String? {
        if let range = text.range(of: label, options: [.caseInsensitive, .diacriticInsensitive]) {
            let suffix = String(text[range.upperBound...])
            if let value = firstNumericToken(in: suffix) {
                return value
            }
            let prefix = String(text[..<range.lowerBound])
            return firstNumericToken(in: prefix)
        }

        let normalizedLabel = FitdaysCSVColumnMapping.normalized(label)
        let normalizedText = FitdaysCSVColumnMapping.normalized(text)
        guard normalizedText.contains(normalizedLabel) else { return nil }
        return firstNumericToken(in: text)
    }

    private func firstNumericToken(in text: String) -> String? {
        let pattern = #"[-+]?\d+(?:[.,]\d+)?"#
        guard let match = firstMatch(pattern: pattern, in: text) else {
            return nil
        }
        return stringCapture(0, in: match, text: text)
    }

    private func whitespaceTokens(in text: String) -> [String] {
        text
            .replacingOccurrences(of: "：", with: ":")
            .split(whereSeparator: \.isWhitespace)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func whitespaceTableSchema(from tokens: [String]) -> WhitespaceTableSchema? {
        let dateIndex = tokens.firstIndex { token in
            mapping.isDateColumn(token) || ["일", "일자", "Day", "day"].contains(token)
        }
        guard let dateIndex else { return nil }

        let timeIndex = tokens.firstIndex(where: mapping.isTimeColumn)
        let metricColumns = tokens.enumerated().compactMap { index, token -> MetricColumn? in
            guard index != dateIndex,
                  index != timeIndex,
                  let metricID = mapping.metricID(for: token) else {
                return nil
            }
            return MetricColumn(index: index, name: token, metricID: metricID)
        }

        guard !metricColumns.isEmpty else { return nil }
        return WhitespaceTableSchema(dateIndex: dateIndex, timeIndex: timeIndex, metricColumns: metricColumns)
    }

    private func firstMatch(pattern: String, in text: String) -> NSTextCheckingResult? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, range: range)
    }

    private func stringCapture(_ index: Int, in match: NSTextCheckingResult, text: String) -> String? {
        guard index < match.numberOfRanges else { return nil }
        let range = match.range(at: index)
        guard range.location != NSNotFound,
              let swiftRange = Range(range, in: text) else {
            return nil
        }
        return String(text[swiftRange])
    }

    private func intCapture(_ index: Int, in match: NSTextCheckingResult, text: String) -> Int? {
        guard let capture = stringCapture(index, in: match, text: text) else {
            return nil
        }
        return Int(capture)
    }
}

private struct MetricColumn: Equatable {
    var index: Int
    var name: String
    var metricID: UnifiedHealthMetricID
}

private struct FitdaysPasteImportContext {
    var fileName: String
    var importedAt: Date
    var sourceName: String
    var sampleNotes: String
    var batchNotes: String
}

private struct LoosePasteLine {
    var number: Int
    var text: String
}

private struct LooseMonthContext {
    var year: Int
    var month: Int
}

private struct WhitespaceTableSchema {
    var dateIndex: Int
    var timeIndex: Int?
    var metricColumns: [MetricColumn]
}

private struct PendingLooseMetric {
    var metricID: UnifiedHealthMetricID
    var label: String
    var lineNumber: Int
}

private struct LooseMetricPair {
    var metricID: UnifiedHealthMetricID
    var label: String
    var value: Double
}

enum CSVTableParser {
    static func rows(from csv: String) -> [[String]] {
        rows(from: csv, delimiter: inferredDelimiter(from: csv))
    }

    private static func rows(from csv: String, delimiter: Character) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var isInsideQuotes = false
        var index = csv.startIndex

        while index < csv.endIndex {
            let character = csv[index]

            if character == "\"" {
                let nextIndex = csv.index(after: index)
                if isInsideQuotes, nextIndex < csv.endIndex, csv[nextIndex] == "\"" {
                    field.append("\"")
                    index = nextIndex
                } else {
                    isInsideQuotes.toggle()
                }
            } else if character == delimiter, !isInsideQuotes {
                row.append(field)
                field = ""
            } else if character == "\n", !isInsideQuotes {
                row.append(field)
                rows.append(row)
                row = []
                field = ""
            } else if character == "\r", !isInsideQuotes {
                // Ignore CR in CRLF line endings.
            } else {
                field.append(character)
            }

            index = csv.index(after: index)
        }

        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }

        return rows
    }

    private static func inferredDelimiter(from csv: String) -> Character {
        guard let headerLine = csv.split(whereSeparator: { $0 == "\n" || $0 == "\r" }).first else {
            return ","
        }

        let candidates: [Character] = [",", ";", "\t"]
        return candidates.max { lhs, rhs in
            delimiterCount(lhs, in: headerLine) < delimiterCount(rhs, in: headerLine)
        } ?? ","
    }

    private static func delimiterCount(_ delimiter: Character, in text: Substring) -> Int {
        var count = 0
        var isInsideQuotes = false
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]
            if character == "\"" {
                let nextIndex = text.index(after: index)
                if isInsideQuotes, nextIndex < text.endIndex, text[nextIndex] == "\"" {
                    index = nextIndex
                } else {
                    isInsideQuotes.toggle()
                }
            } else if character == delimiter, !isInsideQuotes {
                count += 1
            }
            index = text.index(after: index)
        }

        return count
    }
}
