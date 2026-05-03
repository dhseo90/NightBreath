import SwiftUI

enum NBAnimation {
  static let quickDuration = 0.16
  static let standardDuration = 0.24
  static let slowDuration = 0.36

  static let buttonPress = Animation.easeOut(duration: quickDuration)
  static let stateChange = Animation.easeInOut(duration: standardDuration)
  static let breathingPulse = Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true)
}
