import Foundation

public struct AudioRingBuffer: Equatable, Sendable {
    public let maxChunkCount: Int
    public let maxDuration: TimeInterval?

    private var chunks: [AudioChunk]

    public init(maxChunkCount: Int, maxDuration: TimeInterval? = nil) {
        self.maxChunkCount = max(1, maxChunkCount)
        if let maxDuration {
            self.maxDuration = max(0, maxDuration)
        } else {
            self.maxDuration = nil
        }
        self.chunks = []
    }

    public init(capacity: Int) {
        self.init(maxChunkCount: capacity)
    }

    public var count: Int {
        chunks.count
    }

    public var isEmpty: Bool {
        chunks.isEmpty
    }

    public var retainedDuration: TimeInterval {
        chunks.reduce(0) { $0 + $1.duration }
    }

    public mutating func append(_ chunk: AudioChunk) {
        guard chunk.duration.isFinite, chunk.duration > 0 else { return }
        chunks.append(chunk)
        trimToLimits()
    }

    public mutating func append(contentsOf newChunks: [AudioChunk]) {
        for chunk in newChunks {
            append(chunk)
        }
    }

    public func snapshot() -> [AudioChunk] {
        chunks
    }

    public func sampleSnapshot() -> [Float] {
        chunks.flatMap(\.samples)
    }

    public mutating func removeAll() {
        chunks.removeAll(keepingCapacity: true)
    }

    private mutating func trimToLimits() {
        if chunks.count > maxChunkCount {
            chunks.removeFirst(chunks.count - maxChunkCount)
        }

        guard let maxDuration, maxDuration > 0 else { return }

        while retainedDuration > maxDuration, chunks.count > 1 {
            chunks.removeFirst()
        }
    }
}
