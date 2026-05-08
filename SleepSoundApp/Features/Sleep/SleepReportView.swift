import Charts
import SwiftUI
#if DEBUG
  import AVFoundation
#endif

struct SleepReportView: View {
  @EnvironmentObject private var appState: AppState
  #if DEBUG
    @StateObject private var debugAudioPreviewViewModel = DebugAudioPreviewViewModel()
  #endif

  let report: NightReport
  let events: [SleepEvent]

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.xLarge) {
        summaryCard
        measurementQualitySection
        detectorDiagnosticsSection
        zeroEventStateSection
        #if DEBUG
          debugAudioPreviewSection
        #endif
        scoreCard
        trendLinkCard
        keyEventsSection
        disturbedHourSection
        timelineSection
        reasonCard
        cautionCard
        actionLinks
      }
      .padding(NBSpacing.large)
    }
    .navigationTitle("어젯밤 수면 리포트")
    .toolbar(.hidden, for: .tabBar)
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
    #if DEBUG
      .onAppear {
        debugAudioPreviewViewModel.refresh(sessionId: report.sessionId)
      }
    #endif
  }

  private var summaryCard: some View {
    NBCard {
      VStack(alignment: .leading, spacing: NBSpacing.large) {
        HStack(alignment: .top, spacing: 12) {
          Image(systemName: "moon.zzz.fill")
            .font(.title2)
            .foregroundStyle(NBColor.sleepTint)
            .frame(width: 34, height: 34)

          VStack(alignment: .leading, spacing: 6) {
            Text("어젯밤 수면 리포트")
              .font(.title2.bold())
        Text("감지된 수면 중 소리를 바탕으로 정리한 아침 리포트입니다.")
              .font(.callout)
              .foregroundStyle(NBColor.secondaryText)
          }

          Spacer()
        }

        HStack(spacing: 12) {
          SummaryPill(
            title: "앱 동작 시간",
            value: SleepFormatters.compactDurationString(report.measurementDuration),
            systemImage: "clock"
          )
          SummaryPill(
            title: "추정 수면 시간",
            value: SleepFormatters.compactDurationString(report.estimatedSleepDuration),
            systemImage: "bed.double"
          )
        }

        Text(SleepFormatters.shortDate(report.generatedAt))
          .font(.caption)
          .foregroundStyle(NBColor.secondaryText)
      }
    }
  }

  private var scoreCard: some View {
    NBCard {
      VStack(alignment: .leading, spacing: NBSpacing.large) {
        SectionHeader(title: "수면 소리 점수", systemImage: "waveform.path.ecg")

        HStack(alignment: .center, spacing: 20) {
          ZStack {
            Circle()
              .stroke(Color(.systemGray5), lineWidth: 14)
            Circle()
              .trim(from: 0, to: CGFloat(report.sleepSoundScore) / 100)
              .stroke(scoreTint, style: StrokeStyle(lineWidth: 14, lineCap: .round))
              .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
              Text("\(report.sleepSoundScore)")
                .font(.system(size: 42, weight: .bold, design: .rounded))
              Text("/100")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          .frame(width: 132, height: 132)

          VStack(alignment: .leading, spacing: 8) {
            Text(scoreHeadline)
              .font(.headline)
            Text("점수는 코골기, 환경 소음, 각성 의심 구간 같은 수면 중 소리 기반 지표를 종합한 웰니스 참고값입니다.")
              .font(.callout)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
  }

  private var measurementQualitySection: some View {
    NBReportSection(title: "측정 품질", systemImage: "waveform.badge.checkmark") {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
          ReportMetricCard(
            title: "앱 동작 시간",
            value: SleepFormatters.compactDurationString(report.measurementDuration),
            systemImage: "clock",
            color: .blue
          )
          ReportMetricCard(
            title: "실제 오디오 수신",
            value: SleepFormatters.compactDurationString(report.receivedAudioDuration),
            systemImage: "waveform",
            color: .teal
          )
          ReportMetricCard(
            title: "실제 분석 시간",
            value: SleepFormatters.compactDurationString(report.analyzedAudioDuration),
            systemImage: "waveform.path.ecg",
            color: .indigo
          )
          ReportMetricCard(
            title: "감지 이벤트 시간",
            value: SleepFormatters.compactDurationString(displayDetectedEventDuration),
            systemImage: "waveform.and.magnifyingglass",
            color: .purple
          )
          ReportMetricCard(
            title: "저장된 오디오",
            value: SleepFormatters.compactDurationString(report.savedAudioDuration),
            systemImage: "waveform.circle",
            color: .gray
          )
          ReportMetricCard(
            title: "저장된 오디오 용량",
            value: appState.eventAudioStorageStats.formattedTotalSize,
            systemImage: "internaldrive",
            color: NBColor.privacy,
            status: appState.eventAudioStorageStats.sampleCount > 0 ? .debug : .privacy
          )
          ReportMetricCard(
            title: "녹음 커버리지",
            value: percentString(report.audioCoverageRatio),
            systemImage: "gauge.with.dots.needle.67percent",
            color: coverageStatus.tint,
            status: coverageStatus
          )
          ReportMetricCard(
            title: "오디오 중단",
            value: "\(report.interruptionCount)회",
            systemImage: "mic.slash",
            color: .orange
          )
          ReportMetricCard(
            title: "측정 품질",
            value: report.measurementQuality.displayName,
            systemImage: "checkmark.seal",
            color: measurementQualityTint
          )
        }

        Text("가장 긴 입력 공백: \(SleepFormatters.compactDurationString(report.longestAudioGapSeconds))")
          .font(.caption)
          .foregroundStyle(NBColor.secondaryText)

        Text(
          "실제 오디오 수신은 분석을 위해 마이크 입력이 들어온 시간입니다. 감지 이벤트 시간은 소리 이벤트 후보로 판단한 구간의 합계이고, 저장된 오디오는 이벤트 오디오 샘플 저장을 켠 경우에만 남는 전후 짧은 로컬 샘플 합계입니다."
        )
        .font(.caption)
        .foregroundStyle(NBColor.secondaryText)

        if shouldShowLowMeasurementQualityNote {
          NBEmptyStateView(
            title: "오디오 커버리지가 낮습니다",
            message: "오디오 수신 시간이 부족해 오늘 리포트의 참고 범위가 제한적일 수 있습니다. 화면 잠금, 충전 상태, 마이크 위치를 함께 확인해 주세요.",
            systemImage: "waveform.badge.exclamationmark",
            illustration: .devicePlacement
          )
        }
      }
    }
  }

  @ViewBuilder
  private var detectorDiagnosticsSection: some View {
    if let diagnostics = report.detectorDiagnostics {
      NBDiagnosticCard(title: "Detector 분석 요약") {
        VStack(alignment: .leading, spacing: NBSpacing.medium) {
          LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ReportMetricCard(
              title: "수신 chunk",
              value: "\(diagnostics.audioChunkCount)개",
              systemImage: "tray.and.arrow.down",
              color: NBColor.audioTint
            )
            ReportMetricCard(
              title: "분석 chunk",
              value: "\(diagnostics.analyzedChunkCount)개",
              systemImage: "square.stack.3d.up",
              color: NBColor.audioTint
            )
            ReportMetricCard(
              title: "Raw 후보",
              value: "\(diagnostics.rawCandidateCount)개",
              systemImage: "waveform",
              color: NBColor.breath
            )
            ReportMetricCard(
              title: "코골기 raw",
              value: "\(diagnostics.snoreRawCandidateCount)개",
              systemImage: SleepEventType.snore.symbolName,
              color: SleepEventType.snore.tintColor
            )
            ReportMetricCard(
              title: "코골기 feature",
              value: "\(diagnostics.snoreLikeFeatureCandidateCount)개",
              systemImage: "waveform.badge.magnifyingglass",
              color: NBColor.breathBlue
            )
            ReportMetricCard(
              title: "코골기 제외",
              value: "\(diagnostics.snoreRejectedCount + diagnostics.snoreLikeFeatureRejectedCount)개",
              systemImage: "line.3.horizontal.decrease.circle",
              color: NBColor.caution
            )
            ReportMetricCard(
              title: "Smoothing 후",
              value: "\(diagnostics.postSmoothingEventCount)개",
              systemImage: "line.3.horizontal.decrease",
              color: NBColor.sleep
            )
            ReportMetricCard(
              title: "최종 이벤트",
              value: "\(diagnostics.finalEventCountByType.values.reduce(0, +))개",
              systemImage: "checkmark.circle",
              color: NBColor.success
            )
            ReportMetricCard(
              title: "RMS p90",
              value: shortNumber(diagnostics.rmsSummary.p90),
              systemImage: "speaker.wave.2",
              color: NBColor.lavender
            )
            ReportMetricCard(
              title: "Energy p90",
              value: shortNumber(diagnostics.energySummary.p90),
              systemImage: "bolt",
              color: NBColor.warning
            )
            ReportMetricCard(
              title: "Low band p90",
              value: shortNumber(diagnostics.lowBandEnergyP90),
              systemImage: "waveform.path",
              color: NBColor.breathBlue
            )
            ReportMetricCard(
              title: "ZCR p50",
              value: shortNumber(diagnostics.zeroCrossingRateP50),
              systemImage: "waveform.path.ecg",
              color: NBColor.mistTeal
            )
            ReportMetricCard(
              title: "저활동 관찰",
              value: "\(diagnostics.lowActivityObservedCount ?? 0)개",
              systemImage: "lungs",
              color: NBColor.breath
            )
            ReportMetricCard(
              title: "회복 패턴",
              value: "\(diagnostics.recoveryPatternCount ?? 0)개",
              systemImage: "arrow.uturn.forward.circle",
              color: NBColor.mistTeal
            )
          }

          VStack(alignment: .leading, spacing: 6) {
            Text("현재 backend: \(diagnostics.activeDetectorBackend)")
              .font(.caption)
              .foregroundStyle(NBColor.secondaryText)
            if let tuningProfile = diagnostics.tuningProfile {
              Text("Tuning profile: \(tuningProfile)")
                .font(.caption)
                .foregroundStyle(NBColor.secondaryText)
            }
            Text("Core ML fallback: \(diagnostics.modelFallbackCount)회")
              .font(.caption)
              .foregroundStyle(NBColor.secondaryText)
            if let snoreRejectReason = diagnostics.snoreRejectReasonTop {
              Text("코골기 후보 제외 주요 이유: \(snoreRejectReason.displayName)")
                .font(.caption)
                .foregroundStyle(NBColor.secondaryText)
            }
            if !diagnostics.snoreLikeFeatureRejectReasonCounts.isEmpty {
              Text("코골기 feature 제외 이유: \(featureRejectReasonText(diagnostics))")
                .font(.caption)
                .foregroundStyle(NBColor.secondaryText)
            }
            Text("주요 탈락 이유: \(topRejectReasonText(diagnostics))")
              .font(.caption)
              .foregroundStyle(NBColor.secondaryText)
            Text("호흡 활동 score: \(shortNumber(diagnostics.latestBreathingActivityScore ?? 0)), 최근 저활동 지속: \(SleepFormatters.compactDurationString(diagnostics.latestLowActivityDurationSeconds ?? 0))")
              .font(.caption)
              .foregroundStyle(NBColor.secondaryText)
            Text("최근 회복 패턴: \((diagnostics.latestRecoveryPatternDetected ?? false) ? "감지" : "없음"), 후보 confidence: \(percentString(diagnostics.latestPauseCandidateConfidence ?? 0))")
              .font(.caption)
              .foregroundStyle(NBColor.secondaryText)
            if let rejectedReason = diagnostics.latestPauseCandidateRejectedReason {
              Text("최근 sequence 제외 이유: \(rejectedReason)")
                .font(.caption)
                .foregroundStyle(NBColor.secondaryText)
            }
            Text("sequence 제외: 맥락 부족 \(diagnostics.pauseCandidatesRejectedByInsufficientContext ?? 0)개, 회복 패턴 없음 \(diagnostics.pauseCandidatesRejectedByNoRecovery ?? 0)개, 무음만 지속 \(diagnostics.pauseCandidatesRejectedByLikelySilence ?? 0)개")
              .font(.caption)
              .foregroundStyle(NBColor.secondaryText)
          }

          if let zeroEventText = diagnostics.summaryTextForZeroEvents {
            Text(zeroEventText + " 감지 기준이 보수적으로 동작했을 수 있어 상세 분석을 함께 확인하세요.")
              .font(.callout)
              .foregroundStyle(NBColor.secondaryText)
              .fixedSize(horizontal: false, vertical: true)
          }

          if let zeroEventAnalysis = ZeroEventAnalysis.make(
            diagnostics: diagnostics,
            configuration: appState.detectorThresholdConfiguration
          ) {
            VStack(alignment: .leading, spacing: 6) {
              Text("이벤트 0개 분석: \(zeroEventAnalysis.probableReason.displayName)")
                .font(.subheadline.weight(.semibold))
              Text(zeroEventAnalysis.recommendedDebugAction)
                .font(.footnote)
                .foregroundStyle(NBColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 4)
          }

          #if DEBUG
            NBDiagnosticItemList(
              items: [
                NBDiagnosticItem(title: "raw by type", value: eventCountText(diagnostics.rawCandidateCountByType), status: .debug),
                NBDiagnosticItem(title: "pre-smoothing by type", value: eventCountText(diagnostics.preSmoothingCandidateCountByType), status: .debug),
                NBDiagnosticItem(title: "post-smoothing by type", value: eventCountText(diagnostics.postSmoothingEventCountByType), status: .debug),
                NBDiagnosticItem(title: "snore-like feature rejected", value: "\(diagnostics.snoreLikeFeatureRejectedCount)개, \(featureRejectReasonText(diagnostics))", status: diagnostics.snoreLikeFeatureRejectedCount > 0 ? .caution : .good),
                NBDiagnosticItem(title: "input level assessment", value: diagnostics.inputLevelAssessmentDisplayText, status: diagnostics.inputLevelLooksTooLowForPlacement ? .caution : .good),
                NBDiagnosticItem(title: "placement guidance", value: inputPlacementGuidanceText(diagnostics), status: diagnostics.inputLevelLooksTooLowForPlacement ? .caution : .debug),
                NBDiagnosticItem(title: "threshold snapshot", value: thresholdSnapshotText(diagnostics), status: .debug),
                NBDiagnosticItem(title: "RMS min/p50/p90/max", value: "\(shortNumber(diagnostics.rmsMin)) / \(shortNumber(diagnostics.rmsP50)) / \(shortNumber(diagnostics.rmsP90)) / \(shortNumber(diagnostics.rmsMax))", status: .neutral),
                NBDiagnosticItem(title: "Energy min/p50/p90/max", value: "\(shortNumber(diagnostics.energyMin)) / \(shortNumber(diagnostics.energyP50)) / \(shortNumber(diagnostics.energyP90)) / \(shortNumber(diagnostics.energyMax))", status: .neutral),
                NBDiagnosticItem(title: "latest feature", value: diagnostics.latestFeatureDebugSummary ?? "없음", status: .debug),
                NBDiagnosticItem(title: "latest raw candidate", value: diagnostics.latestRawCandidateDebugSummary ?? "없음", status: .debug),
              ],
              showsDetails: true
            )

            ShareLink(item: DetectorDiagnosticsQAReadout.makeMarkdown(diagnostics: diagnostics, report: report)) {
              Label("DEBUG QA readout 공유", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.nbSecondary)

            Text("공유 텍스트에는 원본 오디오, 이벤트 오디오 파일 경로, 개인 오디오 파일 경로를 포함하지 않습니다.")
              .font(NBTypography.caption)
              .foregroundStyle(NBColor.secondaryText)
              .fixedSize(horizontal: false, vertical: true)
          #endif
        }
      }
    }
  }

  @ViewBuilder
  private var zeroEventStateSection: some View {
    if events.isEmpty {
      NBReportSection(title: "이벤트 0개 분석", systemImage: "waveform.slash") {
        VStack(alignment: .leading, spacing: NBSpacing.md) {
          NBEmptyStateView(
            title: "감지 기준을 통과한 이벤트가 없습니다",
            message: "오디오 입력은 수신되었지만 detector 기준을 통과한 이벤트가 없었습니다.\n측정 환경, iPhone 배치, 감지 기준 영향을 상세 분석에서 확인할 수 있습니다.",
            systemImage: "moon.zzz",
            illustration: .emptyReport
          )

          if let diagnostics = report.detectorDiagnostics {
            VStack(alignment: .leading, spacing: NBSpacing.sm) {
              Label("Zero-event 분석", systemImage: "waveform.and.magnifyingglass")
                .font(NBTypography.headline)
                .foregroundStyle(NBColor.audioTint)
              Text("raw 후보 수와 주요 탈락 이유를 함께 확인합니다.")
                .font(NBTypography.caption)
                .foregroundStyle(NBColor.secondaryText)
              NBDiagnosticItemList(
                items: [
                NBDiagnosticItem(title: "raw 후보 수", value: "\(diagnostics.rawCandidateCount)개", status: .neutral),
                NBDiagnosticItem(title: "코골기 feature/raw/제외", value: "\(diagnostics.snoreLikeFeatureCandidateCount) / \(diagnostics.snoreRawCandidateCount) / \(diagnostics.snoreRejectedCount + diagnostics.snoreLikeFeatureRejectedCount)", status: .debug),
                NBDiagnosticItem(title: "smoothing 전/후", value: "\(diagnostics.preSmoothingCandidateCount) / \(diagnostics.postSmoothingEventCount)", status: .debug),
                NBDiagnosticItem(title: "최종 이벤트 수", value: "\(diagnostics.finalEventCountByType.values.reduce(0, +))개", status: .privacy),
                NBDiagnosticItem(title: "입력 레벨 평가", value: diagnostics.inputLevelAssessmentDisplayText, status: diagnostics.inputLevelLooksTooLowForPlacement ? .caution : .good),
                NBDiagnosticItem(title: "배치/거리 안내", value: inputPlacementGuidanceText(diagnostics), status: diagnostics.inputLevelLooksTooLowForPlacement ? .caution : .debug),
                NBDiagnosticItem(title: "주요 탈락 이유", value: topRejectReasonText(diagnostics), status: .caution),
              ],
                showsDetails: true
              )
            }
          }
        }
      }
    }
  }

  #if DEBUG
    @ViewBuilder
    private var debugAudioPreviewSection: some View {
      if !debugAudioPreviewViewModel.records.isEmpty || events.isEmpty {
        NBDiagnosticCard(title: "DEBUG 오디오 미리듣기") {
          VStack(alignment: .leading, spacing: NBSpacing.medium) {
            NBPrivacyNoticeCard(
              title: "DEBUG 전용 샘플",
              messages: [
                "이 영역은 DEBUG 빌드에서만 보입니다.",
                "이벤트가 없어도 마지막 몇 초의 로컬 샘플만 확인합니다.",
                "전체 밤 오디오는 저장하지 않습니다.",
              ],
              systemImage: "wrench.and.screwdriver"
            )

            if debugAudioPreviewViewModel.records.isEmpty {
              Text(debugPreviewEmptyMessage)
                .font(.caption)
                .foregroundStyle(NBColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            } else {
              ForEach(debugAudioPreviewViewModel.records) { record in
                DebugAudioPreviewRow(
                  record: record,
                  isPlaying: debugAudioPreviewViewModel.playingFileName == record.fileName
                ) {
                  debugAudioPreviewViewModel.play(record)
                } onDelete: {
                  debugAudioPreviewViewModel.delete(record)
                }
              }
            }

            if let message = debugAudioPreviewViewModel.message {
              Text(message)
                .font(.caption)
                .foregroundStyle(debugAudioPreviewViewModel.messageIsError ? NBColor.danger : NBColor.secondaryText)
            }
          }
        }
      }
    }

    private var debugPreviewEmptyMessage: String {
      if report.detectorDiagnostics?.eventAudioSampleStorageEnabled == true {
        return "이 세션에는 DEBUG 미리듣기 샘플이 없습니다. 다음 측정 종료 시 최근 오디오 입력이 있으면 짧은 샘플을 저장합니다."
      }
      return "DEBUG 미리듣기 샘플은 이벤트 오디오 샘플 저장을 켠 경우에만 생성됩니다."
    }
  #endif

  private var trendLinkCard: some View {
    NavigationLink {
      SevenDaySleepTrendView(reports: trendReports)
    } label: {
      HStack(spacing: 12) {
        Image(systemName: "chart.xyaxis.line")
          .font(.title3)
          .foregroundStyle(NBColor.breathBlue)
          .frame(width: 32)

        VStack(alignment: .leading, spacing: 4) {
          Text("최근 7일 추세")
            .font(.headline)
          Text("수면 소리 점수, 코골기 시간, 호흡정지 의심 구간, 환경 소음을 함께 확인합니다.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
      }
      .padding(NBSpacing.large)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(NBColor.surface)
      .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.medium, style: .continuous))
    }
    .buttonStyle(.plain)
  }

  private var keyEventsSection: some View {
    NBReportSection(title: "주요 이벤트", systemImage: "list.bullet.rectangle") {
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        ReportMetricCard(
          title: "코골기 시간",
          value: SleepFormatters.durationString(report.snoreTotalSeconds),
          systemImage: SleepEventType.snore.symbolName,
          color: SleepEventType.snore.tintColor
        )
        ReportMetricCard(
          title: "이갈이 의심 소리",
          value: "\(report.bruxismLikeCount)회",
          systemImage: SleepEventType.bruxismLike.symbolName,
          color: SleepEventType.bruxismLike.tintColor
        )
        ReportMetricCard(
          title: "호흡정지 의심 구간",
          value: "\(report.suspectedBreathingPauseCount)회",
          systemImage: SleepEventType.breathingPauseSuspected.symbolName,
          color: SleepEventType.breathingPauseSuspected.tintColor
        )
        ReportMetricCard(
          title: "gasp-like 회복 호흡",
          value: "\(report.gaspLikeCount)회",
          systemImage: SleepEventType.gaspLike.symbolName,
          color: SleepEventType.gaspLike.tintColor
        )
        ReportMetricCard(
          title: "기침 의심 소리",
          value: "\(report.coughLikeCount)회",
          systemImage: SleepEventType.coughLike.symbolName,
          color: SleepEventType.coughLike.tintColor
        )
        ReportMetricCard(
          title: "환경 소음",
          value: "\(report.environmentalNoiseCount)회",
          systemImage: SleepEventType.environmentalNoise.symbolName,
          color: SleepEventType.environmentalNoise.tintColor
        )
        ReportMetricCard(
          title: "각성 의심 구간",
          value: "\(report.awakeningSuspectedCount)회",
          systemImage: SleepEventType.awakeningSuspected.symbolName,
          color: SleepEventType.awakeningSuspected.tintColor
        )
        ReportMetricCard(
          title: "가장 긴 의심 구간",
          value: SleepFormatters.compactDurationString(report.longestSuspectedBreathingPauseSeconds),
          systemImage: "timer",
          color: .red
        )
        ReportMetricCard(
          title: "녹음 시간당 의심 구간",
          value: String(format: "%.1f회/시간", report.suspectedBreathingPauseRatePerRecordingHour),
          systemImage: "clock.arrow.circlepath",
          color: .pink
        )
      }

      if !events.isEmpty {
        NavigationLink {
          SleepTimelineView(report: report, events: events)
        } label: {
          Label("이벤트별 피드백 남기기", systemImage: "checkmark.bubble")
        }
        .buttonStyle(.nbSecondary)
      }
    }
  }

  private var disturbedHourSection: some View {
    NBReportSection(title: "가장 방해가 컸던 시간대", systemImage: "clock.badge.exclamationmark") {
      HStack(spacing: 12) {
        Image(systemName: "moon.stars")
          .font(.title3)
          .foregroundStyle(NBColor.warning)
          .frame(width: 32)

        VStack(alignment: .leading, spacing: 4) {
          Text(report.mostDisturbedHourRange ?? "뚜렷하게 몰린 시간대 없음")
            .font(.headline)
          Text(disturbedHourDescription)
            .font(.callout)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  private var timelineSection: some View {
    NBReportSection(title: "이벤트 타임라인", systemImage: "timeline.selection") {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        EventTimelineBand(events: events)
          .frame(height: 132)
          .padding(NBSpacing.medium)
          .background(NBColor.elevatedSurface)
          .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.medium, style: .continuous))

        NavigationLink {
          SleepTimelineView(report: report, events: events)
        } label: {
          Label("타임라인 및 피드백 보기", systemImage: "arrow.right")
        }
        .buttonStyle(.nbSecondary)
      }
    }
  }

  private var reasonCard: some View {
    NBReportSection(title: "주요 원인 설명", systemImage: "text.alignleft") {
      Text(polishedReason)
        .font(.body)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var cautionCard: some View {
    NBCard(background: NBColor.warning.opacity(0.08)) {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        SectionHeader(title: "주의 문구", systemImage: "info.circle")

        if shouldShowRepeatedPauseNote {
          Text("호흡정지 의심 구간은 오디오 기반 의심 패턴입니다.")
            .font(.callout)
            .foregroundStyle(NBColor.secondaryText)

          Text("반복적으로 높게 보이면 수면 환경, 기기 배치, 오디오 커버리지를 함께 확인해 주세요.")
            .font(.callout)
            .foregroundStyle(NBColor.secondaryText)
        }

        if report.bruxismLikeCount > 0 {
          Text("이갈이 의심 소리는 사용자 확인 필요 항목입니다. 침구 마찰음이나 주변 소음과 구분이 어려울 수 있어 참고 정보로만 확인해 주세요.")
            .font(.callout)
            .foregroundStyle(NBColor.secondaryText)
        }

        Text("수면 중 소리 기반 지표입니다.")
          .font(.callout)
          .foregroundStyle(NBColor.secondaryText)

        Text(
          "이 앱은 진단 목적의 의료기기가 아닙니다. 측정 위치, 주변 소리, 기기 상태에 따라 결과가 달라질 수 있으며, 수면 습관을 돌아보기 위한 참고 정보로 사용해 주세요."
        )
        .font(.callout)
        .foregroundStyle(NBColor.secondaryText)
      }
    }
  }

  private var actionLinks: some View {
    VStack(spacing: 10) {
      NavigationLink {
        MorningCheckInView(sessionId: report.sessionId)
      } label: {
        Label("아침 컨디션 기록", systemImage: "sun.max")
      }
      .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.dawn))
    }
  }

  private var scoreTint: Color {
    switch report.sleepSoundScore {
    case 85...100:
      NBColor.success
    case 70..<85:
      NBColor.breathBlue
    case 55..<70:
      NBColor.warning
    default:
      NBColor.danger
    }
  }

  private var measurementQualityTint: Color {
    switch report.measurementQuality {
    case .excellent:
      return NBColor.success
    case .good:
      return NBColor.breathBlue
    case .limited:
      return NBColor.warning
    case .poor:
      return NBColor.danger
    }
  }

  private var coverageStatus: NBStatusKind {
    switch report.audioCoverageRatio {
    case 0.95...:
      return .good
    case 0.85..<0.95:
      return .neutral
    case 0.60..<0.85:
      return .caution
    default:
      return .danger
    }
  }

  private var scoreHeadline: String {
    switch report.sleepSoundScore {
    case 85...100:
      "비교적 조용한 밤이었습니다"
    case 70..<85:
      "일부 방해 소리가 감지되었습니다"
    case 55..<70:
      "수면 중 소리 이벤트가 꽤 있었습니다"
    default:
      "방해 소리가 여러 차례 감지되었습니다"
    }
  }

  private var disturbedHourDescription: String {
    if report.mostDisturbedHourRange == nil {
      return "특정 시간대에 이벤트가 집중되기보다는 분산된 패턴으로 보입니다."
    }
    return "이 시간대에 감지된 소리 이벤트가 상대적으로 많이 모였습니다."
  }

  private var polishedReason: String {
    let reason = report.mainDisturbanceReason.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !reason.isEmpty else {
      return "어젯밤은 감지된 수면 중 소리 이벤트를 기준으로 수면 소리 점수가 계산되었습니다."
    }
    return reason
  }

  private var shouldShowRepeatedPauseNote: Bool {
    report.suspectedBreathingPauseCount >= 5 || report.gaspLikeCount >= 2
  }

  private var shouldShowLowMeasurementQualityNote: Bool {
    report.measurementQuality == .limited || report.measurementQuality == .poor
  }

  private var displayDetectedEventDuration: TimeInterval {
    if report.detectedEventDuration > 0 {
      return report.detectedEventDuration
    }

    return SleepEventAggregator().detectedEventDuration(events: events)
  }

  private func percentString(_ ratio: Double) -> String {
    String(format: "%.1f%%", min(max(ratio, 0), 1) * 100)
  }

  private func shortNumber(_ value: Double) -> String {
    if abs(value) >= 10 {
      return String(format: "%.1f", value)
    }
    return String(format: "%.4f", value)
  }

  private func topRejectReasonText(_ diagnostics: DetectorDiagnostics) -> String {
    let reasons = diagnostics.topRejectReasons.prefix(3).map { reason, count in
      "\(reason.displayName) \(count)회"
    }
    return reasons.isEmpty ? "없음" : reasons.joined(separator: ", ")
  }

  private func featureRejectReasonText(_ diagnostics: DetectorDiagnostics) -> String {
    let reasons = diagnostics.snoreLikeFeatureRejectReasonCounts
      .sorted { lhs, rhs in
        if lhs.value == rhs.value { return lhs.key.rawValue < rhs.key.rawValue }
        return lhs.value > rhs.value
      }
      .prefix(3)
      .map { reason, count in "\(reason.displayName) \(count)회" }
    return reasons.isEmpty ? "없음" : reasons.joined(separator: ", ")
  }

  private func inputPlacementGuidanceText(_ diagnostics: DetectorDiagnostics) -> String {
    if diagnostics.inputLevelLooksTooLowForPlacement {
      return "입력이 낮습니다. iPhone을 베개 쪽에 더 가깝게 두고 마이크가 침구에 가려지지 않았는지 확인하세요."
    }
    if diagnostics.snoreLikeFeatureRejectReasonCounts[.inputLevelTooLow, default: 0] > 0 {
      return "저진폭 코골기 후보가 있었습니다. 짧은 재테스트에서 iPhone 거리와 방향을 함께 기록하세요."
    }
    return "입력 레벨 특이 사항 없음"
  }

  private func eventCountText(_ counts: [SleepEventType: Int]) -> String {
    let parts = counts
      .sorted { lhs, rhs in lhs.key.rawValue < rhs.key.rawValue }
      .map { type, count in "\(type.timelineDisplayName) \(count)" }
    return parts.isEmpty ? "없음" : parts.joined(separator: ", ")
  }

  private func thresholdSnapshotText(_ diagnostics: DetectorDiagnostics) -> String {
    let keys = [
      "rule.silenceRMS",
      "rule.snoreRMS",
      "tuning.snoreEnergyThreshold",
      "smoothing.confidenceThreshold",
      "smoothing.minimumEventDuration",
    ]
    let parts = keys.compactMap { key -> String? in
      guard let value = diagnostics.thresholdsSnapshot[key] else { return nil }
      return "\(key)=\(shortNumber(value))"
    }
    return parts.isEmpty ? "없음" : parts.joined(separator: ", ")
  }

  private var trendReports: [NightReport] {
    let sortedReports = (appState.recentReports + [report])
      .sorted { $0.generatedAt < $1.generatedAt }

    let uniqueReports = sortedReports.reduce(into: [NightReport]()) { result, nextReport in
      if let index = result.firstIndex(where: { $0.sessionId == nextReport.sessionId }) {
        result[index] = nextReport
      } else {
        result.append(nextReport)
      }
    }

    return Array(uniqueReports.suffix(7))
  }
}

#if DEBUG
  private struct DebugAudioPreviewRow: View {
    let record: EventAudioSnippetFileRecord
    let isPlaying: Bool
    let onPlay: () -> Void
    let onDelete: () -> Void

    var body: some View {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        HStack(alignment: .top, spacing: NBSpacing.small) {
          Image(systemName: "waveform.circle")
            .foregroundStyle(NBColor.audioTint)
            .frame(width: 24)
            .accessibilityHidden(true)

          VStack(alignment: .leading, spacing: 4) {
            Text("최근 오디오 미리듣기")
              .font(.subheadline.weight(.semibold))
            Text(detailText)
              .font(.caption)
              .foregroundStyle(NBColor.secondaryText)
              .lineLimit(2)
          }

          Spacer()
        }

        HStack(spacing: NBSpacing.sm) {
          Button {
            onPlay()
          } label: {
            Label(isPlaying ? "다시 재생" : "재생", systemImage: "play.circle")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.nbSecondary)

          Button(role: .destructive) {
            onDelete()
          } label: {
            Label("삭제", systemImage: "trash")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(NBSecondaryButtonStyle(tint: NBColor.danger))
        }
      }
      .padding(12)
      .background(NBColor.elevatedSurface)
      .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var detailText: String {
      let duration = SleepFormatters.compactDurationString(record.duration)
      let size = ByteCountFormatter.string(fromByteCount: record.sizeBytes, countStyle: .file)
      return "\(duration) · \(size)"
    }
  }

  @MainActor
  private final class DebugAudioPreviewViewModel: ObservableObject {
    @Published var records: [EventAudioSnippetFileRecord] = []
    @Published var playingFileName: String?
    @Published var message: String?
    @Published var messageIsError = false

    private let snippetStore: EventAudioSnippetStore
    private var audioPlayer: AVAudioPlayer?
    private var currentSessionId: UUID?

    init(snippetStore: EventAudioSnippetStore = EventAudioSnippetStore()) {
      self.snippetStore = snippetStore
    }

    func refresh(sessionId: UUID) {
      currentSessionId = sessionId
      records = snippetStore.debugPlayableRecords(sessionId: sessionId)
    }

    func play(_ record: EventAudioSnippetFileRecord) {
      do {
        #if os(iOS)
          try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .default,
            options: [.duckOthers]
          )
          try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        let player = try AVAudioPlayer(contentsOf: record.url)
        player.prepareToPlay()
        player.play()
        audioPlayer = player
        playingFileName = record.fileName
        message = "DEBUG 미리듣기 샘플을 재생합니다."
        messageIsError = false
      } catch {
        audioPlayer = nil
        playingFileName = nil
        message = "오디오 샘플을 재생하지 못했습니다."
        messageIsError = true
      }
    }

    func delete(_ record: EventAudioSnippetFileRecord) {
      audioPlayer?.stop()
      do {
        try snippetStore.deleteSnippet(fileName: record.fileName)
        if let currentSessionId {
          refresh(sessionId: currentSessionId)
        } else {
          records.removeAll { $0.fileName == record.fileName }
        }
        playingFileName = nil
        message = "DEBUG 미리듣기 샘플을 삭제했습니다."
        messageIsError = false
      } catch {
        message = "오디오 샘플을 삭제하지 못했습니다."
        messageIsError = true
      }
    }
  }
#endif

private struct SummaryPill: View {
  let title: String
  let value: String
  let systemImage: String

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: systemImage)
        .foregroundStyle(NBColor.breathBlue)
        .frame(width: 22)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(value)
          .font(.subheadline.weight(.semibold))
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(NBColor.elevatedSurface)
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}

private struct SectionHeader: View {
  let title: String
  let systemImage: String

  var body: some View {
    Label(title, systemImage: systemImage)
      .font(NBTypography.sectionTitle)
      .foregroundStyle(NBColor.nightInk)
  }
}

private struct ReportMetricCard: View {
  let title: String
  let value: String
  let systemImage: String
  let color: Color
  var status: NBStatusKind?

  var body: some View {
    NBMetricCard(
      title: title,
      value: value,
      systemImage: systemImage,
      tint: color,
      status: status,
      accessibilityLabel: "\(title), \(value)"
    )
  }
}

private struct SevenDaySleepTrendView: View {
  let reports: [NightReport]

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.xLarge) {
        VStack(alignment: .leading, spacing: 8) {
          Text("최근 7일 추세")
            .font(.title2.bold())
          Text("수면 소리 점수와 주요 소리 이벤트가 어떻게 변했는지 간단히 확인합니다.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }

        TrendMetricChart(
          title: "수면 소리 점수",
          unit: "점",
          tint: .blue,
          points: trendPoints.map { point in
            TrendMetricPoint(label: point.label, value: Double(point.sleepSoundScore))
          }
        )

        TrendMetricChart(
          title: "코골기 시간",
          unit: "분",
          tint: SleepEventType.snore.tintColor,
          points: trendPoints.map { point in
            TrendMetricPoint(label: point.label, value: point.snoreMinutes)
          }
        )

        TrendMetricChart(
          title: "호흡정지 의심 구간",
          unit: "회",
          tint: SleepEventType.breathingPauseSuspected.tintColor,
          points: trendPoints.map { point in
            TrendMetricPoint(label: point.label, value: Double(point.suspectedPauseCount))
          }
        )

        TrendMetricChart(
          title: "환경 소음",
          unit: "회",
          tint: SleepEventType.environmentalNoise.tintColor,
          points: trendPoints.map { point in
            TrendMetricPoint(label: point.label, value: Double(point.environmentalNoiseCount))
          }
        )
      }
      .padding(NBSpacing.large)
    }
    .navigationTitle("7일 추세")
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
  }

  private var trendPoints: [SleepTrendPoint] {
    reports.map { report in
      SleepTrendPoint(report: report)
    }
  }
}

private struct TrendMetricChart: View {
  let title: String
  let unit: String
  let tint: Color
  let points: [TrendMetricPoint]

  var body: some View {
    NBCard {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        HStack {
          Text(title)
            .font(.headline)
          Spacer()
          if let latest = points.last {
            Text("\(formatted(latest.value))\(unit)")
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(.secondary)
          }
        }

        Chart(points) { point in
          BarMark(
            x: .value("날짜", point.label),
            y: .value(title, point.value)
          )
          .foregroundStyle(tint)
          .cornerRadius(4)
        }
        .chartYAxis {
          AxisMarks(position: .leading)
        }
        .frame(height: 170)

        if points.count < 2 {
          Text("저장된 리포트가 쌓이면 최근 7일 변화를 더 잘 볼 수 있습니다.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  private func formatted(_ value: Double) -> String {
    if value.rounded() == value {
      return "\(Int(value))"
    }
    return String(format: "%.1f", value)
  }
}

private struct SleepTrendPoint: Identifiable {
  let id: UUID
  let label: String
  let sleepSoundScore: Int
  let snoreMinutes: Double
  let suspectedPauseCount: Int
  let environmentalNoiseCount: Int

  init(report: NightReport) {
    id = report.sessionId
    label = SleepFormatters.shortDate(report.generatedAt)
    sleepSoundScore = report.sleepSoundScore
    snoreMinutes = (report.snoreTotalSeconds / 60).rounded()
    suspectedPauseCount = report.suspectedPauseCount
    environmentalNoiseCount = report.environmentalNoiseCount
  }
}

private struct TrendMetricPoint: Identifiable {
  let id = UUID()
  let label: String
  let value: Double
}
