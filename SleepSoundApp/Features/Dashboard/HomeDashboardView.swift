import SwiftUI

struct HomeDashboardView: View {
  @EnvironmentObject private var appState: AppState

  var body: some View {
    TabView {
      NavigationStack {
        dashboardContent
          .navigationTitle("NightBreath")
      }
      .tabItem {
        Label("홈", systemImage: "house")
      }

      NavigationStack {
        SleepStartView()
          .navigationTitle("수면")
      }
      .tabItem {
        Label("수면", systemImage: "moon.zzz")
      }

      NavigationStack {
        SettingsListView()
          .navigationTitle("설정")
      }
      .tabItem {
        Label("설정", systemImage: "gearshape")
      }
    }
  }

  private var dashboardContent: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.xLarge) {
        scoreHeader

        LazyVGrid(
          columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.medium
        ) {
          NBMetricCard(
            title: "앱 동작 시간",
            value: SleepFormatters.compactDurationString(appState.latestReport.measurementDuration),
            systemImage: "clock",
            tint: NBColor.breathBlue
          )
          NBMetricCard(
            title: "추정 수면 시간",
            value: SleepFormatters.compactDurationString(
              appState.latestReport.estimatedSleepDuration),
            systemImage: "bed.double",
            tint: NBColor.mistTeal
          )
          NBMetricCard(
            title: "코골기",
            value: SleepFormatters.durationString(appState.latestReport.snoreTotalSeconds),
            systemImage: SleepEventType.snore.symbolName,
            tint: SleepEventType.snore.tintColor
          )
          NBMetricCard(
            title: "감지 이벤트",
            value: SleepFormatters.compactDurationString(displayDetectedEventDuration),
            systemImage: "waveform.and.magnifyingglass",
            tint: NBColor.audioTint
          )
          NBMetricCard(
            title: "저장 오디오",
            value: SleepFormatters.compactDurationString(appState.latestReport.savedAudioDuration),
            systemImage: "externaldrive.badge.xmark",
            tint: NBColor.neutral
          )
          NBMetricCard(
            title: "호흡정지 의심",
            value: "\(appState.latestReport.suspectedPauseCount)회",
            systemImage: SleepEventType.breathingPauseSuspected.symbolName,
            tint: SleepEventType.breathingPauseSuspected.tintColor
          )
          NBMetricCard(
            title: "측정 품질",
            value: appState.latestReport.measurementQuality.displayName,
            systemImage: "checkmark.seal",
            tint: measurementQualityTint
          )
          NBMetricCard(
            title: "오디오 커버리지",
            value: percentString(appState.latestReport.audioCoverageRatio),
            systemImage: "waveform",
            tint: NBColor.quietIndigo
          )
        }

        NavigationLink {
          SleepStartView()
        } label: {
          Label("수면 시작하기", systemImage: "moon.zzz.fill")
        }
        .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.sleepTint))

        NavigationLink {
          SleepReportView(report: appState.latestReport, events: appState.latestEvents)
        } label: {
          Label("최근 리포트 보기", systemImage: "doc.text.magnifyingglass")
        }
        .buttonStyle(.nbSecondary)

        NBReportSection(title: "최근 수면 소리 점수", systemImage: "chart.xyaxis.line") {
          TrendChartView(scores: trendScores)
            .frame(height: 160)
        }

        NBPrivacyNoticeCard(
          title: "온디바이스 분석",
          message: "분석은 iPhone 안에서 수행됩니다. 서버 전송은 없고, 원본 전체 오디오는 저장하지 않습니다.",
          systemImage: "iphone.gen3.radiowaves.left.and.right"
        )

        healthPlaceholder
      }
      .padding(NBSpacing.large)
    }
    .background(NBColor.pageBackground)
  }

  private var scoreHeader: some View {
    NBCard {
      VStack(alignment: .leading, spacing: NBSpacing.large) {
        HStack(alignment: .center, spacing: NBSpacing.large) {
          ZStack {
            Circle()
              .stroke(NBColor.cardStroke.opacity(0.55), lineWidth: 12)
            Circle()
              .trim(from: 0, to: CGFloat(appState.latestReport.sleepSoundScore) / 100)
              .stroke(NBColor.breathBlue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
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
            Text("최근 수면 리포트")
              .font(NBTypography.cardTitle)
            Label(
              appState.latestReportSource.displayText,
              systemImage: appState.latestReportSource.systemImage
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            Text(SleepFormatters.shortDate(appState.latestReport.generatedAt))
              .foregroundStyle(.secondary)
            Text(
              "측정 품질: \(appState.latestReport.measurementQuality.displayName) · 오디오 커버리지 \(percentString(appState.latestReport.audioCoverageRatio))"
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            Text(appState.latestReport.mainDisturbanceReason)
              .font(.callout)
              .foregroundStyle(.secondary)
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

        if appState.eventAudioStorageStats.sampleCount > 0 {
          NBStatusBadge(
            "이벤트 오디오 \(appState.eventAudioStorageStats.formattedTotalSize)",
            systemImage: "waveform.circle",
            tint: NBColor.audioTint
          )
        }
      }
    }
  }

  private var healthPlaceholder: some View {
    let placeholder = HealthDashboardPlaceholder()
    return NBCard {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        Label(placeholder.title, systemImage: "heart.text.square")
          .font(.headline)
        Text(placeholder.message)
          .font(.callout)
          .foregroundStyle(.secondary)
        Text(placeholder.plannedMetrics.prefix(5).map(\.displayName).joined(separator: " · "))
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
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

private struct DashboardMetricTile: View {
  let title: String
  let value: String
  let systemImage: String
  let tint: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Image(systemName: systemImage)
        .font(.title3)
        .foregroundStyle(tint)
        .frame(width: 28, height: 28)
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(value)
        .font(.headline)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}

private struct SettingsListView: View {
  var body: some View {
    List {
      Section("개인정보") {
        NavigationLink {
          PrivacySettingsView()
        } label: {
          Label("오디오와 데이터 보관", systemImage: "lock.shield")
        }
      }

      Section("측정 준비") {
        NavigationLink {
          DevicePlacementGuideView()
        } label: {
          Label("iPhone 배치 가이드", systemImage: "iphone")
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
            Label("Simulator QA Scenario", systemImage: "iphone.gen3.radiowaves.left.and.right")
          }

          Text("개인 오디오 샘플은 서버로 전송되지 않습니다. 전체 밤 오디오는 저장하지 않으며, 이 기능은 Release 빌드에 포함되지 않습니다.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      #endif
    }
    .scrollContentBackground(.hidden)
    .background(NBColor.pageBackground)
  }
}
