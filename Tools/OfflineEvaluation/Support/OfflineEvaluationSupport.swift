import Foundation
import SleepSoundCore

public enum OfflineEvaluationError: Error, Equatable, Sendable {
  case missingManifestPath
  case emptyManifest
  case failedToWriteOutput(String)
  case invalidProfile(String)
  case invalidBackend(String)

  public var message: String {
    switch self {
    case .missingManifestPath:
      "manifest 경로가 필요합니다."
    case .emptyManifest:
      "manifest에 평가할 segment가 없습니다."
    case .failedToWriteOutput(let reason):
      "evaluation output 저장에 실패했습니다. \(reason)"
    case .invalidProfile(let profile):
      "알 수 없는 detector profile입니다. \(profile)"
    case .invalidBackend(let backend):
      "알 수 없는 detector backend입니다. \(backend)"
    }
  }
}

public struct OfflineEvaluationManifest: Codable, Equatable, Sendable {
  public var datasetName: String?
  public var datasetLicenseNote: String?
  public var segments: [OfflineEvaluationManifestSegment]

  public init(
    datasetName: String? = nil,
    datasetLicenseNote: String? = nil,
    segments: [OfflineEvaluationManifestSegment]
  ) {
    self.datasetName = datasetName
    self.datasetLicenseNote = datasetLicenseNote
    self.segments = segments
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let manifestDatasetName = try container.decodeIfPresent(String.self, forKey: .datasetName)
    let manifestDatasetLicenseNote =
      try container.decodeIfPresent(String.self, forKey: .datasetLicenseNote)
      ?? container.decodeIfPresent(String.self, forKey: .licenseNote)
    datasetName = manifestDatasetName
    datasetLicenseNote = manifestDatasetLicenseNote

    let decodedSegments =
      try container.decodeIfPresent([OfflineEvaluationManifestSegment].self, forKey: .segments) ?? []
    segments = decodedSegments.map { segment in
      var copy = segment
      if copy.datasetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
         let manifestDatasetName {
        copy.datasetName = manifestDatasetName
      }
      if copy.datasetLicenseNote?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true,
         let manifestDatasetLicenseNote {
        copy.datasetLicenseNote = manifestDatasetLicenseNote
      }
      return copy
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(datasetName, forKey: .datasetName)
    try container.encodeIfPresent(datasetLicenseNote, forKey: .datasetLicenseNote)
    try container.encode(segments, forKey: .segments)
  }

  private enum CodingKeys: String, CodingKey {
    case datasetName
    case datasetLicenseNote
    case licenseNote
    case segments
  }
}

public struct OfflineEvaluationManifestSegment: Codable, Equatable, Identifiable, Sendable {
  public var datasetName: String
  public var datasetLicenseNote: String?
  public var fileId: String
  public var localFilePath: String
  public var subjectId: String?
  public var recordingType: String
  public var microphoneType: String
  public var segmentStartSeconds: TimeInterval
  public var segmentDurationSeconds: TimeInterval
  public var expectedLabels: [String]
  public var negativeLabels: [String]
  public var confidenceNote: String?
  public var notes: String?
  public var decodedMissingFields: [String]

  public var id: String {
    "\(datasetName)-\(fileId)-\(segmentStartSeconds)-\(segmentDurationSeconds)"
  }

  public var filePath: String {
    get { localFilePath }
    set { localFilePath = newValue }
  }

  public var licenseNote: String {
    get { datasetLicenseNote ?? "" }
    set { datasetLicenseNote = newValue }
  }

  public init(
    datasetName: String,
    datasetLicenseNote: String? = nil,
    fileId: String,
    localFilePath: String,
    subjectId: String? = nil,
    recordingType: String = DatasetRecordingType.personalDebugSample.rawValue,
    microphoneType: String = DatasetMicrophoneType.unknown.rawValue,
    segmentStartSeconds: TimeInterval,
    segmentDurationSeconds: TimeInterval,
    expectedLabels: [String],
    negativeLabels: [String] = [],
    confidenceNote: String? = nil,
    notes: String? = nil,
    decodedMissingFields: [String] = []
  ) {
    self.datasetName = datasetName
    self.datasetLicenseNote = datasetLicenseNote
    self.fileId = fileId
    self.localFilePath = localFilePath
    self.subjectId = subjectId
    self.recordingType = recordingType
    self.microphoneType = microphoneType
    self.segmentStartSeconds = max(0, segmentStartSeconds)
    self.segmentDurationSeconds = max(0, segmentDurationSeconds)
    self.expectedLabels = expectedLabels
    self.negativeLabels = negativeLabels
    self.confidenceNote = confidenceNote
    self.notes = notes
    self.decodedMissingFields = decodedMissingFields
  }

  public init(
    datasetName: String,
    filePath: String,
    fileId: String,
    segmentStartSeconds: TimeInterval,
    segmentDurationSeconds: TimeInterval,
    expectedLabels: [SleepEventType],
    notes: String? = nil,
    licenseNote: String
  ) {
    self.init(
      datasetName: datasetName,
      datasetLicenseNote: licenseNote,
      fileId: fileId,
      localFilePath: filePath,
      segmentStartSeconds: segmentStartSeconds,
      segmentDurationSeconds: segmentDurationSeconds,
      expectedLabels: expectedLabels.map(\.rawValue),
      notes: notes
    )
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    var missingFields: [String] = []

    datasetName = try Self.decodeString(
      from: container,
      key: .datasetName,
      missingFields: &missingFields
    )
    datasetLicenseNote =
      try container.decodeIfPresent(String.self, forKey: .datasetLicenseNote)
      ?? container.decodeIfPresent(String.self, forKey: .licenseNote)
    fileId = try Self.decodeString(from: container, key: .fileId, missingFields: &missingFields)

    if container.contains(.localFilePath) {
      localFilePath =
        try container.decodeIfPresent(String.self, forKey: .localFilePath) ?? ""
    } else if container.contains(.filePath) {
      localFilePath = try container.decodeIfPresent(String.self, forKey: .filePath) ?? ""
    } else {
      localFilePath = ""
      missingFields.append(CodingKeys.localFilePath.rawValue)
    }

    subjectId = try container.decodeIfPresent(String.self, forKey: .subjectId)
    recordingType = try Self.decodeString(
      from: container,
      key: .recordingType,
      missingFields: &missingFields
    )
    microphoneType = try Self.decodeString(
      from: container,
      key: .microphoneType,
      missingFields: &missingFields
    )

    if container.contains(.segmentStartSeconds) {
      segmentStartSeconds =
        try container.decodeIfPresent(TimeInterval.self, forKey: .segmentStartSeconds) ?? 0
    } else {
      segmentStartSeconds = 0
      missingFields.append(CodingKeys.segmentStartSeconds.rawValue)
    }

    if container.contains(.segmentDurationSeconds) {
      segmentDurationSeconds =
        try container.decodeIfPresent(TimeInterval.self, forKey: .segmentDurationSeconds) ?? 0
    } else {
      segmentDurationSeconds = 0
      missingFields.append(CodingKeys.segmentDurationSeconds.rawValue)
    }

    if container.contains(.expectedLabels) {
      expectedLabels =
        try container.decodeIfPresent([String].self, forKey: .expectedLabels) ?? []
    } else {
      expectedLabels = []
      missingFields.append(CodingKeys.expectedLabels.rawValue)
    }

    negativeLabels = try container.decodeIfPresent([String].self, forKey: .negativeLabels) ?? []
    confidenceNote = try container.decodeIfPresent(String.self, forKey: .confidenceNote)
    notes = try container.decodeIfPresent(String.self, forKey: .notes)
    decodedMissingFields = missingFields
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(datasetName, forKey: .datasetName)
    try container.encodeIfPresent(datasetLicenseNote, forKey: .datasetLicenseNote)
    try container.encode(fileId, forKey: .fileId)
    try container.encode(localFilePath, forKey: .localFilePath)
    try container.encodeIfPresent(subjectId, forKey: .subjectId)
    try container.encode(recordingType, forKey: .recordingType)
    try container.encode(microphoneType, forKey: .microphoneType)
    try container.encode(segmentStartSeconds, forKey: .segmentStartSeconds)
    try container.encode(segmentDurationSeconds, forKey: .segmentDurationSeconds)
    try container.encode(expectedLabels, forKey: .expectedLabels)
    if !negativeLabels.isEmpty {
      try container.encode(negativeLabels, forKey: .negativeLabels)
    }
    try container.encodeIfPresent(confidenceNote, forKey: .confidenceNote)
    try container.encodeIfPresent(notes, forKey: .notes)
  }

  private static func decodeString(
    from container: KeyedDecodingContainer<CodingKeys>,
    key: CodingKeys,
    missingFields: inout [String]
  ) throws -> String {
    guard container.contains(key) else {
      missingFields.append(key.rawValue)
      return ""
    }
    return try container.decodeIfPresent(String.self, forKey: key) ?? ""
  }

  private enum CodingKeys: String, CodingKey {
    case datasetName
    case datasetLicenseNote
    case licenseNote
    case filePath
    case fileId
    case localFilePath
    case subjectId
    case recordingType
    case microphoneType
    case segmentStartSeconds
    case segmentDurationSeconds
    case expectedLabels
    case negativeLabels
    case confidenceNote
    case notes
  }
}

public enum OfflineEvaluationManifestIssueKind: String, Equatable, Sendable {
  case missingRequiredField
  case invalidSegmentDuration
  case missingFile
  case unsupportedLabel
  case licenseWarning
  case unsupportedRecordingType
  case unsupportedMicrophoneType
}

public struct OfflineEvaluationManifestIssue: Equatable, Sendable {
  public var kind: OfflineEvaluationManifestIssueKind
  public var segmentIndex: Int?
  public var fileId: String?
  public var field: String?
  public var value: String?
  public var message: String

  public init(
    kind: OfflineEvaluationManifestIssueKind,
    segmentIndex: Int? = nil,
    fileId: String? = nil,
    field: String? = nil,
    value: String? = nil,
    message: String
  ) {
    self.kind = kind
    self.segmentIndex = segmentIndex
    self.fileId = fileId
    self.field = field
    self.value = value
    self.message = message
  }
}

public struct OfflineEvaluationManifestValidationResult: Equatable, Sendable {
  public var totalSegments: Int
  public var validSegments: [OfflineEvaluationManifestSegment]
  public var missingRequiredFields: [OfflineEvaluationManifestIssue]
  public var invalidDurations: [OfflineEvaluationManifestIssue]
  public var missingFiles: [OfflineEvaluationManifestIssue]
  public var unsupportedLabels: [OfflineEvaluationManifestIssue]
  public var licenseWarnings: [OfflineEvaluationManifestIssue]
  public var fieldWarnings: [OfflineEvaluationManifestIssue]

  public init(
    totalSegments: Int,
    validSegments: [OfflineEvaluationManifestSegment],
    missingRequiredFields: [OfflineEvaluationManifestIssue] = [],
    invalidDurations: [OfflineEvaluationManifestIssue] = [],
    missingFiles: [OfflineEvaluationManifestIssue] = [],
    unsupportedLabels: [OfflineEvaluationManifestIssue] = [],
    licenseWarnings: [OfflineEvaluationManifestIssue] = [],
    fieldWarnings: [OfflineEvaluationManifestIssue] = []
  ) {
    self.totalSegments = max(0, totalSegments)
    self.validSegments = validSegments
    self.missingRequiredFields = missingRequiredFields
    self.invalidDurations = invalidDurations
    self.missingFiles = missingFiles
    self.unsupportedLabels = unsupportedLabels
    self.licenseWarnings = licenseWarnings
    self.fieldWarnings = fieldWarnings
  }

  public var validSegmentCount: Int {
    validSegments.count
  }

  public var hasBlockingIssues: Bool {
    !missingRequiredFields.isEmpty || !invalidDurations.isEmpty || !unsupportedLabels.isEmpty
  }
}

public struct OfflineEvaluationManifestValidator {
  public var fileManager: FileManager

  public init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  public func validate(
    manifest: OfflineEvaluationManifest,
    manifestDirectory: URL
  ) -> OfflineEvaluationManifestValidationResult {
    var validSegments: [OfflineEvaluationManifestSegment] = []
    var missingRequiredFields: [OfflineEvaluationManifestIssue] = []
    var invalidDurations: [OfflineEvaluationManifestIssue] = []
    var missingFiles: [OfflineEvaluationManifestIssue] = []
    var unsupportedLabels: [OfflineEvaluationManifestIssue] = []
    var licenseWarnings: [OfflineEvaluationManifestIssue] = []
    var fieldWarnings: [OfflineEvaluationManifestIssue] = []

    for (index, segment) in manifest.segments.enumerated() {
      var segmentHasBlockingIssue = false

      let requiredFieldIssues = missingRequiredFieldIssues(segment: segment, index: index)
      if !requiredFieldIssues.isEmpty {
        segmentHasBlockingIssue = true
        missingRequiredFields.append(contentsOf: requiredFieldIssues)
      }

      if !segment.segmentDurationSeconds.isFinite || segment.segmentDurationSeconds <= 0 {
        segmentHasBlockingIssue = true
        invalidDurations.append(
          issue(
            kind: .invalidSegmentDuration,
            segment: segment,
            index: index,
            field: "segmentDurationSeconds",
            value: "\(segment.segmentDurationSeconds)",
            message: "segmentDurationSeconds는 0보다 커야 합니다."
          )
        )
      }

      for labelIssue in unsupportedLabelIssues(segment: segment, index: index) {
        segmentHasBlockingIssue = true
        unsupportedLabels.append(labelIssue)
      }

      if segment.datasetLicenseNote?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
        licenseWarnings.append(
          issue(
            kind: .licenseWarning,
            segment: segment,
            index: index,
            field: "datasetLicenseNote",
            message: "datasetLicenseNote가 비어 있습니다. 공개 데이터셋은 라이선스 확인 메모를 남겨야 합니다."
          )
        )
      }

      let recordingType = segment.recordingType.trimmingCharacters(in: .whitespacesAndNewlines)
      if !recordingType.isEmpty, DatasetRecordingType(rawValue: recordingType) == nil {
        fieldWarnings.append(
          issue(
            kind: .unsupportedRecordingType,
            segment: segment,
            index: index,
            field: "recordingType",
            value: recordingType,
            message: "recordingType은 publicDataset, personalDebugSample, synthetic 중 하나여야 합니다."
          )
        )
      }

      let microphoneType = segment.microphoneType.trimmingCharacters(in: .whitespacesAndNewlines)
      if !microphoneType.isEmpty, DatasetMicrophoneType(rawValue: microphoneType) == nil {
        fieldWarnings.append(
          issue(
            kind: .unsupportedMicrophoneType,
            segment: segment,
            index: index,
            field: "microphoneType",
            value: microphoneType,
            message: "microphoneType은 unknown, ambient, tracheal, iPhone, other 중 하나여야 합니다."
          )
        )
      }

      let trimmedPath = segment.localFilePath.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmedPath.isEmpty {
        let fileURL = resolvedFileURL(trimmedPath, relativeTo: manifestDirectory)
        if !fileManager.fileExists(atPath: fileURL.path) {
          missingFiles.append(
            issue(
              kind: .missingFile,
              segment: segment,
              index: index,
              field: "localFilePath",
              value: trimmedPath,
              message: "로컬 오디오 파일을 찾을 수 없습니다. 평가 record는 실패로 남기고 도구는 계속 실행합니다."
            )
          )
        }
      }

      if !segmentHasBlockingIssue {
        validSegments.append(segment)
      }
    }

    return OfflineEvaluationManifestValidationResult(
      totalSegments: manifest.segments.count,
      validSegments: validSegments,
      missingRequiredFields: missingRequiredFields,
      invalidDurations: invalidDurations,
      missingFiles: missingFiles,
      unsupportedLabels: unsupportedLabels,
      licenseWarnings: licenseWarnings,
      fieldWarnings: fieldWarnings
    )
  }

  private func missingRequiredFieldIssues(
    segment: OfflineEvaluationManifestSegment,
    index: Int
  ) -> [OfflineEvaluationManifestIssue] {
    let requiredFields = Set([
      "fileId",
      "localFilePath",
      "recordingType",
      "microphoneType",
      "segmentStartSeconds",
      "segmentDurationSeconds",
      "expectedLabels",
    ])
    var missingFields = Set(segment.decodedMissingFields.filter { requiredFields.contains($0) })

    if segment.datasetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      missingFields.insert("datasetName")
    }
    if segment.fileId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      missingFields.insert("fileId")
    }
    if segment.localFilePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      missingFields.insert("localFilePath")
    }
    if segment.recordingType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      missingFields.insert("recordingType")
    }
    if segment.microphoneType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      missingFields.insert("microphoneType")
    }
    if segment.expectedLabels.isEmpty {
      missingFields.insert("expectedLabels")
    }

    return missingFields.sorted().map { field in
      issue(
        kind: .missingRequiredField,
        segment: segment,
        index: index,
        field: field,
        message: "\(field) 필드가 필요합니다."
      )
    }
  }

  private func unsupportedLabelIssues(
    segment: OfflineEvaluationManifestSegment,
    index: Int
  ) -> [OfflineEvaluationManifestIssue] {
    let labelFields = [
      ("expectedLabels", segment.expectedLabels),
      ("negativeLabels", segment.negativeLabels),
    ]

    return labelFields.flatMap { field, labels in
      labels.compactMap { rawLabel in
        let label = rawLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard DatasetManifestLabel(rawValue: label) == nil else { return nil }
        return issue(
          kind: .unsupportedLabel,
          segment: segment,
          index: index,
          field: field,
          value: rawLabel,
          message: "\(field)에 허용되지 않은 label이 있습니다: \(rawLabel)"
        )
      }
    }
  }

  private func issue(
    kind: OfflineEvaluationManifestIssueKind,
    segment: OfflineEvaluationManifestSegment,
    index: Int,
    field: String? = nil,
    value: String? = nil,
    message: String
  ) -> OfflineEvaluationManifestIssue {
    OfflineEvaluationManifestIssue(
      kind: kind,
      segmentIndex: index,
      fileId: segment.fileId.isEmpty ? nil : segment.fileId,
      field: field,
      value: value,
      message: message
    )
  }

  private func resolvedFileURL(_ filePath: String, relativeTo manifestDirectory: URL) -> URL {
    let expandedPath = NSString(string: filePath).expandingTildeInPath
    if expandedPath.hasPrefix("/") {
      return URL(fileURLWithPath: expandedPath)
    }
    return manifestDirectory.appendingPathComponent(expandedPath).standardizedFileURL
  }
}

public struct OfflineEvaluationReasonCount: Codable, Equatable, Sendable {
  public var reason: String
  public var count: Int

  public init(reason: String, count: Int) {
    self.reason = reason
    self.count = max(0, count)
  }
}

public struct OfflineEvaluationScoreSummary: Codable, Equatable, Sendable {
  public var sleepSoundScore: Int
  public var mainDisturbanceReason: String

  public init(sleepSoundScore: Int, mainDisturbanceReason: String) {
    self.sleepSoundScore = min(max(sleepSoundScore, 0), 100)
    self.mainDisturbanceReason = mainDisturbanceReason
  }

  public init(report: NightReport) {
    sleepSoundScore = report.sleepSoundScore
    mainDisturbanceReason = report.mainDisturbanceReason
  }
}

public struct OfflineEvaluationRecord: Codable, Equatable, Sendable {
  public var evaluatedAt: Date
  public var detectorBackend: String
  public var tuningProfile: String
  public var datasetName: String
  public var fileId: String
  public var filePath: String
  public var segmentStartSeconds: TimeInterval
  public var segmentDurationSeconds: TimeInterval
  public var expectedLabels: [String]
  public var receivedAudioSeconds: TimeInterval
  public var analyzedAudioSeconds: TimeInterval
  public var audioCoverageRatio: Double
  public var rawCandidateCount: Int
  public var averageConfidence: Double?
  public var confidenceSummary: SummaryStats?
  public var rawCandidateCountByType: [String: Int]
  public var preSmoothingCandidateCount: Int
  public var postSmoothingEventCount: Int
  public var finalEventCountByType: [String: Int]
  public var rejectReasonTop: [OfflineEvaluationReasonCount]
  public var zeroEventReason: String?
  public var rmsSummary: SummaryStats
  public var energySummary: SummaryStats
  public var scoreSummary: OfflineEvaluationScoreSummary?
  public var errorMessage: String?

  public init(
    evaluatedAt: Date,
    detectorBackend: String,
    tuningProfile: String,
    datasetName: String,
    fileId: String,
    filePath: String,
    segmentStartSeconds: TimeInterval,
    segmentDurationSeconds: TimeInterval,
    expectedLabels: [String],
    receivedAudioSeconds: TimeInterval = 0,
    analyzedAudioSeconds: TimeInterval = 0,
    audioCoverageRatio: Double = 0,
    rawCandidateCount: Int = 0,
    averageConfidence: Double? = nil,
    confidenceSummary: SummaryStats? = nil,
    rawCandidateCountByType: [String: Int] = [:],
    preSmoothingCandidateCount: Int = 0,
    postSmoothingEventCount: Int = 0,
    finalEventCountByType: [String: Int] = [:],
    rejectReasonTop: [OfflineEvaluationReasonCount] = [],
    zeroEventReason: String? = nil,
    rmsSummary: SummaryStats = SummaryStats(),
    energySummary: SummaryStats = SummaryStats(),
    scoreSummary: OfflineEvaluationScoreSummary? = nil,
    errorMessage: String? = nil
  ) {
    self.evaluatedAt = evaluatedAt
    self.detectorBackend = detectorBackend
    self.tuningProfile = tuningProfile
    self.datasetName = datasetName
    self.fileId = fileId
    self.filePath = filePath
    self.segmentStartSeconds = max(0, segmentStartSeconds)
    self.segmentDurationSeconds = max(0, segmentDurationSeconds)
    self.expectedLabels = expectedLabels
    self.receivedAudioSeconds = max(0, receivedAudioSeconds)
    self.analyzedAudioSeconds = max(0, analyzedAudioSeconds)
    self.audioCoverageRatio = Self.clampedRatio(audioCoverageRatio)
    self.rawCandidateCount = max(0, rawCandidateCount)
    self.averageConfidence = averageConfidence.map(Self.clampedRatio)
    self.confidenceSummary = confidenceSummary
    self.rawCandidateCountByType = rawCandidateCountByType
    self.preSmoothingCandidateCount = max(0, preSmoothingCandidateCount)
    self.postSmoothingEventCount = max(0, postSmoothingEventCount)
    self.finalEventCountByType = finalEventCountByType
    self.rejectReasonTop = rejectReasonTop
    self.zeroEventReason = zeroEventReason
    self.rmsSummary = rmsSummary
    self.energySummary = energySummary
    self.scoreSummary = scoreSummary
    self.errorMessage = errorMessage
  }

  public var finalEventCount: Int {
    finalEventCountByType.values.reduce(0, +)
  }

  private static func clampedRatio(_ value: Double) -> Double {
    guard value.isFinite else { return 0 }
    return min(max(value, 0), 1)
  }
}

public struct OfflineEvaluationRunSummary: Codable, Equatable, Sendable {
  public var evaluatedSegments: Int
  public var evaluatedRecords: Int
  public var zeroEventRecords: Int
  public var failedRecords: Int
  public var snoreCandidates: Int
  public var finalSnoreEvents: Int
  public var topRejectReason: String?

  public init(records: [OfflineEvaluationRecord], manifestSegmentCount: Int) {
    evaluatedSegments = max(0, manifestSegmentCount)
    evaluatedRecords = records.count
    zeroEventRecords = records.filter { $0.errorMessage == nil && $0.finalEventCount == 0 }.count
    failedRecords = records.filter { $0.errorMessage != nil }.count
    snoreCandidates = records.reduce(0) {
      $0 + ($1.rawCandidateCountByType[SleepEventType.snore.rawValue] ?? 0)
    }
    finalSnoreEvents = records.reduce(0) {
      $0 + ($1.finalEventCountByType[SleepEventType.snore.rawValue] ?? 0)
    }

    let rejectCounts = records.flatMap(\.rejectReasonTop).reduce(into: [String: Int]()) {
      result, reasonCount in
      result[reasonCount.reason, default: 0] += reasonCount.count
    }
    topRejectReason =
      rejectCounts.max { lhs, rhs in
        lhs.value == rhs.value ? lhs.key > rhs.key : lhs.value < rhs.value
      }?.key
  }
}

public struct OfflineEvaluationOutput: Codable, Equatable, Sendable {
  public var summary: OfflineEvaluationRunSummary
  public var records: [OfflineEvaluationRecord]

  public init(summary: OfflineEvaluationRunSummary, records: [OfflineEvaluationRecord]) {
    self.summary = summary
    self.records = records
  }
}

public struct OfflineEvaluationRunResult: Equatable, Sendable {
  public var output: OfflineEvaluationOutput
  public var csvURL: URL
  public var jsonURL: URL
  public var validation: OfflineEvaluationManifestValidationResult?

  public init(
    output: OfflineEvaluationOutput,
    csvURL: URL,
    jsonURL: URL,
    validation: OfflineEvaluationManifestValidationResult? = nil
  ) {
    self.output = output
    self.csvURL = csvURL
    self.jsonURL = jsonURL
    self.validation = validation
  }
}

public enum SnoreBaselineEvaluationError: Error, Equatable, Sendable {
  case missingManifestPath
  case manifestFileNotFound(String)
  case failedToWriteOutput(String)

  public var message: String {
    switch self {
    case .missingManifestPath:
      "snore baseline 평가 manifest 경로가 필요합니다."
    case .manifestFileNotFound(let path):
      "manifest 파일을 찾을 수 없습니다: \(path)"
    case .failedToWriteOutput(let reason):
      "snore baseline output 저장에 실패했습니다. \(reason)"
    }
  }
}

public struct SnoreBaselineRecord: Codable, Equatable, Sendable {
  public var fileId: String
  public var segmentStartSeconds: TimeInterval
  public var segmentDurationSeconds: TimeInterval
  public var expectedLabels: [String]
  public var detectorProfile: String
  public var rawCandidateCount: Int
  public var preSmoothingCandidateCount: Int
  public var postSmoothingEventCount: Int
  public var finalSnoreEventCount: Int
  public var finalEventCountByType: [String: Int]
  public var rejectReasonTop: [OfflineEvaluationReasonCount]
  public var zeroEventReason: String?
  public var rmsSummary: SummaryStats
  public var energySummary: SummaryStats
  public var confidenceSummary: SummaryStats
  public var possibleFalsePositive: Bool
  public var possibleFalseNegative: Bool
  public var errorMessage: String?

  public init(
    fileId: String,
    segmentStartSeconds: TimeInterval,
    segmentDurationSeconds: TimeInterval,
    expectedLabels: [String],
    detectorProfile: String,
    rawCandidateCount: Int,
    preSmoothingCandidateCount: Int,
    postSmoothingEventCount: Int,
    finalSnoreEventCount: Int,
    finalEventCountByType: [String: Int],
    rejectReasonTop: [OfflineEvaluationReasonCount],
    zeroEventReason: String?,
    rmsSummary: SummaryStats,
    energySummary: SummaryStats,
    confidenceSummary: SummaryStats,
    possibleFalsePositive: Bool,
    possibleFalseNegative: Bool,
    errorMessage: String? = nil
  ) {
    self.fileId = fileId
    self.segmentStartSeconds = max(0, segmentStartSeconds)
    self.segmentDurationSeconds = max(0, segmentDurationSeconds)
    self.expectedLabels = expectedLabels
    self.detectorProfile = detectorProfile
    self.rawCandidateCount = max(0, rawCandidateCount)
    self.preSmoothingCandidateCount = max(0, preSmoothingCandidateCount)
    self.postSmoothingEventCount = max(0, postSmoothingEventCount)
    self.finalSnoreEventCount = max(0, finalSnoreEventCount)
    self.finalEventCountByType = finalEventCountByType
    self.rejectReasonTop = rejectReasonTop
    self.zeroEventReason = zeroEventReason
    self.rmsSummary = rmsSummary
    self.energySummary = energySummary
    self.confidenceSummary = confidenceSummary
    self.possibleFalsePositive = possibleFalsePositive
    self.possibleFalseNegative = possibleFalseNegative
    self.errorMessage = errorMessage
  }

  public init(evaluationRecord record: OfflineEvaluationRecord) {
    let finalSnoreEventCount = record.finalEventCountByType[SleepEventType.snore.rawValue] ?? 0
    let possibleFalsePositive = Self.isPossibleFalsePositiveLike(
      expectedLabels: record.expectedLabels,
      finalSnoreEventCount: finalSnoreEventCount,
      errorMessage: record.errorMessage
    )
    let possibleFalseNegative = Self.isPossibleFalseNegativeLike(
      expectedLabels: record.expectedLabels,
      finalSnoreEventCount: finalSnoreEventCount,
      errorMessage: record.errorMessage
    )

    self.init(
      fileId: record.fileId,
      segmentStartSeconds: record.segmentStartSeconds,
      segmentDurationSeconds: record.segmentDurationSeconds,
      expectedLabels: record.expectedLabels,
      detectorProfile: record.tuningProfile,
      rawCandidateCount: record.rawCandidateCount,
      preSmoothingCandidateCount: record.preSmoothingCandidateCount,
      postSmoothingEventCount: record.postSmoothingEventCount,
      finalSnoreEventCount: finalSnoreEventCount,
      finalEventCountByType: record.finalEventCountByType,
      rejectReasonTop: record.rejectReasonTop,
      zeroEventReason: record.zeroEventReason,
      rmsSummary: record.rmsSummary,
      energySummary: record.energySummary,
      confidenceSummary: record.confidenceSummary ?? SummaryStats(),
      possibleFalsePositive: possibleFalsePositive,
      possibleFalseNegative: possibleFalseNegative,
      errorMessage: record.errorMessage
    )
  }

  public static func isPossibleFalsePositiveLike(
    expectedLabels: [String],
    finalSnoreEventCount: Int,
    errorMessage: String? = nil
  ) -> Bool {
    guard errorMessage == nil, finalSnoreEventCount > 0 else { return false }
    let labels = Set(expectedLabels.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
      .filter { !$0.isEmpty }
    guard !labels.isEmpty else { return false }
    let quietLabels: Set<String> = [
      DatasetManifestLabel.silence.rawValue,
      DatasetManifestLabel.unknown.rawValue,
      DatasetManifestLabel.environmentalNoise.rawValue,
    ]
    return labels.isSubset(of: quietLabels)
  }

  public static func isPossibleFalseNegativeLike(
    expectedLabels: [String],
    finalSnoreEventCount: Int,
    errorMessage: String? = nil
  ) -> Bool {
    guard errorMessage == nil, finalSnoreEventCount == 0 else { return false }
    return expectedLabels.contains(SleepEventType.snore.rawValue)
  }
}

public struct SnoreBaselineProfileSummary: Codable, Equatable, Sendable {
  public var detectorProfile: String
  public var evaluatedRecords: Int
  public var failedRecords: Int
  public var zeroEventCount: Int
  public var rawCandidateCount: Int
  public var preSmoothingCandidateCount: Int
  public var postSmoothingEventCount: Int
  public var finalSnoreEventCount: Int
  public var topRejectReasons: [OfflineEvaluationReasonCount]
  public var possibleFalsePositiveCount: Int
  public var possibleFalseNegativeCount: Int

  public init(
    detectorProfile: String,
    evaluatedRecords: Int,
    failedRecords: Int,
    zeroEventCount: Int,
    rawCandidateCount: Int,
    preSmoothingCandidateCount: Int,
    postSmoothingEventCount: Int,
    finalSnoreEventCount: Int,
    topRejectReasons: [OfflineEvaluationReasonCount],
    possibleFalsePositiveCount: Int,
    possibleFalseNegativeCount: Int
  ) {
    self.detectorProfile = detectorProfile
    self.evaluatedRecords = max(0, evaluatedRecords)
    self.failedRecords = max(0, failedRecords)
    self.zeroEventCount = max(0, zeroEventCount)
    self.rawCandidateCount = max(0, rawCandidateCount)
    self.preSmoothingCandidateCount = max(0, preSmoothingCandidateCount)
    self.postSmoothingEventCount = max(0, postSmoothingEventCount)
    self.finalSnoreEventCount = max(0, finalSnoreEventCount)
    self.topRejectReasons = topRejectReasons
    self.possibleFalsePositiveCount = max(0, possibleFalsePositiveCount)
    self.possibleFalseNegativeCount = max(0, possibleFalseNegativeCount)
  }
}

public struct SnoreBaselineManifestValidationSummary: Codable, Equatable, Sendable {
  public var totalSegments: Int
  public var validSegments: Int
  public var missingFiles: Int
  public var unsupportedLabels: Int
  public var licenseWarnings: Int
  public var missingRequiredFields: Int
  public var invalidDurations: Int
  public var fieldWarnings: Int

  public init(validation: OfflineEvaluationManifestValidationResult?) {
    totalSegments = validation?.totalSegments ?? 0
    validSegments = validation?.validSegmentCount ?? 0
    missingFiles = validation?.missingFiles.count ?? 0
    unsupportedLabels = validation?.unsupportedLabels.count ?? 0
    licenseWarnings = validation?.licenseWarnings.count ?? 0
    missingRequiredFields = validation?.missingRequiredFields.count ?? 0
    invalidDurations = validation?.invalidDurations.count ?? 0
    fieldWarnings = validation?.fieldWarnings.count ?? 0
  }
}

public struct SnoreBaselineSummary: Codable, Equatable, Sendable {
  public var evaluatedSegments: Int
  public var evaluatedRecords: Int
  public var failedRecords: Int
  public var possibleFalsePositiveCount: Int
  public var possibleFalseNegativeCount: Int
  public var profileSummaries: [SnoreBaselineProfileSummary]
  public var tuningCandidates: [String]
  public var manifestValidation: SnoreBaselineManifestValidationSummary

  public init(
    evaluatedSegments: Int,
    records: [SnoreBaselineRecord],
    manifestValidation: SnoreBaselineManifestValidationSummary
  ) {
    self.evaluatedSegments = max(0, evaluatedSegments)
    evaluatedRecords = records.count
    failedRecords = records.filter { $0.errorMessage != nil }.count
    possibleFalsePositiveCount = records.filter(\.possibleFalsePositive).count
    possibleFalseNegativeCount = records.filter(\.possibleFalseNegative).count
    profileSummaries = Self.makeProfileSummaries(records: records)
    tuningCandidates = Self.makeTuningCandidates(
      records: records,
      manifestValidation: manifestValidation
    )
    self.manifestValidation = manifestValidation
  }

  public static func makeProfileSummaries(
    records: [SnoreBaselineRecord]
  ) -> [SnoreBaselineProfileSummary] {
    let grouped = Dictionary(grouping: records, by: \.detectorProfile)
    return grouped.keys.sorted().map { profile in
      let profileRecords = grouped[profile] ?? []
      let rejectCounts = profileRecords.flatMap(\.rejectReasonTop).reduce(into: [String: Int]()) {
        result, reasonCount in
        result[reasonCount.reason, default: 0] += reasonCount.count
      }
      let topRejectReasons = rejectCounts
        .sorted { lhs, rhs in lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value }
        .prefix(5)
        .map { OfflineEvaluationReasonCount(reason: $0.key, count: $0.value) }

      return SnoreBaselineProfileSummary(
        detectorProfile: profile,
        evaluatedRecords: profileRecords.count,
        failedRecords: profileRecords.filter { $0.errorMessage != nil }.count,
        zeroEventCount: profileRecords.filter {
          $0.errorMessage == nil && $0.finalEventCountByType.values.reduce(0, +) == 0
        }.count,
        rawCandidateCount: profileRecords.reduce(0) { $0 + $1.rawCandidateCount },
        preSmoothingCandidateCount: profileRecords.reduce(0) {
          $0 + $1.preSmoothingCandidateCount
        },
        postSmoothingEventCount: profileRecords.reduce(0) {
          $0 + $1.postSmoothingEventCount
        },
        finalSnoreEventCount: profileRecords.reduce(0) { $0 + $1.finalSnoreEventCount },
        topRejectReasons: topRejectReasons,
        possibleFalsePositiveCount: profileRecords.filter(\.possibleFalsePositive).count,
        possibleFalseNegativeCount: profileRecords.filter(\.possibleFalseNegative).count
      )
    }
  }

  public static func makeTuningCandidates(
    records: [SnoreBaselineRecord],
    manifestValidation: SnoreBaselineManifestValidationSummary
  ) -> [String] {
    var candidates: [String] = []
    if records.isEmpty {
      candidates.append("평가 record가 없습니다. synthetic 또는 로컬 manifest segment를 준비한 뒤 baseline을 다시 생성하세요.")
    }
    if manifestValidation.missingFiles > 0 {
      candidates.append("missing file warning이 있습니다. localFilePath를 로컬 오디오 위치에 맞게 확인하세요.")
    }
    if records.contains(where: \.possibleFalseNegative) {
      candidates.append("snore expected segment에서 final snore event가 없는 profile의 snore RMS/energy/confidence threshold를 소폭 완화할지 검토하세요.")
    }
    if records.contains(where: \.possibleFalsePositive) {
      candidates.append("silence/unknown/environmentalNoise 중심 segment에서 snore event가 생긴 profile은 confidence 또는 snore threshold를 보수적으로 조정할지 검토하세요.")
    }
    candidates.append("threshold 후보는 자동 적용하지 말고 실제 iPhone 짧은 테스트로 별도 확인하세요.")
    return candidates
  }
}

public struct SnoreBaselineOutput: Codable, Equatable, Sendable {
  public var generatedAt: Date
  public var summary: SnoreBaselineSummary
  public var records: [SnoreBaselineRecord]

  public init(
    generatedAt: Date,
    summary: SnoreBaselineSummary,
    records: [SnoreBaselineRecord]
  ) {
    self.generatedAt = generatedAt
    self.summary = summary
    self.records = records
  }
}

public struct SnoreBaselineRunResult: Equatable, Sendable {
  public var output: SnoreBaselineOutput
  public var csvURL: URL
  public var jsonURL: URL
  public var markdownURL: URL
}

public struct SnoreBaselineEvaluationRunner {
  public var fileManager: FileManager
  public var evaluationRunner: OfflineEvaluationRunner

  public init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
    evaluationRunner = OfflineEvaluationRunner(fileManager: fileManager)
  }

  public func evaluate(
    manifestURL: URL,
    outputDirectory: URL,
    profiles: [DetectorTuningProfile] = [.conservative, .balanced, .sensitive],
    evaluatedAt: Date = Date()
  ) throws -> SnoreBaselineRunResult {
    guard fileManager.fileExists(atPath: manifestURL.path) else {
      throw SnoreBaselineEvaluationError.manifestFileNotFound(manifestURL.path)
    }

    let manifest = try evaluationRunner.loadManifest(from: manifestURL)
    let validation = evaluationRunner.validateManifest(
      manifest,
      manifestDirectory: manifestURL.deletingLastPathComponent()
    )
    let validManifest = OfflineEvaluationManifest(
      datasetName: manifest.datasetName,
      datasetLicenseNote: manifest.datasetLicenseNote,
      segments: validation.validSegments
    )
    let evaluationRecords = evaluationRunner.evaluateRecords(
      manifest: validManifest,
      manifestDirectory: manifestURL.deletingLastPathComponent(),
      profiles: profiles,
      evaluatedAt: evaluatedAt
    )
    let output = makeOutput(
      evaluationRecords: evaluationRecords,
      manifestSegmentCount: validManifest.segments.count,
      validation: validation,
      generatedAt: evaluatedAt
    )
    return try write(output: output, to: outputDirectory, generatedAt: evaluatedAt)
  }

  public func makeOutput(
    evaluationRecords: [OfflineEvaluationRecord],
    manifestSegmentCount: Int,
    validation: OfflineEvaluationManifestValidationResult? = nil,
    generatedAt: Date = Date()
  ) -> SnoreBaselineOutput {
    let records = evaluationRecords.map(SnoreBaselineRecord.init(evaluationRecord:))
    let validationSummary = SnoreBaselineManifestValidationSummary(validation: validation)
    return SnoreBaselineOutput(
      generatedAt: generatedAt,
      summary: SnoreBaselineSummary(
        evaluatedSegments: manifestSegmentCount,
        records: records,
        manifestValidation: validationSummary
      ),
      records: records
    )
  }

  public func write(
    output: SnoreBaselineOutput,
    to outputDirectory: URL,
    generatedAt: Date
  ) throws -> SnoreBaselineRunResult {
    do {
      try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
      let timestamp = Self.fileTimestampFormatter.string(from: generatedAt)
      let jsonURL = outputDirectory.appendingPathComponent("snore_baseline_\(timestamp).json")
      let csvURL = outputDirectory.appendingPathComponent("snore_baseline_\(timestamp).csv")
      let markdownURL = outputDirectory.appendingPathComponent("snore_baseline_report.md")
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      encoder.dateEncodingStrategy = .iso8601
      try encoder.encode(output).write(to: jsonURL, options: .atomic)
      try Self.makeCSV(records: output.records).write(
        to: csvURL,
        atomically: true,
        encoding: .utf8
      )
      try Self.makeMarkdownReport(output).write(
        to: markdownURL,
        atomically: true,
        encoding: .utf8
      )
      return SnoreBaselineRunResult(
        output: output,
        csvURL: csvURL,
        jsonURL: jsonURL,
        markdownURL: markdownURL
      )
    } catch {
      throw SnoreBaselineEvaluationError.failedToWriteOutput(error.localizedDescription)
    }
  }

  public static func makeCSV(records: [SnoreBaselineRecord]) -> String {
    let header = [
      "fileId",
      "segmentStartSeconds",
      "segmentDurationSeconds",
      "expectedLabels",
      "detectorProfile",
      "rawCandidateCount",
      "preSmoothingCandidateCount",
      "postSmoothingEventCount",
      "finalSnoreEventCount",
      "finalEventCountByType",
      "rejectReasonTop",
      "zeroEventReason",
      "rmsMean",
      "rmsP90",
      "rmsP95",
      "energyMean",
      "energyP90",
      "energyP95",
      "confidenceMean",
      "confidenceP90",
      "confidenceP95",
      "possibleFalsePositive",
      "possibleFalseNegative",
      "errorMessage",
    ]

    let lines = records.map { record in
      [
        record.fileId,
        format(record.segmentStartSeconds),
        format(record.segmentDurationSeconds),
        record.expectedLabels.joined(separator: ";"),
        record.detectorProfile,
        "\(record.rawCandidateCount)",
        "\(record.preSmoothingCandidateCount)",
        "\(record.postSmoothingEventCount)",
        "\(record.finalSnoreEventCount)",
        dictionaryText(record.finalEventCountByType),
        record.rejectReasonTop.map { "\($0.reason):\($0.count)" }.joined(separator: ";"),
        record.zeroEventReason ?? "",
        format(record.rmsSummary.mean),
        format(record.rmsSummary.p90),
        format(record.rmsSummary.p95),
        format(record.energySummary.mean),
        format(record.energySummary.p90),
        format(record.energySummary.p95),
        format(record.confidenceSummary.mean),
        format(record.confidenceSummary.p90),
        format(record.confidenceSummary.p95),
        "\(record.possibleFalsePositive)",
        "\(record.possibleFalseNegative)",
        record.errorMessage ?? "",
      ].map(csvEscape).joined(separator: ",")
    }

    return ([header.joined(separator: ",")] + lines).joined(separator: "\n") + "\n"
  }

  public static func makeMarkdownReport(_ output: SnoreBaselineOutput) -> String {
    var lines: [String] = [
      "# Snore Baseline Report",
      "",
      "이 리포트는 코골기 detector 개발용 baseline입니다. 의료 성능 검증이나 진단 목적의 결과가 아닙니다.",
      "",
      "## Summary",
      "",
      "- evaluated segments: \(output.summary.evaluatedSegments)",
      "- evaluated records: \(output.summary.evaluatedRecords)",
      "- failed records: \(output.summary.failedRecords)",
      "- possible false-positive-like cases: \(output.summary.possibleFalsePositiveCount)",
      "- possible false-negative-like cases: \(output.summary.possibleFalseNegativeCount)",
      "- manifest missing files: \(output.summary.manifestValidation.missingFiles)",
      "- manifest unsupported labels: \(output.summary.manifestValidation.unsupportedLabels)",
      "",
      "## Profile Summary",
      "",
      "| Profile | Records | Failed | Zero Event | Raw Candidates | Pre Smoothing | Post Smoothing | Final Snore | FP-like | FN-like |",
      "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]

    if output.summary.profileSummaries.isEmpty {
      lines.append("| none | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |")
    } else {
      for summary in output.summary.profileSummaries {
        lines.append(
          "| \(summary.detectorProfile) | \(summary.evaluatedRecords) | \(summary.failedRecords) | \(summary.zeroEventCount) | \(summary.rawCandidateCount) | \(summary.preSmoothingCandidateCount) | \(summary.postSmoothingEventCount) | \(summary.finalSnoreEventCount) | \(summary.possibleFalsePositiveCount) | \(summary.possibleFalseNegativeCount) |"
        )
      }
    }

    lines.append(contentsOf: [
      "",
      "## Top Reject Reasons",
      "",
    ])
    if output.summary.profileSummaries.allSatisfy({ $0.topRejectReasons.isEmpty }) {
      lines.append("- none")
    } else {
      for summary in output.summary.profileSummaries {
        let reasons = summary.topRejectReasons
          .map { "\($0.reason): \($0.count)" }
          .joined(separator: ", ")
        lines.append("- \(summary.detectorProfile): \(reasons.isEmpty ? "none" : reasons)")
      }
    }

    lines.append(contentsOf: [
      "",
      "## Possible False-Positive-Like Cases",
      "",
    ])
    appendCaseLines(
      to: &lines,
      records: output.records.filter(\.possibleFalsePositive)
    )

    lines.append(contentsOf: [
      "",
      "## Possible False-Negative-Like Cases",
      "",
    ])
    appendCaseLines(
      to: &lines,
      records: output.records.filter(\.possibleFalseNegative)
    )

    lines.append(contentsOf: [
      "",
      "## Next Tuning Candidates",
      "",
    ])
    lines.append(contentsOf: output.summary.tuningCandidates.map { "- \($0)" })
    lines.append(contentsOf: [
      "",
      "## Limits",
      "",
      "- 공개/개인 오디오 파일은 repo에 포함하지 않습니다.",
      "- 공개 데이터셋은 자동 다운로드하지 않습니다.",
      "- Offline baseline은 실제 iPhone 마이크, 기기 배치, 백그라운드 안정성 검증을 대체하지 않습니다.",
      "",
    ])
    return lines.joined(separator: "\n")
  }

  private static func appendCaseLines(
    to lines: inout [String],
    records: [SnoreBaselineRecord]
  ) {
    guard !records.isEmpty else {
      lines.append("- none")
      return
    }

    lines.append(contentsOf: records.prefix(50).map { record in
      "- \(record.detectorProfile) \(record.fileId) @ \(format(record.segmentStartSeconds))s labels=\(record.expectedLabels.joined(separator: "/")) finalSnore=\(record.finalSnoreEventCount)"
    })
  }

  private static func dictionaryText(_ dictionary: [String: Int]) -> String {
    dictionary.sorted { $0.key < $1.key }.map { "\($0.key):\($0.value)" }.joined(separator: ";")
  }

  private static func csvEscape(_ value: String) -> String {
    if value.contains(",") || value.contains("\"") || value.contains("\n") {
      return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
    return value
  }

  private static func format(_ value: Double) -> String {
    String(format: "%.6f", value)
  }

  private static let fileTimestampFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyyMMdd_HHmmss"
    return formatter
  }()
}

public enum OfflineProfileComparisonError: Error, Equatable, Sendable {
  case missingInput
  case emptyInput
  case failedToWriteOutput(String)

  public var message: String {
    switch self {
    case .missingInput:
      "비교할 Offline Evaluation JSON 경로가 필요합니다."
    case .emptyInput:
      "비교할 Offline Evaluation record가 없습니다."
    case .failedToWriteOutput(let reason):
      "profile 비교 output 저장에 실패했습니다. \(reason)"
    }
  }
}

public enum OfflineProfileLabelFindingKind: String, Codable, Equatable, Sendable {
  case possibleFalsePositiveLike
  case possibleFalseNegativeLike

  public var displayName: String {
    switch self {
    case .possibleFalsePositiveLike:
      "possible false-positive-like"
    case .possibleFalseNegativeLike:
      "possible false-negative-like"
    }
  }
}

public struct OfflineProfileLabelFinding: Codable, Equatable, Sendable {
  public var kind: OfflineProfileLabelFindingKind
  public var tuningProfile: String
  public var datasetName: String
  public var fileId: String
  public var segmentStartSeconds: TimeInterval
  public var segmentDurationSeconds: TimeInterval
  public var expectedLabels: [String]
  public var finalEventCountByType: [String: Int]
  public var explanation: String

  public init(
    kind: OfflineProfileLabelFindingKind,
    tuningProfile: String,
    datasetName: String,
    fileId: String,
    segmentStartSeconds: TimeInterval,
    segmentDurationSeconds: TimeInterval,
    expectedLabels: [String],
    finalEventCountByType: [String: Int],
    explanation: String
  ) {
    self.kind = kind
    self.tuningProfile = tuningProfile
    self.datasetName = datasetName
    self.fileId = fileId
    self.segmentStartSeconds = max(0, segmentStartSeconds)
    self.segmentDurationSeconds = max(0, segmentDurationSeconds)
    self.expectedLabels = expectedLabels
    self.finalEventCountByType = finalEventCountByType
    self.explanation = explanation
  }
}

public struct OfflineProfileSummary: Codable, Equatable, Sendable {
  public var tuningProfile: String
  public var totalEvaluatedSegments: Int
  public var evaluatedRecords: Int
  public var failedRecords: Int
  public var rawCandidateCount: Int
  public var preSmoothingCandidateCount: Int
  public var postSmoothingEventCount: Int
  public var finalEventCountByType: [String: Int]
  public var zeroEventCount: Int
  public var zeroEventRate: Double
  public var zeroEventNoRawCandidateCount: Int
  public var zeroEventRawCandidateCount: Int
  public var zeroEventDroppedBySmoothingCount: Int
  public var zeroEventAfterPostSmoothingCount: Int
  public var topRejectReasons: [OfflineEvaluationReasonCount]
  public var averageConfidence: Double?
  public var possibleFalsePositiveLikeCount: Int
  public var possibleFalseNegativeLikeCount: Int

  public init(
    tuningProfile: String,
    totalEvaluatedSegments: Int,
    evaluatedRecords: Int,
    failedRecords: Int,
    rawCandidateCount: Int,
    preSmoothingCandidateCount: Int,
    postSmoothingEventCount: Int,
    finalEventCountByType: [String: Int],
    zeroEventCount: Int,
    zeroEventRate: Double,
    topRejectReasons: [OfflineEvaluationReasonCount],
    averageConfidence: Double?,
    possibleFalsePositiveLikeCount: Int,
    possibleFalseNegativeLikeCount: Int,
    zeroEventNoRawCandidateCount: Int = 0,
    zeroEventRawCandidateCount: Int = 0,
    zeroEventDroppedBySmoothingCount: Int = 0,
    zeroEventAfterPostSmoothingCount: Int = 0
  ) {
    self.tuningProfile = tuningProfile
    self.totalEvaluatedSegments = max(0, totalEvaluatedSegments)
    self.evaluatedRecords = max(0, evaluatedRecords)
    self.failedRecords = max(0, failedRecords)
    self.rawCandidateCount = max(0, rawCandidateCount)
    self.preSmoothingCandidateCount = max(0, preSmoothingCandidateCount)
    self.postSmoothingEventCount = max(0, postSmoothingEventCount)
    self.finalEventCountByType = finalEventCountByType
    self.zeroEventCount = max(0, zeroEventCount)
    self.zeroEventRate = Self.clampedRatio(zeroEventRate)
    self.zeroEventNoRawCandidateCount = max(0, zeroEventNoRawCandidateCount)
    self.zeroEventRawCandidateCount = max(0, zeroEventRawCandidateCount)
    self.zeroEventDroppedBySmoothingCount = max(0, zeroEventDroppedBySmoothingCount)
    self.zeroEventAfterPostSmoothingCount = max(0, zeroEventAfterPostSmoothingCount)
    self.topRejectReasons = topRejectReasons
    self.averageConfidence = averageConfidence.map(Self.clampedRatio)
    self.possibleFalsePositiveLikeCount = max(0, possibleFalsePositiveLikeCount)
    self.possibleFalseNegativeLikeCount = max(0, possibleFalseNegativeLikeCount)
  }

  public var finalEventCount: Int {
    finalEventCountByType.values.reduce(0, +)
  }

  private static func clampedRatio(_ value: Double) -> Double {
    guard value.isFinite else { return 0 }
    return min(max(value, 0), 1)
  }
}

public struct OfflineSuggestedThresholdChange: Codable, Equatable, Sendable {
  public var tuningProfile: String
  public var thresholdName: String
  public var currentValue: Double?
  public var suggestedDirection: String
  public var reason: String
  public var falsePositiveRisk: String

  public init(
    tuningProfile: String,
    thresholdName: String,
    currentValue: Double?,
    suggestedDirection: String,
    reason: String,
    falsePositiveRisk: String
  ) {
    self.tuningProfile = tuningProfile
    self.thresholdName = thresholdName
    self.currentValue = currentValue?.isFinite == true ? currentValue : nil
    self.suggestedDirection = suggestedDirection
    self.reason = reason
    self.falsePositiveRisk = falsePositiveRisk
  }
}

public struct OfflineSuggestedThresholdChangeSet: Codable, Equatable, Sendable {
  public var generatedAt: Date
  public var autoApplied: Bool
  public var changes: [OfflineSuggestedThresholdChange]
  public var notes: [String]

  public init(
    generatedAt: Date,
    autoApplied: Bool = false,
    changes: [OfflineSuggestedThresholdChange],
    notes: [String]
  ) {
    self.generatedAt = generatedAt
    self.autoApplied = autoApplied
    self.changes = changes
    self.notes = notes
  }
}

public struct OfflineProfileRecommendation: Codable, Equatable, Sendable {
  public var summary: String
  public var observations: [String]
  public var suggestedReviewItems: [String]
  public var warning: String

  public init(
    summary: String,
    observations: [String],
    suggestedReviewItems: [String],
    warning: String
  ) {
    self.summary = summary
    self.observations = observations
    self.suggestedReviewItems = suggestedReviewItems
    self.warning = warning
  }
}

public struct OfflineProfileComparisonOutput: Codable, Equatable, Sendable {
  public var generatedAt: Date
  public var sourceEvaluationFiles: [String]
  public var profileSummaries: [OfflineProfileSummary]
  public var labelFindings: [OfflineProfileLabelFinding]
  public var recommendation: OfflineProfileRecommendation
  public var suggestedChanges: OfflineSuggestedThresholdChangeSet

  public init(
    generatedAt: Date,
    sourceEvaluationFiles: [String],
    profileSummaries: [OfflineProfileSummary],
    labelFindings: [OfflineProfileLabelFinding],
    recommendation: OfflineProfileRecommendation,
    suggestedChanges: OfflineSuggestedThresholdChangeSet
  ) {
    self.generatedAt = generatedAt
    self.sourceEvaluationFiles = sourceEvaluationFiles
    self.profileSummaries = profileSummaries
    self.labelFindings = labelFindings
    self.recommendation = recommendation
    self.suggestedChanges = suggestedChanges
  }
}

public struct OfflineProfileComparisonRunResult: Equatable, Sendable {
  public var comparison: OfflineProfileComparisonOutput
  public var reportURL: URL
  public var suggestedChangesURL: URL
}

public struct OfflineProfileComparisonRunner {
  public var fileManager: FileManager

  public init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  public func compare(
    evaluationJSONURLs: [URL],
    outputDirectory: URL,
    generatedAt: Date = Date()
  ) throws -> OfflineProfileComparisonRunResult {
    guard !evaluationJSONURLs.isEmpty else {
      throw OfflineProfileComparisonError.missingInput
    }

    let outputs = try loadOutputs(from: evaluationJSONURLs)
    let comparison = makeComparison(
      outputs: outputs,
      sourceFiles: evaluationJSONURLs.map(\.path),
      generatedAt: generatedAt
    )
    return try write(comparison: comparison, to: outputDirectory)
  }

  public func loadOutputs(from urls: [URL]) throws -> [OfflineEvaluationOutput] {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try urls.map { url in
      let data = try Data(contentsOf: url)
      return try decoder.decode(OfflineEvaluationOutput.self, from: data)
    }
  }

  public func makeComparison(
    outputs: [OfflineEvaluationOutput],
    sourceFiles: [String] = [],
    generatedAt: Date = Date()
  ) -> OfflineProfileComparisonOutput {
    let records = outputs.flatMap(\.records)
    let validRecords = records.filter { $0.errorMessage == nil }
    let findings = Self.makeLabelFindings(records: validRecords)
    let summaries = Self.makeProfileSummaries(records: records, findings: findings)
    let suggestedChanges = Self.makeSuggestedChanges(
      summaries: summaries,
      generatedAt: generatedAt
    )
    let recommendation = Self.makeRecommendation(
      summaries: summaries,
      suggestedChanges: suggestedChanges
    )

    return OfflineProfileComparisonOutput(
      generatedAt: generatedAt,
      sourceEvaluationFiles: sourceFiles,
      profileSummaries: summaries,
      labelFindings: findings,
      recommendation: recommendation,
      suggestedChanges: suggestedChanges
    )
  }

  public func write(
    comparison: OfflineProfileComparisonOutput,
    to outputDirectory: URL
  ) throws -> OfflineProfileComparisonRunResult {
    do {
      guard !comparison.profileSummaries.isEmpty else {
        throw OfflineProfileComparisonError.emptyInput
      }

      try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
      let reportURL = outputDirectory.appendingPathComponent("tuning_report.md")
      let suggestedChangesURL = outputDirectory.appendingPathComponent("suggested_changes.json")
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      encoder.dateEncodingStrategy = .iso8601

      try Self.makeMarkdownReport(comparison).write(
        to: reportURL,
        atomically: true,
        encoding: .utf8
      )
      try encoder.encode(comparison.suggestedChanges).write(
        to: suggestedChangesURL,
        options: .atomic
      )

      return OfflineProfileComparisonRunResult(
        comparison: comparison,
        reportURL: reportURL,
        suggestedChangesURL: suggestedChangesURL
      )
    } catch let error as OfflineProfileComparisonError {
      throw error
    } catch {
      throw OfflineProfileComparisonError.failedToWriteOutput(error.localizedDescription)
    }
  }

  public static func makeLabelFindings(
    records: [OfflineEvaluationRecord]
  ) -> [OfflineProfileLabelFinding] {
    records.flatMap { record in
      let expected = Set(record.expectedLabels.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
      let quietLabels: Set<String> = ["unknown", "silence", "quiet"]
      let expectedEventLabels = expected.subtracting(quietLabels).filter { !$0.isEmpty }
      let finalEventCount = record.finalEventCountByType.values.reduce(0, +)
      var findings: [OfflineProfileLabelFinding] = []

      if expectedEventLabels.isEmpty, finalEventCount > 0 {
        findings.append(
          makeFinding(
            kind: .possibleFalsePositiveLike,
            record: record,
            explanation: "expectedLabels가 quiet/unknown 계열인데 이벤트가 생성되었습니다. threshold를 낮출수록 이런 후보가 늘어날 수 있습니다."
          )
        )
      }

      for expectedLabel in expectedEventLabels
      where (record.finalEventCountByType[expectedLabel] ?? 0) == 0 {
        findings.append(
          makeFinding(
            kind: .possibleFalseNegativeLike,
            record: record,
            explanation: "expectedLabels에 \(expectedLabel)이 있지만 해당 최종 이벤트가 없습니다. zero-event와 reject reason을 함께 확인하세요."
          )
        )
      }

      return findings
    }
  }

  public static func makeProfileSummaries(
    records: [OfflineEvaluationRecord],
    findings: [OfflineProfileLabelFinding]
  ) -> [OfflineProfileSummary] {
    let grouped = Dictionary(grouping: records, by: \.tuningProfile)
    return grouped.keys.sorted().map { profile in
      let profileRecords = grouped[profile] ?? []
      let segmentKeys = Set(profileRecords.map(Self.segmentKey))
      let finalCounts = profileRecords.reduce(into: [String: Int]()) { result, record in
        for (type, count) in record.finalEventCountByType {
          result[type, default: 0] += count
        }
      }
      let rejectCounts = profileRecords.flatMap(\.rejectReasonTop).reduce(into: [String: Int]()) {
        result, reasonCount in
        result[reasonCount.reason, default: 0] += reasonCount.count
      }
      let topRejectReasons = rejectCounts
        .sorted { lhs, rhs in lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value }
        .prefix(5)
        .map { OfflineEvaluationReasonCount(reason: $0.key, count: $0.value) }
      let profileFindings = findings.filter { $0.tuningProfile == profile }
      let validProfileRecords = profileRecords.filter { $0.errorMessage == nil }
      let zeroEventRecords = validProfileRecords.filter { $0.finalEventCount == 0 }

      return OfflineProfileSummary(
        tuningProfile: profile,
        totalEvaluatedSegments: segmentKeys.count,
        evaluatedRecords: profileRecords.count,
        failedRecords: profileRecords.filter { $0.errorMessage != nil }.count,
        rawCandidateCount: profileRecords.reduce(0) { $0 + $1.rawCandidateCount },
        preSmoothingCandidateCount: profileRecords.reduce(0) { $0 + $1.preSmoothingCandidateCount },
        postSmoothingEventCount: profileRecords.reduce(0) { $0 + $1.postSmoothingEventCount },
        finalEventCountByType: finalCounts,
        zeroEventCount: zeroEventRecords.count,
        zeroEventRate: profileRecords.isEmpty ? 0 : Double(zeroEventRecords.count) / Double(profileRecords.count),
        topRejectReasons: topRejectReasons,
        averageConfidence: weightedAverageConfidence(records: profileRecords),
        possibleFalsePositiveLikeCount: profileFindings.filter { $0.kind == .possibleFalsePositiveLike }.count,
        possibleFalseNegativeLikeCount: profileFindings.filter { $0.kind == .possibleFalseNegativeLike }.count,
        zeroEventNoRawCandidateCount: zeroEventRecords.filter { $0.rawCandidateCount == 0 }.count,
        zeroEventRawCandidateCount: zeroEventRecords.filter { $0.rawCandidateCount > 0 }.count,
        zeroEventDroppedBySmoothingCount: zeroEventRecords.filter {
          $0.rawCandidateCount > 0 && $0.postSmoothingEventCount == 0
        }.count,
        zeroEventAfterPostSmoothingCount: zeroEventRecords.filter {
          $0.postSmoothingEventCount > 0
        }.count
      )
    }
  }

  public static func makeSuggestedChanges(
    summaries: [OfflineProfileSummary],
    generatedAt: Date
  ) -> OfflineSuggestedThresholdChangeSet {
    let byProfile = Dictionary(uniqueKeysWithValues: summaries.map { ($0.tuningProfile, $0) })
    var changes: [OfflineSuggestedThresholdChange] = []

    if let balanced = byProfile[DetectorTuningProfile.balanced.rawValue],
       balanced.zeroEventRate >= 0.40,
       balanced.possibleFalseNegativeLikeCount > balanced.possibleFalsePositiveLikeCount {
      let configuration = DetectorTuningProfile.balanced.configuration
      changes.append(
        OfflineSuggestedThresholdChange(
          tuningProfile: balanced.tuningProfile,
          thresholdName: "minimumConfidence",
          currentValue: configuration.minimumConfidence,
          suggestedDirection: "review-lower-small-step",
          reason: "balanced profile에서 zero-event와 possible false-negative-like finding이 많습니다.",
          falsePositiveRisk: "confidence 기준을 낮추면 조용한 구간이나 환경 소음이 이벤트로 남을 수 있습니다."
        )
      )
      changes.append(
        OfflineSuggestedThresholdChange(
          tuningProfile: balanced.tuningProfile,
          thresholdName: "snoreRmsThreshold",
          currentValue: configuration.snoreRmsThreshold,
          suggestedDirection: "review-lower-small-step",
          reason: "expected snore segment에서 최종 코골기 이벤트가 부족한지 수동 확인이 필요합니다.",
          falsePositiveRisk: "RMS 기준을 낮추면 낮은 에너지 배경 소음이 코골기 후보로 늘어날 수 있습니다."
        )
      )
    }

    if let sensitive = byProfile[DetectorTuningProfile.sensitive.rawValue],
       sensitive.possibleFalsePositiveLikeCount > max(0, sensitive.possibleFalseNegativeLikeCount) {
      let configuration = DetectorTuningProfile.sensitive.configuration
      changes.append(
        OfflineSuggestedThresholdChange(
          tuningProfile: sensitive.tuningProfile,
          thresholdName: "minimumConfidence",
          currentValue: configuration.minimumConfidence,
          suggestedDirection: "review-raise-or-keep-debug-only",
          reason: "sensitive profile에서 quiet/unknown segment의 possible false-positive-like finding이 많습니다.",
          falsePositiveRisk: "sensitive profile은 DEBUG 비교용으로 유지하고 Release 기본값으로 바로 올리지 않는 편이 안전합니다."
        )
      )
    }

    if let conservative = byProfile[DetectorTuningProfile.conservative.rawValue],
       conservative.zeroEventRate >= 0.60,
       conservative.rawCandidateCount == 0 {
      let configuration = DetectorTuningProfile.conservative.configuration
      changes.append(
        OfflineSuggestedThresholdChange(
          tuningProfile: conservative.tuningProfile,
          thresholdName: "snoreRmsThreshold",
          currentValue: configuration.snoreRmsThreshold,
          suggestedDirection: "review-too-conservative",
          reason: "conservative profile에서 raw 후보가 거의 없고 zero-event가 많습니다.",
          falsePositiveRisk: "conservative 값을 완화하면 false-positive-like 이벤트가 늘 수 있으므로 balanced/sensitive와 비교 후 수동 반영하세요."
        )
      )
    }

    return OfflineSuggestedThresholdChangeSet(
      generatedAt: generatedAt,
      autoApplied: false,
      changes: changes,
      notes: [
        "이 파일은 수동 검토용 제안입니다. 앱 코드의 threshold는 자동 변경하지 않습니다.",
        "false positive와 false negative 균형을 보고 실제 iPhone 짧은 테스트로 재확인하세요.",
        "이 비교는 detector 개발용이며 의료 성능 검증이 아닙니다."
      ]
    )
  }

  public static func makeRecommendation(
    summaries: [OfflineProfileSummary],
    suggestedChanges: OfflineSuggestedThresholdChangeSet
  ) -> OfflineProfileRecommendation {
    guard !summaries.isEmpty else {
      return OfflineProfileRecommendation(
        summary: "비교할 record가 없습니다.",
        observations: [],
        suggestedReviewItems: [],
        warning: "threshold는 변경하지 않았습니다."
      )
    }

    let byProfile = Dictionary(uniqueKeysWithValues: summaries.map { ($0.tuningProfile, $0) })
    var observations: [String] = summaries.map { summary in
      "\(summary.tuningProfile): records=\(summary.evaluatedRecords), zeroEvent=\(summary.zeroEventCount), raw=\(summary.rawCandidateCount), final=\(summary.finalEventCount)"
    }

    if let balanced = byProfile[DetectorTuningProfile.balanced.rawValue],
       let sensitive = byProfile[DetectorTuningProfile.sensitive.rawValue] {
      if balanced.zeroEventRate > sensitive.zeroEventRate,
         sensitive.possibleFalsePositiveLikeCount <= balanced.possibleFalsePositiveLikeCount {
        observations.append("balanced보다 sensitive에서 zero-event가 줄고 possible false-positive-like finding이 크게 늘지 않았습니다.")
      }
      if sensitive.possibleFalsePositiveLikeCount > balanced.possibleFalsePositiveLikeCount {
        observations.append("sensitive에서 possible false-positive-like finding이 늘었습니다. threshold 완화는 신중히 검토해야 합니다.")
      }
    }

    let summaryText: String
    if suggestedChanges.changes.isEmpty {
      summaryText = "현재 output만으로는 threshold 변경 제안이 강하지 않습니다. 더 많은 labeled segment로 비교를 반복하세요."
    } else {
      summaryText = "수동 검토용 threshold 변경 후보가 생성되었습니다. 코드에는 자동 적용하지 않았습니다."
    }

    return OfflineProfileRecommendation(
      summary: summaryText,
      observations: observations,
      suggestedReviewItems: suggestedChanges.changes.map {
        "\($0.tuningProfile).\($0.thresholdName): \($0.suggestedDirection)"
      },
      warning: "threshold를 낮추면 이벤트 누락은 줄 수 있지만 환경 소음/움직임 같은 false-positive-like 이벤트가 늘 수 있습니다. 실제 iPhone 검증 전 Release 기본값으로 반영하지 마세요."
    )
  }

  public static func makeMarkdownReport(_ comparison: OfflineProfileComparisonOutput) -> String {
    var lines: [String] = [
      "# Detector Tuning Report",
      "",
      "이 리포트는 Offline Evaluation 결과를 profile별로 비교하는 개발용 요약입니다.",
      "threshold 변경은 자동 적용되지 않았습니다.",
      "",
      "## Quick Comparison",
      "",
      "| Signal | Profile | Value | Review Cue |",
      "| --- | --- | ---: | --- |",
    ]
    lines.append(contentsOf: quickComparisonRows(summaries: comparison.profileSummaries))

    lines.append(contentsOf: [
      "",
      "## Recommendation",
      "",
      comparison.recommendation.summary,
      "",
      comparison.recommendation.warning,
      "",
      "## Profile Summary",
      "",
      "| Profile | Records | Zero Event | Raw Candidates | Pre Smoothing | Post Smoothing | Final Events | Avg Confidence | FP-like | FN-like |",
      "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
    ])

    for summary in comparison.profileSummaries {
      lines.append(
        "| \(summary.tuningProfile) | \(summary.evaluatedRecords) | \(summary.zeroEventCount) | \(summary.rawCandidateCount) | \(summary.preSmoothingCandidateCount) | \(summary.postSmoothingEventCount) | \(summary.finalEventCount) | \(format(summary.averageConfidence)) | \(summary.possibleFalsePositiveLikeCount) | \(summary.possibleFalseNegativeLikeCount) |"
      )
    }

    lines.append(contentsOf: [
      "",
      "## Recall / Risk Matrix",
      "",
      "| Profile | Records | Failed | Zero Event Rate | Raw -> Final | Final By Type | Top Reject | Review Cue |",
      "| --- | ---: | ---: | ---: | ---: | --- | --- | --- |",
    ])
    lines.append(contentsOf: riskMatrixRows(summaries: comparison.profileSummaries))

    lines.append(contentsOf: [
      "",
      "## Zero Event Stage Breakdown",
      "",
      "| Profile | Zero Events | No Raw Candidate | Raw But No Final | Smoothing Dropped | Post Smoothing But No Final | Top Reject | Review Cue |",
      "| --- | ---: | ---: | ---: | ---: | ---: | --- | --- |",
    ])
    lines.append(contentsOf: zeroEventBreakdownRows(summaries: comparison.profileSummaries))

    lines.append(contentsOf: [
      "",
      "## Observations",
      "",
    ])
    lines.append(contentsOf: comparison.recommendation.observations.map { "- \($0)" })

    lines.append(contentsOf: [
      "",
      "## Suggested Threshold Review",
      "",
    ])
    if comparison.suggestedChanges.changes.isEmpty {
      lines.append("- 강한 변경 제안 없음. 추가 labeled segment로 재평가하세요.")
    } else {
      lines.append(contentsOf: comparison.suggestedChanges.changes.map {
        "- \($0.tuningProfile).\($0.thresholdName): \($0.suggestedDirection) — \($0.reason) 위험: \($0.falsePositiveRisk)"
      })
    }

    lines.append(contentsOf: [
      "",
      "## Label Findings",
      "",
    ])
    if comparison.labelFindings.isEmpty {
      lines.append("- expectedLabels 기반 mismatch finding 없음.")
    } else {
      lines.append(contentsOf: comparison.labelFindings.prefix(50).map {
        "- [\($0.kind.displayName)] \($0.tuningProfile) \($0.fileId) @ \($0.segmentStartSeconds)s: \($0.explanation)"
      })
    }

    lines.append(contentsOf: [
      "",
      "## Safety Notes",
      "",
      "- 공개/개인 오디오 파일은 repo에 포함하지 않습니다.",
      "- 이 결과는 detector 개발용이며 의료 성능 검증이 아닙니다.",
      "- 실제 iPhone 마이크, 백그라운드/잠금, 배터리/발열, 기기 배치는 별도로 검증해야 합니다.",
      "",
    ])

    return lines.joined(separator: "\n")
  }

  private static func quickComparisonRows(summaries: [OfflineProfileSummary]) -> [String] {
    guard !summaries.isEmpty else {
      return ["| No records | none | 0 | Offline Evaluation JSON을 먼저 생성하세요. |"]
    }

    var rows: [String] = []
    if let lowestZeroEvent = summaries.min(by: zeroEventSort) {
      rows.append(
        "| Lowest zero-event rate | \(lowestZeroEvent.tuningProfile) | \(zeroEventText(lowestZeroEvent)) | 최종 이벤트 누락이 가장 적은 profile 후보입니다. FP-like도 함께 확인하세요. |"
      )
    }
    if let highestFinal = summaries.max(by: finalEventSort) {
      rows.append(
        "| Most final events | \(highestFinal.tuningProfile) | \(highestFinal.finalEventCount) | recall 후보입니다. quiet/noise segment의 FP-like 증가 여부를 같이 보세요. |"
      )
    }
    if let lowestFPRisk = summaries.min(by: falsePositiveRiskSort) {
      rows.append(
        "| Lowest FP-like count | \(lowestFPRisk.tuningProfile) | \(lowestFPRisk.possibleFalsePositiveLikeCount) | 과탐지 위험이 가장 낮은 profile 후보입니다. FN-like가 늘지 않았는지 확인하세요. |"
      )
    }
    if let highestFNRisk = summaries.max(by: falseNegativeRiskSort) {
      rows.append(
        "| Highest FN-like count | \(highestFNRisk.tuningProfile) | \(highestFNRisk.possibleFalseNegativeLikeCount) | expected label이 있는 segment에서 누락이 많은지 raw/reject/smoothing을 확인하세요. |"
      )
    }
    if let balanced = summaries.first(where: { $0.tuningProfile == DetectorTuningProfile.balanced.rawValue }) {
      rows.append(
        "| Release default guard | balanced | \(zeroEventText(balanced)), FP-like \(balanced.possibleFalsePositiveLikeCount), FN-like \(balanced.possibleFalseNegativeLikeCount) | 충분한 근거 전에는 Release 기본값을 유지하고 sensitive는 DEBUG 비교용으로 보세요. |"
      )
    }
    return rows
  }

  private static func riskMatrixRows(summaries: [OfflineProfileSummary]) -> [String] {
    guard !summaries.isEmpty else {
      return ["| none | 0 | 0 | 0.0% | 0 -> 0 | none | none | 비교할 record가 없습니다. |"]
    }

    return summaries.map { summary in
      "| \(summary.tuningProfile) | \(summary.evaluatedRecords) | \(summary.failedRecords) | \(zeroEventText(summary)) | \(summary.rawCandidateCount) -> \(summary.finalEventCount) | \(finalEventsText(summary.finalEventCountByType)) | \(topRejectReasonText(summary.topRejectReasons)) | \(reviewCue(summary)) |"
    }
  }

  private static func zeroEventBreakdownRows(summaries: [OfflineProfileSummary]) -> [String] {
    guard !summaries.isEmpty else {
      return ["| none | 0 | 0 | 0 | 0 | 0 | none | 비교할 record가 없습니다. |"]
    }

    return summaries.map { summary in
      "| \(summary.tuningProfile) | \(summary.zeroEventCount) | \(summary.zeroEventNoRawCandidateCount) | \(summary.zeroEventRawCandidateCount) | \(summary.zeroEventDroppedBySmoothingCount) | \(summary.zeroEventAfterPostSmoothingCount) | \(topRejectReasonText(summary.topRejectReasons)) | \(reviewCue(summary)) |"
    }
  }

  private static func zeroEventText(_ summary: OfflineProfileSummary) -> String {
    "\(summary.zeroEventCount)/\(summary.evaluatedRecords) (\(formatPercent(summary.zeroEventRate)))"
  }

  private static func finalEventsText(_ counts: [String: Int]) -> String {
    guard !counts.isEmpty else { return "none" }
    return counts.sorted { $0.key < $1.key }.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
  }

  private static func topRejectReasonText(_ reasons: [OfflineEvaluationReasonCount]) -> String {
    guard let reason = reasons.first else { return "none" }
    return "\(reason.reason): \(reason.count)"
  }

  private static func reviewCue(_ summary: OfflineProfileSummary) -> String {
    if summary.failedRecords > 0 {
      return "missing/failed record를 먼저 해결하세요."
    }
    if summary.possibleFalsePositiveLikeCount > 0 {
      return "quiet/noise segment의 false-positive-like guard를 확인하세요."
    }
    if summary.rawCandidateCount == 0, summary.zeroEventCount > 0 {
      return "feature scale 또는 raw threshold에서 후보가 생기지 않는지 확인하세요."
    }
    if summary.rawCandidateCount > 0, summary.finalEventCount == 0 {
      return "raw 후보가 smoothing/final 단계에서 사라지는지 확인하세요."
    }
    if summary.possibleFalseNegativeLikeCount > 0 {
      return "expected label 누락 segment의 reject reason을 확인하세요."
    }
    return "labeled segment를 늘려 반복 확인하세요."
  }

  private static func zeroEventSort(
    lhs: OfflineProfileSummary,
    rhs: OfflineProfileSummary
  ) -> Bool {
    if lhs.zeroEventRate != rhs.zeroEventRate {
      return lhs.zeroEventRate < rhs.zeroEventRate
    }
    if lhs.possibleFalsePositiveLikeCount != rhs.possibleFalsePositiveLikeCount {
      return lhs.possibleFalsePositiveLikeCount < rhs.possibleFalsePositiveLikeCount
    }
    return lhs.tuningProfile < rhs.tuningProfile
  }

  private static func finalEventSort(
    lhs: OfflineProfileSummary,
    rhs: OfflineProfileSummary
  ) -> Bool {
    if lhs.finalEventCount != rhs.finalEventCount {
      return lhs.finalEventCount < rhs.finalEventCount
    }
    if lhs.possibleFalsePositiveLikeCount != rhs.possibleFalsePositiveLikeCount {
      return lhs.possibleFalsePositiveLikeCount > rhs.possibleFalsePositiveLikeCount
    }
    return lhs.tuningProfile > rhs.tuningProfile
  }

  private static func falsePositiveRiskSort(
    lhs: OfflineProfileSummary,
    rhs: OfflineProfileSummary
  ) -> Bool {
    if lhs.possibleFalsePositiveLikeCount != rhs.possibleFalsePositiveLikeCount {
      return lhs.possibleFalsePositiveLikeCount < rhs.possibleFalsePositiveLikeCount
    }
    return lhs.tuningProfile < rhs.tuningProfile
  }

  private static func falseNegativeRiskSort(
    lhs: OfflineProfileSummary,
    rhs: OfflineProfileSummary
  ) -> Bool {
    if lhs.possibleFalseNegativeLikeCount != rhs.possibleFalseNegativeLikeCount {
      return lhs.possibleFalseNegativeLikeCount < rhs.possibleFalseNegativeLikeCount
    }
    return lhs.tuningProfile > rhs.tuningProfile
  }

  private static func formatPercent(_ value: Double) -> String {
    String(format: "%.1f%%", value * 100)
  }

  private static func makeFinding(
    kind: OfflineProfileLabelFindingKind,
    record: OfflineEvaluationRecord,
    explanation: String
  ) -> OfflineProfileLabelFinding {
    OfflineProfileLabelFinding(
      kind: kind,
      tuningProfile: record.tuningProfile,
      datasetName: record.datasetName,
      fileId: record.fileId,
      segmentStartSeconds: record.segmentStartSeconds,
      segmentDurationSeconds: record.segmentDurationSeconds,
      expectedLabels: record.expectedLabels,
      finalEventCountByType: record.finalEventCountByType,
      explanation: explanation
    )
  }

  private static func segmentKey(_ record: OfflineEvaluationRecord) -> String {
    "\(record.datasetName)|\(record.fileId)|\(record.segmentStartSeconds)|\(record.segmentDurationSeconds)"
  }

  private static func weightedAverageConfidence(records: [OfflineEvaluationRecord]) -> Double? {
    let weightedValues = records.compactMap { record -> (value: Double, weight: Double)? in
      guard let averageConfidence = record.averageConfidence else { return nil }
      return (averageConfidence, Double(max(record.rawCandidateCount, 1)))
    }
    let totalWeight = weightedValues.reduce(0) { $0 + $1.weight }
    guard totalWeight > 0 else { return nil }
    return weightedValues.reduce(0) { $0 + $1.value * $1.weight } / totalWeight
  }

  private static func format(_ value: Double?) -> String {
    guard let value else { return "" }
    return String(format: "%.3f", value)
  }
}

public enum BackendDisagreementType: String, Codable, CaseIterable, Equatable, Sendable {
  case bothNoEvent
  case bothDetectedSnore
  case ruleOnlySnore
  case mlOnlySnore
  case differentEventType
  case confidenceGapLarge
}

public enum BackendComparisonError: Error, Equatable, Sendable {
  case missingManifestPath
  case manifestFileNotFound(String)
  case emptyInput
  case failedToWriteOutput(String)

  public var message: String {
    switch self {
    case .missingManifestPath:
      "backend 비교 manifest 경로가 필요합니다."
    case .manifestFileNotFound(let path):
      "manifest 파일을 찾을 수 없습니다: \(path)"
    case .emptyInput:
      "비교할 backend evaluation record가 없습니다."
    case .failedToWriteOutput(let reason):
      "backend 비교 output 저장에 실패했습니다. \(reason)"
    }
  }
}

public struct BackendComparisonRecord: Codable, Equatable, Sendable {
  public var fileId: String
  public var segmentStartSeconds: TimeInterval
  public var segmentDurationSeconds: TimeInterval
  public var expectedLabels: [String]
  public var ruleBasedEventCountByType: [String: Int]
  public var mlEventCountByType: [String: Int]
  public var hybridEventCountByType: [String: Int]
  public var ruleBasedConfidenceSummary: SummaryStats
  public var mlConfidenceSummary: SummaryStats
  public var hybridConfidenceSummary: SummaryStats
  public var disagreementType: BackendDisagreementType
  public var possibleFalsePositiveBackend: [String]
  public var possibleFalseNegativeBackend: [String]
  public var zeroEventReasonByBackend: [String: String]

  public init(
    fileId: String,
    segmentStartSeconds: TimeInterval,
    segmentDurationSeconds: TimeInterval,
    expectedLabels: [String],
    ruleBasedEventCountByType: [String: Int],
    mlEventCountByType: [String: Int],
    hybridEventCountByType: [String: Int],
    ruleBasedConfidenceSummary: SummaryStats,
    mlConfidenceSummary: SummaryStats,
    hybridConfidenceSummary: SummaryStats,
    disagreementType: BackendDisagreementType,
    possibleFalsePositiveBackend: [String],
    possibleFalseNegativeBackend: [String],
    zeroEventReasonByBackend: [String: String]
  ) {
    self.fileId = fileId
    self.segmentStartSeconds = max(0, segmentStartSeconds)
    self.segmentDurationSeconds = max(0, segmentDurationSeconds)
    self.expectedLabels = expectedLabels
    self.ruleBasedEventCountByType = ruleBasedEventCountByType
    self.mlEventCountByType = mlEventCountByType
    self.hybridEventCountByType = hybridEventCountByType
    self.ruleBasedConfidenceSummary = ruleBasedConfidenceSummary
    self.mlConfidenceSummary = mlConfidenceSummary
    self.hybridConfidenceSummary = hybridConfidenceSummary
    self.disagreementType = disagreementType
    self.possibleFalsePositiveBackend = possibleFalsePositiveBackend
    self.possibleFalseNegativeBackend = possibleFalseNegativeBackend
    self.zeroEventReasonByBackend = zeroEventReasonByBackend
  }
}

public struct BackendComparisonSummary: Codable, Equatable, Sendable {
  public var evaluatedSegments: Int
  public var backendZeroEventCount: [String: Int]
  public var backendSnoreEventCount: [String: Int]
  public var ruleOnlyCases: Int
  public var mlOnlyCases: Int
  public var disagreementCountByType: [String: Int]
  public var disagreementTopCases: [BackendComparisonRecord]
  public var recommendedBackendForNextIteration: String

  public init(records: [BackendComparisonRecord]) {
    evaluatedSegments = records.count
    backendZeroEventCount = [
      "ruleBased": records.filter { $0.ruleBasedEventCountByType.values.reduce(0, +) == 0 }.count,
      "coreML": records.filter { $0.mlEventCountByType.values.reduce(0, +) == 0 }.count,
      "hybrid": records.filter { $0.hybridEventCountByType.values.reduce(0, +) == 0 }.count,
    ]
    backendSnoreEventCount = [
      "ruleBased": records.reduce(0) { $0 + ($1.ruleBasedEventCountByType[SleepEventType.snore.rawValue] ?? 0) },
      "coreML": records.reduce(0) { $0 + ($1.mlEventCountByType[SleepEventType.snore.rawValue] ?? 0) },
      "hybrid": records.reduce(0) { $0 + ($1.hybridEventCountByType[SleepEventType.snore.rawValue] ?? 0) },
    ]
    ruleOnlyCases = records.filter { $0.disagreementType == .ruleOnlySnore }.count
    mlOnlyCases = records.filter { $0.disagreementType == .mlOnlySnore }.count
    disagreementCountByType = records.reduce(into: [String: Int]()) { result, record in
      result[record.disagreementType.rawValue, default: 0] += 1
    }
    disagreementTopCases = records.filter {
      $0.disagreementType != .bothNoEvent && $0.disagreementType != .bothDetectedSnore
    }.prefix(25).map { $0 }
    recommendedBackendForNextIteration = Self.makeRecommendation(records: records)
  }

  private static func makeRecommendation(records: [BackendComparisonRecord]) -> String {
    guard !records.isEmpty else {
      return "비교할 segment가 없습니다. manifest와 로컬 오디오 파일을 먼저 준비하세요."
    }

    let mlFalsePositive = records.filter {
      $0.possibleFalsePositiveBackend.contains("coreML")
    }.count
    let mlFalseNegative = records.filter {
      $0.possibleFalseNegativeBackend.contains("coreML")
    }.count
    let ruleFalseNegative = records.filter {
      $0.possibleFalseNegativeBackend.contains("ruleBased")
    }.count

    if mlFalsePositive > ruleFalseNegative {
      return "hybrid 유지 권장: ML이 quiet/noise label에서 더 민감하게 반응하는지 먼저 검토하세요."
    }
    if ruleFalseNegative > mlFalseNegative,
       records.contains(where: { $0.disagreementType == .mlOnlySnore }) {
      return "hybrid 유지 후 ML 후보를 검토: rule-based 누락 가능 segment에서 ML이 snore를 잡는지 확인하세요."
    }
    return "hybrid 유지 권장: 모델 부재/낮은 confidence/환경 차이를 흡수하면서 rule-based fallback을 보존합니다."
  }
}

public struct BackendComparisonOutput: Codable, Equatable, Sendable {
  public var generatedAt: Date
  public var detectorProfile: String
  public var summary: BackendComparisonSummary
  public var records: [BackendComparisonRecord]

  public init(
    generatedAt: Date,
    detectorProfile: String,
    summary: BackendComparisonSummary,
    records: [BackendComparisonRecord]
  ) {
    self.generatedAt = generatedAt
    self.detectorProfile = detectorProfile
    self.summary = summary
    self.records = records
  }
}

public struct BackendComparisonRunResult: Equatable, Sendable {
  public var output: BackendComparisonOutput
  public var csvURL: URL
  public var jsonURL: URL
  public var markdownURL: URL
}

public struct BackendComparisonRunner {
  public var fileManager: FileManager
  public var evaluationRunner: OfflineEvaluationRunner

  public init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
    evaluationRunner = OfflineEvaluationRunner(fileManager: fileManager)
  }

  public func compare(
    manifestURL: URL,
    outputDirectory: URL,
    profile: DetectorTuningProfile = .balanced,
    evaluatedAt: Date = Date()
  ) throws -> BackendComparisonRunResult {
    guard fileManager.fileExists(atPath: manifestURL.path) else {
      throw BackendComparisonError.manifestFileNotFound(manifestURL.path)
    }

    let manifest = try evaluationRunner.loadManifest(from: manifestURL)
    let validation = evaluationRunner.validateManifest(
      manifest,
      manifestDirectory: manifestURL.deletingLastPathComponent()
    )
    let validManifest = OfflineEvaluationManifest(
      datasetName: manifest.datasetName,
      datasetLicenseNote: manifest.datasetLicenseNote,
      segments: validation.validSegments
    )
    let evaluationRecords = evaluationRunner.evaluateRecords(
      manifest: validManifest,
      manifestDirectory: manifestURL.deletingLastPathComponent(),
      profiles: [profile],
      backends: [.ruleBased, .coreML, .hybrid],
      evaluatedAt: evaluatedAt
    )
    let output = makeOutput(
      evaluationRecords: evaluationRecords,
      profile: profile,
      generatedAt: evaluatedAt
    )
    return try write(output: output, to: outputDirectory, generatedAt: evaluatedAt)
  }

  public func makeOutput(
    evaluationRecords: [OfflineEvaluationRecord],
    profile: DetectorTuningProfile = .balanced,
    generatedAt: Date = Date()
  ) -> BackendComparisonOutput {
    let grouped = Dictionary(grouping: evaluationRecords, by: Self.segmentKey)
    let records = grouped.keys.sorted().compactMap { key in
      Self.makeRecord(records: grouped[key] ?? [])
    }
    return BackendComparisonOutput(
      generatedAt: generatedAt,
      detectorProfile: profile.rawValue,
      summary: BackendComparisonSummary(records: records),
      records: records
    )
  }

  public func write(
    output: BackendComparisonOutput,
    to outputDirectory: URL,
    generatedAt: Date
  ) throws -> BackendComparisonRunResult {
    do {
      guard !output.records.isEmpty else {
        throw BackendComparisonError.emptyInput
      }

      try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
      let timestamp = Self.fileTimestampFormatter.string(from: generatedAt)
      let jsonURL = outputDirectory.appendingPathComponent("backend_comparison_\(timestamp).json")
      let csvURL = outputDirectory.appendingPathComponent("backend_comparison_\(timestamp).csv")
      let markdownURL = outputDirectory.appendingPathComponent("backend_comparison_report.md")
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      encoder.dateEncodingStrategy = .iso8601
      try encoder.encode(output).write(to: jsonURL, options: .atomic)
      try Self.makeCSV(records: output.records).write(to: csvURL, atomically: true, encoding: .utf8)
      try Self.makeMarkdownReport(output).write(
        to: markdownURL,
        atomically: true,
        encoding: .utf8
      )
      return BackendComparisonRunResult(
        output: output,
        csvURL: csvURL,
        jsonURL: jsonURL,
        markdownURL: markdownURL
      )
    } catch let error as BackendComparisonError {
      throw error
    } catch {
      throw BackendComparisonError.failedToWriteOutput(error.localizedDescription)
    }
  }

  public static func makeRecord(records: [OfflineEvaluationRecord]) -> BackendComparisonRecord? {
    guard let first = records.first else { return nil }
    let byBackend = records.reduce(into: [String: OfflineEvaluationRecord]()) { result, record in
      result[backendKey(record.detectorBackend)] = result[backendKey(record.detectorBackend)] ?? record
    }
    let rule = byBackend["ruleBased"]
    let ml = byBackend["coreML"]
    let hybrid = byBackend["hybrid"]
    let ruleCounts = rule?.finalEventCountByType ?? [:]
    let mlCounts = ml?.finalEventCountByType ?? [:]
    let hybridCounts = hybrid?.finalEventCountByType ?? [:]
    let expectedLabels = first.expectedLabels

    return BackendComparisonRecord(
      fileId: first.fileId,
      segmentStartSeconds: first.segmentStartSeconds,
      segmentDurationSeconds: first.segmentDurationSeconds,
      expectedLabels: expectedLabels,
      ruleBasedEventCountByType: ruleCounts,
      mlEventCountByType: mlCounts,
      hybridEventCountByType: hybridCounts,
      ruleBasedConfidenceSummary: rule?.confidenceSummary ?? SummaryStats(),
      mlConfidenceSummary: ml?.confidenceSummary ?? SummaryStats(),
      hybridConfidenceSummary: hybrid?.confidenceSummary ?? SummaryStats(),
      disagreementType: disagreementType(rule: rule, ml: ml),
      possibleFalsePositiveBackend: possibleFalsePositiveBackends(
        expectedLabels: expectedLabels,
        countsByBackend: [
          "ruleBased": ruleCounts,
          "coreML": mlCounts,
          "hybrid": hybridCounts,
        ]
      ),
      possibleFalseNegativeBackend: possibleFalseNegativeBackends(
        expectedLabels: expectedLabels,
        countsByBackend: [
          "ruleBased": ruleCounts,
          "coreML": mlCounts,
          "hybrid": hybridCounts,
        ]
      ),
      zeroEventReasonByBackend: zeroEventReasons(
        recordsByBackend: [
          "ruleBased": rule,
          "coreML": ml,
          "hybrid": hybrid,
        ]
      )
    )
  }

  public static func makeCSV(records: [BackendComparisonRecord]) -> String {
    let header = [
      "fileId",
      "segmentStartSeconds",
      "expectedLabels",
      "ruleBasedEventCountByType",
      "mlEventCountByType",
      "hybridEventCountByType",
      "ruleBasedConfidenceMean",
      "mlConfidenceMean",
      "hybridConfidenceMean",
      "disagreementType",
      "possibleFalsePositiveBackend",
      "possibleFalseNegativeBackend",
      "zeroEventReasonByBackend",
    ]
    let lines = records.map { record in
      [
        record.fileId,
        format(record.segmentStartSeconds),
        record.expectedLabels.joined(separator: ";"),
        dictionaryText(record.ruleBasedEventCountByType),
        dictionaryText(record.mlEventCountByType),
        dictionaryText(record.hybridEventCountByType),
        format(record.ruleBasedConfidenceSummary.mean),
        format(record.mlConfidenceSummary.mean),
        format(record.hybridConfidenceSummary.mean),
        record.disagreementType.rawValue,
        record.possibleFalsePositiveBackend.joined(separator: ";"),
        record.possibleFalseNegativeBackend.joined(separator: ";"),
        dictionaryText(record.zeroEventReasonByBackend),
      ].map(csvEscape).joined(separator: ",")
    }
    return ([header.joined(separator: ",")] + lines).joined(separator: "\n") + "\n"
  }

  public static func makeMarkdownReport(_ output: BackendComparisonOutput) -> String {
    var lines: [String] = [
      "# Rule-based vs ML Backend Comparison",
      "",
      "이 리포트는 같은 manifest segment에서 rule-based, Core ML, hybrid detector 결과를 비교하는 개발용 자료입니다. 의료 성능 검증이나 진단 목적의 결과가 아닙니다.",
      "",
      "## Summary",
      "",
      "- detector profile: \(output.detectorProfile)",
      "- evaluated segments: \(output.summary.evaluatedSegments)",
      "- backend zero-event count: \(dictionaryText(output.summary.backendZeroEventCount))",
      "- backend snore event count: \(dictionaryText(output.summary.backendSnoreEventCount))",
      "- ruleOnly cases: \(output.summary.ruleOnlyCases)",
      "- mlOnly cases: \(output.summary.mlOnlyCases)",
      "- recommended backend for next iteration: \(output.summary.recommendedBackendForNextIteration)",
      "",
      "## Disagreement Counts",
      "",
    ]
    lines.append(contentsOf: output.summary.disagreementCountByType.sorted { $0.key < $1.key }.map {
      "- \($0.key): \($0.value)"
    })

    lines.append(contentsOf: [
      "",
      "## Top Disagreement Cases",
      "",
    ])
    if output.summary.disagreementTopCases.isEmpty {
      lines.append("- 큰 disagreement 후보 없음.")
    } else {
      lines.append(contentsOf: output.summary.disagreementTopCases.map {
        "- \($0.fileId) @ \(format($0.segmentStartSeconds))s: \($0.disagreementType.rawValue), labels=\($0.expectedLabels.joined(separator: "/")), rule=\(dictionaryText($0.ruleBasedEventCountByType)), ml=\(dictionaryText($0.mlEventCountByType)), hybrid=\(dictionaryText($0.hybridEventCountByType))"
      })
    }

    lines.append(contentsOf: [
      "",
      "## Interpretation Notes",
      "",
      "- ML이 quiet/unknown/environmentalNoise segment에서 snore를 많이 만들면 false-positive-like 증가 가능성을 먼저 봅니다.",
      "- rule-based가 snore expected segment에서 자주 0 event이면 보수적인 threshold 또는 smoothing 영향을 봅니다.",
      "- hybrid fallback은 모델 미설치, 낮은 confidence, non-snore label에서 안정성을 유지하기 위한 기본 비교 후보입니다.",
      "- 실제 iPhone 마이크/기기 배치/백그라운드 조건은 이 리포트와 별도로 확인해야 합니다.",
      "",
    ])

    return lines.joined(separator: "\n")
  }

  private static func disagreementType(
    rule: OfflineEvaluationRecord?,
    ml: OfflineEvaluationRecord?
  ) -> BackendDisagreementType {
    let ruleCounts = rule?.finalEventCountByType ?? [:]
    let mlCounts = ml?.finalEventCountByType ?? [:]
    let ruleFinal = ruleCounts.values.reduce(0, +)
    let mlFinal = mlCounts.values.reduce(0, +)
    let ruleSnore = ruleCounts[SleepEventType.snore.rawValue] ?? 0
    let mlSnore = mlCounts[SleepEventType.snore.rawValue] ?? 0

    if ruleFinal == 0 && mlFinal == 0 {
      return .bothNoEvent
    }
    if ruleSnore > 0 && mlSnore == 0 {
      return .ruleOnlySnore
    }
    if ruleSnore == 0 && mlSnore > 0 {
      return .mlOnlySnore
    }
    if ruleSnore > 0 && mlSnore > 0 {
      return confidenceGap(rule: rule, ml: ml) >= 0.25 ? .confidenceGapLarge : .bothDetectedSnore
    }
    if Set(ruleCounts.keys) != Set(mlCounts.keys) {
      return .differentEventType
    }
    if confidenceGap(rule: rule, ml: ml) >= 0.25 {
      return .confidenceGapLarge
    }
    return .differentEventType
  }

  private static func possibleFalsePositiveBackends(
    expectedLabels: [String],
    countsByBackend: [String: [String: Int]]
  ) -> [String] {
    let labels = Set(expectedLabels.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
    let quietLabels: Set<String> = [
      DatasetManifestLabel.silence.rawValue,
      DatasetManifestLabel.unknown.rawValue,
      DatasetManifestLabel.environmentalNoise.rawValue,
    ]
    guard !labels.isEmpty, labels.isSubset(of: quietLabels) else { return [] }
    return countsByBackend.keys.sorted().filter {
      (countsByBackend[$0]?[SleepEventType.snore.rawValue] ?? 0) > 0
    }
  }

  private static func possibleFalseNegativeBackends(
    expectedLabels: [String],
    countsByBackend: [String: [String: Int]]
  ) -> [String] {
    guard expectedLabels.contains(SleepEventType.snore.rawValue) else { return [] }
    return countsByBackend.keys.sorted().filter {
      (countsByBackend[$0]?[SleepEventType.snore.rawValue] ?? 0) == 0
    }
  }

  private static func zeroEventReasons(
    recordsByBackend: [String: OfflineEvaluationRecord?]
  ) -> [String: String] {
    recordsByBackend.reduce(into: [String: String]()) { result, item in
      guard let record = item.value,
            record.errorMessage == nil,
            record.finalEventCount == 0 else { return }
      result[item.key] = record.zeroEventReason ?? "unknown"
    }
  }

  private static func confidenceGap(
    rule: OfflineEvaluationRecord?,
    ml: OfflineEvaluationRecord?
  ) -> Double {
    abs((rule?.confidenceSummary?.mean ?? 0) - (ml?.confidenceSummary?.mean ?? 0))
  }

  private static func backendKey(_ displayName: String) -> String {
    switch displayName {
    case SleepDetectionBackend.ruleBased.displayName, SleepDetectionBackend.ruleBased.rawValue:
      return "ruleBased"
    case SleepDetectionBackend.coreML.displayName, SleepDetectionBackend.coreML.rawValue:
      return "coreML"
    case SleepDetectionBackend.coreMLMulticlass.displayName, SleepDetectionBackend.coreMLMulticlass.rawValue:
      return "coreMLMulticlass"
    case SleepDetectionBackend.hybrid.displayName, SleepDetectionBackend.hybrid.rawValue:
      return "hybrid"
    default:
      return displayName
    }
  }

  private static func segmentKey(_ record: OfflineEvaluationRecord) -> String {
    "\(record.datasetName)|\(record.fileId)|\(record.segmentStartSeconds)|\(record.segmentDurationSeconds)"
  }

  private static func dictionaryText(_ dictionary: [String: Int]) -> String {
    dictionary.sorted { $0.key < $1.key }.map { "\($0.key):\($0.value)" }.joined(separator: ";")
  }

  private static func dictionaryText(_ dictionary: [String: String]) -> String {
    dictionary.sorted { $0.key < $1.key }.map { "\($0.key):\($0.value)" }.joined(separator: ";")
  }

  private static func csvEscape(_ value: String) -> String {
    if value.contains(",") || value.contains("\"") || value.contains("\n") {
      return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
    return value
  }

  private static func format(_ value: Double) -> String {
    String(format: "%.6f", value)
  }

  private static let fileTimestampFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyyMMdd_HHmmss"
    return formatter
  }()
}

public struct OfflineEvaluationRunner {
  public var fileManager: FileManager

  public init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  public func loadManifest(from url: URL) throws -> OfflineEvaluationManifest {
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(OfflineEvaluationManifest.self, from: data)
  }

  public func validateManifest(
    _ manifest: OfflineEvaluationManifest,
    manifestDirectory: URL
  ) -> OfflineEvaluationManifestValidationResult {
    OfflineEvaluationManifestValidator(fileManager: fileManager).validate(
      manifest: manifest,
      manifestDirectory: manifestDirectory
    )
  }

  public func evaluate(
    manifestURL: URL,
    outputDirectory: URL,
    profiles: [DetectorTuningProfile] = [.conservative, .balanced, .sensitive],
    backends: [SleepDetectionBackend] = [.hybrid],
    evaluatedAt: Date = Date()
  ) throws -> OfflineEvaluationRunResult {
    let manifest = try loadManifest(from: manifestURL)
    let validation = validateManifest(
      manifest,
      manifestDirectory: manifestURL.deletingLastPathComponent()
    )
    let validManifest = OfflineEvaluationManifest(
      datasetName: manifest.datasetName,
      datasetLicenseNote: manifest.datasetLicenseNote,
      segments: validation.validSegments
    )
    let records = evaluateRecords(
      manifest: validManifest,
      manifestDirectory: manifestURL.deletingLastPathComponent(),
      profiles: profiles,
      backends: backends,
      evaluatedAt: evaluatedAt
    )
    let output = OfflineEvaluationOutput(
      summary: OfflineEvaluationRunSummary(
        records: records,
        manifestSegmentCount: validManifest.segments.count
      ),
      records: records
    )
    var result = try write(output: output, to: outputDirectory, evaluatedAt: evaluatedAt)
    result.validation = validation
    return result
  }

  public func evaluateRecords(
    manifest: OfflineEvaluationManifest,
    manifestDirectory: URL,
    profiles: [DetectorTuningProfile],
    backends: [SleepDetectionBackend] = [.hybrid],
    evaluatedAt: Date = Date()
  ) -> [OfflineEvaluationRecord] {
    guard !manifest.segments.isEmpty else { return [] }

    return manifest.segments.flatMap { segment in
      profiles.flatMap { profile in
        backends.map { backend in
          evaluate(
            segment: segment,
            manifestDirectory: manifestDirectory,
            profile: profile,
            backend: backend,
            evaluatedAt: evaluatedAt
          )
        }
      }
    }
  }

  public func write(
    output: OfflineEvaluationOutput,
    to outputDirectory: URL,
    evaluatedAt: Date
  ) throws -> OfflineEvaluationRunResult {
    do {
      try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
      let timestamp = Self.fileTimestampFormatter.string(from: evaluatedAt)
      let jsonURL = outputDirectory.appendingPathComponent("offline_evaluation_\(timestamp).json")
      let csvURL = outputDirectory.appendingPathComponent("offline_evaluation_\(timestamp).csv")
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      encoder.dateEncodingStrategy = .iso8601
      try encoder.encode(output).write(to: jsonURL, options: .atomic)
      try Self.makeCSV(records: output.records).write(to: csvURL, atomically: true, encoding: .utf8)
      return OfflineEvaluationRunResult(output: output, csvURL: csvURL, jsonURL: jsonURL)
    } catch {
      throw OfflineEvaluationError.failedToWriteOutput(error.localizedDescription)
    }
  }

  public func evaluate(
    segment: OfflineEvaluationManifestSegment,
    manifestDirectory: URL,
    profile: DetectorTuningProfile,
    backend: SleepDetectionBackend = .hybrid,
    evaluatedAt: Date
  ) -> OfflineEvaluationRecord {
    let configuration = profile.configuration
    let analyzer = configuration.makeSleepAnalyzer(backend: backend)
    let fileURL = resolvedFileURL(segment.localFilePath, relativeTo: manifestDirectory)
    let baseRecord = baseRecord(
      segment: segment,
      profile: profile,
      analyzer: analyzer,
      evaluatedAt: evaluatedAt
    )

    do {
      let chunks = try DatasetReplayAudioSource.loadChunks(
        fileURL: fileURL,
        chunkDuration: 1,
        segmentStartSeconds: segment.segmentStartSeconds,
        segmentDurationSeconds: segment.segmentDurationSeconds,
        startedAt: evaluatedAt
      )
      guard !chunks.isEmpty else {
        var record = baseRecord
        record.errorMessage = "선택한 segment에서 읽을 AudioChunk가 없습니다."
        return record
      }

      return makeRecord(
        baseRecord: baseRecord,
        chunks: chunks,
        analyzer: analyzer,
        configuration: configuration,
        profile: profile,
        evaluatedAt: evaluatedAt
      )
    } catch {
      var record = baseRecord
      record.errorMessage = (error as? AudioSourceError)?.message ?? error.localizedDescription
      return record
    }
  }

  public static func makeCSV(records: [OfflineEvaluationRecord]) -> String {
    let header = [
      "evaluatedAt",
      "detectorBackend",
      "tuningProfile",
      "fileId",
      "segmentStartSeconds",
      "segmentDurationSeconds",
      "receivedAudioSeconds",
      "analyzedAudioSeconds",
      "audioCoverageRatio",
      "rawCandidateCount",
      "averageConfidence",
      "preSmoothingCandidateCount",
      "postSmoothingEventCount",
      "finalEventCountByType",
      "rejectReasonTop",
      "zeroEventReason",
      "rmsMean",
      "rmsP90",
      "rmsP95",
      "energyMean",
      "energyP90",
      "energyP95",
      "sleepSoundScore",
      "mainDisturbanceReason",
      "errorMessage",
    ]

    let lines = records.map { record in
      [
        ISO8601DateFormatter().string(from: record.evaluatedAt),
        record.detectorBackend,
        record.tuningProfile,
        record.fileId,
        Self.format(record.segmentStartSeconds),
        Self.format(record.segmentDurationSeconds),
        Self.format(record.receivedAudioSeconds),
        Self.format(record.analyzedAudioSeconds),
        Self.format(record.audioCoverageRatio),
        "\(record.rawCandidateCount)",
        record.averageConfidence.map(Self.format) ?? "",
        "\(record.preSmoothingCandidateCount)",
        "\(record.postSmoothingEventCount)",
        Self.dictionaryText(record.finalEventCountByType),
        record.rejectReasonTop.map { "\($0.reason):\($0.count)" }.joined(separator: ";"),
        record.zeroEventReason ?? "",
        Self.format(record.rmsSummary.mean),
        Self.format(record.rmsSummary.p90),
        Self.format(record.rmsSummary.p95),
        Self.format(record.energySummary.mean),
        Self.format(record.energySummary.p90),
        Self.format(record.energySummary.p95),
        record.scoreSummary.map { "\($0.sleepSoundScore)" } ?? "",
        record.scoreSummary?.mainDisturbanceReason ?? "",
        record.errorMessage ?? "",
      ].map(Self.csvEscape).joined(separator: ",")
    }

    return ([header.joined(separator: ",")] + lines).joined(separator: "\n") + "\n"
  }

  public static func parseProfiles(_ rawValue: String) throws -> [DetectorTuningProfile] {
    let profiles = rawValue.split(separator: ",").map {
      String($0).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    guard !profiles.isEmpty else { return [.conservative, .balanced, .sensitive] }

    return try profiles.map { profile in
      guard let parsed = DetectorTuningProfile(rawValue: profile) else {
        throw OfflineEvaluationError.invalidProfile(profile)
      }
      return parsed
    }
  }

  public static func parseBackends(_ rawValue: String) throws -> [SleepDetectionBackend] {
    let backends = rawValue.split(separator: ",").map {
      String($0).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    guard !backends.isEmpty else { return [.hybrid] }

    return try backends.map { backend in
      guard let parsed = SleepDetectionBackend(rawValue: backend) else {
        throw OfflineEvaluationError.invalidBackend(backend)
      }
      return parsed
    }
  }

  private func makeRecord(
    baseRecord: OfflineEvaluationRecord,
    chunks: [AudioChunk],
    analyzer: SleepAnalyzer,
    configuration: DetectorThresholdConfiguration,
    profile: DetectorTuningProfile,
    evaluatedAt: Date
  ) -> OfflineEvaluationRecord {
    var metrics = AudioCaptureMetrics()
    metrics.start(at: evaluatedAt)
    let collector = DetectorDiagnosticsCollector()
    var rawOutputs: [DetectorOutput] = []
    var audioFeatures: [AudioFeatures] = []

    collector.reset(
      sessionId: UUID(),
      startedAt: evaluatedAt,
      detectorBackend: analyzer.detectorBackend.displayName,
      modelInstalled: analyzer.isModelInstalled,
      thresholdsSnapshot: analyzer.thresholdsSnapshot.merging(configuration.thresholdSnapshot) {
        current, _ in current
      },
      eventAudioSampleStorageEnabled: false
    )
    collector.addNote("Offline Evaluation profile=\(profile.rawValue)")

    for chunk in chunks {
      metrics.recordReceived(chunk: chunk, at: chunk.startedAt)
      let features = analyzer.extractor.extractFeatures(from: chunk)
      let outputs = analyzer.detector.detect(features: features)
      metrics.recordAnalyzed(chunk: chunk, at: chunk.startedAt)
      collector.recordModelFallbackIfNeeded(
        backend: analyzer.detectorBackend,
        modelInstalled: analyzer.isModelInstalled
      )
      collector.record(features: features, outputs: outputs)
      audioFeatures.append(features)
      rawOutputs.append(contentsOf: outputs)
    }

    let sequenceResult = analyzer.detectSuspectedBreathingPauseSequence(
      features: audioFeatures,
      contextOutputs: rawOutputs
    )
    collector.record(sequenceResult: sequenceResult)
    rawOutputs.append(contentsOf: sequenceResult.outputs)

    let smoothingResult = analyzer.smoothWithDiagnostics(outputs: rawOutputs)
    collector.record(smoothingDiagnostics: smoothingResult.diagnostics)

    let endedAt = evaluatedAt.addingTimeInterval(metrics.receivedAudioSeconds)
    metrics.stop(at: endedAt)
    let session = SleepSession(
      startedAt: evaluatedAt,
      endedAt: endedAt,
      measurementDuration: metrics.receivedAudioSeconds,
      estimatedSleepDuration: metrics.receivedAudioSeconds,
      modelVersion: "offline-\(profile.rawValue)"
    )
    let events = analyzer.makeEvents(session: session, outputs: smoothingResult.outputs)
    collector.record(finalEvents: events)

    guard let diagnostics = collector.finalize(endedAt: endedAt, metrics: metrics) else {
      var record = baseRecord
      record.errorMessage = "detector diagnostics 생성에 실패했습니다."
      return record
    }

    let report = SleepScoreCalculator().makeReport(
      session: session,
      events: events,
      captureMetrics: metrics
    )
    let zeroEventAnalysis = ZeroEventAnalysis.make(
      diagnostics: diagnostics,
      configuration: configuration
    )

    var record = baseRecord
    record.receivedAudioSeconds = metrics.receivedAudioSeconds
    record.analyzedAudioSeconds = metrics.analyzedAudioSeconds
    record.audioCoverageRatio = metrics.audioCoverageRatio
    record.rawCandidateCount = diagnostics.rawCandidateCount
    record.averageConfidence = Self.averageConfidence(from: rawOutputs)
    record.confidenceSummary = SummaryStats.make(values: rawOutputs.map(\.confidence))
    record.rawCandidateCountByType = typeDictionary(diagnostics.rawCandidateCountByType)
    record.preSmoothingCandidateCount = diagnostics.preSmoothingCandidateCount
    record.postSmoothingEventCount = diagnostics.postSmoothingEventCount
    record.finalEventCountByType = typeDictionary(diagnostics.finalEventCountByType)
    record.rejectReasonTop = diagnostics.topRejectReasons.prefix(5).map {
      OfflineEvaluationReasonCount(reason: $0.0.rawValue, count: $0.1)
    }
    record.zeroEventReason = zeroEventAnalysis?.probableReason.rawValue
    record.rmsSummary = diagnostics.rmsSummary
    record.energySummary = diagnostics.energySummary
    record.scoreSummary = OfflineEvaluationScoreSummary(report: report)
    return record
  }

  private func baseRecord(
    segment: OfflineEvaluationManifestSegment,
    profile: DetectorTuningProfile,
    analyzer: SleepAnalyzer,
    evaluatedAt: Date
  ) -> OfflineEvaluationRecord {
    OfflineEvaluationRecord(
      evaluatedAt: evaluatedAt,
      detectorBackend: analyzer.detectorBackend.displayName,
      tuningProfile: profile.rawValue,
      datasetName: segment.datasetName,
      fileId: segment.fileId,
      filePath: segment.localFilePath,
      segmentStartSeconds: segment.segmentStartSeconds,
      segmentDurationSeconds: segment.segmentDurationSeconds,
      expectedLabels: segment.expectedLabels
    )
  }

  private func resolvedFileURL(_ filePath: String, relativeTo manifestDirectory: URL) -> URL {
    let expandedPath = NSString(string: filePath).expandingTildeInPath
    if expandedPath.hasPrefix("/") {
      return URL(fileURLWithPath: expandedPath)
    }
    return manifestDirectory.appendingPathComponent(expandedPath).standardizedFileURL
  }

  private func typeDictionary(_ values: [SleepEventType: Int]) -> [String: Int] {
    values.reduce(into: [String: Int]()) { result, item in
      result[item.key.rawValue] = item.value
    }
  }

  private static func dictionaryText(_ dictionary: [String: Int]) -> String {
    dictionary.sorted { $0.key < $1.key }.map { "\($0.key):\($0.value)" }.joined(separator: ";")
  }

  private static func averageConfidence(from outputs: [DetectorOutput]) -> Double? {
    let values = outputs.map(\.confidence).filter { $0.isFinite }
    guard !values.isEmpty else { return nil }
    return values.reduce(0, +) / Double(values.count)
  }

  private static func csvEscape(_ value: String) -> String {
    if value.contains(",") || value.contains("\"") || value.contains("\n") {
      return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
    return value
  }

  private static func format(_ value: Double) -> String {
    String(format: "%.6f", value)
  }

  private static let fileTimestampFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyyMMdd_HHmmss"
    return formatter
  }()
}
