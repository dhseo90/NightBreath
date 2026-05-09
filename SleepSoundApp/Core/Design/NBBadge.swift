import SwiftUI

enum NBStatusKind: String, CaseIterable, Sendable {
  case good
  case warning
  case caution
  case danger
  case neutral
  case privacy
  case debug

  var tint: Color {
    switch self {
    case .good:
      NBColor.success
    case .warning:
      NBColor.warning
    case .caution:
      NBColor.caution
    case .danger:
      NBColor.danger
    case .neutral:
      NBColor.neutral
    case .privacy:
      NBColor.privacy
    case .debug:
      NBColor.lavender
    }
  }

  var defaultSystemImage: String {
    switch self {
    case .good:
      "checkmark.circle"
    case .warning:
      "exclamationmark.triangle"
    case .caution:
      "exclamationmark.circle"
    case .danger:
      "xmark.octagon"
    case .neutral:
      "circle"
    case .privacy:
      "lock.shield"
    case .debug:
      "ladybug"
    }
  }
}

struct NBStatusBadge: View {
  @Environment(\.colorScheme) private var colorScheme

  let text: String
  let systemImage: String?
  let tint: Color
  let kind: NBStatusKind?

  init(_ text: String, systemImage: String? = nil, tint: Color = NBColor.accent) {
    self.text = text
    self.systemImage = systemImage
    self.tint = tint
    self.kind = nil
  }

  init(_ text: String, kind: NBStatusKind, systemImage: String? = nil) {
    self.text = text
    self.systemImage = systemImage ?? kind.defaultSystemImage
    self.tint = kind.tint
    self.kind = kind
  }

  var body: some View {
    HStack(spacing: NBSpacing.xSmall) {
      if let systemImage {
        Image(systemName: systemImage)
          .font(NBTypography.captionEmphasis)
          .accessibilityHidden(true)
      }
      Text(text)
        .font(NBTypography.captionEmphasis)
        .lineLimit(2)
        .minimumScaleFactor(0.85)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .foregroundStyle(tint)
    .background(tint.opacity(colorScheme == .dark ? 0.18 : 0.12))
    .overlay(
      Capsule()
        .stroke(tint.opacity(colorScheme == .dark ? 0.34 : 0.18), lineWidth: 0.7)
    )
    .clipShape(Capsule())
    .accessibilityElement(children: .combine)
  }
}

struct NBInlineStatus: View {
  let title: String
  let detail: String
  let kind: NBStatusKind
  let systemImage: String
  var isLoading = false

  var body: some View {
    VStack(alignment: .leading, spacing: NBSpacing.xs) {
      HStack(spacing: NBSpacing.sm) {
        if isLoading {
          ProgressView()
            .controlSize(.small)
            .tint(kind.tint)
            .accessibilityHidden(true)
        }

        NBStatusBadge(title, kind: kind, systemImage: systemImage)
      }

      Text(detail)
        .font(NBTypography.caption)
        .foregroundStyle(NBColor.secondaryText)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(NBSpacing.sm)
    .background(kind.tint.opacity(0.08), in: RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous)
        .stroke(kind.tint.opacity(0.18), lineWidth: 1)
    )
    .accessibilityElement(children: .combine)
  }
}

#if DEBUG
struct NBStatusBadge_Previews: PreviewProvider {
  static var previews: some View {
    VStack(alignment: .leading, spacing: NBSpacing.sm) {
      NBStatusBadge("측정 품질 좋음", kind: .good)
      NBStatusBadge("오디오 커버리지 낮음", kind: .warning)
      NBStatusBadge("이벤트 샘플 저장 꺼짐", kind: .privacy)
      NBStatusBadge("DEBUG", kind: .debug)
      NBInlineStatus(
        title: "새로고침 완료",
        detail: "버튼을 누른 결과와 완료 시간을 같은 자리에서 확인합니다.",
        kind: .good,
        systemImage: "checkmark.circle"
      )
    }
    .padding()
    .background(NBColor.background)
  }
}
#endif
