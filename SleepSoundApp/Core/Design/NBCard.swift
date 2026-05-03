import SwiftUI

struct NBCard<Content: View>: View {
  private let padding: CGFloat
  private let background: Color
  private let stroke: Color
  private let shadowStyle: NBShadowStyle
  private let content: Content

  init(
    padding: CGFloat = NBSpacing.cardPadding,
    background: Color = NBColor.cardBackground,
    stroke: Color = NBColor.border,
    shadow: NBShadowStyle = NBShadow.card,
    @ViewBuilder content: () -> Content
  ) {
    self.padding = padding
    self.background = background
    self.stroke = stroke
    self.shadowStyle = shadow
    self.content = content()
  }

  var body: some View {
    content
      .padding(padding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(background)
      .overlay(
        RoundedRectangle(cornerRadius: NBCornerRadius.card, style: .continuous)
          .stroke(stroke.opacity(0.60), lineWidth: 0.6)
      )
      .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.card, style: .continuous))
      .nbShadow(shadowStyle)
  }
}
