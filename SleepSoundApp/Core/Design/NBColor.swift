import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum NBColor {
  private struct RGBA {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
  }

  static let background = adaptive(
    light: rgba(0.950, 0.958, 0.980),
    dark: rgba(0.031, 0.047, 0.086)
  )
  static let groupedBackground = adaptive(
    light: rgba(0.929, 0.941, 0.968),
    dark: rgba(0.051, 0.075, 0.133)
  )
  static let cardBackground = adaptive(
    light: rgba(0.992, 0.994, 1.000),
    dark: rgba(0.071, 0.102, 0.169)
  )
  static let elevatedCardBackground = adaptive(
    light: rgba(0.969, 0.979, 0.996),
    dark: rgba(0.094, 0.133, 0.208)
  )

  static let primaryText = adaptive(
    light: rgba(0.070, 0.092, 0.145),
    dark: rgba(0.945, 0.961, 1.000)
  )
  static let secondaryText = adaptive(
    light: rgba(0.330, 0.380, 0.470),
    dark: rgba(0.720, 0.761, 0.839)
  )
  static let tertiaryText = adaptive(
    light: rgba(0.520, 0.560, 0.640),
    dark: rgba(0.538, 0.580, 0.667)
  )

  static let accent = adaptive(
    light: rgba(0.176, 0.353, 0.735),
    dark: rgba(0.560, 0.671, 1.000)
  )
  static let accentSoft = adaptive(
    light: rgba(0.835, 0.878, 0.980),
    dark: rgba(0.114, 0.165, 0.302)
  )
  static let sleep = adaptive(
    light: rgba(0.235, 0.302, 0.647),
    dark: rgba(0.663, 0.706, 1.000)
  )
  static let breath = adaptive(
    light: rgba(0.075, 0.470, 0.535),
    dark: rgba(0.494, 0.855, 0.890)
  )
  static let privacy = adaptive(
    light: rgba(0.095, 0.415, 0.405),
    dark: rgba(0.447, 0.831, 0.788)
  )

  static let success = adaptive(
    light: rgba(0.145, 0.540, 0.355),
    dark: rgba(0.447, 0.851, 0.608)
  )
  static let warning = adaptive(
    light: rgba(0.820, 0.455, 0.135),
    dark: rgba(0.953, 0.706, 0.416)
  )
  static let caution = adaptive(
    light: rgba(0.730, 0.600, 0.170),
    dark: rgba(0.882, 0.792, 0.380)
  )
  static let danger = adaptive(
    light: rgba(0.780, 0.210, 0.250),
    dark: rgba(1.000, 0.541, 0.573)
  )
  static let neutral = adaptive(
    light: rgba(0.430, 0.480, 0.560),
    dark: rgba(0.667, 0.706, 0.769)
  )

  static let border = adaptive(
    light: rgba(0.800, 0.835, 0.900),
    dark: rgba(0.165, 0.212, 0.314)
  )
  static let divider = adaptive(
    light: rgba(0.865, 0.890, 0.935),
    dark: rgba(0.133, 0.188, 0.286)
  )
  static let chartPrimary = accent
  static let chartSecondary = breath

  static let quietIndigo = adaptive(
    light: rgba(0.350, 0.380, 0.720),
    dark: rgba(0.659, 0.682, 1.000)
  )
  static let mistTeal = breath
  static let lavender = adaptive(
    light: rgba(0.500, 0.360, 0.720),
    dark: rgba(0.820, 0.710, 1.000)
  )
  static let dawn = adaptive(
    light: rgba(0.880, 0.540, 0.220),
    dark: rgba(0.953, 0.698, 0.463)
  )

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

  private static func rgba(
    _ red: Double,
    _ green: Double,
    _ blue: Double,
    alpha: Double = 1
  ) -> RGBA {
    RGBA(red: red, green: green, blue: blue, alpha: alpha)
  }

  private static func adaptive(light: RGBA, dark: RGBA) -> Color {
    #if canImport(UIKit)
      return Color(
        UIColor { traitCollection in
          uiColor(traitCollection.userInterfaceStyle == .dark ? dark : light)
        }
      )
    #elseif canImport(AppKit)
      return Color(
        NSColor(name: nil) { appearance in
          let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
          return nsColor(isDark ? dark : light)
        }
      )
    #else
      return Color(red: light.red, green: light.green, blue: light.blue, opacity: light.alpha)
    #endif
  }

  #if canImport(UIKit)
    private static func uiColor(_ rgba: RGBA) -> UIColor {
      UIColor(
        red: CGFloat(rgba.red),
        green: CGFloat(rgba.green),
        blue: CGFloat(rgba.blue),
        alpha: CGFloat(rgba.alpha)
      )
    }
  #elseif canImport(AppKit)
    private static func nsColor(_ rgba: RGBA) -> NSColor {
      NSColor(
        calibratedRed: CGFloat(rgba.red),
        green: CGFloat(rgba.green),
        blue: CGFloat(rgba.blue),
        alpha: CGFloat(rgba.alpha)
      )
    }
  #endif
}
