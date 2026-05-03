import Foundation

public enum DetectorTuningProfile: String, CaseIterable, Codable, Identifiable, Sendable {
    case conservative
    case balanced
    case sensitive
    case customDebug

    public var id: String { rawValue }

    public static var releaseDefault: DetectorTuningProfile { .balanced }

    public static var debugSelectableProfiles: [DetectorTuningProfile] {
        [.conservative, .balanced, .sensitive]
    }

    public var displayName: String {
        switch self {
        case .conservative:
            "Conservative"
        case .balanced:
            "Balanced"
        case .sensitive:
            "Sensitive"
        case .customDebug:
            "Custom Debug"
        }
    }

    public var koreanDescription: String {
        switch self {
        case .conservative:
            "후보를 더 신중하게 남기는 개발용 profile입니다."
        case .balanced:
            "Release 기본값으로 사용할 균형형 profile입니다."
        case .sensitive:
            "짧은 테스트에서 후보 누락 여부를 비교하기 위한 DEBUG profile입니다."
        case .customDebug:
            "개별 threshold 실험을 위한 예약 profile입니다. 현재 앱에서는 읽기 전용으로 둡니다."
        }
    }

    public var configuration: DetectorThresholdConfiguration {
        DetectorThresholdConfiguration.profile(self)
    }

    public var snapshotIndex: Double {
        switch self {
        case .conservative:
            0
        case .balanced:
            1
        case .sensitive:
            2
        case .customDebug:
            3
        }
    }
}

public struct DetectorThresholdConfiguration: Codable, Equatable, Sendable {
    public var profile: DetectorTuningProfile
    public var silenceRmsThreshold: Double
    public var snoreRmsThreshold: Double
    public var snoreEnergyThreshold: Double
    public var coughEnergyThreshold: Double
    public var gaspEnergyThreshold: Double
    public var bruxismHighBandThreshold: Double
    public var environmentalNoiseThreshold: Double
    public var suspectedPauseMinimumDuration: TimeInterval
    public var minimumConfidence: Double
    public var minimumEventDuration: TimeInterval
    public var mergeGapSeconds: TimeInterval

    public init(
        profile: DetectorTuningProfile,
        silenceRmsThreshold: Double,
        snoreRmsThreshold: Double,
        snoreEnergyThreshold: Double,
        coughEnergyThreshold: Double,
        gaspEnergyThreshold: Double,
        bruxismHighBandThreshold: Double,
        environmentalNoiseThreshold: Double,
        suspectedPauseMinimumDuration: TimeInterval,
        minimumConfidence: Double,
        minimumEventDuration: TimeInterval,
        mergeGapSeconds: TimeInterval
    ) {
        self.profile = profile
        self.silenceRmsThreshold = Self.clampedUnit(silenceRmsThreshold)
        self.snoreRmsThreshold = Self.clampedUnit(snoreRmsThreshold)
        self.snoreEnergyThreshold = Self.clampedUnit(snoreEnergyThreshold)
        self.coughEnergyThreshold = Self.clampedUnit(coughEnergyThreshold)
        self.gaspEnergyThreshold = Self.clampedUnit(gaspEnergyThreshold)
        self.bruxismHighBandThreshold = Self.clampedUnit(bruxismHighBandThreshold)
        self.environmentalNoiseThreshold = Self.clampedUnit(environmentalNoiseThreshold)
        self.suspectedPauseMinimumDuration = max(1, suspectedPauseMinimumDuration)
        self.minimumConfidence = Self.clampedUnit(minimumConfidence)
        self.minimumEventDuration = max(0.05, minimumEventDuration)
        self.mergeGapSeconds = max(0, mergeGapSeconds)
    }

    public static func profile(_ profile: DetectorTuningProfile) -> DetectorThresholdConfiguration {
        // 임시 profile 값이며, 실제 overnight 데이터와 detector diagnostics를 바탕으로 조정할 예정입니다.
        switch profile {
        case .conservative:
            return DetectorThresholdConfiguration(
                profile: .conservative,
                silenceRmsThreshold: 0.012,
                snoreRmsThreshold: 0.060,
                snoreEnergyThreshold: 0.0036,
                coughEnergyThreshold: 0.0048,
                gaspEnergyThreshold: 0.0028,
                bruxismHighBandThreshold: 0.30,
                environmentalNoiseThreshold: 0.28,
                suspectedPauseMinimumDuration: 12,
                minimumConfidence: 0.42,
                minimumEventDuration: 0.30,
                mergeGapSeconds: 0.80
            )
        case .balanced:
            return DetectorThresholdConfiguration(
                profile: .balanced,
                silenceRmsThreshold: 0.010,
                snoreRmsThreshold: 0.050,
                snoreEnergyThreshold: 0.0025,
                coughEnergyThreshold: 0.0032,
                gaspEnergyThreshold: 0.0018,
                bruxismHighBandThreshold: 0.24,
                environmentalNoiseThreshold: 0.24,
                suspectedPauseMinimumDuration: 10,
                minimumConfidence: 0.35,
                minimumEventDuration: 0.20,
                mergeGapSeconds: 1.00
            )
        case .sensitive:
            return DetectorThresholdConfiguration(
                profile: .sensitive,
                silenceRmsThreshold: 0.008,
                snoreRmsThreshold: 0.040,
                snoreEnergyThreshold: 0.0016,
                coughEnergyThreshold: 0.0020,
                gaspEnergyThreshold: 0.0010,
                bruxismHighBandThreshold: 0.20,
                environmentalNoiseThreshold: 0.20,
                suspectedPauseMinimumDuration: 8,
                minimumConfidence: 0.32,
                minimumEventDuration: 0.16,
                mergeGapSeconds: 1.20
            )
        case .customDebug:
            var configuration = DetectorThresholdConfiguration.profile(.balanced)
            configuration.profile = .customDebug
            return configuration
        }
    }

    public var ruleBasedThresholds: RuleBasedDetectionThresholds {
        RuleBasedDetectionThresholds(
            silenceRMS: silenceRmsThreshold,
            snoreRMS: snoreRmsThreshold,
            noiseRMS: environmentalNoiseThreshold,
            suspectedPauseMinimumDuration: suspectedPauseMinimumDuration
        )
    }

    public var smoothingPolicy: DetectionSmoothingPolicy {
        DetectionSmoothingPolicy(
            minimumEventDuration: minimumEventDuration,
            maximumMergeGap: mergeGapSeconds,
            confidenceThreshold: minimumConfidence,
            bruxismLikeMinimumEventDuration: max(0.12, minimumEventDuration * 0.60),
            bruxismLikeMaximumMergeGap: max(mergeGapSeconds, 1.6),
            bruxismLikeConfidenceThreshold: max(minimumConfidence, 0.45),
            bruxismLikeEnvironmentalOverlapPenalty: 0.20
        )
    }

    public func makeSleepAnalyzer(backend: SleepDetectionBackend = .hybrid) -> SleepAnalyzer {
        let ruleDetector = RuleBasedSleepEventDetector(thresholds: ruleBasedThresholds)
        let breathingActivityEstimator = BreathingActivityEstimator(
            silenceRMS: silenceRmsThreshold,
            snoreRMS: snoreRmsThreshold,
            noiseRMS: environmentalNoiseThreshold
        )
        let sequenceDetector = SuspectedBreathingPauseSequenceDetector(
            estimator: breathingActivityEstimator,
            minimumLowActivityDuration: suspectedPauseMinimumDuration,
            minimumOutputConfidence: max(0.30, minimumConfidence - 0.05)
        )
        let detector = CompositeSleepEventDetector(
            backend: backend,
            ruleBasedDetector: ruleDetector,
            coreMLDetector: CoreMLSleepEventDetector()
        )

        return SleepAnalyzer(
            detector: detector,
            suspectedBreathingPauseSequenceDetector: sequenceDetector,
            smoothingPolicy: smoothingPolicy
        )
    }

    public var thresholdSnapshot: [String: Double] {
        [
            "tuning.profileIndex": profile.snapshotIndex,
            "tuning.silenceRmsThreshold": silenceRmsThreshold,
            "tuning.snoreRmsThreshold": snoreRmsThreshold,
            "tuning.snoreEnergyThreshold": snoreEnergyThreshold,
            "tuning.coughEnergyThreshold": coughEnergyThreshold,
            "tuning.gaspEnergyThreshold": gaspEnergyThreshold,
            "tuning.bruxismHighBandThreshold": bruxismHighBandThreshold,
            "tuning.environmentalNoiseThreshold": environmentalNoiseThreshold,
            "tuning.suspectedPauseMinimumDuration": suspectedPauseMinimumDuration,
            "tuning.minimumConfidence": minimumConfidence,
            "tuning.minimumEventDuration": minimumEventDuration,
            "tuning.mergeGapSeconds": mergeGapSeconds
        ]
    }

    private static func clampedUnit(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }
}
