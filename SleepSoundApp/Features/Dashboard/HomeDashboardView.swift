import SwiftUI

struct HomeDashboardView: View {
  @EnvironmentObject private var appState: AppState
  @State private var selectedTab: HomeDashboardTab = .home

  var body: some View {
    ZStack {
      NBColor.pageBackground.ignoresSafeArea()

      TabView(selection: $selectedTab) {
        tabRoot {
          dashboardContent
        }
        .tag(HomeDashboardTab.home)
        .tabItem {
          Label("홈", systemImage: "house")
        }

        tabRoot {
          SleepStartView()
        }
        .tag(HomeDashboardTab.sleep)
        .tabItem {
          Label("수면", systemImage: "moon.zzz")
        }

        tabRoot {
          HealthDashboardView()
        }
        .tag(HomeDashboardTab.health)
        .tabItem {
          Label("건강", systemImage: "heart.text.square")
        }

        tabRoot {
          SettingsListView()
        }
        .tag(HomeDashboardTab.settings)
        .tabItem {
          Label("설정", systemImage: "gearshape")
        }
      }
      .background(NBColor.pageBackground.ignoresSafeArea())
    }
  }

  private func tabRoot<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    NavigationStack {
      content()
        .toolbar(.hidden, for: .navigationBar)
    }
    .background(NBColor.pageBackground.ignoresSafeArea())
  }

  private var dashboardContent: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        scoreHeader

        actionLinks

        LazyVGrid(
          columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.medium
        ) {
          NBMetricCard(
            title: "수면 소리 점수",
            value: "\(appState.latestReport.sleepSoundScore)",
            unit: "점",
            subtitle: "수면 중 소리 기반 지표",
            systemImage: "waveform.path.ecg",
            tint: scoreTint,
            status: scoreStatus,
            accessibilityLabel: "수면 소리 점수 \(appState.latestReport.sleepSoundScore)점"
          )
          NBMetricCard(
            title: "측정 품질",
            value: appState.latestReport.measurementQuality.displayName,
            subtitle: "오디오 커버리지 \(percentString(appState.latestReport.audioCoverageRatio))",
            systemImage: "checkmark.seal",
            tint: measurementQualityTint,
            status: measurementQualityStatus,
            accessibilityLabel:
              "측정 품질 \(appState.latestReport.measurementQuality.displayName), 오디오 커버리지 \(percentString(appState.latestReport.audioCoverageRatio))"
          )
          NBMetricCard(
            title: "실제 오디오 수신",
            value: SleepFormatters.compactDurationString(appState.latestReport.receivedAudioDuration),
            subtitle: "분석에 들어온 마이크 입력",
            systemImage: "waveform",
            tint: NBColor.breath
          )
          NBMetricCard(
            title: "감지 이벤트 시간",
            value: SleepFormatters.compactDurationString(displayDetectedEventDuration),
            subtitle: "소리 이벤트 후보 구간 합계",
            systemImage: "waveform.and.magnifyingglass",
            tint: NBColor.audioTint
          )
          NBMetricCard(
            title: "녹음 커버리지",
            value: percentString(appState.latestReport.audioCoverageRatio),
            subtitle: coverageDescription,
            systemImage: "gauge.with.dots.needle.67percent",
            tint: coverageTint,
            status: coverageStatus
          )
          NBMetricCard(
            title: "이벤트 오디오 샘플",
            value: appState.isEventAudioSampleStorageEnabled ? "켜짐" : "꺼짐",
            subtitle: eventAudioStorageSummary,
            systemImage: "waveform.circle",
            tint: appState.isEventAudioSampleStorageEnabled ? NBColor.audioTint : NBColor.privacy,
            status: appState.isEventAudioSampleStorageEnabled ? .debug : .privacy
          )
        }

        recentEventsSection
        eventAudioStorageSection

        NBReportSection(title: "최근 수면 소리 점수", subtitle: "저장된 리포트가 쌓이면 최근 흐름을 더 쉽게 볼 수 있습니다.", systemImage: "chart.xyaxis.line") {
          TrendChartView(scores: trendScores)
            .frame(height: 160)
        }

        NBPrivacyNoticeCard(
          title: "온디바이스 분석",
          messages: [
            "분석은 iPhone 안에서 수행됩니다.",
            "서버로 전송하지 않습니다.",
            "원본 전체 오디오는 저장하지 않습니다.",
          ],
          systemImage: "iphone.gen3.radiowaves.left.and.right"
        )
      }
      .padding(.horizontal, NBSpacing.screenHorizontal)
      .padding(.top, NBSpacing.sm)
      .padding(.bottom, NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar(background: NBColor.pageBackground)
  }

  private var scoreHeader: some View {
    NBCard(background: NBColor.sleep.opacity(0.08), stroke: NBColor.sleep.opacity(0.18)) {
      VStack(alignment: .leading, spacing: NBSpacing.large) {
        HStack(alignment: .center, spacing: NBSpacing.large) {
          ZStack {
            Circle()
              .stroke(NBColor.cardStroke.opacity(0.55), lineWidth: 12)
            Circle()
              .trim(from: 0, to: CGFloat(appState.latestReport.sleepSoundScore) / 100)
              .stroke(scoreTint, style: StrokeStyle(lineWidth: 12, lineCap: .round))
              .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
              Text("\(appState.latestReport.sleepSoundScore)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
              Text("/100")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          .frame(width: 112, height: 112)
          .accessibilityLabel("수면 소리 점수 \(appState.latestReport.sleepSoundScore)점")

          VStack(alignment: .leading, spacing: NBSpacing.small) {
            Text("밤숨")
              .font(NBTypography.titleLarge)
              .foregroundStyle(NBColor.primaryText)
            Text("최근 수면 리포트")
              .font(NBTypography.headline)
            Label(
              appState.latestReportSource.displayText,
              systemImage: appState.latestReportSource.systemImage
            )
            .font(NBTypography.captionEmphasis)
            .foregroundStyle(NBColor.secondaryText)
            Text(SleepFormatters.shortDate(appState.latestReport.generatedAt))
              .foregroundStyle(NBColor.secondaryText)
            ViewThatFits(in: .horizontal) {
              HStack(spacing: NBSpacing.xs) {
                scoreHeaderBadges
              }
              VStack(alignment: .leading, spacing: NBSpacing.xs) {
                scoreHeaderBadges
              }
            }
            Text(appState.latestReport.mainDisturbanceReason)
              .font(.callout)
              .foregroundStyle(NBColor.secondaryText)
              .lineLimit(4)
          }
        }

        if let hourRange = appState.latestReport.mostDisturbedHourRange {
          NBStatusBadge(
            "가장 방해가 컸던 시간대 \(hourRange)",
            systemImage: "exclamationmark.magnifyingglass",
            tint: NBColor.warning
          )
        }
      }
    }
  }

  @ViewBuilder
  private var scoreHeaderBadges: some View {
    NBStatusBadge(
      "측정 품질 \(appState.latestReport.measurementQuality.displayName)",
      kind: measurementQualityStatus,
      systemImage: "checkmark.seal"
    )
    NBStatusBadge(
      "커버리지 \(percentString(appState.latestReport.audioCoverageRatio))",
      kind: coverageStatus,
      systemImage: "waveform"
    )
  }

  private var actionLinks: some View {
    VStack(spacing: NBSpacing.md) {
      Button {
        selectedTab = .sleep
      } label: {
        Label("수면 시작하기", systemImage: "moon.zzz.fill")
      }
      .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.sleepTint))

      HStack(spacing: NBSpacing.md) {
        NavigationLink {
          SleepReportView(report: appState.latestReport, events: appState.latestEvents)
        } label: {
          Label("최근 리포트", systemImage: "doc.text.magnifyingglass")
        }
        .buttonStyle(.nbSecondary)

        NavigationLink {
          TrendDashboardView()
        } label: {
          Label("트렌드", systemImage: "chart.line.uptrend.xyaxis")
        }
        .buttonStyle(.nbSecondary)
      }

      dailyRhythmLinks

      Button {
        selectedTab = .health
      } label: {
        Label("건강 탭에서 자세히", systemImage: "heart.text.square")
      }
      .buttonStyle(.nbSecondary)
    }
  }

  private var dailyRhythmLinks: some View {
    NBReportSection(
      title: "Daily Rhythm",
      subtitle: "수면, 컨디션, 사용 가능한 건강 데이터를 하루 리듬으로 정리합니다.",
      systemImage: "sparkles"
    ) {
      VStack(spacing: NBSpacing.md) {
        HStack(spacing: NBSpacing.md) {
          NavigationLink {
            MorningBriefView(
              nightReport: appState.latestReport,
              morningCheckIn: appState.morningCheckIn
            )
          } label: {
            Label("아침 리포트", systemImage: "sunrise")
          }
          .buttonStyle(NBSecondaryButtonStyle(tint: NBColor.dawn))

          NavigationLink {
            DailyRhythmReportView(
              nightReport: appState.latestReport,
              morningCheckIn: appState.morningCheckIn
            )
          } label: {
            Label("오늘의 리듬", systemImage: "gauge.with.dots.needle.67percent")
          }
          .buttonStyle(NBSecondaryButtonStyle(tint: NBColor.accent))
        }

        HStack(spacing: NBSpacing.md) {
          NavigationLink {
            EveningCheckInView()
          } label: {
            Label("저녁 체크인", systemImage: "moon.haze")
          }
          .buttonStyle(NBSecondaryButtonStyle(tint: NBColor.sleepTint))

          NavigationLink {
            DailyHealthCardPreviewView(
              nightReport: appState.latestReport,
              morningCheckIn: appState.morningCheckIn
            )
          } label: {
            Label("하루 리듬 카드", systemImage: "rectangle.on.rectangle")
          }
          .buttonStyle(NBSecondaryButtonStyle(tint: NBColor.privacyTint))
        }
      }
    }
  }

  private var recentEventsSection: some View {
    NBReportSection(title: "최근 주요 이벤트", systemImage: "list.bullet.rectangle") {
      if recentEventSummaries.isEmpty {
        NBEmptyStateView(
          title: "표시할 주요 이벤트가 없습니다",
          message: "오디오 입력은 수신되었지만 detector 기준을 통과한 주요 이벤트가 없었을 수 있습니다.",
          systemImage: "waveform.slash",
          illustration: .emptyTimeline
        )
      } else {
        VStack(spacing: NBSpacing.sm) {
          ForEach(recentEventSummaries, id: \.title) { item in
            NBListRow(
              title: item.title,
              value: item.value,
              subtitle: item.subtitle,
              systemImage: item.systemImage,
              tint: item.tint
            )
          }
        }
      }
    }
  }

  private var eventAudioStorageSection: some View {
    NBReportSection(title: "이벤트 오디오 샘플", systemImage: "waveform.circle") {
      VStack(alignment: .leading, spacing: NBSpacing.sm) {
        NBStatusBadge(
          appState.isEventAudioSampleStorageEnabled ? "이벤트 샘플 저장 켜짐" : "이벤트 샘플 저장 꺼짐",
          kind: appState.isEventAudioSampleStorageEnabled ? .debug : .privacy,
          systemImage: appState.isEventAudioSampleStorageEnabled ? "waveform.circle" : "lock.shield"
        )
        Text(eventAudioStorageSummary)
          .font(NBTypography.callout)
          .foregroundStyle(NBColor.secondaryText)
        Text("이벤트 오디오 샘플은 사용자가 켠 경우에만 저장됩니다. 원본 전체 오디오는 저장하지 않습니다.")
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
      }
    }
  }

  private var calendarReports: [NightReport] {
    appState.trendReports(days: 370)
  }

  private var trendScores: [Int] {
    let storedScores = appState.recentReports
      .sorted { $0.generatedAt < $1.generatedAt }
      .suffix(7)
      .map(\.sleepSoundScore)

    guard !storedScores.isEmpty else {
      return [
        min(100, appState.latestReport.sleepSoundScore + 8),
        min(100, appState.latestReport.sleepSoundScore + 4),
        max(0, appState.latestReport.sleepSoundScore - 2),
        appState.latestReport.sleepSoundScore,
      ]
    }

    return storedScores
  }

  private var measurementQualityTint: Color {
    switch appState.latestReport.measurementQuality {
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

  private var measurementQualityStatus: NBStatusKind {
    switch appState.latestReport.measurementQuality {
    case .excellent, .good:
      return .good
    case .limited:
      return .caution
    case .poor:
      return .danger
    }
  }

  private var scoreTint: Color {
    switch appState.latestReport.sleepSoundScore {
    case 85...100:
      return NBColor.success
    case 70..<85:
      return NBColor.accent
    case 55..<70:
      return NBColor.warning
    default:
      return NBColor.danger
    }
  }

  private var scoreStatus: NBStatusKind {
    switch appState.latestReport.sleepSoundScore {
    case 85...100:
      return .good
    case 70..<85:
      return .neutral
    case 55..<70:
      return .caution
    default:
      return .warning
    }
  }

  private var coverageStatus: NBStatusKind {
    switch appState.latestReport.audioCoverageRatio {
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

  private var coverageTint: Color {
    coverageStatus.tint
  }

  private var coverageDescription: String {
    switch appState.latestReport.audioCoverageRatio {
    case 0.95...:
      return "좋음"
    case 0.85..<0.95:
      return "보통"
    case 0.60..<0.85:
      return "제한적"
    default:
      return "낮음"
    }
  }

  private var eventAudioStorageSummary: String {
    let stats = appState.eventAudioStorageStats
    guard stats.sampleCount > 0 else {
      return "저장된 이벤트 오디오 샘플 없음"
    }
    return "\(stats.sampleCount)개 · \(SleepFormatters.compactDurationString(stats.totalDurationSeconds)) · \(stats.formattedTotalSize)"
  }

  private var recentEventSummaries: [(title: String, value: String, subtitle: String, systemImage: String, tint: Color)] {
    let report = appState.latestReport
    let summaries: [(SleepEventType, String, String)] = [
      (.snore, SleepFormatters.durationString(report.snoreTotalSeconds), "코골기 시간"),
      (.bruxismLike, "\(report.bruxismLikeCount)회", "사용자 확인이 도움이 되는 항목"),
      (.breathingPauseSuspected, "\(report.suspectedBreathingPauseCount)회", "호흡정지 의심 구간"),
      (.gaspLike, "\(report.gaspLikeCount)회", "gasp-like 회복 호흡"),
      (.coughLike, "\(report.coughLikeCount)회", "기침 의심 소리"),
      (.environmentalNoise, "\(report.environmentalNoiseCount)회", "환경 소음"),
      (.awakeningSuspected, "\(report.awakeningSuspectedCount)회", "각성 의심 구간"),
    ]

    return summaries
      .filter { type, value, _ in
        type == .snore
          ? report.snoreTotalSeconds > 0
          : value != "0회"
      }
      .prefix(4)
      .map { type, value, subtitle in
        (
          title: type.timelineDisplayName,
          value: value,
          subtitle: subtitle,
          systemImage: type.symbolName,
          tint: type.tintColor
        )
      }
  }

  private var displayDetectedEventDuration: TimeInterval {
    if appState.latestReport.detectedEventDuration > 0 {
      return appState.latestReport.detectedEventDuration
    }

    return SleepEventAggregator().detectedEventDuration(events: appState.latestEvents)
  }

  private func percentString(_ ratio: Double) -> String {
    String(format: "%.0f%%", min(max(ratio, 0), 1) * 100)
  }

}

private enum HomeDashboardTab: Hashable {
  case home
  case sleep
  case health
  case settings
}

private struct DetectorSensitivitySettingsView: View {
  @EnvironmentObject private var appState: AppState

  var body: some View {
    List {
      Section("코골기 감지 민감도") {
        ForEach(DetectorTuningProfile.debugSelectableProfiles) { profile in
          Button {
            appState.setDetectorTuningProfile(profile)
          } label: {
            HStack(spacing: NBSpacing.sm) {
              VStack(alignment: .leading, spacing: 4) {
                Text(profile.displayName)
                  .font(NBTypography.body)
                  .foregroundStyle(NBColor.primaryText)
                Text(profile.koreanDescription)
                  .font(NBTypography.caption)
                  .foregroundStyle(NBColor.secondaryText)
                  .fixedSize(horizontal: false, vertical: true)
              }

              Spacer(minLength: NBSpacing.sm)

              if appState.detectorTuningProfile == profile {
                Image(systemName: "checkmark.circle.fill")
                  .foregroundStyle(NBColor.success)
                  .accessibilityHidden(true)
              }
            }
          }
          .disabled(appState.isRecording)
          .accessibilityLabel("\(profile.displayName) 민감도")
          .accessibilityValue(appState.detectorTuningProfile == profile ? "현재 선택됨" : "선택 가능")
        }
      }

      Section("적용 기준") {
        Text(
          appState.isRecording
            ? "측정 중에는 민감도를 바꾸지 않습니다. 수면 종료 후 다음 측정 전에 변경하세요."
            : "선택한 민감도는 다음 측정부터 적용됩니다. 기본값은 보통입니다."
        )
        .font(NBTypography.footnote)
        .foregroundStyle(NBColor.secondaryText)

        Text("민감도를 높이면 작은 코골기 후보를 더 잘 남길 수 있지만, 주변 소음 후보도 함께 늘 수 있어 조용한 구간과 함께 비교하세요.")
          .font(NBTypography.footnote)
          .foregroundStyle(NBColor.secondaryText)
      }
    }
    .navigationTitle("감지 민감도")
    .scrollContentBackground(.hidden)
    .background(NBColor.pageBackground)
    .toolbar(.hidden, for: .tabBar)
  }
}

private struct SettingsListView: View {
  @EnvironmentObject private var appState: AppState

  var body: some View {
    List {
      Section("시작하기") {
        Button {
          appState.resetOnboarding()
        } label: {
          Label("온보딩 다시 보기", systemImage: "arrow.counterclockwise.circle")
        }
        .disabled(!appState.canResetOnboarding)

        Text("개인정보 원칙, iPhone 배치, 마이크 권한, 30초 캘리브레이션 안내를 다시 확인합니다.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }

      Section("개인정보") {
        NavigationLink {
          PrivacySettingsView()
        } label: {
          Label("오디오와 데이터 보관", systemImage: "lock.shield")
        }
      }

      Section("측정 준비") {
        NavigationLink {
          DetectorSensitivitySettingsView()
        } label: {
          Label("코골기 감지 민감도", systemImage: "slider.horizontal.3")
        }

        NavigationLink {
          DevicePlacementGuideView()
        } label: {
          Label("iPhone 배치 가이드", systemImage: "iphone")
        }

        NavigationLink {
          CalibrationView()
        } label: {
          Label("30초 캘리브레이션", systemImage: "waveform.badge.magnifyingglass")
        }
      }

      #if DEBUG
        Section("개발") {
          NavigationLink {
            SampleCaptureView()
          } label: {
            Label("개발자용 샘플 수집", systemImage: "record.circle")
          }

          NavigationLink {
            AudioDebugView()
          } label: {
            Label("오디오 감지 Debug", systemImage: "waveform.and.magnifyingglass")
          }

          NavigationLink {
            DebugAudioSamplesView()
          } label: {
            Label("DEBUG 오디오 샘플", systemImage: "waveform.circle")
          }

          NavigationLink {
            DetectorTuningView()
          } label: {
            Label("Detector 튜닝", systemImage: "slider.horizontal.3")
          }

          NavigationLink {
            DatasetReplayView()
          } label: {
            Label("Dataset Replay", systemImage: "play.rectangle.on.rectangle")
          }

          NavigationLink {
            SimulatorScenarioView()
          } label: {
            Label("Simulator QA / Screenshot Scenario", systemImage: "iphone.gen3.radiowaves.left.and.right")
          }

          Text("개인 오디오 샘플은 서버로 전송되지 않습니다. 전체 밤 오디오는 저장하지 않으며, 이 기능은 Release 빌드에 포함되지 않습니다.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      #endif
    }
    .scrollContentBackground(.hidden)
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
  }
}
