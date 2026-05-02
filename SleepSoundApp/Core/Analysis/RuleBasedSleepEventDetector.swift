import Foundation

public struct RuleBasedDetectionThresholds: Equatable, Sendable {
    public var silenceRMS: Double
    public var snoreRMS: Double
    public var noiseRMS: Double
    public var suspectedPauseMinimumDuration: TimeInterval

    public static let `default` = RuleBasedDetectionThresholds()

    public init(
        silenceRMS: Double = 0.01,
        snoreRMS: Double = 0.05,
        noiseRMS: Double = 0.24,
        suspectedPauseMinimumDuration: TimeInterval = 10
    ) {
        self.silenceRMS = Self.clamp(silenceRMS)
        self.snoreRMS = Self.clamp(snoreRMS)
        self.noiseRMS = Self.clamp(noiseRMS)
        self.suspectedPauseMinimumDuration = max(1, suspectedPauseMinimumDuration)
    }

    private static func clamp(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }
}

public struct RuleBasedSleepEventDetector: SleepEventDetector {
    public var thresholds: RuleBasedDetectionThresholds

    public var silenceRMS: Double {
        get { thresholds.silenceRMS }
        set { thresholds.silenceRMS = RuleBasedDetectionThresholds(silenceRMS: newValue).silenceRMS }
    }

    public var snoreRMS: Double {
        get { thresholds.snoreRMS }
        set { thresholds.snoreRMS = RuleBasedDetectionThresholds(snoreRMS: newValue).snoreRMS }
    }

    public var noiseRMS: Double {
        get { thresholds.noiseRMS }
        set { thresholds.noiseRMS = RuleBasedDetectionThresholds(noiseRMS: newValue).noiseRMS }
    }

    public var suspectedPauseMinimumDuration: TimeInterval {
        get { thresholds.suspectedPauseMinimumDuration }
        set { thresholds.suspectedPauseMinimumDuration = max(1, newValue) }
    }

    public init(
        silenceRMS: Double = 0.01,
        snoreRMS: Double = 0.05,
        noiseRMS: Double = 0.24,
        suspectedPauseMinimumDuration: TimeInterval = 10
    ) {
        self.init(
            thresholds: RuleBasedDetectionThresholds(
                silenceRMS: silenceRMS,
                snoreRMS: snoreRMS,
                noiseRMS: noiseRMS,
                suspectedPauseMinimumDuration: suspectedPauseMinimumDuration
            )
        )
    }

    public init(thresholds: RuleBasedDetectionThresholds = .default) {
        self.thresholds = thresholds
    }

    public func detect(features: AudioFeatures) -> [DetectorOutput] {
        guard features.duration > 0 else { return [] }

        // 임시 로직이며 추후 ML 모델로 대체 예정입니다.
        if features.isLikelySilence || features.rms < silenceRMS {
            guard features.duration >= suspectedPauseMinimumDuration else {
                return []
            }
            return [
                makeOutput(
                    .breathingPauseSuspected,
                    features: features,
                    confidence: 0.48 + min(features.duration / 120, 0.18),
                    intensity: 0.2,
                    debugReason: "긴 저에너지 구간 placeholder"
                )
            ]
        }

        var outputs: [DetectorOutput] = []

        if features.rms >= noiseRMS || features.peak >= 0.85 {
            outputs.append(
                makeOutput(
                    .environmentalNoise,
                    features: features,
                    confidence: 0.55 + min(features.rms, 0.35),
                    intensity: max(features.rms, features.peak),
                    debugReason: "높은 RMS/peak 기반 환경 소음 placeholder"
                )
            )

            if features.rms >= 0.35 || features.peak >= 0.92 {
                outputs.append(
                    makeOutput(
                        .awakeningSuspected,
                        features: features,
                        confidence: 0.44 + min(features.rms, 0.25),
                        intensity: max(features.rms, features.peak),
                        debugReason: "큰 소리 후 각성 의심 placeholder"
                    )
                )
            }

            return outputs
        }

        if features.rms >= snoreRMS,
           features.lowFrequencyEnergyRatio >= 0.55,
           features.zeroCrossingRate <= 0.35 {
            outputs.append(
                makeOutput(
                    .snore,
                    features: features,
                    confidence: 0.50 + min(features.lowFrequencyEnergyRatio * 0.25, 0.25),
                    intensity: min(features.rms * 2.5, 1),
                    debugReason: "저주파 에너지와 RMS 기반 코골기 후보 placeholder"
                )
            )
        }

        if features.peak >= 0.55,
           features.duration <= 1.6,
           features.zeroCrossingRate >= 0.22 {
            outputs.append(
                makeOutput(
                    .coughLike,
                    features: features,
                    confidence: 0.42 + min(features.peak * 0.25, 0.25),
                    intensity: features.peak,
                    debugReason: "짧고 급격한 peak 기반 기침 의심 소리 placeholder"
                )
            )
        }

        if features.rms >= 0.035,
           features.zeroCrossingRate >= 0.35,
           features.lowFrequencyEnergyRatio < 0.5 {
            outputs.append(
                makeOutput(
                    .bruxismLike,
                    features: features,
                    confidence: 0.40 + min(features.zeroCrossingRate * 0.25, 0.25),
                    intensity: min(features.rms * 3, 1),
                    debugReason: "고 zero-crossing 기반 이갈이 의심 소리 placeholder"
                )
            )
        }

        if features.rms >= 0.04,
           features.zeroCrossingRate >= 0.18,
           features.lowFrequencyEnergyRatio < 0.65,
           outputs.isEmpty {
            outputs.append(
                makeOutput(
                    .gaspLike,
                    features: features,
                    confidence: 0.40 + min(features.rms * 2, 0.25),
                    intensity: min(features.rms * 3, 1),
                    debugReason: "짧은 회복 호흡 후보 placeholder"
                )
            )
        }

        if features.rms >= 0.035,
           features.zeroCrossingRate >= 0.12,
           features.zeroCrossingRate < 0.35,
           features.lowFrequencyEnergyRatio < 0.55,
           outputs.isEmpty {
            outputs.append(
                makeOutput(
                    .sleepTalkLike,
                    features: features,
                    confidence: 0.38,
                    intensity: min(features.rms * 2.5, 1),
                    debugReason: "음성 유사 패턴 placeholder, 텍스트 변환 없음"
                )
            )
        }

        if features.rms >= 0.03,
           features.peak >= 0.45,
           outputs.isEmpty {
            outputs.append(
                makeOutput(
                    .movementLike,
                    features: features,
                    confidence: 0.38 + min(features.peak * 0.15, 0.2),
                    intensity: features.peak,
                    debugReason: "불규칙 peak 기반 움직임 의심 소리 placeholder"
                )
            )
        }

        return outputs
    }

    private func makeOutput(
        _ type: SleepEventType,
        features: AudioFeatures,
        confidence: Double,
        intensity: Double,
        debugReason: String
    ) -> DetectorOutput {
        DetectorOutput(
            eventType: type,
            startedAt: features.startedAt,
            endedAt: features.endedAt,
            confidence: confidence,
            intensity: intensity,
            debugReason: debugReason
        )
    }
}
