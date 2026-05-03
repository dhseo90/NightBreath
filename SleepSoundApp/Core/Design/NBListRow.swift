import SwiftUI

struct NBListRow: View {
  let title: String
  let value: String?
  let subtitle: String?
  let systemImage: String
  var tint: Color = NBColor.accent
  var accessibilityLabelText: String?

  init(
    title: String,
    value: String? = nil,
    subtitle: String? = nil,
    systemImage: String,
    tint: Color = NBColor.accent,
    accessibilityLabel: String? = nil
  ) {
    self.title = title
    self.value = value
    self.subtitle = subtitle
    self.systemImage = systemImage
    self.tint = tint
    self.accessibilityLabelText = accessibilityLabel
  }

  var body: some View {
    HStack(alignment: .top, spacing: NBSpacing.medium) {
      Image(systemName: systemImage)
        .font(.body.weight(.semibold))
        .foregroundStyle(tint)
        .frame(width: 28, height: 28)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))

      VStack(alignment: .leading, spacing: NBSpacing.xSmall) {
        HStack(alignment: .firstTextBaseline) {
          Text(title)
            .font(.subheadline.weight(.semibold))
          Spacer()
          if let value {
            Text(value)
              .font(.subheadline.monospacedDigit().weight(.semibold))
              .foregroundStyle(NBColor.mutedText)
              .multilineTextAlignment(.trailing)
          }
        }

        if let subtitle {
          Text(subtitle)
            .font(NBTypography.caption)
            .foregroundStyle(NBColor.mutedText)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
    .padding(.vertical, NBSpacing.rowPadding)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityLabelText ?? defaultAccessibilityLabel)
  }

  private var defaultAccessibilityLabel: String {
    [title, value, subtitle]
      .compactMap { $0 }
      .joined(separator: ", ")
  }
}
