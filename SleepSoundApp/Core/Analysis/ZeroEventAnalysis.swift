import Foundation

public enum ZeroEventProbableReason: String, Codable, CaseIterable, Sendable {
    case audioNotReceivedEnough
    case inputLevelTooLowForPlacement
    case audioReceivedButNoRawCandidates
    case snoreLikeFeaturesRejectedBeforeRaw
    case detectorTooConservative
    case featureScaleBelowThreshold
    case featuresMostlySilence
    case candidatesRejectedByConfidence
    case snoreCandidatesRejectedByConfidence
    case candidatesRejectedByTooShort
    case smoothingRemovedCandidates
    case modelUnavailableFallback
    case genuinelyQuietSession
    case unknown

    public var displayName: String {
        switch self {
        case .audioNotReceivedEnough:
            "오디오 수신 부족"
        case .inputLevelTooLowForPlacement:
            "입력 레벨/배치 확인 필요"
        case .audioReceivedButNoRawCandidates:
            "오디오 수신 후 raw 후보 없음"
        case .snoreLikeFeaturesRejectedBeforeRaw:
            "코골기 feature 후보가 raw 후보 전 단계에서 제외"
        case .detectorTooConservative:
            "감지 기준이 보수적일 가능성"
        case .featureScaleBelowThreshold:
            "feature 분포가 기준보다 낮음"
        case .featuresMostlySilence:
            "대부분 저활동/무음"
        case .candidatesRejectedByConfidence:
            "confidence 기준에서 제외"
        case .snoreCandidatesRejectedByConfidence:
            "코골기 raw 후보가 confidence 기준에서 제외"
        case .candidatesRejectedByTooShort:
            "후보가 너무 짧음"
        case .smoothingRemovedCandidates:
            "smoothing 단계에서 제외"
        case .modelUnavailableFallback:
            "Core ML fallback 발생"
        case .genuinelyQuietSession:
            "조용한 세션 가능성"
        case .unknown:
            "추가 확인 필요"
        }
    }
}

public struct ZeroEventAnalysis: Codable, Equatable, Sendable {
    public var probableReason: ZeroEventProbableReason
    public var recommendedDebugAction: String
    public var confidence: Double

    public init(
        probableReason: ZeroEventProbableReason,
        recommendedDebugAction: String,
        confidence: Double
    ) {
        self.probableReason = probableReason
        self.recommendedDebugAction = recommendedDebugAction
        self.confidence = min(max(confidence.isFinite ? confidence : 0, 0), 1)
    }

    public static func make(
        diagnostics: DetectorDiagnostics,
        configuration: DetectorThresholdConfiguration = DetectorTuningProfile.releaseDefault.configuration
    ) -> ZeroEventAnalysis? {
        guard diagnostics.finalEventCountByType.values.reduce(0, +) == 0 else { return nil }

        if diagnostics.audioChunkCount == 0 ||
            diagnostics.analyzedChunkCount == 0 ||
            diagnostics.analyzedAudioSeconds < 30 ||
            diagnostics.audioCoverageRatio < 0.60 {
            return ZeroEventAnalysis(
                probableReason: .audioNotReceivedEnough,
                recommendedDebugAction: "먼저 백그라운드/잠금 테스트에서 실제 오디오 수신 시간과 녹음 커버리지를 확인하세요.",
                confidence: 0.88
            )
        }

        if diagnostics.inputLevelLooksTooLowForPlacement {
            return ZeroEventAnalysis(
                probableReason: .inputLevelTooLowForPlacement,
                recommendedDebugAction: "오디오는 충분히 수신됐지만 RMS/energy p90/p99가 저진폭 코골기 후보 기준보다 크게 낮았습니다. iPhone을 베개 쪽에 더 가깝게 두고 마이크가 침구에 가려지지 않았는지 30초 foreground 입력 테스트로 확인하세요.",
                confidence: 0.86
            )
        }

        if diagnostics.modelFallbackCount > 0,
           diagnostics.rawCandidateCount == 0 {
            return ZeroEventAnalysis(
                probableReason: .modelUnavailableFallback,
                recommendedDebugAction: "Core ML 모델이 없어 rule-based fallback으로 동작했습니다. backend와 fallback 횟수를 함께 확인하세요.",
                confidence: 0.70
            )
        }

        if diagnostics.snoreLikeFeatureCandidateCount > 0,
           diagnostics.snoreRawCandidateCount == 0 {
            return ZeroEventAnalysis(
                probableReason: .snoreLikeFeaturesRejectedBeforeRaw,
                recommendedDebugAction: "코골기처럼 보이는 feature 후보는 있었지만 raw 코골기 후보로 올라오지 않았습니다. RMS/energy p90, low-band 비율, zero crossing, iPhone 배치를 함께 확인하세요.",
                confidence: 0.82
            )
        }

        if diagnostics.rawCandidateCount == 0 {
            return analyzeNoRawCandidateSession(
                diagnostics: diagnostics,
                configuration: configuration
            )
        }

        if diagnostics.snoreRawCandidateCount > 0,
           diagnostics.snorePostSmoothingEventCount == 0,
           diagnostics.rejectedCountByReason[.belowConfidenceThreshold, default: 0] > 0 ||
            diagnostics.rejectedCountByReason[.belowConfidence, default: 0] > 0 {
            return ZeroEventAnalysis(
                probableReason: .snoreCandidatesRejectedByConfidence,
                recommendedDebugAction: "코골기 raw 후보가 있었지만 confidence 기준에서 제외되었습니다. Threshold를 바로 낮추기보다 raw 후보 confidence 분포, iPhone 배치, RMS/저주파 p90을 함께 확인하세요.",
                confidence: 0.84
            )
        }

        let topReason = diagnostics.topRejectReasons.first?.0
        if topReason == .belowConfidenceThreshold || topReason == .belowConfidence {
            return ZeroEventAnalysis(
                probableReason: .candidatesRejectedByConfidence,
                recommendedDebugAction: "대부분의 후보가 confidence 기준에서 제외되었습니다. DEBUG에서 ‘민감’ 또는 ‘많이 민감’ 레벨로 짧은 비교 테스트를 해볼 수 있습니다.",
                confidence: 0.82
            )
        }

        if topReason == .tooShort || topReason == .tooShortDuration {
            return ZeroEventAnalysis(
                probableReason: .candidatesRejectedByTooShort,
                recommendedDebugAction: "후보는 있었지만 너무 짧아 이벤트로 남지 않았습니다. 박수/두드림 같은 짧은 소리 테스트와 minimumEventDuration을 비교하세요.",
                confidence: 0.80
            )
        }

        if diagnostics.preSmoothingCandidateCount > 0,
           diagnostics.postSmoothingEventCount == 0 {
            return ZeroEventAnalysis(
                probableReason: .smoothingRemovedCandidates,
                recommendedDebugAction: "raw 후보는 있었지만 smoothing 후 모두 제외되었습니다. 주요 탈락 이유, 최소 duration, confidence 기준을 함께 확인하세요.",
                confidence: 0.80
            )
        }

        return ZeroEventAnalysis(
            probableReason: .unknown,
            recommendedDebugAction: "Raw 후보, smoothing 결과, feature p90/p95를 함께 보고 다음 짧은 재현 테스트를 진행하세요.",
            confidence: 0.45
        )
    }

    private static func analyzeNoRawCandidateSession(
        diagnostics: DetectorDiagnostics,
        configuration: DetectorThresholdConfiguration
    ) -> ZeroEventAnalysis {
        let likelySilenceCount = diagnostics.rejectedCountByReason[.likelySilence] ?? 0
        let belowRmsCount = diagnostics.rejectedCountByReason[.belowRmsThreshold] ?? 0
        let silenceDominant = likelySilenceCount >= max(1, diagnostics.analyzedChunkCount / 2)
        let rmsP95 = diagnostics.rmsSummary.p95
        let energyP95 = diagnostics.energySummary.p95

        if silenceDominant,
           rmsP95 < configuration.silenceRmsThreshold * 1.2 {
            return ZeroEventAnalysis(
                probableReason: .featuresMostlySilence,
                recommendedDebugAction: "feature 분포상 대부분 저활동/무음에 가깝습니다. 마이크 위치와 실제 소리 입력 여부를 짧은 foreground 테스트로 확인하세요.",
                confidence: 0.86
            )
        }

        if rmsP95 >= configuration.snoreRmsThreshold * 0.80 ||
            energyP95 >= configuration.snoreEnergyThreshold * 0.80 {
            return ZeroEventAnalysis(
                probableReason: .detectorTooConservative,
                recommendedDebugAction: "feature 값이 기준 근처까지 올라왔지만 후보가 없었습니다. DEBUG에서 ‘민감’ 또는 ‘많이 민감’ 레벨로 다음 짧은 테스트를 비교하세요.",
                confidence: 0.74
            )
        }

        if belowRmsCount >= max(1, diagnostics.analyzedChunkCount / 2) {
            return ZeroEventAnalysis(
                probableReason: .featureScaleBelowThreshold,
                recommendedDebugAction: "오디오 입력은 있었지만 RMS/energy 분포가 기준보다 낮았습니다. 입력 크기, iPhone 위치, 마이크 방향을 짧은 foreground 테스트와 비교하세요.",
                confidence: 0.68
            )
        }

        return ZeroEventAnalysis(
            probableReason: .audioReceivedButNoRawCandidates,
            recommendedDebugAction: "Raw 후보가 없었습니다. RMS/energy p90/p95, 마이크 배치, background 수신 상태를 함께 확인하세요.",
            confidence: 0.45
        )
    }
}
