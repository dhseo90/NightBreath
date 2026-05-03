import SwiftUI

enum NBTypography {
  static let titleLarge = Font.largeTitle.weight(.bold)
  static let title = Font.title2.weight(.bold)
  static let headline = Font.headline.weight(.semibold)
  static let subheadline = Font.subheadline.weight(.semibold)
  static let body = Font.body
  static let bodyEmphasis = Font.body.weight(.semibold)
  static let callout = Font.callout
  static let caption = Font.caption
  static let captionEmphasis = Font.caption.weight(.semibold)
  static let metricNumber = Font.title2.weight(.bold).monospacedDigit()
  static let metricLabel = Font.caption.weight(.semibold)
  static let footnote = Font.footnote

  static let screenTitle = titleLarge
  static let sectionTitle = headline
  static let cardTitle = title
  static let metricValue = metricNumber
}
