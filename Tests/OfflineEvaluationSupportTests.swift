import AVFoundation
import Foundation
import OfflineEvaluationSupport
import Testing

@testable import SleepSoundCore

@Suite("OfflineEvaluationSupport")
struct OfflineEvaluationSupportTests {
  @Test
  func parsesManifestSegments() throws {
    let manifestURL = try writeManifest(
      segments: [
        makeSegment(filePath: "sample.caf", fileId: "segment-1")
      ]
    )
    defer { try? FileManager.default.removeItem(at: manifestURL) }

    let manifest = try OfflineEvaluationRunner().loadManifest(from: manifestURL)

    #expect(manifest.segments.count == 1)
    #expect(manifest.segments.first?.datasetName == "unit-test")
    #expect(manifest.segments.first?.localFilePath == "sample.caf")
    #expect(manifest.segments.first?.expectedLabels == ["snore"])
  }

  @Test
  func topLevelDatasetFieldsApplyToSegments() throws {
    let manifestURL = try writeRawManifest(
      """
      {
        "datasetName": "top-level-dataset",
        "datasetLicenseNote": "local unit fixture",
        "segments": [
          {
            "fileId": "segment-1",
            "localFilePath": "sample.caf",
            "recordingType": "personalDebugSample",
            "microphoneType": "unknown",
            "segmentStartSeconds": 0,
            "segmentDurationSeconds": 1,
            "expectedLabels": ["silence"]
          }
        ]
      }
      """
    )
    defer { try? FileManager.default.removeItem(at: manifestURL) }

    let runner = OfflineEvaluationRunner()
    let manifest = try runner.loadManifest(from: manifestURL)
    let validation = runner.validateManifest(
      manifest,
      manifestDirectory: manifestURL.deletingLastPathComponent()
    )

    #expect(manifest.segments.first?.datasetName == "top-level-dataset")
    #expect(manifest.segments.first?.datasetLicenseNote == "local unit fixture")
    #expect(validation.validSegmentCount == 1)
    #expect(validation.missingRequiredFields.isEmpty)
  }

  @Test
  func writesCSVAndJSONOutput() throws {
    let outputDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: outputDirectory) }
    let evaluatedAt = Date(timeIntervalSince1970: 1_800_000_000)
    let record = OfflineEvaluationRecord(
      evaluatedAt: evaluatedAt,
      detectorBackend: "Rule-based",
      tuningProfile: "balanced",
      datasetName: "unit-test",
      fileId: "file-1",
      filePath: "sample.caf",
      segmentStartSeconds: 0,
      segmentDurationSeconds: 2,
      expectedLabels: ["snore"],
      rawCandidateCount: 1,
      finalEventCountByType: ["snore": 1],
      scoreSummary: OfflineEvaluationScoreSummary(
        sleepSoundScore: 92,
        mainDisturbanceReason: "어젯밤은 비교적 조용하고 안정적인 수면 소리 패턴을 보였습니다."
      )
    )
    let output = OfflineEvaluationOutput(
      summary: OfflineEvaluationRunSummary(records: [record], manifestSegmentCount: 1),
      records: [record]
    )

    let result = try OfflineEvaluationRunner().write(
      output: output,
      to: outputDirectory,
      evaluatedAt: evaluatedAt
    )

    #expect(FileManager.default.fileExists(atPath: result.csvURL.path))
    #expect(FileManager.default.fileExists(atPath: result.jsonURL.path))
    let csv = try String(contentsOf: result.csvURL)
    #expect(csv.contains("sleepSoundScore"))
    #expect(csv.contains("balanced"))
  }

  @Test
  func evaluatesAllRequestedProfiles() throws {
    let audioURL = try writeCAF(
      samples: snoreLikeSamples(duration: 2, sampleRate: 16_000), sampleRate: 16_000)
    defer { try? FileManager.default.removeItem(at: audioURL) }
    let manifest = OfflineEvaluationManifest(
      segments: [
        makeSegment(filePath: audioURL.path, fileId: "snore-1", duration: 2)
      ]
    )

    let records = OfflineEvaluationRunner().evaluateRecords(
      manifest: manifest,
      manifestDirectory: FileManager.default.temporaryDirectory,
      profiles: [.conservative, .balanced, .sensitive],
      evaluatedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )

    #expect(records.count == 3)
    #expect(Set(records.map(\.tuningProfile)) == ["conservative", "balanced", "sensitive"])
    #expect(records.allSatisfy { $0.errorMessage == nil })
  }

  @Test
  func evaluatesLocalShortSampleManifestAndWritesDiagnostics() throws {
    let root = FileManager.default.temporaryDirectory
      .appendingPathComponent("NightBreathOfflineLocalSample-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let sampleURL = root.appendingPathComponent("debug-snore-short.caf")
    try writeCAF(
      samples: snoreLikeSamples(duration: 2, sampleRate: 16_000),
      sampleRate: 16_000,
      targetURL: sampleURL
    )
    let manifestURL = root.appendingPathComponent("manifest.json")
    let outputDirectory = root.appendingPathComponent("output", isDirectory: true)
    let manifest = OfflineEvaluationManifest(
      datasetName: "local-debug-short-samples",
      datasetLicenseNote: "local synthetic fixture only",
      segments: [
        makeSegment(filePath: "debug-snore-short.caf", fileId: "debug-snore-short", duration: 2)
      ]
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(manifest).write(to: manifestURL)

    let result = try OfflineEvaluationRunner().evaluate(
      manifestURL: manifestURL,
      outputDirectory: outputDirectory,
      profiles: [.balanced],
      backends: [.ruleBased],
      evaluatedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )

    let record = try #require(result.output.records.first)
    #expect(record.errorMessage == nil)
    #expect(record.filePath == "debug-snore-short.caf")
    #expect(record.receivedAudioSeconds == 2)
    #expect(record.rmsSummary.p90 > 0)
    #expect(record.energySummary.p90 > 0)
    #expect(record.rawCandidateCountByType[SleepEventType.snore.rawValue, default: 0] > 0)
    #expect(FileManager.default.fileExists(atPath: result.csvURL.path))
    #expect(FileManager.default.fileExists(atPath: result.jsonURL.path))

    let csv = try String(contentsOf: result.csvURL, encoding: .utf8)
    #expect(csv.contains("rawCandidateCount"))
    #expect(csv.contains("rejectReasonTop"))
    #expect(csv.contains("rmsP90"))
    #expect(csv.contains("energyP90"))
  }

  @Test
  func balancedOfflineEvaluationDetectsLowAmplitudeSnoreAndGuardsNegativeSamples() throws {
    let root = FileManager.default.temporaryDirectory
      .appendingPathComponent("NightBreathSnoreRecallGuard-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let snoreURL = root.appendingPathComponent("synthetic-low-amplitude-snore.caf")
    let noiseURL = root.appendingPathComponent("synthetic-high-frequency-negative.caf")
    try writeCAF(
      samples: lowAmplitudeSnoreLikeSamples(duration: 2, sampleRate: 16_000),
      sampleRate: 16_000,
      targetURL: snoreURL
    )
    try writeCAF(
      samples: highFrequencyNegativeSamples(duration: 2, sampleRate: 16_000),
      sampleRate: 16_000,
      targetURL: noiseURL
    )

    let manifest = OfflineEvaluationManifest(
      datasetName: "local-synthetic-recall-guard",
      datasetLicenseNote: "local synthetic fixture only",
      segments: [
        makeSegment(
          filePath: "synthetic-low-amplitude-snore.caf",
          fileId: "low-amplitude-snore",
          duration: 2,
          expectedLabels: [.snore]
        ),
        makeSegment(
          filePath: "synthetic-high-frequency-negative.caf",
          fileId: "high-frequency-negative",
          duration: 2,
          expectedLabels: [.environmentalNoise]
        )
      ]
    )

    let records = OfflineEvaluationRunner().evaluateRecords(
      manifest: manifest,
      manifestDirectory: root,
      profiles: [.balanced],
      backends: [.ruleBased],
      evaluatedAt: Date(timeIntervalSince1970: 1_800_000_001)
    )
    let byFileId = Dictionary(uniqueKeysWithValues: records.map { ($0.fileId, $0) })
    let snoreRecord = try #require(byFileId["low-amplitude-snore"])
    let noiseRecord = try #require(byFileId["high-frequency-negative"])

    #expect(snoreRecord.errorMessage == nil)
    #expect(snoreRecord.rawCandidateCountByType[SleepEventType.snore.rawValue, default: 0] > 0)
    #expect(snoreRecord.finalEventCountByType[SleepEventType.snore.rawValue, default: 0] > 0)
    #expect(noiseRecord.errorMessage == nil)
    #expect(noiseRecord.rawCandidateCountByType[SleepEventType.snore.rawValue, default: 0] == 0)
    #expect(noiseRecord.finalEventCountByType[SleepEventType.snore.rawValue, default: 0] == 0)
  }

  @Test
  func missingFileCreatesFailedRecordWithoutThrowing() {
    let manifest = OfflineEvaluationManifest(
      segments: [
        makeSegment(filePath: "/tmp/missing-\(UUID().uuidString).wav", fileId: "missing")
      ]
    )

    let records = OfflineEvaluationRunner().evaluateRecords(
      manifest: manifest,
      manifestDirectory: FileManager.default.temporaryDirectory,
      profiles: [.balanced],
      evaluatedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )

    #expect(records.count == 1)
    #expect(records.first?.errorMessage?.contains("오디오 파일을 찾을 수 없습니다") == true)
    #expect(records.first?.rawCandidateCount == 0)
  }

  @Test
  func missingFileCreatesManifestWarning() {
    let manifest = OfflineEvaluationManifest(
      segments: [
        makeSegment(filePath: "/tmp/missing-\(UUID().uuidString).wav", fileId: "missing")
      ]
    )

    let validation = OfflineEvaluationRunner().validateManifest(
      manifest,
      manifestDirectory: FileManager.default.temporaryDirectory
    )

    #expect(validation.validSegmentCount == 1)
    #expect(validation.missingFiles.count == 1)
    #expect(validation.unsupportedLabels.isEmpty)
  }

  @Test
  func invalidLabelCreatesWarningWithoutDecodeFailure() throws {
    let manifestURL = try writeRawManifest(
      """
      {
        "datasetName": "unit-test",
        "datasetLicenseNote": "local unit fixture",
        "segments": [
          {
            "fileId": "invalid-label",
            "localFilePath": "sample.caf",
            "recordingType": "personalDebugSample",
            "microphoneType": "unknown",
            "segmentStartSeconds": 0,
            "segmentDurationSeconds": 1,
            "expectedLabels": ["snore", "notALabel"]
          }
        ]
      }
      """
    )
    defer { try? FileManager.default.removeItem(at: manifestURL) }

    let runner = OfflineEvaluationRunner()
    let manifest = try runner.loadManifest(from: manifestURL)
    let validation = runner.validateManifest(
      manifest,
      manifestDirectory: manifestURL.deletingLastPathComponent()
    )

    #expect(manifest.segments.first?.expectedLabels == ["snore", "notALabel"])
    #expect(validation.validSegmentCount == 0)
    #expect(validation.unsupportedLabels.count == 1)
    #expect(validation.unsupportedLabels.first?.value == "notALabel")
  }

  @Test
  func emptyManifestProducesEmptyOutput() {
    let records = OfflineEvaluationRunner().evaluateRecords(
      manifest: OfflineEvaluationManifest(segments: []),
      manifestDirectory: FileManager.default.temporaryDirectory,
      profiles: [.balanced],
      evaluatedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )
    let summary = OfflineEvaluationRunSummary(records: records, manifestSegmentCount: 0)

    #expect(records.isEmpty)
    #expect(summary.evaluatedSegments == 0)
    #expect(summary.evaluatedRecords == 0)
  }

  @Test
  func emptyManifestValidationProducesNoWarnings() {
    let validation = OfflineEvaluationRunner().validateManifest(
      OfflineEvaluationManifest(segments: []),
      manifestDirectory: FileManager.default.temporaryDirectory
    )

    #expect(validation.totalSegments == 0)
    #expect(validation.validSegmentCount == 0)
    #expect(!validation.hasBlockingIssues)
  }

  @Test
  func missingLicenseNoteCreatesWarning() {
    let manifest = OfflineEvaluationManifest(
      segments: [
        OfflineEvaluationManifestSegment(
          datasetName: "unit-test",
          datasetLicenseNote: nil,
          fileId: "no-license-note",
          localFilePath: "/tmp/missing-\(UUID().uuidString).wav",
          recordingType: "personalDebugSample",
          microphoneType: "unknown",
          segmentStartSeconds: 0,
          segmentDurationSeconds: 1,
          expectedLabels: ["silence"]
        )
      ]
    )

    let validation = OfflineEvaluationRunner().validateManifest(
      manifest,
      manifestDirectory: FileManager.default.temporaryDirectory
    )

    #expect(validation.validSegmentCount == 1)
    #expect(validation.licenseWarnings.count == 1)
    #expect(validation.licenseWarnings.first?.field == "datasetLicenseNote")
  }

  private func makeSegment(
    filePath: String,
    fileId: String,
    duration: TimeInterval = 1,
    expectedLabels: [SleepEventType] = [.snore]
  ) -> OfflineEvaluationManifestSegment {
    OfflineEvaluationManifestSegment(
      datasetName: "unit-test",
      filePath: filePath,
      fileId: fileId,
      segmentStartSeconds: 0,
      segmentDurationSeconds: duration,
      expectedLabels: expectedLabels,
      notes: "synthetic fixture",
      licenseNote: "local synthetic test fixture"
    )
  }

  private func writeManifest(segments: [OfflineEvaluationManifestSegment]) throws -> URL {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("json")
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(OfflineEvaluationManifest(segments: segments))
    try data.write(to: url)
    return url
  }

  private func writeRawManifest(_ json: String) throws -> URL {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("json")
    try json.write(to: url, atomically: true, encoding: .utf8)
    return url
  }

  @discardableResult
  private func writeCAF(samples: [Float], sampleRate: Double, targetURL: URL? = nil) throws -> URL {
    let generatedURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("caf")
    let resolvedURL = targetURL ?? generatedURL
    let format = AVAudioFormat(
      commonFormat: .pcmFormatFloat32,
      sampleRate: sampleRate,
      channels: 1,
      interleaved: false
    )!
    let file = try AVAudioFile(forWriting: resolvedURL, settings: format.settings)
    let buffer = AVAudioPCMBuffer(
      pcmFormat: format,
      frameCapacity: AVAudioFrameCount(samples.count)
    )!
    buffer.frameLength = AVAudioFrameCount(samples.count)
    let channel = buffer.floatChannelData![0]
    for index in samples.indices {
      channel[index] = samples[index]
    }
    try file.write(from: buffer)
    return resolvedURL
  }

  private func snoreLikeSamples(duration: TimeInterval, sampleRate: Double) -> [Float] {
    let frameCount = Int(duration * sampleRate)
    return (0..<frameCount).map { frame in
      let t = Double(frame) / sampleRate
      return Float(sin(2 * Double.pi * 120 * t) * 0.13)
    }
  }

  private func lowAmplitudeSnoreLikeSamples(duration: TimeInterval, sampleRate: Double) -> [Float] {
    let frameCount = Int(duration * sampleRate)
    return (0..<frameCount).map { frame in
      let t = Double(frame) / sampleRate
      let envelope = 0.72 + 0.28 * sin(2 * Double.pi * 3 * t)
      return Float(sin(2 * Double.pi * 120 * t) * 0.09 * envelope)
    }
  }

  private func highFrequencyNegativeSamples(duration: TimeInterval, sampleRate: Double) -> [Float] {
    let frameCount = Int(duration * sampleRate)
    return (0..<frameCount).map { frame in
      let t = Double(frame) / sampleRate
      return Float(sin(2 * Double.pi * 3_200 * t) * 0.065)
    }
  }
}
