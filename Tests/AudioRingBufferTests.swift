import Foundation
import Testing
@testable import SleepSoundCore

@Suite("AudioRingBuffer")
struct AudioRingBufferTests {
    @Test
    func keepsOnlyRecentChunksByCount() {
        var buffer = AudioRingBuffer(maxChunkCount: 3)

        buffer.append(makeChunk(index: 0))
        buffer.append(makeChunk(index: 1))
        buffer.append(makeChunk(index: 2))
        buffer.append(makeChunk(index: 3))

        let snapshot = buffer.snapshot()

        #expect(snapshot.count == 3)
        #expect(snapshot.map(\.samples.first) == [1, 2, 3])
    }

    @Test
    func keepsOnlyRecentChunksByDuration() {
        var buffer = AudioRingBuffer(maxChunkCount: 10, maxDuration: 2.5)

        buffer.append(makeChunk(index: 0, duration: 1))
        buffer.append(makeChunk(index: 1, duration: 1))
        buffer.append(makeChunk(index: 2, duration: 1))

        let snapshot = buffer.snapshot()

        #expect(snapshot.count == 2)
        #expect(buffer.retainedDuration == 2)
        #expect(snapshot.map(\.samples.first) == [1, 2])
    }

    @Test
    func ignoresInvalidChunks() {
        var buffer = AudioRingBuffer(maxChunkCount: 3)

        buffer.append(makeChunk(index: 0, duration: 0))
        buffer.append(makeChunk(index: 1, duration: -1))
        buffer.append(makeChunk(index: 2, duration: 1))

        #expect(buffer.count == 1)
        #expect(buffer.snapshot().first?.samples.first == 2)
    }

    private func makeChunk(index: Int, duration: TimeInterval = 1) -> AudioChunk {
        AudioChunk(
            timestamp: Date(timeIntervalSince1970: Double(index)),
            sampleRate: 16_000,
            channelCount: 1,
            frameCount: 16_000,
            duration: duration,
            rms: 0.1,
            samples: [Float(index)]
        )
    }
}
