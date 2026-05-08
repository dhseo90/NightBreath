import Foundation

public struct RuleBasedDetectionThresholds: Equatable, Sendable {
    public var silenceRMS: Double
    public var snoreRMS: Double
    public var lowLevelSnoreRMS: Double
    public var lowLevelSnoreEnergy: Double
    public var lowLevelSnoreLowBandRatio: Double
    public var snoreRelativeEnergyRatio: Double
    public var noiseRMS: Double
    public var suspectedPauseMinimumDuration: TimeInterval

    public static let `default` = RuleBasedDetectionThresholds()

    public init(
        silenceRMS: Double = 0.01,
        snoreRMS: Double = 0.045,
        lowLevelSnoreRMS: Double? = nil,
        lowLevelSnoreEnergy: Double? = nil,
        lowLevelSnoreLowBandRatio: Double = 0.64,
        snoreRelativeEnergyRatio: Double = 1.35,
        noiseRMS: Double = 0.24,
        suspectedPauseMinimumDuration: TimeInterval = 10
    ) {
        self.silenceRMS = Self.clamp(silenceRMS)
        self.snoreRMS = min(max(Self.clamp(snoreRMS), self.silenceRMS + 0.001), 1)
        let lowLevelRMS = lowLevelSnoreRMS ?? max(self.silenceRMS * 2.2, self.snoreRMS * 0.55)
        self.lowLevelSnoreRMS = min(max(Self.clamp(lowLevelRMS), self.silenceRMS), self.snoreRMS)
        let lowLevelEnergy = lowLevelSnoreEnergy ?? self.lowLevelSnoreRMS * self.lowLevelSnoreRMS * 0.65
        self.lowLevelSnoreEnergy = Self.clamp(lowLevelEnergy)
        self.lowLevelSnoreLowBandRatio = Self.clamp(lowLevelSnoreLowBandRatio)
        self.snoreRelativeEnergyRatio = max(1, snoreRelativeEnergyRatio.isFinite ? snoreRelativeEnergyRatio : 1)
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
            return []
        }

        var outputs: [DetectorOutput] = []
        let peakContrast = max(0, features.peak - features.rms)
        let isBroadbandNoise =
            features.zeroCrossingRate >= 0.42 ||
            features.spectralCentroid >= 2_200 ||
            (features.highBandEnergy >= 0.30 && features.midBandEnergy >= 0.20 && features.lowBandEnergy <= 0.55)
        let isSustainedExternalNoise =
            features.duration >= 1.2 &&
            features.estimatedNoiseLevel >= noiseRMS * 0.8
        let isVeryLoudInput =
            features.rms >= noiseRMS ||
            features.peak >= 0.65 ||
            features.estimatedNoiseLevel >= noiseRMS

        // 임시 로직이며 추후 실제 데이터/ML 모델로 대체 예정입니다.
        // 큰 broadband noise나 지속적인 외부 소음은 수면 이벤트보다 환경 소음 후보로 우선 표시합니다.
        if isVeryLoudInput,
           isBroadbandNoise || isSustainedExternalNoise || features.rms >= noiseRMS * 1.25 {
            outputs.append(
                makeOutput(
                    .environmentalNoise,
                    features: features,
                    confidence: 0.50 + min(features.rms * 0.7, 0.22) + (isBroadbandNoise ? 0.10 : 0),
                    intensity: max(features.rms, features.peak),
                    debugReason: "큰 broadband/지속 소음 기반 환경 소음 placeholder"
                )
            )

            if features.rms >= 0.18 || features.peak >= 0.55 {
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

        }

        let hasEnvironmentalNoise = outputs.contains { $0.eventType == .environmentalNoise }
        let snoreTexture = snoreTextureAssessment(for: features)
        let passesStandardSnoreThreshold = features.rms >= snoreRMS
        let passesLowLevelSnoreThreshold =
            features.rms >= thresholds.lowLevelSnoreRMS &&
            features.energy >= thresholds.lowLevelSnoreEnergy
        let passesCloseLowMidSnoreThreshold =
            snoreTexture.passesCloseLowMidGuard &&
            features.rms >= max(thresholds.lowLevelSnoreRMS, thresholds.snoreRMS * 0.82) &&
            features.energy >= thresholds.lowLevelSnoreEnergy
        let passesDistantNearMissSnoreThreshold =
            thresholds.snoreRMS <= 0.045 &&
            snoreTexture.passesDistantNearMissGuard &&
            features.rms >= max(silenceRMS * 1.4, thresholds.lowLevelSnoreRMS * 0.62) &&
            features.energy >= max(0.000_03, thresholds.lowLevelSnoreEnergy * 0.18)
        let passesSnoreLevelGate =
            passesStandardSnoreThreshold ||
            (passesLowLevelSnoreThreshold && snoreTexture.passesDistanceGuard) ||
            passesCloseLowMidSnoreThreshold

        if passesSnoreLevelGate,
           !hasEnvironmentalNoise,
           snoreTexture.passesBasicGuard {
            outputs.append(
                makeOutput(
                    .snore,
                    features: features,
                    confidence: snoreConfidence(
                        features: features,
                        texture: snoreTexture,
                        usedLowLevelGuard: !passesStandardSnoreThreshold
                    ),
                    intensity: snoreIntensity(features: features, usedLowLevelGuard: !passesStandardSnoreThreshold),
                    debugReason: !passesStandardSnoreThreshold
                        ? "저진폭이지만 noise 대비 상대 energy, 저주파 비율, 낮은 ZCR/high-band guard를 통과한 코골기 후보 placeholder"
                        : "저주파 에너지, RMS, 저진폭 texture guard 기반 코골기 후보 placeholder"
                )
            )
        }

        if !passesSnoreLevelGate,
           passesDistantNearMissSnoreThreshold,
           !hasEnvironmentalNoise,
           snoreTexture.passesBasicGuard {
            outputs.append(
                makeOutput(
                    .snore,
                    features: features,
                    confidence: snoreNearMissConfidence(features: features, texture: snoreTexture),
                    intensity: snoreIntensity(features: features, usedLowLevelGuard: true) * 0.85,
                    debugReason: "입력 레벨은 낮지만 저주파 texture와 noise 대비 상대 energy가 있어 raw near-miss 코골기 후보로 남깁니다. 기본 profile에서는 smoothing에서 제외될 수 있습니다."
                )
            )
        }

        // 임시 로직이며 추후 실제 데이터/ML 모델로 대체 예정입니다.
        // 기침 의심 소리는 짧고 강한 burst, 높은 peak 대비 RMS, mid/high band 활동을 함께 봅니다.
        if features.duration <= 1.8,
           features.rms >= 0.03,
           features.peak >= 0.22,
           peakContrast >= 0.08,
           features.zeroCrossingRate >= 0.10 || features.midBandEnergy >= 0.20 || features.highBandEnergy >= 0.18 {
            outputs.append(
                makeOutput(
                    .coughLike,
                    features: features,
                    confidence: 0.44 + min(features.peak * 0.25, 0.20) + min(peakContrast, 0.12),
                    intensity: features.peak,
                    debugReason: "짧고 강한 burst 기반 기침 의심 소리 placeholder"
                )
            )
        }

        let hasCoughLike = outputs.contains { $0.eventType == .coughLike }
        let isLocalizedFrictionCandidate =
            features.duration <= 2.0 &&
            features.rms >= 0.025 &&
            features.peak >= 0.10 &&
            peakContrast >= 0.03 &&
            features.lowFrequencyEnergyRatio <= 0.45 &&
            (features.zeroCrossingRate >= 0.24 || features.highBandEnergy >= 0.24 || features.spectralCentroid >= 1_700)

        // 임시 로직이며 추후 실제 데이터/ML 모델로 대체 예정입니다.
        // 이갈이 의심 소리는 짧고 날카로운 고주파 마찰음 후보만 표시하며, 침구/침대/주변 소음과 혼동될 수 있습니다.
        if isLocalizedFrictionCandidate,
           !hasEnvironmentalNoise {
            outputs.append(
                makeOutput(
                    .bruxismLike,
                    features: features,
                    confidence: 0.43 + min(features.zeroCrossingRate * 0.18, 0.14) + min(features.highBandEnergy * 0.16, 0.12),
                    intensity: min(max(features.peak, features.rms * 2.5), 1),
                    debugReason: "짧은 고주파 마찰음 패턴으로 이갈이 의심 소리 후보입니다. 침구 마찰음 또는 외부 소음일 수 있어 사용자 확인이 필요합니다. 임시 rule-based 판단입니다."
                )
            )
        }

        let hasSnore = outputs.contains { $0.eventType == .snore }

        // 임시 로직이며 추후 실제 데이터/ML 모델로 대체 예정입니다.
        // gasp-like 후보는 짧은 회복 호흡으로 의심되는 burst를 보되, 코골기/환경 소음/기침 후보와 분리합니다.
        if features.duration <= 2.2,
           features.rms >= 0.02,
           features.peak >= 0.14,
           features.zeroCrossingRate >= 0.06,
           features.zeroCrossingRate <= 0.34,
           features.lowFrequencyEnergyRatio < 0.65,
           features.highBandEnergy < 0.55,
           !hasSnore,
           !hasEnvironmentalNoise,
           !hasCoughLike {
            outputs.append(
                makeOutput(
                    .gaspLike,
                    features: features,
                    confidence: 0.40 + min(features.rms * 2.2, 0.22) + min(peakContrast * 0.35, 0.10),
                    intensity: min(max(features.rms * 2.5, features.peak), 1),
                    debugReason: "짧은 회복 호흡으로 의심되는 소리 placeholder"
                )
            )
        }

        if features.rms >= 0.02,
           features.zeroCrossingRate >= 0.08,
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

        if features.rms >= 0.015,
           features.peak >= 0.15,
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

    private func snoreTextureAssessment(
        for features: AudioFeatures
    ) -> (passesBasicGuard: Bool, passesDistanceGuard: Bool, passesCloseLowMidGuard: Bool, passesDistantNearMissGuard: Bool, relativeEnergy: Double) {
        let relativeEnergy = relativeEnergyRatio(for: features)
        let lowMidEnergy = features.lowBandEnergy + features.midBandEnergy
        let lowLevelTexture =
            features.lowFrequencyEnergyRatio >= thresholds.lowLevelSnoreLowBandRatio &&
            features.zeroCrossingRate <= 0.24 &&
            features.highBandEnergy <= 0.18 &&
            features.midBandEnergy <= 0.36 &&
            features.spectralCentroid <= 950 &&
            relativeEnergy >= thresholds.snoreRelativeEnergyRatio
        let closeLowMidTexture =
            features.lowFrequencyEnergyRatio >= 0.40 &&
            lowMidEnergy >= 0.78 &&
            features.midBandEnergy <= 0.50 &&
            features.zeroCrossingRate <= 0.26 &&
            features.highBandEnergy <= 0.22 &&
            features.spectralCentroid <= 1_450 &&
            relativeEnergy >= 1.20
        let distantNearMissTexture =
            features.lowFrequencyEnergyRatio >= max(0.70, thresholds.lowLevelSnoreLowBandRatio) &&
            features.zeroCrossingRate <= 0.18 &&
            features.highBandEnergy <= 0.16 &&
            features.midBandEnergy <= 0.30 &&
            features.spectralCentroid <= 700 &&
            relativeEnergy >= 1.12
        let basicTexture =
            closeLowMidTexture ||
            distantNearMissTexture ||
            (
                features.lowFrequencyEnergyRatio >= 0.45 &&
                features.zeroCrossingRate <= 0.45 &&
                (
                    features.rms >= 0.05 ||
                    (
                        features.lowFrequencyEnergyRatio >= 0.58 &&
                        features.zeroCrossingRate <= 0.28 &&
                        features.highBandEnergy <= 0.22 &&
                        features.spectralCentroid <= 1_200
                    )
                )
            )

        return (
            passesBasicGuard: basicTexture,
            passesDistanceGuard: lowLevelTexture,
            passesCloseLowMidGuard: closeLowMidTexture,
            passesDistantNearMissGuard: distantNearMissTexture,
            relativeEnergy: relativeEnergy
        )
    }

    private func snoreConfidence(
        features: AudioFeatures,
        texture: (passesBasicGuard: Bool, passesDistanceGuard: Bool, passesCloseLowMidGuard: Bool, passesDistantNearMissGuard: Bool, relativeEnergy: Double),
        usedLowLevelGuard: Bool
    ) -> Double {
        let lowBandSupport = min(max(features.lowFrequencyEnergyRatio - 0.45, 0) * 0.50, 0.22)
        let relativeSupport = min(max(texture.relativeEnergy - 1, 0) * 0.10, 0.10)
        let amplitudeSupport = usedLowLevelGuard
            ? min(max((features.rms - thresholds.lowLevelSnoreRMS) / max(snoreRMS - thresholds.lowLevelSnoreRMS, 0.001), 0) * 0.08, 0.08)
            : min(features.rms * 1.6, 0.12)
        let base = usedLowLevelGuard ? 0.36 : 0.50
        return min(max(base + lowBandSupport + relativeSupport + amplitudeSupport, 0), 1)
    }

    private func snoreNearMissConfidence(
        features: AudioFeatures,
        texture: (passesBasicGuard: Bool, passesDistanceGuard: Bool, passesCloseLowMidGuard: Bool, passesDistantNearMissGuard: Bool, relativeEnergy: Double)
    ) -> Double {
        let lowBandSupport = min(max(features.lowFrequencyEnergyRatio - 0.70, 0) * 0.20, 0.04)
        let relativeSupport = min(max(texture.relativeEnergy - 1.12, 0) * 0.04, 0.04)
        return min(max(0.28 + lowBandSupport + relativeSupport, 0.24), 0.34)
    }

    private func snoreIntensity(
        features: AudioFeatures,
        usedLowLevelGuard: Bool
    ) -> Double {
        if usedLowLevelGuard {
            return min(max(features.rms / max(thresholds.lowLevelSnoreRMS, 0.001), features.lowFrequencyEnergyRatio) * 0.45, 1)
        }
        return min(features.rms * 2.5, 1)
    }

    private func relativeEnergyRatio(for features: AudioFeatures) -> Double {
        let floor = max(features.estimatedNoiseLevel, silenceRMS * 0.75, 0.0001)
        let floorEnergy = max(floor * floor, 0.000_000_01)
        guard features.energy.isFinite else { return 0 }
        return max(0, features.energy / floorEnergy)
    }
}
