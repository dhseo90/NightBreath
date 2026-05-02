import SwiftUI

struct SleepTimelineView: View {
    let report: NightReport
    let events: [SleepEvent]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("이벤트 타임라인")
                        .font(.title2.bold())
                    Text("감지된 수면 중 소리 이벤트를 시간 순서로 확인합니다.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                EventTimelineBand(events: events)
                    .frame(height: 130)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(events) { event in
                        EventRow(event: event)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("타임라인")
        .background(Color(.systemGroupedBackground))
    }
}

private struct EventTimelineBand: View {
    let events: [SleepEvent]

    var body: some View {
        GeometryReader { proxy in
            if let start = events.map(\.startedAt).min(),
               let end = events.map(\.endedAt).max() {
                let total = max(end.timeIntervalSince(start), 1)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                        .position(x: proxy.size.width / 2, y: proxy.size.height - 24)

                    ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                        let x = proxy.size.width * CGFloat(event.startedAt.timeIntervalSince(start) / total)
                        let width = max(CGFloat(4), proxy.size.width * CGFloat(event.duration / total))
                        Capsule()
                            .fill(event.type.tintColor.opacity(0.82))
                            .frame(width: min(width, proxy.size.width), height: 10)
                            .position(x: min(proxy.size.width - width / 2, max(width / 2, x + width / 2)), y: yPosition(for: index))
                    }

                    Text(SleepFormatters.shortTime(start))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .position(x: 24, y: proxy.size.height - 4)

                    Text(SleepFormatters.shortTime(end))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .position(x: proxy.size.width - 24, y: proxy.size.height - 4)
                }
            } else {
                ContentUnavailableView("감지된 이벤트 없음", systemImage: "waveform.slash")
            }
        }
    }

    private func yPosition(for index: Int) -> CGFloat {
        CGFloat(18 + (index % 6) * 15)
    }
}

private struct EventRow: View {
    let event: SleepEvent

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: event.type.symbolName)
                .foregroundStyle(event.type.tintColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.type.displayName)
                    .font(.headline)
                Text("\(SleepFormatters.shortTime(event.startedAt)) · \(SleepFormatters.compactDurationString(event.duration)) · 신뢰도 \(Int(event.confidence * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Circle()
                .fill(event.type.tintColor)
                .frame(width: 10, height: 10)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
