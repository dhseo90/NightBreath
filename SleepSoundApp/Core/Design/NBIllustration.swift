import SwiftUI

enum NBIllustrationKind: Sendable {
  case breath
  case moonSleep
  case privacyOnDevice
  case devicePlacement
  case emptyReport
  case emptyTimeline

  var accessibilityLabel: String {
    switch self {
    case .breath:
      "부드러운 호흡 파형 일러스트"
    case .moonSleep:
      "달과 수면 파형 일러스트"
    case .privacyOnDevice:
      "온디바이스 개인정보 보호 일러스트"
    case .devicePlacement:
      "침대 옆 iPhone 배치 일러스트"
    case .emptyReport:
      "아직 리포트가 없는 상태 일러스트"
    case .emptyTimeline:
      "아직 타임라인 이벤트가 없는 상태 일러스트"
    }
  }
}

struct NBIllustration: View {
  let kind: NBIllustrationKind

  var body: some View {
    illustration
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(kind.accessibilityLabel)
  }

  @ViewBuilder private var illustration: some View {
    switch kind {
    case .breath:
      NBBreathWaveIllustration()
    case .moonSleep:
      NBMoonSleepIllustration()
    case .privacyOnDevice:
      NBPrivacyOnDeviceIllustration()
    case .devicePlacement:
      NBDevicePlacementIllustration()
    case .emptyReport:
      NBMoonSleepIllustration(tint: NBColor.sleep, accent: NBColor.breath)
    case .emptyTimeline:
      NBBreathWaveIllustration(tint: NBColor.neutral, accent: NBColor.sleep)
    }
  }
}

struct NBBreathWaveIllustration: View {
  var tint: Color = NBColor.breath
  var accent: Color = NBColor.sleep

  var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      let height = proxy.size.height
      let lineWidth = max(3, min(width, height) * 0.035)

      ZStack {
        NBIllustrationBackground(tint: tint, accent: accent)

        Circle()
          .fill(accent.opacity(0.16))
          .frame(width: width * 0.20, height: width * 0.20)
          .position(x: width * 0.25, y: height * 0.42)

        Circle()
          .fill(tint.opacity(0.12))
          .frame(width: width * 0.12, height: width * 0.12)
          .position(x: width * 0.78, y: height * 0.35)

        breathWave(width: width, height: height)
          .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

        breathWave(width: width, height: height)
          .stroke(accent.opacity(0.26), style: StrokeStyle(lineWidth: lineWidth * 2.4, lineCap: .round, lineJoin: .round))
          .blur(radius: 8)
      }
    }
    .aspectRatio(1.62, contentMode: .fit)
  }

  private func breathWave(width: CGFloat, height: CGFloat) -> Path {
    Path { path in
      path.move(to: CGPoint(x: width * 0.13, y: height * 0.58))
      path.addCurve(
        to: CGPoint(x: width * 0.34, y: height * 0.48),
        control1: CGPoint(x: width * 0.20, y: height * 0.33),
        control2: CGPoint(x: width * 0.27, y: height * 0.69)
      )
      path.addCurve(
        to: CGPoint(x: width * 0.55, y: height * 0.51),
        control1: CGPoint(x: width * 0.42, y: height * 0.28),
        control2: CGPoint(x: width * 0.48, y: height * 0.74)
      )
      path.addCurve(
        to: CGPoint(x: width * 0.74, y: height * 0.50),
        control1: CGPoint(x: width * 0.61, y: height * 0.31),
        control2: CGPoint(x: width * 0.68, y: height * 0.68)
      )
      path.addCurve(
        to: CGPoint(x: width * 0.88, y: height * 0.45),
        control1: CGPoint(x: width * 0.79, y: height * 0.36),
        control2: CGPoint(x: width * 0.84, y: height * 0.40)
      )
    }
  }
}

struct NBMoonSleepIllustration: View {
  var tint: Color = NBColor.sleep
  var accent: Color = NBColor.breath

  var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      let height = proxy.size.height

      ZStack {
        NBIllustrationBackground(tint: tint, accent: accent)

        Circle()
          .fill(tint.opacity(0.18))
          .frame(width: width * 0.28, height: width * 0.28)
          .position(x: width * 0.34, y: height * 0.40)

        Circle()
          .fill(NBColor.cardBackground)
          .frame(width: width * 0.24, height: width * 0.24)
          .position(x: width * 0.40, y: height * 0.34)

        NBBreathWaveIcon(tint: accent)
          .frame(width: width * 0.34, height: height * 0.28)
          .position(x: width * 0.58, y: height * 0.58)

        star(size: width * 0.035)
          .fill(accent.opacity(0.48))
          .position(x: width * 0.68, y: height * 0.30)

        star(size: width * 0.025)
          .fill(tint.opacity(0.42))
          .position(x: width * 0.78, y: height * 0.44)
      }
    }
    .aspectRatio(1.62, contentMode: .fit)
  }

  private func star(size: CGFloat) -> Path {
    Path { path in
      path.move(to: CGPoint(x: 0, y: -size))
      path.addLine(to: CGPoint(x: size * 0.32, y: -size * 0.32))
      path.addLine(to: CGPoint(x: size, y: 0))
      path.addLine(to: CGPoint(x: size * 0.32, y: size * 0.32))
      path.addLine(to: CGPoint(x: 0, y: size))
      path.addLine(to: CGPoint(x: -size * 0.32, y: size * 0.32))
      path.addLine(to: CGPoint(x: -size, y: 0))
      path.addLine(to: CGPoint(x: -size * 0.32, y: -size * 0.32))
      path.closeSubpath()
    }
  }
}

struct NBPrivacyOnDeviceIllustration: View {
  var tint: Color = NBColor.privacy
  var accent: Color = NBColor.breath

  var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      let height = proxy.size.height

      ZStack {
        NBIllustrationBackground(tint: tint, accent: accent)

        RoundedRectangle(cornerRadius: width * 0.05, style: .continuous)
          .fill(NBColor.cardBackground)
          .frame(width: width * 0.28, height: height * 0.58)
          .overlay(
            RoundedRectangle(cornerRadius: width * 0.05, style: .continuous)
              .stroke(tint.opacity(0.55), lineWidth: 2)
          )
          .position(x: width * 0.34, y: height * 0.52)

        NBPrivacyShieldIcon(tint: tint)
          .frame(width: width * 0.22, height: width * 0.22)
          .position(x: width * 0.58, y: height * 0.45)

        NBBreathWaveIcon(tint: accent)
          .frame(width: width * 0.28, height: height * 0.22)
          .position(x: width * 0.58, y: height * 0.66)

        Circle()
          .fill(tint.opacity(0.12))
          .frame(width: width * 0.15, height: width * 0.15)
          .position(x: width * 0.75, y: height * 0.30)
      }
    }
    .aspectRatio(1.62, contentMode: .fit)
  }
}

struct NBDevicePlacementIllustration: View {
  var tint: Color = NBColor.sleep
  var accent: Color = NBColor.breath

  var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      let height = proxy.size.height

      ZStack {
        NBIllustrationBackground(tint: tint, accent: accent)

        RoundedRectangle(cornerRadius: 4, style: .continuous)
          .fill(tint.opacity(0.18))
          .frame(width: width * 0.62, height: height * 0.08)
          .position(x: width * 0.50, y: height * 0.74)

        RoundedRectangle(cornerRadius: width * 0.05, style: .continuous)
          .fill(NBColor.cardBackground)
          .frame(width: width * 0.24, height: height * 0.54)
          .rotationEffect(.degrees(-6))
          .overlay(
            RoundedRectangle(cornerRadius: width * 0.05, style: .continuous)
              .stroke(tint.opacity(0.65), lineWidth: 2)
              .rotationEffect(.degrees(-6))
          )
          .position(x: width * 0.38, y: height * 0.48)

        RoundedRectangle(cornerRadius: width * 0.03, style: .continuous)
          .fill(accent.opacity(0.12))
          .frame(width: width * 0.22, height: height * 0.36)
          .position(x: width * 0.64, y: height * 0.57)

        NBBreathWaveIcon(tint: accent)
          .frame(width: width * 0.30, height: height * 0.24)
          .position(x: width * 0.64, y: height * 0.43)

        Image(systemName: "mic")
          .font(.system(size: max(13, width * 0.055), weight: .semibold))
          .foregroundStyle(tint)
          .position(x: width * 0.38, y: height * 0.55)
      }
    }
    .aspectRatio(1.62, contentMode: .fit)
  }
}

private struct NBIllustrationBackground: View {
  let tint: Color
  let accent: Color

  var body: some View {
    RoundedRectangle(cornerRadius: NBCornerRadius.card, style: .continuous)
      .fill(
        LinearGradient(
          colors: [
            tint.opacity(0.11),
            accent.opacity(0.08),
            NBColor.cardBackground.opacity(0.92),
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .overlay(
        RoundedRectangle(cornerRadius: NBCornerRadius.card, style: .continuous)
          .stroke(tint.opacity(0.14), lineWidth: 1)
      )
  }
}

#if DEBUG
struct NBIllustration_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: NBSpacing.md) {
      NBIllustration(kind: .breath)
      NBIllustration(kind: .moonSleep)
      NBIllustration(kind: .privacyOnDevice)
      NBIllustration(kind: .devicePlacement)
    }
    .padding()
    .background(NBColor.background)
  }
}
#endif
