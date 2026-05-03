import SwiftUI

struct NBCard<Content: View>: View {
  private let padding: CGFloat
  private let background: Color
  private let content: Content

  init(
    padding: CGFloat = NBSpacing.large,
    background: Color = NBColor.surface,
    @ViewBuilder content: () -> Content
  ) {
    self.padding = padding
    self.background = background
    self.content = content()
  }

  var body: some View {
    content
      .padding(padding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(background)
      .overlay(
        RoundedRectangle(cornerRadius: NBCornerRadius.medium, style: .continuous)
          .stroke(NBColor.cardStroke.opacity(0.55), lineWidth: 0.6)
      )
      .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.medium, style: .continuous))
      .shadow(color: NBShadow.cardColor, radius: NBShadow.cardRadius, x: 0, y: NBShadow.cardY)
  }
}

struct NBReportSection<Content: View>: View {
  let title: String
  let systemImage: String
  private let content: Content

  init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.systemImage = systemImage
    self.content = content()
  }

  var body: some View {
    NBCard {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        Label(title, systemImage: systemImage)
          .font(NBTypography.sectionTitle)
          .foregroundStyle(NBColor.nightInk)
        content
      }
    }
  }
}

struct NBPrivacyNoticeCard: View {
  let title: String
  let message: String
  var systemImage: String = "lock.shield"

  var body: some View {
    NBCard(background: NBColor.privacyTint.opacity(0.10)) {
      HStack(alignment: .top, spacing: NBSpacing.medium) {
        Image(systemName: systemImage)
          .font(.title3.weight(.semibold))
          .foregroundStyle(NBColor.privacyTint)
          .frame(width: 28)

        VStack(alignment: .leading, spacing: NBSpacing.xSmall) {
          Text(title)
            .font(NBTypography.sectionTitle)
          Text(message)
            .font(NBTypography.callout)
            .foregroundStyle(NBColor.mutedText)
        }
      }
    }
  }
}

struct NBDiagnosticCard<Content: View>: View {
  let title: String
  let systemImage: String
  private let content: Content

  init(
    title: String, systemImage: String = "waveform.and.magnifyingglass",
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.systemImage = systemImage
    self.content = content()
  }

  var body: some View {
    NBCard(background: NBColor.audioTint.opacity(0.08)) {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        Label(title, systemImage: systemImage)
          .font(NBTypography.sectionTitle)
          .foregroundStyle(NBColor.audioTint)
        content
      }
    }
  }
}
