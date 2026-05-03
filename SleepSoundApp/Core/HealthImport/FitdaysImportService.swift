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
    case unreadableFile
    case emptyFile
    case missingDateColumn

    public var errorDescription: String? {
        switch self {
        case .unreadableFile:
            "선택한 파일을 읽을 수 없습니다."
        case .emptyFile:
            "가져올 CSV 데이터가 없습니다."
        case .missingDateColumn:
            "측정일 column을 찾을 수 없습니다."
        }
    }
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
            .bodyMass: ["Weight", "Body Weight", "Wt", "WT", "Weight kg", "Weight(kg)", "체중", "몸무게"],
            .bodyMassIndex: ["BMI", "Body Mass Index"],
            .bodyFatPercentage: ["Body Fat", "Body Fat %", "Body Fat Percentage", "BF", "BF%", "Fat %", "체지방률"],
            .muscleMass: ["Muscle Mass", "Muscle", "Muscle kg", "Muscle(kg)", "MM", "근육량", "근육"],
            .skeletalMuscleMass: ["Skeletal Muscle", "Skeletal Muscle Mass", "SMM", "Skeletal Muscle kg", "Skeletal Muscle(kg)", "골격근량"],
            .bodyWaterPercentage: ["Body Water", "Body Water %", "Body Water Percentage", "BW%", "Water", "Water %", "체수분", "체수분률"],
            .visceralFatLevel: ["Visceral Fat", "Visceral Fat Level", "Visceral Fat Rating", "Visceral Fat Index", "VF", "VFL", "내장지방", "내장지방 레벨"],
            .visceralFatPercentage: ["Visceral Fat %", "Visceral Fat Percentage", "복부지방률"],
            .boneMass: ["Bone Mass", "Bone", "Bone kg", "Bone(kg)", "골량"],
            .mineralMass: ["Mineral", "Mineral Mass", "Minerals", "Mineral kg", "Mineral(kg)", "무기질"],
            .basalMetabolicRate: ["BMR", "BMR kcal", "BMR(kcal)", "Basal Metabolic Rate", "기초대사량"],
            .proteinPercentage: ["Protein", "Protein %", "Protein Percentage", "Protein%", "Protein Rate", "단백질률"],
            .subcutaneousFatPercentage: ["Subcutaneous Fat", "Subcutaneous Fat %", "Subcutaneous Fat Percentage", "SubQ Fat", "Subcutaneous Fat Rate", "피하지방률"],
            .metabolicAge: ["Body Age", "BodyAge", "Metabolic Age", "Age of Body", "대사 나이"],
            .bodyScore: ["Body Score", "Fitdays Body Score", "바디 점수", "몸 점수"],
            .obesityLevel: ["Obesity Level", "Body Type Level", "체형 레벨"],
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
        let trimmedColumn = columnName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        for (metricID, aliases) in metricColumnAliases {
            if aliases.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedColumn }) {
                return metricID
            }
        }

        let normalizedColumn = Self.normalized(columnName)
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
        let normalizedColumn = Self.normalized(columnName)
        return aliases.contains { Self.normalized($0) == normalizedColumn }
    }

    public static func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
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
        guard let csv = try? String(contentsOf: fileURL, encoding: .utf8) else {
            throw FitdaysImportError.unreadableFile
        }
        return try parseCSV(
            csv,
            fileName: fileURL.lastPathComponent,
            importedAt: now()
        )
    }

    @discardableResult
    public func importFile(
        from fileURL: URL,
        repository: UnifiedHealthMetricSampleRepositoryProtocol
    ) throws -> FitdaysImportResult {
        let result = try previewImport(from: fileURL)
        try repository.save(batch: result.batch, samples: result.samples)
        return result
    }

    public func parseCSV(
        _ csv: String,
        fileName: String = "fitdays_export.csv",
        importedAt: Date? = nil
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
                        sourceName: "Fitdays CSV",
                        externalRecordId: "\(fileName)#row\(rowNumber)#\(metricColumn.metricID.rawValue)",
                        importBatchId: importBatchId,
                        notes: "사용자가 선택한 Fitdays export 파일에서 가져온 값입니다.",
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
            sourceName: "Fitdays CSV",
            sourceType: .fitdaysCSV,
            importedAt: importedAt,
            fileName: fileName,
            rowCount: dataRows.count,
            sampleCount: samples.count,
            skippedRowCount: skippedRows,
            errorCount: rowErrors.count,
            notes: "서버/API 연동 없이 사용자가 선택한 로컬 파일에서 가져온 batch입니다."
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
            "yyyy-MM-dd",
            "yyyy/MM/dd",
            "yyyy.MM.dd",
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

        return nil
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
}

private struct MetricColumn: Equatable {
    var index: Int
    var name: String
    var metricID: UnifiedHealthMetricID
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
