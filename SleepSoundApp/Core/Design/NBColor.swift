import SwiftUI

enum NBColor {
  static let background = Color(red: 0.950, green: 0.958, blue: 0.980)
  static let groupedBackground = Color(red: 0.929, green: 0.941, blue: 0.968)
  static let cardBackground = Color(red: 0.992, green: 0.994, blue: 1.000)
  static let elevatedCardBackground = Color(red: 0.969, green: 0.979, blue: 0.996)

  static let primaryText = Color(red: 0.070, green: 0.092, blue: 0.145)
  static let secondaryText = Color(red: 0.330, green: 0.380, blue: 0.470)
  static let tertiaryText = Color(red: 0.520, green: 0.560, blue: 0.640)

  static let accent = Color(red: 0.176, green: 0.353, blue: 0.735)
  static let accentSoft = Color(red: 0.835, green: 0.878, blue: 0.980)
  static let sleep = Color(red: 0.235, green: 0.302, blue: 0.647)
  static let breath = Color(red: 0.075, green: 0.470, blue: 0.535)
  static let privacy = Color(red: 0.095, green: 0.415, blue: 0.405)

  static let success = Color(red: 0.145, green: 0.540, blue: 0.355)
  static let warning = Color(red: 0.820, green: 0.455, blue: 0.135)
  static let caution = Color(red: 0.730, green: 0.600, blue: 0.170)
  static let danger = Color(red: 0.780, green: 0.210, blue: 0.250)
  static let neutral = Color(red: 0.430, green: 0.480, blue: 0.560)

  static let border = Color(red: 0.800, green: 0.835, blue: 0.900)
  static let divider = Color(red: 0.865, green: 0.890, blue: 0.935)
  static let chartPrimary = accent
  static let chartSecondary = breath

  static let quietIndigo = Color(red: 0.350, green: 0.380, blue: 0.720)
  static let mistTeal = breath
  static let lavender = Color(red: 0.500, green: 0.360, blue: 0.720)
  static let dawn = Color(red: 0.880, green: 0.540, blue: 0.220)

  static let pageBackground = background
  static let surface = cardBackground
  static let elevatedSurface = elevatedCardBackground
  static let cardStroke = border
  static let nightInk = primaryText
  static let mutedText = secondaryText
  static let breathBlue = accent
  static let privacyTint = privacy
  static let sleepTint = sleep
  static let audioTint = lavender
}
