#if DEBUG
  import SwiftUI

  struct DetectorTuningView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
      List {
        profileSection
        thresholdSection
        diagnosticsSection
        zeroEventSection
        featureDistributionSection
        backendSection
        noteSection
      }
      .navigationTitle("Detector 튜닝")
      .scrollContentBackground(.hidden)
      .background(NBColor.pageBackground)
    }

    private var profileSection: some View {
      Section("Profile") {
        Picker("현재 profile", selection: profileBinding) {
          ForEach(DetectorTuningProfile.debugSelectableProfiles) { profile in
            Text(profile.displayName).tag(profile)
          }
        }
        .pickerStyle(.segmented)
        .disabled(appState.isRecording)

        Text(appState.detectorTuningProfile.koreanDescription)
          .font(.footnote)
          .foregroundStyle(.secondary)

        if appState.isRecording {
          Text("측정 중에는 profile을 바꾸지 않습니다. 변경값은 다음 세션 전에 선택하세요.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        } else {
          Text("선택한 profile은 다음 측정 세션부터 적용되고, 세션 종료 후 thresholdsSnapshot에 저장됩니다.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
    }

    private var thresholdSection: some View {
      Section("현재 Threshold Snapshot") {
        ForEach(sortedThresholdKeys, id: \.self) { key in
          DetectorTuningRow(
            title: key,
            value: shortNumber(appState.currentDetectorThresholdSnapshot[key] ?? 0),
            systemImage: "slider.horizontal.3"
          )
        }
      }
    }

    @ViewBuilder
    private var diagnosticsSection: some View {
      Section("최근 세션 Detector Diagnostics") {
        if let diagnostics = appState.latestDetectorDiagnostics {
          DetectorTuningRow(
            title: "Raw 후보", value: "\(diagnostics.rawCandidateCount)개", systemImage: "waveform")
          DetectorTuningRow(
            title: "Smoothing 후", value: "\(diagnostics.postSmoothingEventCount)개",
            systemImage: "line.3.horizontal.decrease")
          DetectorTuningRow(
            title: "최종 이벤트", value: "\(diagnostics.finalEventCountByType.values.reduce(0, +))개",
            systemImage: "checkmark.circle")
          DetectorTuningRow(
            title: "분석 chunk", value: "\(diagnostics.analyzedChunkCount)개",
            systemImage: "square.stack.3d.up")
          DetectorTuningRow(
            title: "오디오 커버리지", value: percentString(diagnostics.audioCoverageRatio),
            systemImage: "waveform.badge.checkmark")
          DetectorTuningRow(
            title: "호흡 활동 score",
            value: shortNumber(diagnostics.latestBreathingActivityScore ?? 0),
            systemImage: "lungs")
          DetectorTuningRow(
            title: "저활동 지속",
            value: durationString(diagnostics.latestLowActivityDurationSeconds ?? 0),
            systemImage: "timer")
          DetectorTuningRow(
            title: "회복 패턴",
            value: (diagnostics.latestRecoveryPatternDetected ?? false) ? "감지" : "없음",
            systemImage: "arrow.clockwise.circle")
          DetectorTuningRow(
            title: "후보 confidence",
            value: percentString(diagnostics.latestPauseCandidateConfidence ?? 0),
            systemImage: "gauge.with.dots.needle.67percent")
          DetectorTuningRow(
            title: "최근 제외 이유",
            value: diagnostics.latestPauseCandidateRejectedReason ?? "없음",
            systemImage: "xmark.circle")

          VStack(alignment: .leading, spacing: 8) {
            Text("Reject reason TOP 5")
              .font(.subheadline.weight(.semibold))
            Text(topRejectReasonText(diagnostics, limit: 5))
              .font(.footnote)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }
          .padding(.vertical, 4)
        } else {
          Text("아직 저장된 detector diagnostics가 없습니다. 측정을 한 번 종료하면 raw 후보 수와 탈락 이유가 여기에 표시됩니다.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
    }

    @ViewBuilder
    private var zeroEventSection: some View {
      Section("Zero-event 분석") {
        if let diagnostics = appState.latestDetectorDiagnostics,
          let analysis = ZeroEventAnalysis.make(
            diagnostics: diagnostics,
            configuration: appState.detectorThresholdConfiguration
          )
        {
          DetectorTuningRow(
            title: "추정 원인",
            value: analysis.probableReason.displayName,
            systemImage: "questionmark.magnifyingglass"
          )
          DetectorTuningRow(
            title: "분석 confidence",
            value: percentString(analysis.confidence),
            systemImage: "gauge.with.dots.needle.67percent"
          )
          Text(analysis.recommendedDebugAction)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        } else if let diagnostics = appState.latestDetectorDiagnostics,
          diagnostics.finalEventCountByType.values.reduce(0, +) > 0
        {
          Text("최근 세션에는 최종 이벤트가 있어 zero-event 분석이 필요하지 않습니다.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        } else {
          Text("이벤트 0개 세션이 저장되면 가능한 원인과 다음 DEBUG 액션을 표시합니다.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
    }

    @ViewBuilder
    private var featureDistributionSection: some View {
      Section("Feature 분포") {
        if let diagnostics = appState.latestDetectorDiagnostics {
          DetectorFeatureStatsRow(title: "RMS", stats: diagnostics.rmsSummary)
          DetectorFeatureStatsRow(title: "Energy", stats: diagnostics.energySummary)
          DetectorFeatureStatsRow(
            title: "Zero Crossing", stats: diagnostics.zeroCrossingRateSummary)
          DetectorFeatureStatsRow(
            title: "Spectral Centroid", stats: diagnostics.spectralCentroidSummary)
          DetectorFeatureStatsRow(title: "Low Band", stats: diagnostics.lowBandEnergySummary)
          DetectorFeatureStatsRow(title: "Mid Band", stats: diagnostics.midBandEnergySummary)
          DetectorFeatureStatsRow(title: "High Band", stats: diagnostics.highBandEnergySummary)
          DetectorTuningRow(
            title: "저활동 후보",
            value: "\(diagnostics.lowActivityCandidateCount ?? 0)개",
            systemImage: "waveform.path.ecg")
          DetectorTuningRow(
            title: "소음 영향 저활동",
            value: "\(diagnostics.noiseContaminatedLowActivityCount ?? 0)개",
            systemImage: "speaker.wave.3")
          DetectorTuningRow(
            title: "gasp-like 승격",
            value: "\(diagnostics.pauseCandidatesPromotedByGasp ?? 0)개",
            systemImage: "arrow.up.circle")
          DetectorTuningRow(
            title: "duration 제외",
            value: "\(diagnostics.pauseCandidatesRejectedByDuration ?? 0)개",
            systemImage: "timer")
          DetectorTuningRow(
            title: "noise 제외",
            value: "\(diagnostics.pauseCandidatesRejectedByNoise ?? 0)개",
            systemImage: "speaker.slash")
        } else {
          Text("최근 세션 feature summary가 없습니다.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
    }

    private var backendSection: some View {
      Section("Backend") {
        DetectorTuningRow(
          title: "현재 backend",
          value: appState.currentDetectorBackend.displayName,
          systemImage: "switch.2"
        )
        DetectorTuningRow(
          title: "Core ML model",
          value: appState.isCurrentDetectorModelInstalled ? "Installed" : "Not installed",
          systemImage: "cpu"
        )
        DetectorTuningRow(
          title: "최근 fallback",
          value: "\(appState.latestDetectorDiagnostics?.modelFallbackCount ?? 0)회",
          systemImage: "arrow.triangle.2.circlepath"
        )
      }
    }

    private var noteSection: some View {
      Section("개발 메모") {
        Text(
          "이 화면은 DEBUG 빌드에서만 노출됩니다. threshold 값은 임시 rule-based 튜닝을 위한 로컬 설정이며, 정확도나 의학적 판단을 의미하지 않습니다."
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
        Text("원본 전체 밤 오디오는 저장하지 않습니다. 이벤트 오디오 샘플은 별도 opt-in 설정이 켜진 경우에만 짧게 저장됩니다.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }

    private var profileBinding: Binding<DetectorTuningProfile> {
      Binding(
        get: { appState.detectorTuningProfile },
        set: { appState.setDetectorTuningProfile($0) }
      )
    }

    private var sortedThresholdKeys: [String] {
      appState.currentDetectorThresholdSnapshot.keys.sorted()
    }

    private func shortNumber(_ value: Double) -> String {
      if abs(value) >= 10 {
        return String(format: "%.1f", value)
      }
      return String(format: "%.4f", value)
    }

    private func percentString(_ ratio: Double) -> String {
      String(format: "%.1f%%", min(max(ratio, 0), 1) * 100)
    }

    private func durationString(_ seconds: TimeInterval) -> String {
      SleepFormatters.compactDurationString(seconds)
    }

    private func topRejectReasonText(_ diagnostics: DetectorDiagnostics, limit: Int) -> String {
      let reasons = diagnostics.topRejectReasons.prefix(limit).map { reason, count in
        "\(reason.displayName) \(count)회"
      }
      return reasons.isEmpty ? "없음" : reasons.joined(separator: ", ")
    }
  }

  private struct DetectorTuningRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
      NBListRow(
        title: title,
        value: value,
        systemImage: systemImage,
        tint: NBColor.audioTint
      )
    }
  }

  private struct DetectorFeatureStatsRow: View {
    let title: String
    let stats: SummaryStats

    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        Text(title)
          .font(.subheadline.weight(.semibold))

        HStack {
          statPill("p50", stats.p50)
          statPill("p90", stats.p90)
          statPill("p95", stats.p95)
        }
      }
      .padding(.vertical, 4)
    }

    private func statPill(_ label: String, _ value: Double) -> some View {
      VStack(spacing: 2) {
        Text(label)
          .font(.caption2)
          .foregroundStyle(.secondary)
        Text(shortNumber(value))
          .font(.caption.monospacedDigit().weight(.semibold))
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
      .background(NBColor.elevatedSurface)
      .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func shortNumber(_ value: Double) -> String {
      if abs(value) >= 10 {
        return String(format: "%.1f", value)
      }
      return String(format: "%.4f", value)
    }
  }
#endif
