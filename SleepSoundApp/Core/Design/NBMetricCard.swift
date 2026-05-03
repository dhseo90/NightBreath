import SwiftUI

enum NBMetricTrend: Equatable, Sendable {
  case up(String)
  case down(String)
  case flat(String)

  var text: String {
    switch self {
    case .up(let text), .down(let text), .flat(let text):
      text
    }
  }

  var systemImage: String {
    switch self {
    case .up:
      "arrow.up.right"
    case .down:
      "arrow.down.right"
    case .flat:
      "minus"
    }
  }
}

struct NBMetricCard: View {
  let title: String
  let value: String
  var unit: String?
  var subtitle: String?
  var systemImage: String?
  var tint: Color = NBColor.accent
  var status: NBStatusKind?
  var trend: NBMetricTrend?
  var footnote: String?
  var accessibilityLabelText: String?

  init(
    title: String,
    value: String,
    unit: String? = nil,
    subtitle: String? = nil,
    systemImage: String? = nil,
    tint: Color = NBColor.accent,
    status: NBStatusKind? = nil,
    trend: NBMetricTrend? = nil,
    footnote: String? = nil,
    accessibilityLabel: String? = nil
  ) {
    self.title = title
    self.value = value
    self.unit = unit
    self.subtitle = subtitle
    self.systemImage = systemImage
    self.tint = tint
    self.status = status
    self.trend = trend
    self.footnote = footnote
    self.accessibilityLabelText = accessibilityLabel
  }

  var body: some View {
    NBCard(padding: NBSpacing.medium) {
      VStack(alignment: .leading, spacing: NBSpacing.sm) {
        HStack(alignment: .center, spacing: NBSpacing.sm) {
          if let systemImage {
            metricIcon(systemImage)
          }
          Spacer(minLength: NBSpacing.xs)
          if let status {
            NBStatusBadge(statusText(for: status), kind: status)
          }
        }

        VStack(alignment: .leading, spacing: NBSpacing.xxs) {
          Text(title)
            .font(NBTypography.metricLabel)
            .foregroundStyle(NBColor.secondaryText)
            .fixedSize(horizontal: false, vertical: true)

          HStack(alignment: .firstTextBaseline, spacing: NBSpacing.xxs) {
            Text(value)
              .font(NBTypography.metricNumber)
              .foregroundStyle(NBColor.primaryText)
              .lineLimit(1)
              .minimumScaleFactor(0.72)

            if let unit {
              Text(unit)
                .font(NBTypography.captionEmphasis)
                .foregroundStyle(NBColor.secondaryText)
            }
          }
        }

        if let subtitle {
          Text(subtitle)
            .font(NBTypography.caption)
            .foregroundStyle(NBColor.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
        }

        if let trend {
          Label(trend.text, systemImage: trend.systemImage)
            .font(NBTypography.captionEmphasis)
            .foregroundStyle(tint)
            .lineLimit(2)
        }

        if let footnote {
          Text(footnote)
            .font(.caption2)
            .foregroundStyle(NBColor.tertiaryText)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityLabelText ?? defaultAccessibilityLabel)
  }

  private func metricIcon(_ systemImage: String) -> some View {
    Image(systemName: systemImage)
      .font(.headline)
      .foregroundStyle(tint)
      .frame(width: 30, height: 30)
      .background(tint.opacity(0.10))
      .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
      .accessibilityHidden(true)
  }

  private func statusText(for status: NBStatusKind) -> String {
    switch status {
    case .good:
      "좋음"
    case .warning:
      "주의"
    case .caution:
      "확인"
    case .danger:
      "낮음"
    case .neutral:
      "보통"
    case .privacy:
      "보호"
    case .debug:
      "DEBUG"
    }
  }

  private var defaultAccessibilityLabel: String {
    var parts = [title, value]
    if let unit {
      parts.append(unit)
    }
    if let subtitle {
      parts.append(subtitle)
    }
    if let footnote {
      parts.append(footnote)
    }
    return parts.joined(separator: ", ")
  }
}

#if DEBUG
struct NBMetricCard_Previews: PreviewProvider {
  static var previews: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.md) {
      NBMetricCard(
        title: "수면 소리 점수",
        value: "82",
        unit: "점",
        subtitle: "수면 중 소리 기반 지표",
        systemImage: "moon.zzz",
        tint: NBColor.sleep,
        status: .good,
        accessibilityLabel: "수면 소리 점수 82점, 수면 중 소리 기반 지표"
      )
      NBMetricCard(
        title: "녹음 커버리지",
        value: "76",
        unit: "%",
        subtitle: "일부 구간 누락",
        systemImage: "waveform",
        tint: NBColor.warning,
        status: .warning,
        trend: .down("전날보다 낮음")
      )
    }
    .padding()
    .background(NBColor.background)
  }
}
#endif
