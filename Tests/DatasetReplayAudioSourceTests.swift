import AVFoundation
import Foundation
import Testing

@testable import SleepSoundCore

@Suite("DatasetReplayAudioSource")
struct DatasetReplayAudioSourceTests {
  @Test
  func loadChunksCalculatesFrameDurationAndSampleRate() throws {
    let url = try writeCAF(samples: Array(repeating: 0.1, count: 16_000), sampleRate: 16_000)
    defer { try? FileManager.default.removeItem(at: url) }

    let chunks = try DatasetReplayAudioSource.loadChunks(
      fileURL: url,
      chunkDuration: 0.5,
      startedAt: Date(timeIntervalSince1970: 200)
    )

    #expect(chunks.count == 2)
    #expect(chunks.allSatisfy { $0.sampleRate == 16_000 })
    #expect(chunks.reduce(0) { $0 + $1.frameCount } == 16_000)
    #expect(abs(chunks.reduce(0) { $0 + $1.duration } - 1) < 0.0001)
  }

  @Test
  func missingFileThrowsWithoutCrash() {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("wav")

    #expect(throws: AudioSourceError.fileNotFound(url.path)) {
      _ = try DatasetReplayAudioSource.loadChunks(fileURL: url)
    }
  }

  @Test
  func unsupportedExtensionThrowsWithoutCrash() throws {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("txt")
    try "not audio".write(to: url, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: url) }

    #expect(throws: AudioSourceError.unsupportedFileType("txt")) {
      _ = try DatasetReplayAudioSource.loadChunks(fileURL: url)
    }
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
}
