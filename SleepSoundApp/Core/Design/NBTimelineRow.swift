import SwiftUI

struct NBTimelineRow<Accessory: View>: View {
  let title: String
  let subtitle: String?
  let detail: String?
  let systemImage: String?
  let eventType: SleepEventType?
  let time: String?
  let duration: String?
  let confidence: Double?
  let hasAudioSample: Bool
  let tint: Color
  let playAction: (() -> Void)?
  let deleteAction: (() -> Void)?
  private let accessory: Accessory

  init(
    title: String,
    subtitle: String,
    detail: String? = nil,
    systemImage: String,
    tint: Color,
    @ViewBuilder accessory: () -> Accessory
  ) {
    self.title = title
    self.subtitle = subtitle
    self.detail = detail
    self.systemImage = systemImage
    self.eventType = nil
    self.time = nil
    self.duration = nil
    self.confidence = nil
    self.hasAudioSample = false
    self.tint = tint
    self.playAction = nil
    self.deleteAction = nil
    self.accessory = accessory()
  }

  var body: some View {
    NBCard {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        HStack(alignment: .top, spacing: NBSpacing.medium) {
          leadingIcon

          VStack(alignment: .leading, spacing: NBSpacing.xSmall) {
            Text(title)
              .font(NBTypography.sectionTitle)
            if let subtitle {
              Text(subtitle)
                .font(NBTypography.caption)
                .foregroundStyle(NBColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            }
            metadata
            if let detail {
              Text(detail)
                .font(NBTypography.caption)
                .foregroundStyle(NBColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            }
          }

          Spacer()

          actionButtons
        }

        accessory
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(accessibilityLabelText)
  }

  private var leadingIcon: some View {
    ZStack {
      if let eventType {
        NBEventTypeIcon(eventType: eventType, tint: tint)
          .padding(7)
      } else if let systemImage {
        Image(systemName: systemImage)
          .font(.headline)
          .foregroundStyle(tint)
      }
    }
    .frame(width: 34, height: 34)
    .background(tint.opacity(0.12))
    .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
    .accessibilityHidden(true)
  }

  @ViewBuilder private var metadata: some View {
    let items = [time, duration, confidenceText].compactMap { $0 }
    if !items.isEmpty || hasAudioSample {
      HStack(spacing: NBSpacing.xs) {
        ForEach(items, id: \.self) { item in
          Text(item)
            .font(NBTypography.captionEmphasis)
            .foregroundStyle(NBColor.tertiaryText)
        }
        if hasAudioSample {
          NBStatusBadge("샘플 있음", kind: .privacy, systemImage: "waveform")
        }
      }
      .fixedSize(horizontal: false, vertical: true)
    }
  }

  @ViewBuilder private var actionButtons: some View {
    if playAction != nil || deleteAction != nil {
      HStack(spacing: NBSpacing.xs) {
        if let playAction {
          NBIconButton(title: "이벤트 오디오 샘플 재생", systemImage: "play.fill", tint: tint, action: playAction)
        }
        if let deleteAction {
          NBIconButton(
            title: "이벤트 오디오 샘플 삭제",
            systemImage: "trash",
            tint: NBColor.danger,
            role: .destructive,
            action: deleteAction
          )
        }
      }
    } else {
      Circle()
        .fill(tint)
        .frame(width: 9, height: 9)
        .accessibilityHidden(true)
    }
  }

  private var confidenceText: String? {
    guard let confidence else { return nil }
    let percent = Int((confidence * 100).rounded())
    return "신뢰도 \(percent)%"
  }

  private var accessibilityLabelText: String {
    var parts = [title]
    parts.append(contentsOf: [subtitle, time, duration, confidenceText, detail].compactMap { $0 })
    if hasAudioSample {
      parts.append("이벤트 오디오 샘플 있음")
    }
    return parts.joined(separator: ", ")
  }
}

extension NBTimelineRow where Accessory == EmptyView {
  init(
    eventType: SleepEventType,
    title: String,
    time: String,
    duration: String,
    confidence: Double? = nil,
    subtitle: String? = nil,
    hasAudioSample: Bool = false,
    playAction: (() -> Void)? = nil,
    deleteAction: (() -> Void)? = nil
  ) {
    self.title = title
    self.subtitle = subtitle
    self.detail = nil
    self.systemImage = nil
    self.eventType = eventType
    self.time = time
    self.duration = duration
    self.confidence = confidence
    self.hasAudioSample = hasAudioSample
    self.tint = NBEventTypeIcon.tint(for: eventType)
    self.playAction = playAction
    self.deleteAction = deleteAction
    self.accessory = EmptyView()
  }
}

#if DEBUG
struct NBTimelineRow_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: NBSpacing.md) {
      NBTimelineRow(
        eventType: .snore,
        title: "코골기",
        time: "02:14",
        duration: "1분 12초",
        confidence: 0.86,
        subtitle: "수면 중 소리 기반 지표",
        hasAudioSample: true,
        playAction: {},
        deleteAction: {}
      )

      NBTimelineRow(
        title: "환경 소음",
        subtitle: "03:42 · 24초",
        detail: "창밖 소음으로 분류된 구간",
        systemImage: "speaker.wave.2",
        tint: NBColor.caution
      ) {
        NBStatusBadge("원본 전체 오디오 저장 안 함", kind: .privacy)
      }
    }
    .padding()
    .background(NBColor.background)
  }
}
#endif
