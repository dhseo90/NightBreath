import SwiftUI

struct NBTimelineRow<Accessory: View>: View {
  let title: String
  let subtitle: String
  let detail: String?
  let systemImage: String
  let tint: Color
  private let accessory: Accessory

  init(
    title: String,
    subtitle: String,
    detail: String? = nil,
    systemImage: String,
    tint: Color,
    @ViewBuilder accessory: () -> Accessory
  ) {
    self.title = title
    self.subtitle = subtitle
    self.detail = detail
    self.systemImage = systemImage
    self.tint = tint
    self.accessory = accessory()
  }

  var body: some View {
    NBCard {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        HStack(alignment: .top, spacing: NBSpacing.medium) {
          Image(systemName: systemImage)
            .font(.headline)
            .foregroundStyle(tint)
            .frame(width: 34, height: 34)
            .background(tint.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))

          VStack(alignment: .leading, spacing: NBSpacing.xSmall) {
            Text(title)
              .font(NBTypography.sectionTitle)
            Text(subtitle)
              .font(NBTypography.caption)
              .foregroundStyle(NBColor.mutedText)
            if let detail {
              Text(detail)
                .font(NBTypography.caption)
                .foregroundStyle(NBColor.mutedText)
                .fixedSize(horizontal: false, vertical: true)
            }
          }

          Spacer()

          Circle()
            .fill(tint)
            .frame(width: 9, height: 9)
            .accessibilityHidden(true)
        }

        accessory
      }
    }
  }
}
