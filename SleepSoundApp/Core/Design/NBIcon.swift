import SwiftUI

struct NBBreathWaveIcon: View {
  var tint: Color = NBColor.breath

  var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      let height = proxy.size.height
      let lineWidth = max(2, width * 0.08)

      ZStack {
        Circle()
          .fill(tint.opacity(0.12))
          .frame(width: width * 0.34, height: width * 0.34)
          .position(x: width * 0.25, y: height * 0.50)

        Path { path in
          path.move(to: CGPoint(x: width * 0.12, y: height * 0.56))
          path.addCurve(
            to: CGPoint(x: width * 0.42, y: height * 0.50),
            control1: CGPoint(x: width * 0.22, y: height * 0.32),
            control2: CGPoint(x: width * 0.32, y: height * 0.68)
          )
          path.addCurve(
            to: CGPoint(x: width * 0.72, y: height * 0.48),
            control1: CGPoint(x: width * 0.52, y: height * 0.31),
            control2: CGPoint(x: width * 0.62, y: height * 0.66)
          )
          path.addCurve(
            to: CGPoint(x: width * 0.88, y: height * 0.45),
            control1: CGPoint(x: width * 0.78, y: height * 0.37),
            control2: CGPoint(x: width * 0.83, y: height * 0.42)
          )
        }
        .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
      }
    }
  }
}

struct NBMoonBreathIcon: View {
  var tint: Color = NBColor.sleep

  var body: some View {
    ZStack {
      Circle()
        .fill(tint.opacity(0.12))

      Circle()
        .trim(from: 0.18, to: 0.88)
        .stroke(tint, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        .rotationEffect(.degrees(28))
        .padding(7)

      NBBreathWaveIcon(tint: NBColor.breath)
        .padding(13)
        .offset(x: 3, y: 4)
    }
  }
}

struct NBPrivacyShieldIcon: View {
  var tint: Color = NBColor.privacy

  var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      let height = proxy.size.height
      let lineWidth = max(2, width * 0.07)

      ZStack {
        Path { path in
          path.move(to: CGPoint(x: width * 0.50, y: height * 0.08))
          path.addLine(to: CGPoint(x: width * 0.82, y: height * 0.20))
          path.addLine(to: CGPoint(x: width * 0.76, y: height * 0.62))
          path.addCurve(
            to: CGPoint(x: width * 0.50, y: height * 0.91),
            control1: CGPoint(x: width * 0.72, y: height * 0.76),
            control2: CGPoint(x: width * 0.60, y: height * 0.86)
          )
          path.addCurve(
            to: CGPoint(x: width * 0.24, y: height * 0.62),
            control1: CGPoint(x: width * 0.40, y: height * 0.86),
            control2: CGPoint(x: width * 0.28, y: height * 0.76)
          )
          path.addLine(to: CGPoint(x: width * 0.18, y: height * 0.20))
          path.closeSubpath()
        }
        .fill(tint.opacity(0.13))

        Path { path in
          path.move(to: CGPoint(x: width * 0.50, y: height * 0.08))
          path.addLine(to: CGPoint(x: width * 0.82, y: height * 0.20))
          path.addLine(to: CGPoint(x: width * 0.76, y: height * 0.62))
          path.addCurve(
            to: CGPoint(x: width * 0.50, y: height * 0.91),
            control1: CGPoint(x: width * 0.72, y: height * 0.76),
            control2: CGPoint(x: width * 0.60, y: height * 0.86)
          )
          path.addCurve(
            to: CGPoint(x: width * 0.24, y: height * 0.62),
            control1: CGPoint(x: width * 0.40, y: height * 0.86),
            control2: CGPoint(x: width * 0.28, y: height * 0.76)
          )
          path.addLine(to: CGPoint(x: width * 0.18, y: height * 0.20))
          path.closeSubpath()
        }
        .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))

        Path { path in
          path.move(to: CGPoint(x: width * 0.35, y: height * 0.52))
          path.addLine(to: CGPoint(x: width * 0.46, y: height * 0.64))
          path.addLine(to: CGPoint(x: width * 0.66, y: height * 0.39))
        }
        .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
      }
    }
  }
}

struct NBRecordingPulseIcon: View {
  var tint: Color = NBColor.danger

  var body: some View {
    ZStack {
      Circle()
        .stroke(tint.opacity(0.18), lineWidth: 8)
        .padding(5)
      Circle()
        .stroke(tint.opacity(0.36), lineWidth: 4)
        .padding(13)
      Circle()
        .fill(tint)
        .padding(21)
    }
  }
}

struct NBSleepScoreIcon: View {
  var tint: Color = NBColor.accent

  var body: some View {
    ZStack {
      Circle()
        .fill(tint.opacity(0.10))
      Circle()
        .trim(from: 0.12, to: 0.86)
        .stroke(tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
        .rotationEffect(.degrees(120))
        .padding(7)
      Text("S")
        .font(.system(size: 14, weight: .bold, design: .rounded))
        .foregroundStyle(tint)
    }
  }
}

struct NBStorageIcon: View {
  var tint: Color = NBColor.privacy

  var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      let height = proxy.size.height
      let lineWidth = max(2, width * 0.06)

      ZStack {
        RoundedRectangle(cornerRadius: width * 0.14, style: .continuous)
          .fill(tint.opacity(0.12))
          .frame(width: width * 0.74, height: height * 0.66)
          .position(x: width * 0.50, y: height * 0.57)

        Path { path in
          path.addRoundedRect(
            in: CGRect(x: width * 0.18, y: height * 0.28, width: width * 0.64, height: height * 0.52),
            cornerSize: CGSize(width: width * 0.10, height: width * 0.10)
          )
          path.move(to: CGPoint(x: width * 0.29, y: height * 0.43))
          path.addLine(to: CGPoint(x: width * 0.71, y: height * 0.43))
          path.move(to: CGPoint(x: width * 0.29, y: height * 0.57))
          path.addLine(to: CGPoint(x: width * 0.62, y: height * 0.57))
        }
        .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
      }
    }
  }
}

struct NBBruxismLikeIcon: View {
  var tint: Color = NBColor.caution

  var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      let height = proxy.size.height
      let lineWidth = max(2, width * 0.07)

      Path { path in
        path.move(to: CGPoint(x: width * 0.22, y: height * 0.35))
        path.addLine(to: CGPoint(x: width * 0.78, y: height * 0.35))
        path.move(to: CGPoint(x: width * 0.22, y: height * 0.65))
        path.addLine(to: CGPoint(x: width * 0.78, y: height * 0.65))
        path.move(to: CGPoint(x: width * 0.34, y: height * 0.28))
        path.addLine(to: CGPoint(x: width * 0.30, y: height * 0.45))
        path.move(to: CGPoint(x: width * 0.50, y: height * 0.28))
        path.addLine(to: CGPoint(x: width * 0.50, y: height * 0.45))
        path.move(to: CGPoint(x: width * 0.66, y: height * 0.28))
        path.addLine(to: CGPoint(x: width * 0.70, y: height * 0.45))
        path.move(to: CGPoint(x: width * 0.34, y: height * 0.72))
        path.addLine(to: CGPoint(x: width * 0.30, y: height * 0.55))
        path.move(to: CGPoint(x: width * 0.50, y: height * 0.72))
        path.addLine(to: CGPoint(x: width * 0.50, y: height * 0.55))
        path.move(to: CGPoint(x: width * 0.66, y: height * 0.72))
        path.addLine(to: CGPoint(x: width * 0.70, y: height * 0.55))
      }
      .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
    }
  }
}

struct NBEventTypeIcon: View {
  let eventType: SleepEventType
  var tint: Color = NBColor.accent

  var body: some View {
    icon
      .foregroundStyle(tint)
  }

  @ViewBuilder private var icon: some View {
    switch eventType {
    case .snore:
      NBBreathWaveIcon(tint: tint)
    case .bruxismLike:
      NBBruxismLikeIcon(tint: tint)
    case .breathingPauseSuspected:
      NBMoonBreathIcon(tint: tint)
    case .gaspLike:
      Image(systemName: "wind")
        .font(.headline)
    case .coughLike:
      Image(systemName: "exclamationmark.triangle")
        .font(.headline)
    case .sleepTalkLike:
      Image(systemName: "bubble.left.and.waveform")
        .font(.headline)
    case .movementLike:
      Image(systemName: "figure.walk")
        .font(.headline)
    case .environmentalNoise:
      Image(systemName: "speaker.wave.2")
        .font(.headline)
    case .awakeningSuspected:
      Image(systemName: "eye")
        .font(.headline)
    case .unknown:
      Image(systemName: "questionmark.circle")
        .font(.headline)
    }
  }

  static func tint(for eventType: SleepEventType) -> Color {
    switch eventType {
    case .snore:
      NBColor.breath
    case .bruxismLike:
      NBColor.caution
    case .breathingPauseSuspected:
      NBColor.sleep
    case .gaspLike:
      NBColor.mistTeal
    case .coughLike:
      NBColor.warning
    case .sleepTalkLike:
      NBColor.lavender
    case .movementLike:
      NBColor.quietIndigo
    case .environmentalNoise:
      NBColor.neutral
    case .awakeningSuspected:
      NBColor.dawn
    case .unknown:
      NBColor.neutral
    }
  }
}

#if DEBUG
struct NBIcon_Previews: PreviewProvider {
  static var previews: some View {
    HStack(spacing: NBSpacing.lg) {
      NBBreathWaveIcon()
      NBMoonBreathIcon()
      NBPrivacyShieldIcon()
      NBRecordingPulseIcon()
      NBSleepScoreIcon()
      NBStorageIcon()
    }
    .frame(height: 44)
    .padding()
    .background(NBColor.background)
  }
}
#endif
