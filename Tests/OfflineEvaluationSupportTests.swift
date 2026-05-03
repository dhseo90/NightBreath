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
    #expect(manifest.segments.first?.expectedLabels == [.snore])
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
    #expect(records.first?.errorMessage != nil)
    #expect(records.first?.rawCandidateCount == 0)
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

  private func makeSegment(
    filePath: String,
    fileId: String,
    duration: TimeInterval = 1
  ) -> OfflineEvaluationManifestSegment {
    OfflineEvaluationManifestSegment(
      datasetName: "unit-test",
      filePath: filePath,
      fileId: fileId,
      segmentStartSeconds: 0,
      segmentDurationSeconds: duration,
      expectedLabels: [.snore],
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

  private func writeCAF(samples: [Float], sampleRate: Double) throws -> URL {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("caf")
    let format = AVAudioFormat(
      commonFormat: .pcmFormatFloat32,
      sampleRate: sampleRate,
      channels: 1,
      interleaved: false
    )!
    let file = try AVAudioFile(forWriting: url, settings: format.settings)
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
    return url
  }

  private func snoreLikeSamples(duration: TimeInterval, sampleRate: Double) -> [Float] {
    let frameCount = Int(duration * sampleRate)
    return (0..<frameCount).map { frame in
      let t = Double(frame) / sampleRate
      return Float(sin(2 * Double.pi * 120 * t) * 0.13)
    }
  }
}
