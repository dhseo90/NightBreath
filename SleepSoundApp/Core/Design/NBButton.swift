import SwiftUI

struct NBPrimaryButtonStyle: ButtonStyle {
  var tint: Color = NBColor.breathBlue

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.headline)
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity, minHeight: 52)
      .padding(.horizontal, NBSpacing.large)
      .background(tint.opacity(configuration.isPressed ? 0.82 : 1))
      .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.medium, style: .continuous))
      .scaleEffect(configuration.isPressed ? 0.985 : 1)
  }
}

struct NBSecondaryButtonStyle: ButtonStyle {
  var tint: Color = NBColor.breathBlue

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.headline)
      .foregroundStyle(tint)
      .frame(maxWidth: .infinity, minHeight: 48)
      .padding(.horizontal, NBSpacing.large)
      .background(tint.opacity(configuration.isPressed ? 0.16 : 0.10))
      .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.medium, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: NBCornerRadius.medium, style: .continuous)
          .stroke(tint.opacity(0.20), lineWidth: 1)
      )
  }
}

extension ButtonStyle where Self == NBPrimaryButtonStyle {
  static var nbPrimary: NBPrimaryButtonStyle { NBPrimaryButtonStyle() }
}

extension ButtonStyle where Self == NBSecondaryButtonStyle {
  static var nbSecondary: NBSecondaryButtonStyle { NBSecondaryButtonStyle() }
}
