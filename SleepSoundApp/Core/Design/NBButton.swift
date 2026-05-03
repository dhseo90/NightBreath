import SwiftUI

private struct NBButtonLabel: View {
  let title: String
  let systemImage: String?

  var body: some View {
    HStack(spacing: NBSpacing.sm) {
      if let systemImage {
        Image(systemName: systemImage)
          .imageScale(.medium)
      }
      Text(title)
        .lineLimit(2)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .combine)
  }
}

struct NBPrimaryButtonStyle: ButtonStyle {
  var tint: Color = NBColor.accent

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.headline)
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity, minHeight: 52)
      .padding(.horizontal, NBSpacing.lg)
      .background(tint.opacity(configuration.isPressed ? 0.82 : 1))
      .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.medium, style: .continuous))
      .scaleEffect(configuration.isPressed ? 0.985 : 1)
      .animation(NBAnimation.buttonPress, value: configuration.isPressed)
  }
}

struct NBSecondaryButtonStyle: ButtonStyle {
  @Environment(\.colorScheme) private var colorScheme

  var tint: Color = NBColor.accent

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.headline)
      .foregroundStyle(tint)
      .frame(maxWidth: .infinity, minHeight: 48)
      .padding(.horizontal, NBSpacing.lg)
      .background(tint.opacity(secondaryBackgroundOpacity(isPressed: configuration.isPressed)))
      .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.medium, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: NBCornerRadius.medium, style: .continuous)
          .stroke(tint.opacity(colorScheme == .dark ? 0.34 : 0.20), lineWidth: 1)
      )
      .animation(NBAnimation.buttonPress, value: configuration.isPressed)
  }

  private func secondaryBackgroundOpacity(isPressed: Bool) -> Double {
    if colorScheme == .dark {
      return isPressed ? 0.26 : 0.18
    }
    return isPressed ? 0.16 : 0.10
  }
}

struct NBDangerButtonStyle: ButtonStyle {
  var tint: Color = NBColor.danger

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.headline)
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity, minHeight: 52)
      .padding(.horizontal, NBSpacing.lg)
      .background(tint.opacity(configuration.isPressed ? 0.82 : 1))
      .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.medium, style: .continuous))
      .scaleEffect(configuration.isPressed ? 0.985 : 1)
      .animation(NBAnimation.buttonPress, value: configuration.isPressed)
  }
}

struct NBPrimaryButton: View {
  let title: String
  var systemImage: String?
  var isDisabled: Bool = false
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      NBButtonLabel(title: title, systemImage: systemImage)
    }
    .buttonStyle(NBPrimaryButtonStyle())
    .disabled(isDisabled)
    .opacity(isDisabled ? 0.55 : 1)
  }
}

struct NBSecondaryButton: View {
  let title: String
  var systemImage: String?
  var isDisabled: Bool = false
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      NBButtonLabel(title: title, systemImage: systemImage)
    }
    .buttonStyle(NBSecondaryButtonStyle())
    .disabled(isDisabled)
    .opacity(isDisabled ? 0.55 : 1)
  }
}

struct NBDangerButton: View {
  let title: String
  var systemImage: String?
  var isDisabled: Bool = false
  let action: () -> Void

  var body: some View {
    Button(role: .destructive, action: action) {
      NBButtonLabel(title: title, systemImage: systemImage)
    }
    .buttonStyle(NBDangerButtonStyle())
    .disabled(isDisabled)
    .opacity(isDisabled ? 0.55 : 1)
  }
}

struct NBIconButton: View {
  let title: String
  let systemImage: String
  var tint: Color = NBColor.accent
  var role: ButtonRole?
  let action: () -> Void

  var body: some View {
    Button(role: role, action: action) {
      Image(systemName: systemImage)
        .font(.body.weight(.semibold))
        .foregroundStyle(tint)
        .frame(width: 44, height: 44)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.medium, style: .continuous))
    }
    .accessibilityLabel(title)
  }
}

extension ButtonStyle where Self == NBPrimaryButtonStyle {
  static var nbPrimary: NBPrimaryButtonStyle { NBPrimaryButtonStyle() }
}

extension ButtonStyle where Self == NBSecondaryButtonStyle {
  static var nbSecondary: NBSecondaryButtonStyle { NBSecondaryButtonStyle() }
}

extension ButtonStyle where Self == NBDangerButtonStyle {
  static var nbDanger: NBDangerButtonStyle { NBDangerButtonStyle() }
}

#if DEBUG
struct NBButton_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: NBSpacing.md) {
      NBPrimaryButton(title: "수면 시작", systemImage: "moon.zzz") {}
      NBSecondaryButton(title: "이벤트 샘플 설정", systemImage: "waveform") {}
      NBDangerButton(title: "수면 종료", systemImage: "stop.fill") {}
      HStack {
        NBIconButton(title: "재생", systemImage: "play.fill") {}
        NBIconButton(title: "삭제", systemImage: "trash", tint: NBColor.danger, role: .destructive) {}
      }
    }
    .padding()
    .background(NBColor.background)
  }
}
#endif
