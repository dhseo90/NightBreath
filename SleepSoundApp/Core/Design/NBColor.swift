import SwiftUI

enum NBColor {
  static let pageBackground = Color(red: 0.955, green: 0.965, blue: 0.985)
  #if os(iOS)
    static let surface = Color(uiColor: .secondarySystemBackground)
    static let elevatedSurface = Color(uiColor: .tertiarySystemBackground)
  #else
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let elevatedSurface = Color(nsColor: .windowBackgroundColor)
  #endif
  static let cardStroke = Color(red: 0.82, green: 0.86, blue: 0.92)

  static let nightInk = Color(red: 0.09, green: 0.12, blue: 0.20)
  static let mutedText = Color.secondary
  static let breathBlue = Color(red: 0.18, green: 0.36, blue: 0.78)
  static let quietIndigo = Color(red: 0.35, green: 0.38, blue: 0.72)
  static let mistTeal = Color(red: 0.08, green: 0.50, blue: 0.54)
  static let lavender = Color(red: 0.50, green: 0.36, blue: 0.72)
  static let dawn = Color(red: 0.88, green: 0.54, blue: 0.22)

  static let success = Color(red: 0.17, green: 0.57, blue: 0.36)
  static let warning = Color(red: 0.86, green: 0.50, blue: 0.13)
  static let danger = Color(red: 0.82, green: 0.24, blue: 0.24)
  static let neutral = Color(red: 0.43, green: 0.48, blue: 0.56)

  static let privacyTint = Color(red: 0.12, green: 0.48, blue: 0.50)
  static let sleepTint = Color(red: 0.24, green: 0.33, blue: 0.72)
  static let audioTint = Color(red: 0.40, green: 0.32, blue: 0.70)
}
