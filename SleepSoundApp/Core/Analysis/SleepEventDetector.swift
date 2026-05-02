import Foundation

public protocol SleepEventDetector: Sendable {
    func detect(features: AudioFeatures) -> [DetectorOutput]
}

public extension SleepEventDetector {
    func detect(chunk: AudioChunk) -> [DetectorOutput] {
        detect(chunk: chunk, extractor: AudioFeatureExtractor())
    }

    func detect(chunk: AudioChunk, extractor: any AudioFeatureExtracting) -> [DetectorOutput] {
        detect(features: extractor.extractFeatures(from: chunk))
    }
}

public typealias SleepEventDetecting = SleepEventDetector
