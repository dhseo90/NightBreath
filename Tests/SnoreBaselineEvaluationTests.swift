import Foundation
import OfflineEvaluationSupport
import SleepSoundCore
import Testing

@Suite("Snore Baseline Evaluation")
struct SnoreBaselineEvaluationTests {
  @Test
  func generatesBaselineJSONCSVAndMarkdown() throws {
    let outputDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("NightBreathSnoreBaseline-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: outputDirectory) }
    let runner = SnoreBaselineEvaluationRunner()
    let output = runner.makeOutput(
      evaluationRecords: [
        makeRecord(
          profile: "balanced",
          fileId: "snore-1",
          expectedLabels: ["snore"],
          finalEventCountByType: ["snore": 1],
          rawCandidateCount: 2
        )
      ],
      manifestSegmentCount: 1,
      generatedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )

    let result = try runner.write(
      output: output,
      to: outputDirectory,
      generatedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )

    #expect(FileManager.default.fileExists(atPath: result.jsonURL.path))
    #expect(FileManager.default.fileExists(atPath: result.csvURL.path))
    #expect(FileManager.default.fileExists(atPath: result.markdownURL.path))
    #expect(result.markdownURL.lastPathComponent == "snore_baseline_report.md")

    let csv = try String(contentsOf: result.csvURL, encoding: .utf8)
    let report = try String(contentsOf: result.markdownURL, encoding: .utf8)
    #expect(csv.contains("finalSnoreEventCount"))
    #expect(csv.contains("possibleFalseNegative"))
    #expect(report.contains("Snore Baseline Report"))
    #expect(report.contains("Profile Summary"))
  }

  @Test
  func classifiesPossibleFalsePositiveLikeSnoreCases() {
    let record = SnoreBaselineRecord(
      evaluationRecord: makeRecord(
        profile: "sensitive",
        fileId: "quiet-1",
        expectedLabels: ["silence", "unknown"],
        finalEventCountByType: ["snore": 2],
        rawCandidateCount: 3
      )
    )

    #expect(record.possibleFalsePositive)
    #expect(!record.possibleFalseNegative)
  }

  @Test
  func classifiesPossibleFalseNegativeLikeSnoreCases() {
    let record = SnoreBaselineRecord(
      evaluationRecord: makeRecord(
        profile: "balanced",
        fileId: "snore-expected",
        expectedLabels: ["snore"],
        finalEventCountByType: [:],
        rawCandidateCount: 1
      )
    )

    #expect(record.possibleFalseNegative)
    #expect(!record.possibleFalsePositive)
  }

  @Test
  func emptyManifestOutputWritesReportWithoutThrowing() throws {
    let outputDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("NightBreathEmptySnoreBaseline-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: outputDirectory) }
    let runner = SnoreBaselineEvaluationRunner()
    let output = runner.makeOutput(
      evaluationRecords: [],
      manifestSegmentCount: 0,
      generatedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )
    let result = try runner.write(
      output: output,
      to: outputDirectory,
      generatedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )
    let report = try String(contentsOf: result.markdownURL, encoding: .utf8)

    #expect(output.summary.evaluatedSegments == 0)
    #expect(output.summary.evaluatedRecords == 0)
    #expect(report.contains("평가 record가 없습니다"))
  }

  @Test
  func summarizesProfilesForComparison() {
    let output = SnoreBaselineEvaluationRunner().makeOutput(
      evaluationRecords: [
        makeRecord(
          profile: "balanced",
          fileId: "snore-1",
          expectedLabels: ["snore"],
          finalEventCountByType: [:],
          rawCandidateCount: 1,
          rejectReasonTop: [OfflineEvaluationReasonCount(reason: "belowConfidenceThreshold", count: 2)]
        ),
        makeRecord(
          profile: "sensitive",
          fileId: "snore-1",
          expectedLabels: ["snore"],
          finalEventCountByType: ["snore": 1],
          rawCandidateCount: 3
        ),
        makeRecord(
          profile: "sensitive",
          fileId: "quiet-1",
          expectedLabels: ["environmentalNoise"],
          finalEventCountByType: ["snore": 1],
          rawCandidateCount: 2
        ),
      ],
      manifestSegmentCount: 2
    )

    let balanced = try! #require(
      output.summary.profileSummaries.first { $0.detectorProfile == "balanced" }
    )
    let sensitive = try! #require(
      output.summary.profileSummaries.first { $0.detectorProfile == "sensitive" }
    )

    #expect(output.summary.profileSummaries.count == 2)
    #expect(balanced.possibleFalseNegativeCount == 1)
    #expect(balanced.topRejectReasons.first?.reason == "belowConfidenceThreshold")
    #expect(sensitive.finalSnoreEventCount == 2)
    #expect(sensitive.possibleFalsePositiveCount == 1)
  }

  private func makeRecord(
    profile: String,
    fileId: String,
    expectedLabels: [String],
    finalEventCountByType: [String: Int],
    rawCandidateCount: Int,
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
      averageConfidence: rawCandidateCount > 0 ? 0.72 : nil,
      confidenceSummary: rawCandidateCount > 0
        ? SummaryStats.make(values: Array(repeating: 0.72, count: rawCandidateCount))
        : SummaryStats(),
      rawCandidateCountByType: rawCandidateCount > 0 ? ["snore": rawCandidateCount] : [:],
      preSmoothingCandidateCount: rawCandidateCount,
      postSmoothingEventCount: finalEventCountByType.values.reduce(0, +),
      finalEventCountByType: finalEventCountByType,
      rejectReasonTop: rejectReasonTop
    )
  }
}
