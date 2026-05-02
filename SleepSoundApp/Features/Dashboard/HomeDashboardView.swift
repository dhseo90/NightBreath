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
            VStack(alignment: .leading, spacing: 20) {
                scoreHeader

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    DashboardMetricTile(
                        title: "앱 동작 시간",
                        value: SleepFormatters.compactDurationString(appState.latestReport.measurementDuration),
                        systemImage: "clock",
                        tint: .blue
                    )
                    DashboardMetricTile(
                        title: "추정 수면 시간",
                        value: SleepFormatters.compactDurationString(appState.latestReport.estimatedSleepDuration),
                        systemImage: "bed.double",
                        tint: .teal
                    )
                    DashboardMetricTile(
                        title: "코골기",
                        value: SleepFormatters.durationString(appState.latestReport.snoreTotalSeconds),
                        systemImage: SleepEventType.snore.symbolName,
                        tint: SleepEventType.snore.tintColor
                    )
                    DashboardMetricTile(
                        title: "감지 이벤트",
                        value: SleepFormatters.compactDurationString(displayDetectedEventDuration),
                        systemImage: "waveform.and.magnifyingglass",
                        tint: .purple
                    )
                    DashboardMetricTile(
                        title: "저장 오디오",
                        value: SleepFormatters.compactDurationString(appState.latestReport.savedAudioDuration),
                        systemImage: "externaldrive.badge.xmark",
                        tint: .gray
                    )
                    DashboardMetricTile(
                        title: "호흡정지 의심",
                        value: "\(appState.latestReport.suspectedPauseCount)회",
                        systemImage: SleepEventType.breathingPauseSuspected.symbolName,
                        tint: SleepEventType.breathingPauseSuspected.tintColor
                    )
                    DashboardMetricTile(
                        title: "측정 품질",
                        value: appState.latestReport.measurementQuality.displayName,
                        systemImage: "checkmark.seal",
                        tint: measurementQualityTint
                    )
                    DashboardMetricTile(
                        title: "오디오 커버리지",
                        value: percentString(appState.latestReport.audioCoverageRatio),
                        systemImage: "waveform",
                        tint: .indigo
                    )
                }

                NavigationLink {
                    SleepReportView(report: appState.latestReport, events: appState.latestEvents)
                } label: {
                    Label("최근 리포트 보기", systemImage: "doc.text.magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                VStack(alignment: .leading, spacing: 10) {
                    Text("최근 수면 소리 점수")
                        .font(.headline)
                    TrendChartView(scores: trendScores)
                        .frame(height: 160)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                healthPlaceholder
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var scoreHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: CGFloat(appState.latestReport.sleepSoundScore) / 100)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text("\(appState.latestReport.sleepSoundScore)")
                            .font(.system(size: 34, weight: .bold))
                        Text("/100")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 112, height: 112)

                VStack(alignment: .leading, spacing: 8) {
                    Text("최근 수면 리포트")
                        .font(.title3.bold())
                    Label(appState.latestReportSource.displayText, systemImage: appState.latestReportSource.systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(SleepFormatters.shortDate(appState.latestReport.generatedAt))
                        .foregroundStyle(.secondary)
                    Text("측정 품질: \(appState.latestReport.measurementQuality.displayName) · 오디오 커버리지 \(percentString(appState.latestReport.audioCoverageRatio))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(appState.latestReport.mainDisturbanceReason)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                }
            }

            if let hourRange = appState.latestReport.mostDisturbedHourRange {
                Label("가장 방해가 컸던 시간대 \(hourRange)", systemImage: "exclamationmark.magnifyingglass")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var healthPlaceholder: some View {
        let placeholder = HealthDashboardPlaceholder()
        return VStack(alignment: .leading, spacing: 10) {
            Label(placeholder.title, systemImage: "heart.text.square")
                .font(.headline)
            Text(placeholder.message)
                .font(.callout)
                .foregroundStyle(.secondary)
            Text(placeholder.plannedMetrics.prefix(5).map(\.displayName).joined(separator: " · "))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
                appState.latestReport.sleepSoundScore
            ]
        }

        return storedScores
    }

    private var measurementQualityTint: Color {
        switch appState.latestReport.measurementQuality {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .limited:
            return .orange
        case .poor:
            return .red
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

                Text("개인 오디오 샘플은 서버로 전송되지 않습니다. 전체 밤 오디오는 저장하지 않으며, 이 기능은 Release 빌드에 포함되지 않습니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            #endif
        }
    }
}
