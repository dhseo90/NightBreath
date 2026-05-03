import Foundation
import SleepSoundCore

public enum OfflineEvaluationError: Error, Equatable, Sendable {
  case missingManifestPath
  case emptyManifest
  case failedToWriteOutput(String)
  case invalidProfile(String)

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
    }
  }
}

public struct OfflineEvaluationManifest: Codable, Equatable, Sendable {
  public var segments: [OfflineEvaluationManifestSegment]

  public init(segments: [OfflineEvaluationManifestSegment]) {
    self.segments = segments
  }
}

public struct OfflineEvaluationManifestSegment: Codable, Equatable, Identifiable, Sendable {
  public var datasetName: String
  public var filePath: String
  public var fileId: String
  public var segmentStartSeconds: TimeInterval
  public var segmentDurationSeconds: TimeInterval
  public var expectedLabels: [SleepEventType]
  public var notes: String?
  public var licenseNote: String

  public var id: String {
    "\(datasetName)-\(fileId)-\(segmentStartSeconds)-\(segmentDurationSeconds)"
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
    self.datasetName = datasetName
    self.filePath = filePath
    self.fileId = fileId
    self.segmentStartSeconds = max(0, segmentStartSeconds)
    self.segmentDurationSeconds = max(0, segmentDurationSeconds)
    self.expectedLabels = expectedLabels
    self.notes = notes
    self.licenseNote = licenseNote
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
    possibleFalseNegativeLikeCount: Int
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

      return OfflineProfileSummary(
        tuningProfile: profile,
        totalEvaluatedSegments: segmentKeys.count,
        evaluatedRecords: profileRecords.count,
        failedRecords: profileRecords.filter { $0.errorMessage != nil }.count,
        rawCandidateCount: profileRecords.reduce(0) { $0 + $1.rawCandidateCount },
        preSmoothingCandidateCount: profileRecords.reduce(0) { $0 + $1.preSmoothingCandidateCount },
        postSmoothingEventCount: profileRecords.reduce(0) { $0 + $1.postSmoothingEventCount },
        finalEventCountByType: finalCounts,
        zeroEventCount: profileRecords.filter { $0.errorMessage == nil && $0.finalEventCount == 0 }.count,
        zeroEventRate: profileRecords.isEmpty ? 0 : Double(profileRecords.filter { $0.errorMessage == nil && $0.finalEventCount == 0 }.count) / Double(profileRecords.count),
        topRejectReasons: topRejectReasons,
        averageConfidence: weightedAverageConfidence(records: profileRecords),
        possibleFalsePositiveLikeCount: profileFindings.filter { $0.kind == .possibleFalsePositiveLike }.count,
        possibleFalseNegativeLikeCount: profileFindings.filter { $0.kind == .possibleFalseNegativeLike }.count
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
    ]

    for summary in comparison.profileSummaries {
      lines.append(
        "| \(summary.tuningProfile) | \(summary.evaluatedRecords) | \(summary.zeroEventCount) | \(summary.rawCandidateCount) | \(summary.preSmoothingCandidateCount) | \(summary.postSmoothingEventCount) | \(summary.finalEventCount) | \(format(summary.averageConfidence)) | \(summary.possibleFalsePositiveLikeCount) | \(summary.possibleFalseNegativeLikeCount) |"
      )
    }

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

public struct OfflineEvaluationRunner {
  public var fileManager: FileManager

  public init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  public func loadManifest(from url: URL) throws -> OfflineEvaluationManifest {
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(OfflineEvaluationManifest.self, from: data)
  }

  public func evaluate(
    manifestURL: URL,
    outputDirectory: URL,
    profiles: [DetectorTuningProfile] = [.conservative, .balanced, .sensitive],
    evaluatedAt: Date = Date()
  ) throws -> OfflineEvaluationRunResult {
    let manifest = try loadManifest(from: manifestURL)
    let records = evaluateRecords(
      manifest: manifest,
      manifestDirectory: manifestURL.deletingLastPathComponent(),
      profiles: profiles,
      evaluatedAt: evaluatedAt
    )
    let output = OfflineEvaluationOutput(
      summary: OfflineEvaluationRunSummary(
        records: records,
        manifestSegmentCount: manifest.segments.count
      ),
      records: records
    )
    return try write(output: output, to: outputDirectory, evaluatedAt: evaluatedAt)
  }

  public func evaluateRecords(
    manifest: OfflineEvaluationManifest,
    manifestDirectory: URL,
    profiles: [DetectorTuningProfile],
    evaluatedAt: Date = Date()
  ) -> [OfflineEvaluationRecord] {
    guard !manifest.segments.isEmpty else { return [] }

    return manifest.segments.flatMap { segment in
      profiles.map { profile in
        evaluate(
          segment: segment, manifestDirectory: manifestDirectory, profile: profile,
          evaluatedAt: evaluatedAt)
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
    evaluatedAt: Date
  ) -> OfflineEvaluationRecord {
    let configuration = profile.configuration
    let analyzer = configuration.makeSleepAnalyzer()
    let fileURL = resolvedFileURL(segment.filePath, relativeTo: manifestDirectory)
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
      collector.record(features: features, outputs: outputs)
      rawOutputs.append(contentsOf: outputs)
    }

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
      filePath: segment.filePath,
      segmentStartSeconds: segment.segmentStartSeconds,
      segmentDurationSeconds: segment.segmentDurationSeconds,
      expectedLabels: segment.expectedLabels.map(\.rawValue)
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
