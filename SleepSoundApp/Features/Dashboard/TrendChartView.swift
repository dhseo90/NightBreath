import SwiftUI

struct TrendChartView: View {
    let scores: [Int]

    var body: some View {
        GeometryReader { proxy in
            let barWidth = max(CGFloat(18), (proxy.size.width - CGFloat(max(scores.count - 1, 0)) * 12) / CGFloat(max(scores.count, 1)))

            HStack(alignment: .bottom, spacing: 12) {
                ForEach(Array(scores.enumerated()), id: \.offset) { index, score in
                    VStack(spacing: 8) {
                        Text("\(score)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(NBColor.secondaryText)

                        RoundedRectangle(cornerRadius: 5)
                            .fill(index == scores.count - 1 ? NBColor.chartPrimary : NBColor.chartSecondary.opacity(0.72))
                            .frame(
                                width: barWidth,
                                height: max(12, proxy.size.height * CGFloat(score) / 120)
                            )

                        Text(index == scores.count - 1 ? "최근" : "\(index + 1)")
                            .font(.caption2)
                            .foregroundStyle(NBColor.secondaryText)
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("최근 수면 소리 점수 추이")
    }
}
