import SwiftUI

struct NBReportSection<Content: View>: View {
  let title: String
  let subtitle: String?
  let systemImage: String?
  private let content: Content

  init(
    title: String,
    subtitle: String? = nil,
    systemImage: String? = nil,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.subtitle = subtitle
    self.systemImage = systemImage
    self.content = content()
  }

  var body: some View {
    NBCard {
      VStack(alignment: .leading, spacing: NBSpacing.md) {
        HStack(alignment: .firstTextBaseline, spacing: NBSpacing.sm) {
          if let systemImage {
            Image(systemName: systemImage)
              .foregroundStyle(NBColor.accent)
              .accessibilityHidden(true)
          }
          Text(title)
            .font(NBTypography.sectionTitle)
            .foregroundStyle(NBColor.primaryText)
        }

        if let subtitle {
          Text(subtitle)
            .font(NBTypography.caption)
            .foregroundStyle(NBColor.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
        }

        content
      }
    }
  }
}
