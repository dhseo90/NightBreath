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
                        title: "측정 시간",
                        value: SleepFormatters.durationString(appState.latestReport.measurementDuration),
                        systemImage: "clock",
                        tint: .blue
                    )
                    DashboardMetricTile(
                        title: "추정 수면 시간",
                        value: SleepFormatters.durationString(appState.latestReport.estimatedSleepDuration),
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
                        title: "호흡정지 의심",
                        value: "\(appState.latestReport.suspectedPauseCount)회",
                        systemImage: SleepEventType.breathingPauseSuspected.symbolName,
                        tint: SleepEventType.breathingPauseSuspected.tintColor
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
                    Text(SleepFormatters.shortDate(appState.latestReport.generatedAt))
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
        [
            min(100, appState.latestReport.sleepSoundScore + 8),
            min(100, appState.latestReport.sleepSoundScore + 4),
            max(0, appState.latestReport.sleepSoundScore - 2),
            appState.latestReport.sleepSoundScore
        ]
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
        }
    }
}
