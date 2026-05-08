import SwiftUI

enum NBIllustrationKind: Sendable {
  case breath
  case onboardingIntro
  case moonBreath
  case moonSleep
  case privacyOnDevice
  case devicePlacement
  case eventAudioSamples
  case microphonePermission
  case calibrationCheck
  case sleepReport
  case healthDashboard
  case emptyReport
  case emptyTimeline

  var accessibilityLabel: String {
    switch self {
    case .breath:
      "부드러운 호흡 파형 일러스트"
    case .onboardingIntro:
      "밤숨 온보딩 소개 일러스트"
    case .moonBreath:
      "달과 숨결 파형 일러스트"
    case .moonSleep:
      "달과 수면 파형 일러스트"
    case .privacyOnDevice:
      "온디바이스 개인정보 보호 일러스트"
    case .devicePlacement:
      "침대 옆 iPhone 배치 일러스트"
    case .eventAudioSamples:
      "짧은 이벤트 오디오 샘플 opt-in 일러스트"
    case .microphonePermission:
      "마이크 권한과 로컬 처리 일러스트"
    case .calibrationCheck:
      "입력 캘리브레이션 확인 일러스트"
    case .sleepReport:
      "수면 리포트 카드 일러스트"
    case .healthDashboard:
      "건강 대시보드 카드 일러스트"
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
    case .onboardingIntro:
      NBOnboardingIntroIllustration()
    case .moonBreath:
      NBMoonBreathIllustration()
    case .moonSleep:
      NBMoonSleepIllustration()
    case .privacyOnDevice:
      NBPrivacyOnDeviceIllustration()
    case .devicePlacement:
      NBDevicePlacementIllustration()
    case .eventAudioSamples:
      NBEventAudioSamplesIllustration()
    case .microphonePermission:
      NBMicrophonePermissionIllustration()
    case .calibrationCheck:
      NBCalibrationCheckIllustration()
    case .sleepReport:
      NBSleepReportIllustration()
    case .healthDashboard:
      NBHealthDashboardIllustration()
    case .emptyReport:
      NBEmptyReportIllustration()
    case .emptyTimeline:
      NBEmptyTimelineIllustration()
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
    NBMoonBreathIllustration(tint: tint, accent: accent)
  }
}

struct NBMoonBreathIllustration: View {
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

struct NBSleepReportIllustration: View {
  var tint: Color = NBColor.sleep
  var accent: Color = NBColor.breath

  var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      let height = proxy.size.height
      let cardWidth = width * 0.56
      let cardHeight = height * 0.58

      ZStack {
        NBIllustrationBackground(tint: tint, accent: accent)

        RoundedRectangle(cornerRadius: width * 0.045, style: .continuous)
          .fill(NBColor.cardBackground)
          .frame(width: cardWidth, height: cardHeight)
          .overlay(
            RoundedRectangle(cornerRadius: width * 0.045, style: .continuous)
              .stroke(tint.opacity(0.42), lineWidth: 2)
          )
          .position(x: width * 0.50, y: height * 0.52)

        Circle()
          .trim(from: 0, to: 0.74)
          .stroke(accent, style: StrokeStyle(lineWidth: max(4, width * 0.035), lineCap: .round))
          .rotationEffect(.degrees(-90))
          .frame(width: width * 0.20, height: width * 0.20)
          .position(x: width * 0.37, y: height * 0.43)

        VStack(alignment: .leading, spacing: max(5, height * 0.025)) {
          reportLine(width: width * 0.20, color: tint.opacity(0.60))
          reportLine(width: width * 0.30, color: NBColor.divider)
          reportLine(width: width * 0.24, color: NBColor.divider)
        }
        .position(x: width * 0.60, y: height * 0.44)

        HStack(spacing: max(6, width * 0.025)) {
          RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(tint.opacity(0.28))
            .frame(width: width * 0.10, height: height * 0.11)
          RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(accent.opacity(0.34))
            .frame(width: width * 0.10, height: height * 0.17)
          RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(NBColor.privacy.opacity(0.28))
            .frame(width: width * 0.10, height: height * 0.08)
        }
        .position(x: width * 0.52, y: height * 0.67)
      }
    }
    .aspectRatio(1.62, contentMode: .fit)
  }

  private func reportLine(width: CGFloat, color: Color) -> some View {
    Capsule()
      .fill(color)
      .frame(width: width, height: 5)
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

struct NBHealthDashboardIllustration: View {
  var tint: Color = NBColor.privacy
  var accent: Color = NBColor.sleep

  var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      let height = proxy.size.height

      ZStack {
        NBIllustrationBackground(tint: tint, accent: accent)

        RoundedRectangle(cornerRadius: width * 0.05, style: .continuous)
          .fill(NBColor.cardBackground)
          .frame(width: width * 0.58, height: height * 0.52)
          .overlay(
            RoundedRectangle(cornerRadius: width * 0.05, style: .continuous)
              .stroke(tint.opacity(0.42), lineWidth: 2)
          )
          .position(x: width * 0.50, y: height * 0.52)

        Image(systemName: "heart.text.square")
          .font(.system(size: max(18, width * 0.10), weight: .semibold))
          .foregroundStyle(tint)
          .position(x: width * 0.35, y: height * 0.41)

        dashboardLine(width: width * 0.24, color: NBColor.divider)
          .position(x: width * 0.61, y: height * 0.38)
        dashboardLine(width: width * 0.30, color: NBColor.divider)
          .position(x: width * 0.64, y: height * 0.49)

        healthWave(width: width, height: height)
          .stroke(accent, style: StrokeStyle(lineWidth: max(3, width * 0.018), lineCap: .round, lineJoin: .round))

        Circle()
          .fill(NBColor.breath.opacity(0.18))
          .frame(width: width * 0.13, height: width * 0.13)
          .position(x: width * 0.72, y: height * 0.64)
      }
    }
    .aspectRatio(1.62, contentMode: .fit)
  }

  private func dashboardLine(width: CGFloat, color: Color) -> some View {
    Capsule()
      .fill(color)
      .frame(width: width, height: 5)
  }

  private func healthWave(width: CGFloat, height: CGFloat) -> Path {
    Path { path in
      path.move(to: CGPoint(x: width * 0.30, y: height * 0.64))
      path.addLine(to: CGPoint(x: width * 0.39, y: height * 0.64))
      path.addLine(to: CGPoint(x: width * 0.43, y: height * 0.58))
      path.addLine(to: CGPoint(x: width * 0.49, y: height * 0.70))
      path.addLine(to: CGPoint(x: width * 0.55, y: height * 0.59))
      path.addLine(to: CGPoint(x: width * 0.61, y: height * 0.64))
      path.addLine(to: CGPoint(x: width * 0.70, y: height * 0.64))
    }
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

struct NBOnboardingIntroIllustration: View {
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
          .frame(width: width * 0.22, height: width * 0.22)
          .position(x: width * 0.31, y: height * 0.34)

        Circle()
          .fill(NBColor.cardBackground)
          .frame(width: width * 0.19, height: width * 0.19)
          .position(x: width * 0.36, y: height * 0.29)

        RoundedRectangle(cornerRadius: width * 0.045, style: .continuous)
          .fill(NBColor.cardBackground)
          .frame(width: width * 0.28, height: height * 0.56)
          .overlay(
            RoundedRectangle(cornerRadius: width * 0.045, style: .continuous)
              .stroke(tint.opacity(0.46), lineWidth: 2)
          )
          .position(x: width * 0.38, y: height * 0.56)

        NBBreathWaveIcon(tint: accent)
          .frame(width: width * 0.23, height: height * 0.17)
          .position(x: width * 0.38, y: height * 0.55)

        RoundedRectangle(cornerRadius: width * 0.035, style: .continuous)
          .fill(NBColor.cardBackground)
          .frame(width: width * 0.36, height: height * 0.30)
          .overlay(
            RoundedRectangle(cornerRadius: width * 0.035, style: .continuous)
              .stroke(accent.opacity(0.38), lineWidth: 2)
          )
          .position(x: width * 0.64, y: height * 0.57)

        VStack(alignment: .leading, spacing: max(5, height * 0.026)) {
          Capsule()
            .fill(tint.opacity(0.52))
            .frame(width: width * 0.18, height: 5)
          Capsule()
            .fill(NBColor.divider)
            .frame(width: width * 0.26, height: 5)
          HStack(spacing: width * 0.018) {
            ForEach(0..<3, id: \.self) { index in
              RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill([tint.opacity(0.22), accent.opacity(0.35), NBColor.privacy.opacity(0.25)][index])
                .frame(width: width * 0.052, height: height * [CGFloat(0.08), 0.13, 0.06][index])
            }
          }
        }
        .position(x: width * 0.66, y: height * 0.58)
      }
    }
    .aspectRatio(1.62, contentMode: .fit)
  }
}

struct NBEventAudioSamplesIllustration: View {
  var tint: Color = NBColor.audioTint
  var accent: Color = NBColor.privacy

  var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      let height = proxy.size.height

      ZStack {
        NBIllustrationBackground(tint: tint, accent: accent)

        RoundedRectangle(cornerRadius: width * 0.045, style: .continuous)
          .fill(NBColor.cardBackground)
          .frame(width: width * 0.62, height: height * 0.46)
          .overlay(
            RoundedRectangle(cornerRadius: width * 0.045, style: .continuous)
              .stroke(tint.opacity(0.36), lineWidth: 2)
          )
          .position(x: width * 0.50, y: height * 0.52)

        sampleSegment(width: width * 0.15, tint: tint.opacity(0.28))
          .position(x: width * 0.32, y: height * 0.52)
        sampleSegment(width: width * 0.20, tint: tint.opacity(0.55))
          .position(x: width * 0.50, y: height * 0.52)
        sampleSegment(width: width * 0.15, tint: tint.opacity(0.28))
          .position(x: width * 0.68, y: height * 0.52)

        NBBreathWaveIcon(tint: tint)
          .frame(width: width * 0.44, height: height * 0.19)
          .position(x: width * 0.50, y: height * 0.40)

        NBPrivacyShieldIcon(tint: accent)
          .frame(width: width * 0.15, height: width * 0.15)
          .position(x: width * 0.73, y: height * 0.30)
      }
    }
    .aspectRatio(1.62, contentMode: .fit)
  }

  private func sampleSegment(width: CGFloat, tint: Color) -> some View {
    Capsule()
      .fill(tint)
      .frame(width: width, height: 10)
  }
}

struct NBMicrophonePermissionIllustration: View {
  var tint: Color = NBColor.audioTint
  var accent: Color = NBColor.privacy

  var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      let height = proxy.size.height

      ZStack {
        NBIllustrationBackground(tint: tint, accent: accent)

        RoundedRectangle(cornerRadius: width * 0.055, style: .continuous)
          .fill(NBColor.cardBackground)
          .frame(width: width * 0.30, height: height * 0.62)
          .overlay(
            RoundedRectangle(cornerRadius: width * 0.055, style: .continuous)
              .stroke(tint.opacity(0.45), lineWidth: 2)
          )
          .position(x: width * 0.40, y: height * 0.52)

        Image(systemName: "mic")
          .font(.system(size: max(22, width * 0.11), weight: .semibold))
          .foregroundStyle(tint)
          .position(x: width * 0.40, y: height * 0.51)

        NBPrivacyShieldIcon(tint: accent)
          .frame(width: width * 0.19, height: width * 0.19)
          .position(x: width * 0.61, y: height * 0.48)

        NBBreathWaveIcon(tint: tint.opacity(0.76))
          .frame(width: width * 0.28, height: height * 0.17)
          .position(x: width * 0.62, y: height * 0.66)
      }
    }
    .aspectRatio(1.62, contentMode: .fit)
  }
}

struct NBCalibrationCheckIllustration: View {
  var tint: Color = NBColor.breath
  var accent: Color = NBColor.success

  var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      let height = proxy.size.height

      ZStack {
        NBIllustrationBackground(tint: tint, accent: accent)

        RoundedRectangle(cornerRadius: width * 0.045, style: .continuous)
          .fill(NBColor.cardBackground)
          .frame(width: width * 0.62, height: height * 0.48)
          .overlay(
            RoundedRectangle(cornerRadius: width * 0.045, style: .continuous)
              .stroke(tint.opacity(0.36), lineWidth: 2)
          )
          .position(x: width * 0.50, y: height * 0.52)

        ForEach(0..<5, id: \.self) { index in
          RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(index == 2 ? tint.opacity(0.72) : tint.opacity(0.26))
            .frame(width: width * 0.052, height: height * [CGFloat(0.12), 0.22, 0.31, 0.20, 0.14][index])
            .position(x: width * (0.34 + CGFloat(index) * 0.08), y: height * 0.56)
        }

        Capsule()
          .fill(NBColor.divider)
          .frame(width: width * 0.34, height: 4)
          .position(x: width * 0.50, y: height * 0.72)

        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: max(18, width * 0.09), weight: .semibold))
          .foregroundStyle(accent)
          .position(x: width * 0.70, y: height * 0.35)
      }
    }
    .aspectRatio(1.62, contentMode: .fit)
  }
}

struct NBEmptyReportIllustration: View {
  var tint: Color = NBColor.sleep
  var accent: Color = NBColor.breath

  var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      let height = proxy.size.height

      ZStack {
        NBIllustrationBackground(tint: tint, accent: accent)

        RoundedRectangle(cornerRadius: width * 0.048, style: .continuous)
          .fill(NBColor.cardBackground)
          .frame(width: width * 0.58, height: height * 0.56)
          .overlay(
            RoundedRectangle(cornerRadius: width * 0.048, style: .continuous)
              .stroke(tint.opacity(0.34), lineWidth: 2)
          )
          .position(x: width * 0.52, y: height * 0.54)

        Circle()
          .trim(from: 0, to: 0.64)
          .stroke(accent.opacity(0.82), style: StrokeStyle(lineWidth: max(4, width * 0.032), lineCap: .round))
          .rotationEffect(.degrees(-90))
          .frame(width: width * 0.18, height: width * 0.18)
          .position(x: width * 0.40, y: height * 0.46)

        VStack(alignment: .leading, spacing: max(5, height * 0.026)) {
          Capsule()
            .fill(tint.opacity(0.46))
            .frame(width: width * 0.22, height: 5)
          Capsule()
            .fill(NBColor.divider)
            .frame(width: width * 0.30, height: 5)
          Capsule()
            .fill(NBColor.divider)
            .frame(width: width * 0.24, height: 5)
        }
        .position(x: width * 0.62, y: height * 0.47)

        Image(systemName: "plus.circle")
          .font(.system(size: max(16, width * 0.074), weight: .semibold))
          .foregroundStyle(tint.opacity(0.62))
          .position(x: width * 0.52, y: height * 0.69)
      }
    }
    .aspectRatio(1.62, contentMode: .fit)
  }
}

struct NBEmptyTimelineIllustration: View {
  var tint: Color = NBColor.neutral
  var accent: Color = NBColor.sleep

  var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      let height = proxy.size.height

      ZStack {
        NBIllustrationBackground(tint: tint, accent: accent)

        Capsule()
          .fill(tint.opacity(0.18))
          .frame(width: width * 0.64, height: 8)
          .position(x: width * 0.50, y: height * 0.56)

        ForEach(0..<4, id: \.self) { index in
          Circle()
            .fill(index == 0 ? accent.opacity(0.50) : tint.opacity(0.24))
            .frame(width: width * 0.065, height: width * 0.065)
            .position(x: width * (0.25 + CGFloat(index) * 0.17), y: height * 0.56)
        }

        NBBreathWaveIcon(tint: accent.opacity(0.72))
          .frame(width: width * 0.44, height: height * 0.20)
          .position(x: width * 0.50, y: height * 0.38)

        Image(systemName: "sparkle.magnifyingglass")
          .font(.system(size: max(17, width * 0.078), weight: .semibold))
          .foregroundStyle(accent.opacity(0.72))
          .position(x: width * 0.72, y: height * 0.70)
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
      NBIllustration(kind: .onboardingIntro)
      NBIllustration(kind: .moonBreath)
      NBIllustration(kind: .moonSleep)
      NBIllustration(kind: .privacyOnDevice)
      NBIllustration(kind: .devicePlacement)
      NBIllustration(kind: .eventAudioSamples)
      NBIllustration(kind: .microphonePermission)
      NBIllustration(kind: .calibrationCheck)
      NBIllustration(kind: .sleepReport)
      NBIllustration(kind: .healthDashboard)
      NBIllustration(kind: .emptyReport)
      NBIllustration(kind: .emptyTimeline)
    }
    .padding()
    .background(NBColor.background)
  }
}
#endif
