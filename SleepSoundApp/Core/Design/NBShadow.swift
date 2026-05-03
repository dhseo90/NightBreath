import SwiftUI

struct NBShadowStyle {
  let color: Color
  let radius: CGFloat
  let x: CGFloat
  let y: CGFloat
}

enum NBShadow {
  static let none = NBShadowStyle(color: Color.black.opacity(0), radius: 0, x: 0, y: 0)
  static let subtle = NBShadowStyle(color: Color.black.opacity(0.025), radius: 4, x: 0, y: 1)
  static let card = NBShadowStyle(color: Color.black.opacity(0.045), radius: 8, x: 0, y: 3)
  static let elevated = NBShadowStyle(color: Color.black.opacity(0.070), radius: 14, x: 0, y: 6)

  static let cardColor = card.color
  static let cardRadius = card.radius
  static let cardY = card.y
}

extension View {
  func nbShadow(_ style: NBShadowStyle) -> some View {
    shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
  }
}
