import Foundation

public struct LabeledAudioSample: Codable, Equatable, Identifiable, Sendable {
    public var sampleId: UUID
    public var label: SampleLabel
    public var capturedAt: Date
    public var duration: TimeInterval
    public var sampleRate: Double
    public var channelCount: Int
    public var rms: Double
    public var energy: Double
    public var zeroCrossingRate: Double
    public var spectralCentroid: Double
    public var lowBandEnergy: Double
    public var midBandEnergy: Double
    public var highBandEnergy: Double
    public var notes: String
    public var appVersion: String
    public var deviceModel: String
    public var audioFileName: String
    public var metadataFileName: String
    public var featureCSVFileName: String

    public var id: UUID {
        sampleId
    }

    public init(
        sampleId: UUID = UUID(),
        label: SampleLabel,
        capturedAt: Date,
        duration: TimeInterval,
        sampleRate: Double,
        channelCount: Int,
        rms: Double,
        energy: Double,
        zeroCrossingRate: Double,
        spectralCentroid: Double,
        lowBandEnergy: Double,
        midBandEnergy: Double,
        highBandEnergy: Double,
        notes: String,
        appVersion: String,
        deviceModel: String,
        audioFileName: String,
        metadataFileName: String,
        featureCSVFileName: String
    ) {
        self.sampleId = sampleId
        self.label = label
        self.capturedAt = capturedAt
        self.duration = max(0, duration)
        self.sampleRate = max(1, sampleRate)
        self.channelCount = max(1, channelCount)
        self.rms = Self.clamp(rms)
        self.energy = Self.finiteNonNegative(energy)
        self.zeroCrossingRate = Self.clamp(zeroCrossingRate)
        self.spectralCentroid = Self.finiteNonNegative(spectralCentroid)
        self.lowBandEnergy = Self.clamp(lowBandEnergy)
        self.midBandEnergy = Self.clamp(midBandEnergy)
        self.highBandEnergy = Self.clamp(highBandEnergy)
        self.notes = notes
        self.appVersion = appVersion
        self.deviceModel = deviceModel
        self.audioFileName = audioFileName
        self.metadataFileName = metadataFileName
        self.featureCSVFileName = featureCSVFileName
    }

    public init(
        label: SampleLabel,
        capturedAt: Date,
        features: AudioFeatures,
        notes: String,
        appVersion: String,
        deviceModel: String,
        audioFileName: String,
        metadataFileName: String,
        featureCSVFileName: String
    ) {
        self.init(
            label: label,
            capturedAt: capturedAt,
            duration: features.duration,
            sampleRate: features.sampleRate,
            channelCount: features.channelCount,
            rms: features.rms,
            energy: features.energy,
            zeroCrossingRate: features.zeroCrossingRate,
            spectralCentroid: features.spectralCentroid,
            lowBandEnergy: features.lowBandEnergy,
            midBandEnergy: features.midBandEnergy,
            highBandEnergy: features.highBandEnergy,
            notes: notes,
            appVersion: appVersion,
            deviceModel: deviceModel,
            audioFileName: audioFileName,
            metadataFileName: metadataFileName,
            featureCSVFileName: featureCSVFileName
        )
    }

    private static func clamp(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }

    private static func finiteNonNegative(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return max(0, value)
    }
}
