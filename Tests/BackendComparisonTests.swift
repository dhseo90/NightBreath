import Foundation
import OfflineEvaluationSupport
import SleepSoundCore
import Testing

@Suite("Backend Comparison")
struct BackendComparisonTests {
  @Test
  func backendComparisonOutputWritesJSONCSVAndMarkdown() throws {
    let outputDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("NightBreathBackendCompare-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: outputDirectory) }

    let output = BackendComparisonRunner().makeOutput(
      evaluationRecords: [
        makeRecord(backend: .ruleBased, finalEventCountByType: ["snore": 1], confidenceValues: [0.7]),
        makeRecord(backend: .coreML, finalEventCountByType: ["snore": 1], confidenceValues: [0.8]),
        makeRecord(backend: .hybrid, finalEventCountByType: ["snore": 1], confidenceValues: [0.8]),
      ],
      generatedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )

    let result = try BackendComparisonRunner().write(
      output: output,
      to: outputDirectory,
      generatedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )
    let csv = try String(contentsOf: result.csvURL, encoding: .utf8)
    let report = try String(contentsOf: result.markdownURL, encoding: .utf8)

    #expect(FileManager.default.fileExists(atPath: result.jsonURL.path))
    #expect(FileManager.default.fileExists(atPath: result.csvURL.path))
    #expect(FileManager.default.fileExists(atPath: result.markdownURL.path))
    #expect(result.markdownURL.lastPathComponent == "backend_comparison_report.md")
    #expect(csv.contains("disagreementType"))
    #expect(report.contains("Rule-based vs ML Backend Comparison"))
    #expect(report.contains("recommended backend"))
  }

  @Test
  func disagreementClassificationCoversBothNoEvent() throws {
    let record = try #require(
      BackendComparisonRunner.makeRecord(
        records: [
          makeRecord(backend: .ruleBased, finalEventCountByType: [:]),
          makeRecord(backend: .coreML, finalEventCountByType: [:]),
          makeRecord(backend: .hybrid, finalEventCountByType: [:]),
        ]
      )
    )

    #expect(record.disagreementType == .bothNoEvent)
    #expect(record.zeroEventReasonByBackend.keys.sorted() == ["coreML", "hybrid", "ruleBased"])
  }

  @Test
  func disagreementClassificationCoversRuleOnlySnore() throws {
    let record = try #require(
      BackendComparisonRunner.makeRecord(
        records: [
          makeRecord(backend: .ruleBased, expectedLabels: ["snore"], finalEventCountByType: ["snore": 1]),
          makeRecord(backend: .coreML, expectedLabels: ["snore"], finalEventCountByType: [:]),
          makeRecord(backend: .hybrid, expectedLabels: ["snore"], finalEventCountByType: ["snore": 1]),
        ]
      )
    )

    #expect(record.disagreementType == .ruleOnlySnore)
    #expect(record.possibleFalseNegativeBackend == ["coreML"])
  }

  @Test
  func disagreementClassificationCoversMLOnlySnore() throws {
    let record = try #require(
      BackendComparisonRunner.makeRecord(
        records: [
          makeRecord(backend: .ruleBased, expectedLabels: ["snore"], finalEventCountByType: [:]),
          makeRecord(backend: .coreML, expectedLabels: ["snore"], finalEventCountByType: ["snore": 1]),
          makeRecord(backend: .hybrid, expectedLabels: ["snore"], finalEventCountByType: ["snore": 1]),
        ]
      )
    )

    #expect(record.disagreementType == .mlOnlySnore)
    #expect(record.possibleFalseNegativeBackend == ["ruleBased"])
  }

  @Test
  func emptyModelFallbackCaseDoesNotCrashAndKeepsHybridRecommendation() {
    let output = BackendComparisonRunner().makeOutput(
      evaluationRecords: [
        makeRecord(backend: .ruleBased, expectedLabels: ["snore"], finalEventCountByType: ["snore": 1]),
        makeRecord(
          backend: .coreML,
          expectedLabels: ["snore"],
          finalEventCountByType: [:],
          zeroEventReason: ZeroEventProbableReason.modelUnavailableFallback.rawValue
        ),
        makeRecord(backend: .hybrid, expectedLabels: ["snore"], finalEventCountByType: ["snore": 1]),
      ]
    )

    #expect(output.records.count == 1)
    #expect(output.records.first?.disagreementType == .ruleOnlySnore)
    #expect(output.records.first?.zeroEventReasonByBackend["coreML"] == "modelUnavailableFallback")
    #expect(output.summary.recommendedBackendForNextIteration.contains("hybrid"))
  }

  private func makeRecord(
    backend: SleepDetectionBackend,
    fileId: String = "segment-1",
    expectedLabels: [String] = ["snore"],
    finalEventCountByType: [String: Int],
    confidenceValues: [Double] = [],
    zeroEventReason: String? = "unknown"
  ) -> OfflineEvaluationRecord {
    let rawCandidateCount = max(finalEventCountByType.values.reduce(0, +), confidenceValues.count)
    return OfflineEvaluationRecord(
      evaluatedAt: Date(timeIntervalSince1970: 1_800_000_000),
      detectorBackend: backend.displayName,
      tuningProfile: DetectorTuningProfile.balanced.rawValue,
      datasetName: "unit-test",
      fileId: fileId,
      filePath: "local-only.caf",
      segmentStartSeconds: 0,
      segmentDurationSeconds: 10,
      expectedLabels: expectedLabels,
      rawCandidateCount: rawCandidateCount,
      averageConfidence: confidenceValues.isEmpty
        ? nil
        : confidenceValues.reduce(0, +) / Double(confidenceValues.count),
      confidenceSummary: SummaryStats.make(values: confidenceValues),
      rawCandidateCountByType: finalEventCountByType,
      preSmoothingCandidateCount: rawCandidateCount,
      postSmoothingEventCount: finalEventCountByType.values.reduce(0, +),
      finalEventCountByType: finalEventCountByType,
      zeroEventReason: finalEventCountByType.isEmpty ? zeroEventReason : nil
    )
  }
}
