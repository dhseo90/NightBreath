import Foundation
import OfflineEvaluationSupport
import Testing

@Suite("Offline Profile Comparison")
struct OfflineProfileComparisonTests {
  @Test
  func classifiesPossibleFalsePositiveAndFalseNegativeLikeCases() {
    let records = [
      makeRecord(
        profile: "balanced",
        fileId: "expected-snore",
        expectedLabels: ["snore"],
        finalEventCountByType: [:],
        rawCandidateCount: 1
      ),
      makeRecord(
        profile: "balanced",
        fileId: "expected-quiet",
        expectedLabels: ["unknown"],
        finalEventCountByType: ["environmentalNoise": 3],
        rawCandidateCount: 3
      ),
    ]

    let findings = OfflineProfileComparisonRunner.makeLabelFindings(records: records)

    #expect(findings.count == 2)
    #expect(findings.contains { $0.kind == .possibleFalseNegativeLike })
    #expect(findings.contains { $0.kind == .possibleFalsePositiveLike })
  }

  @Test
  func summarizesProfilesWithCandidateCountsAndAverageConfidence() {
    let records = [
      makeRecord(
        profile: "balanced",
        fileId: "one",
        expectedLabels: ["snore"],
        finalEventCountByType: ["snore": 1],
        rawCandidateCount: 2,
        averageConfidence: 0.7,
        rejectReasonTop: [OfflineEvaluationReasonCount(reason: "tooShort", count: 1)]
      ),
      makeRecord(
        profile: "balanced",
        fileId: "two",
        expectedLabels: ["unknown"],
        finalEventCountByType: [:],
        rawCandidateCount: 0,
        averageConfidence: nil,
        rejectReasonTop: [OfflineEvaluationReasonCount(reason: "belowConfidenceThreshold", count: 2)]
      ),
      makeRecord(
        profile: "sensitive",
        fileId: "one",
        expectedLabels: ["snore"],
        finalEventCountByType: ["snore": 2],
        rawCandidateCount: 3,
        averageConfidence: 0.6
      ),
    ]
    let findings = OfflineProfileComparisonRunner.makeLabelFindings(records: records)

    let summaries = OfflineProfileComparisonRunner.makeProfileSummaries(
      records: records,
      findings: findings
    )
    let balanced = try! #require(summaries.first { $0.tuningProfile == "balanced" })

    #expect(summaries.count == 2)
    #expect(balanced.totalEvaluatedSegments == 2)
    #expect(balanced.expectedSnoreRecords == 1)
    #expect(balanced.expectedSnoreDetectedRecords == 1)
    #expect(balanced.snoreNegativeRecords == 1)
    #expect(balanced.snoreNegativeWithSnoreEventRecords == 0)
    #expect(balanced.snoreNegativeRawCandidateCountByType.isEmpty)
    #expect(balanced.rawCandidateCount == 2)
    #expect(balanced.zeroEventCount == 1)
    #expect(balanced.zeroEventNoRawCandidateCount == 1)
    #expect(balanced.zeroEventRawCandidateCount == 0)
    #expect(balanced.zeroEventDroppedBySmoothingCount == 0)
    #expect(balanced.zeroEventAfterPostSmoothingCount == 0)
    #expect(balanced.finalEventCountByType["snore"] == 1)
    #expect(balanced.averageConfidence == 0.7)
    #expect(balanced.topRejectReasons.first?.reason == "belowConfidenceThreshold")
  }

  @Test
  func summarizesPublicNegativeRawCandidateMixByProfile() {
    let records = [
      makeRecord(
        profile: "balanced",
        fileId: "fan-noise",
        expectedLabels: ["environmentalNoise"],
        finalEventCountByType: [:],
        rawCandidateCount: 3,
        rawCandidateCountByType: ["coughLike": 1, "movementLike": 2]
      ),
      makeRecord(
        profile: "balanced",
        fileId: "quiet-room",
        expectedLabels: ["unknown"],
        finalEventCountByType: [:],
        rawCandidateCount: 1,
        rawCandidateCountByType: ["bruxismLike": 1]
      ),
      makeRecord(
        profile: "balanced",
        fileId: "snore",
        expectedLabels: ["snore"],
        finalEventCountByType: ["snore": 1],
        rawCandidateCount: 1
      ),
    ]

    let summary = try! #require(
      OfflineProfileComparisonRunner.makeProfileSummaries(
        records: records,
        findings: OfflineProfileComparisonRunner.makeLabelFindings(records: records)
      ).first
    )

    #expect(summary.snoreNegativeRecords == 2)
    #expect(summary.snoreNegativeRawCandidateCountByType["coughLike"] == 1)
    #expect(summary.snoreNegativeRawCandidateCountByType["movementLike"] == 2)
    #expect(summary.snoreNegativeRawCandidateCountByType["bruxismLike"] == 1)
    #expect(summary.snoreNegativeRawCandidateCountByType["snore"] == nil)
  }

  @Test
  func summarizesSnoreNegativeRiskForEnvironmentalNoiseLabels() {
    let records = [
      makeRecord(
        profile: "sensitive",
        fileId: "fan-noise",
        expectedLabels: ["environmentalNoise"],
        finalEventCountByType: ["snore": 1],
        rawCandidateCount: 2
      ),
      makeRecord(
        profile: "sensitive",
        fileId: "room-tone",
        expectedLabels: ["silence"],
        finalEventCountByType: [:],
        rawCandidateCount: 0
      ),
    ]

    let findings = OfflineProfileComparisonRunner.makeLabelFindings(records: records)
    let summary = try! #require(
      OfflineProfileComparisonRunner.makeProfileSummaries(
        records: records,
        findings: findings
      ).first
    )

    #expect(summary.snoreNegativeRecords == 2)
    #expect(summary.snoreNegativeWithSnoreEventRecords == 1)
    #expect(summary.snoreNegativeEventRate == 0.5)
    #expect(findings.contains { $0.kind == .possibleFalsePositiveLike && $0.fileId == "fan-noise" })
  }

  @Test
  func generatesManualThresholdSuggestionsWithoutApplyingThem() {
    let records = [
      makeRecord(profile: "balanced", fileId: "snore-a", expectedLabels: ["snore"], finalEventCountByType: [:], rawCandidateCount: 1),
      makeRecord(profile: "balanced", fileId: "snore-b", expectedLabels: ["snore"], finalEventCountByType: [:], rawCandidateCount: 0),
      makeRecord(profile: "sensitive", fileId: "snore-a", expectedLabels: ["snore"], finalEventCountByType: ["snore": 1], rawCandidateCount: 3),
      makeRecord(profile: "sensitive", fileId: "quiet-a", expectedLabels: ["unknown"], finalEventCountByType: ["environmentalNoise": 2], rawCandidateCount: 2),
    ]
    let runner = OfflineProfileComparisonRunner()
    let comparison = runner.makeComparison(
      outputs: [
        OfflineEvaluationOutput(
          summary: OfflineEvaluationRunSummary(records: records, manifestSegmentCount: 4),
          records: records
        )
      ],
      generatedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )

    #expect(comparison.suggestedChanges.autoApplied == false)
    #expect(!comparison.suggestedChanges.changes.isEmpty)
    #expect(comparison.recommendation.summary.contains("자동 적용하지 않았습니다"))
    #expect(comparison.recommendation.warning.contains("false-positive-like"))
  }

  @Test
  func writesTuningReportAndSuggestedChangesJSON() throws {
    let outputDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("NightBreathProfileCompare-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: outputDirectory) }
    let records = [
      makeRecord(profile: "balanced", fileId: "snore", expectedLabels: ["snore"], finalEventCountByType: [:], rawCandidateCount: 1)
    ]
    let comparison = OfflineProfileComparisonRunner().makeComparison(
      outputs: [
        OfflineEvaluationOutput(
          summary: OfflineEvaluationRunSummary(records: records, manifestSegmentCount: 1),
          records: records
        )
      ],
      generatedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )

    let result = try OfflineProfileComparisonRunner().write(
      comparison: comparison,
      to: outputDirectory
    )
    let report = try String(contentsOf: result.reportURL, encoding: .utf8)
    let suggestedChanges = try Data(contentsOf: result.suggestedChangesURL)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    #expect(FileManager.default.fileExists(atPath: result.reportURL.path))
    #expect(FileManager.default.fileExists(atPath: result.suggestedChangesURL.path))
    #expect(report.contains("threshold 변경은 자동 적용되지 않았습니다"))
    #expect(try decoder.decode(OfflineSuggestedThresholdChangeSet.self, from: suggestedChanges).autoApplied == false)
  }

  @Test
  func markdownReportIncludesQuickComparisonAndRiskMatrix() {
    let records = [
      makeRecord(
        profile: "balanced",
        fileId: "snore-a",
        expectedLabels: ["snore"],
        finalEventCountByType: [:],
        rawCandidateCount: 1,
        rejectReasonTop: [OfflineEvaluationReasonCount(reason: "belowConfidenceThreshold", count: 3)]
      ),
      makeRecord(
        profile: "balanced",
        fileId: "quiet-a",
        expectedLabels: ["unknown"],
        finalEventCountByType: [:],
        rawCandidateCount: 0
      ),
      makeRecord(
        profile: "sensitive",
        fileId: "snore-a",
        expectedLabels: ["snore"],
        finalEventCountByType: ["snore": 1],
        rawCandidateCount: 3
      ),
      makeRecord(
        profile: "sensitive",
        fileId: "quiet-a",
        expectedLabels: ["unknown"],
        finalEventCountByType: ["environmentalNoise": 1],
        rawCandidateCount: 2,
        rawCandidateCountByType: ["coughLike": 1, "environmentalNoise": 1],
        rejectReasonTop: [OfflineEvaluationReasonCount(reason: "likelyEnvironmentalNoise", count: 1)]
      ),
    ]
    let comparison = OfflineProfileComparisonRunner().makeComparison(
      outputs: [
        OfflineEvaluationOutput(
          summary: OfflineEvaluationRunSummary(records: records, manifestSegmentCount: 2),
          records: records
        )
      ]
    )

    let report = OfflineProfileComparisonRunner.makeMarkdownReport(comparison)

    #expect(report.contains("## Quick Comparison"))
    #expect(report.contains("| Lowest zero-event rate | sensitive | 0/2 (0.0%) |"))
    #expect(report.contains("| Release default guard | balanced | 2/2 (100.0%), FP-like 0, FN-like 1 |"))
    #expect(report.contains("## Recall / Risk Matrix"))
    #expect(report.contains("| balanced | 2 | 0 | 2/2 (100.0%) | 1 -> 0 | none | belowConfidenceThreshold: 3 |"))
    #expect(report.contains("| sensitive | 2 | 0 | 0/2 (0.0%) | 5 -> 2 | environmentalNoise: 1, snore: 1 | likelyEnvironmentalNoise: 1 |"))
    #expect(report.contains("## Snore / Negative Snapshot"))
    #expect(report.contains("| balanced | 0/1 (0.0%) | 1 | 0/1 (0.0%) | 0 | expected snore 누락 record의 reject reason과 smoothing drop을 확인하세요. |"))
    #expect(report.contains("| sensitive | 1/1 (100.0%) | 0 | 0/1 (0.0%) | 1 | 현재 labeled set에서는 snore hit와 negative guard가 함께 유지됩니다. |"))
    #expect(report.contains("## Public Negative Raw Event Mix"))
    #expect(report.contains("| balanced | 1 | 0 | 0 | 0 | 0 | 0 | none | 현재 public negative에서는 raw event 후보가 거의 없습니다. |"))
    #expect(report.contains("| sensitive | 1 | 0 | 1 | 0 | 0 | 1 | coughLike: 1, environmentalNoise: 1 | negative에서 transient raw 후보가 남았습니다. cough/bruxism/movement guard 변화를 추적하세요. |"))
    #expect(report.contains("## Delta From Balanced"))
    #expect(report.contains("| balanced | 0 | 0 | 0 | 0 | Release 기본 profile 기준선입니다. |"))
    #expect(report.contains("| sensitive | +2 | -2 | +1 | -1 | balanced보다 FP-like가 늘었습니다. Release 기본값 후보로 바로 올리지 마세요. |"))
    #expect(report.contains("## Zero Event Stage Breakdown"))
    #expect(report.contains("| balanced | 2 | 1 | 1 | 1 | 0 | belowConfidenceThreshold: 3 | raw 후보가 smoothing/final 단계에서 사라지는지 확인하세요. |"))
    #expect(report.contains("| sensitive | 0 | 0 | 0 | 0 | 0 | likelyEnvironmentalNoise: 1 | quiet/noise segment의 false-positive-like guard를 확인하세요. |"))
  }

  @Test
  func emptyComparisonDoesNotProduceWritableReport() {
    let outputDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("NightBreathEmptyProfileCompare-\(UUID().uuidString)", isDirectory: true)
    let comparison = OfflineProfileComparisonRunner().makeComparison(outputs: [])

    #expect(comparison.profileSummaries.isEmpty)
    #expect(throws: OfflineProfileComparisonError.emptyInput) {
      try OfflineProfileComparisonRunner().write(comparison: comparison, to: outputDirectory)
    }
  }

  @Test
  func allFailedRecordsStillProduceFailureSummary() {
    let failedRecord = OfflineEvaluationRecord(
      evaluatedAt: Date(timeIntervalSince1970: 1_800_000_000),
      detectorBackend: "Rule-based",
      tuningProfile: "balanced",
      datasetName: "unit-test",
      fileId: "missing",
      filePath: "missing.caf",
      segmentStartSeconds: 0,
      segmentDurationSeconds: 10,
      expectedLabels: ["snore"],
      errorMessage: "파일을 읽을 수 없습니다."
    )
    let comparison = OfflineProfileComparisonRunner().makeComparison(
      outputs: [
        OfflineEvaluationOutput(
          summary: OfflineEvaluationRunSummary(records: [failedRecord], manifestSegmentCount: 1),
          records: [failedRecord]
        )
      ]
    )

    #expect(comparison.profileSummaries.count == 1)
    #expect(comparison.profileSummaries.first?.failedRecords == 1)
    #expect(comparison.profileSummaries.first?.zeroEventCount == 0)
  }

  private func makeRecord(
    profile: String,
    fileId: String,
    expectedLabels: [String],
    finalEventCountByType: [String: Int],
    rawCandidateCount: Int,
    rawCandidateCountByType: [String: Int]? = nil,
    averageConfidence: Double? = nil,
    rejectReasonTop: [OfflineEvaluationReasonCount] = []
  ) -> OfflineEvaluationRecord {
    OfflineEvaluationRecord(
      evaluatedAt: Date(timeIntervalSince1970: 1_800_000_000),
      detectorBackend: "Rule-based",
      tuningProfile: profile,
      datasetName: "unit-test",
      fileId: fileId,
      filePath: "local-only.caf",
      segmentStartSeconds: 0,
      segmentDurationSeconds: 10,
      expectedLabels: expectedLabels,
      rawCandidateCount: rawCandidateCount,
      averageConfidence: averageConfidence,
      rawCandidateCountByType: rawCandidateCountByType ?? (rawCandidateCount > 0 ? ["snore": rawCandidateCount] : [:]),
      preSmoothingCandidateCount: rawCandidateCount,
      postSmoothingEventCount: finalEventCountByType.values.reduce(0, +),
      finalEventCountByType: finalEventCountByType,
      rejectReasonTop: rejectReasonTop
    )
  }
}
