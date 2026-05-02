import Foundation

public struct ModelInput: Equatable, Sendable {
    public var timestamp: Date
    public var duration: TimeInterval
    public var featureNames: [String]
    public var featureVector: [Double]
    public var debugSummary: String

    public init(
        timestamp: Date,
        duration: TimeInterval,
        featureNames: [String],
        featureVector: [Double],
        debugSummary: String
    ) {
        self.timestamp = timestamp
        self.duration = max(0, duration)
        self.featureNames = featureNames
        self.featureVector = featureVector.map(Self.finite)
        self.debugSummary = debugSummary
    }

    private static func finite(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return value
    }
}

public struct ModelInputAdapter: Sendable {
    public static let featureNames: [String] = [
        "rms",
        "energy",
        "zeroCrossingRate",
        "spectralCentroid",
        "lowBandEnergy",
        "midBandEnergy",
        "highBandEnergy",
        "estimatedNoiseLevel"
    ]

    public init() {}

    public func makeInput(from features: AudioFeatures) -> ModelInput {
        ModelInput(
            timestamp: features.timestamp,
            duration: features.duration,
            featureNames: Self.featureNames,
            featureVector: [
                features.rms,
                features.energy,
                features.zeroCrossingRate,
                features.spectralCentroid,
                features.lowBandEnergy,
                features.midBandEnergy,
                features.highBandEnergy,
                features.estimatedNoiseLevel
            ],
            debugSummary: features.debugSummary
        )
    }
}
