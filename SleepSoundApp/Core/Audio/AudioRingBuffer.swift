import Foundation

public struct AudioRingBuffer {
    public let capacity: Int
    private var samples: [Float]

    public init(capacity: Int) {
        self.capacity = max(1, capacity)
        self.samples = []
    }

    public mutating func append(_ newSamples: [Float]) {
        guard !newSamples.isEmpty else { return }
        samples.append(contentsOf: newSamples)
        if samples.count > capacity {
            samples.removeFirst(samples.count - capacity)
        }
    }

    public func snapshot() -> [Float] {
        samples
    }

    public mutating func removeAll() {
        samples.removeAll(keepingCapacity: true)
    }
}
