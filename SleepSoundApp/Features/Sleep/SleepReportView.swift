import SwiftUI

struct SleepReportView: View {
    let report: NightReport
    let events: [SleepEvent]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                metrics
                reasonCard

                NavigationLink {
                    SleepTimelineView(report: report, events: events)
                } label: {
                    Label("이벤트 타임라인 보기", systemImage: "timeline.selection")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                NavigationLink {
                    MorningCheckInView(sessionId: report.sessionId)
                } label: {
                    Label("아침 컨디션 기록", systemImage: "sun.max")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("수면 리포트")
        .background(Color(.systemGroupedBackground))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(report.sleepSoundScore)")
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                Text("/100")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "waveform.path.ecg")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
            }

            Text("수면 소리 점수")
                .font(.headline)
            Text("감지된 소리와 수면 중 소리 기반 지표로 만든 웰니스 리포트입니다.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var metrics: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ReportMetricCard(title: "측정 시간", value: SleepFormatters.durationString(report.measurementDuration), color: .blue)
            ReportMetricCard(title: "추정 수면 시간", value: SleepFormatters.durationString(report.estimatedSleepDuration), color: .teal)
            ReportMetricCard(title: "코골기", value: SleepFormatters.durationString(report.snoreTotalSeconds), color: SleepEventType.snore.tintColor)
            ReportMetricCard(title: "이갈이 의심", value: "\(report.bruxismLikeCount)회", color: SleepEventType.bruxismLike.tintColor)
            ReportMetricCard(title: "호흡정지 의심", value: "\(report.suspectedPauseCount)회", color: SleepEventType.breathingPauseSuspected.tintColor)
            ReportMetricCard(title: "gasp-like", value: "\(report.gaspLikeCount)회", color: SleepEventType.gaspLike.tintColor)
            ReportMetricCard(title: "기침 의심", value: "\(report.coughLikeCount)회", color: SleepEventType.coughLike.tintColor)
            ReportMetricCard(title: "환경 소음", value: "\(report.environmentalNoiseCount)회", color: SleepEventType.environmentalNoise.tintColor)
            ReportMetricCard(title: "각성 의심", value: "\(report.awakeningSuspectedCount)회", color: SleepEventType.awakeningSuspected.tintColor)
            ReportMetricCard(title: "최장 의심 구간", value: SleepFormatters.compactDurationString(report.longestSuspectedPause), color: .red)
        }
    }

    private var reasonCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("주요 원인 설명")
                .font(.headline)
            Text(report.mainDisturbanceReason)
                .font(.body)
                .foregroundStyle(.secondary)

            if let hourRange = report.mostDisturbedHourRange {
                Divider()
                Label("가장 방해가 컸던 시간대 \(hourRange)", systemImage: "clock.badge.exclamationmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ReportMetricCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
