import SwiftUI

enum NBSpacing {
  static let xxs: CGFloat = 4
  static let xs: CGFloat = 6
  static let sm: CGFloat = 8
  static let md: CGFloat = 12
  static let lg: CGFloat = 16
  static let xl: CGFloat = 20
  static let xxl: CGFloat = 24

  static let screenHorizontal: CGFloat = 20
  static let sectionVertical: CGFloat = 24
  static let cardPadding: CGFloat = 16
  static let rowPadding: CGFloat = 12
  static let floatingTabBarAvoidance: CGFloat = 0

  static let xSmall = xxs
  static let small = sm
  static let medium = md
  static let large = lg
  static let xLarge = xl
  static let xxLarge = xxl
}

extension View {
  @ViewBuilder
  func nbAvoidFloatingTabBar(background: Color = NBColor.pageBackground) -> some View {
    if NBSpacing.floatingTabBarAvoidance > 0 {
      safeAreaInset(edge: .bottom, spacing: 0) {
        background
          .frame(height: NBSpacing.floatingTabBarAvoidance)
          .allowsHitTesting(false)
      }
    } else {
      self
    }
  }
}
