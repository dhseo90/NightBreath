import SwiftUI

struct NBMetricCard: View {
  let title: String
  let value: String
  let systemImage: String
  var tint: Color = NBColor.breathBlue
  var footnote: String?

  var body: some View {
    NBCard(padding: NBSpacing.medium) {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        HStack(alignment: .center) {
          Image(systemName: systemImage)
            .font(.headline)
            .foregroundStyle(tint)
            .frame(width: 30, height: 30)
            .background(tint.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
          Spacer()
        }

        Text(title)
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.mutedText)
          .lineLimit(2)

        Text(value)
          .font(NBTypography.metricValue)
          .foregroundStyle(NBColor.nightInk)
          .lineLimit(1)
          .minimumScaleFactor(0.72)

        if let footnote {
          Text(footnote)
            .font(.caption2)
            .foregroundStyle(NBColor.mutedText)
            .lineLimit(2)
        }
      }
    }
    .accessibilityElement(children: .combine)
  }
}
