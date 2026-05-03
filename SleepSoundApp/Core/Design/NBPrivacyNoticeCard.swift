import SwiftUI

struct NBPrivacyNoticeCard: View {
  static let defaultMessages = [
    "분석은 iPhone 안에서 수행됩니다.",
    "원본 전체 오디오는 저장하지 않습니다.",
    "이벤트 오디오 샘플은 사용자가 켠 경우에만 저장됩니다.",
    "서버로 전송하지 않습니다.",
    "이 앱은 진단 목적의 의료기기가 아닙니다.",
  ]

  let title: String
  let messages: [String]
  var systemImage: String?

  init(
    title: String = "개인정보 보호 안내",
    message: String,
    systemImage: String = "lock.shield"
  ) {
    self.title = title
    self.messages = [message]
    self.systemImage = systemImage
  }

  init(
    title: String = "개인정보 보호 안내",
    messages: [String] = Self.defaultMessages,
    systemImage: String? = nil
  ) {
    self.title = title
    self.messages = messages
    self.systemImage = systemImage
  }

  var body: some View {
    NBCard(background: NBColor.privacy.opacity(0.10), stroke: NBColor.privacy.opacity(0.20)) {
      HStack(alignment: .top, spacing: NBSpacing.md) {
        icon

        VStack(alignment: .leading, spacing: NBSpacing.sm) {
          Text(title)
            .font(NBTypography.sectionTitle)
            .foregroundStyle(NBColor.primaryText)

          VStack(alignment: .leading, spacing: NBSpacing.xs) {
            ForEach(messages, id: \.self) { message in
              HStack(alignment: .firstTextBaseline, spacing: NBSpacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                  .font(.caption)
                  .foregroundStyle(NBColor.privacy)
                  .accessibilityHidden(true)
                Text(message)
                  .font(NBTypography.callout)
                  .foregroundStyle(NBColor.secondaryText)
                  .fixedSize(horizontal: false, vertical: true)
              }
            }
          }
        }
      }
    }
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder private var icon: some View {
    if let systemImage {
      Image(systemName: systemImage)
        .font(.title3.weight(.semibold))
        .foregroundStyle(NBColor.privacy)
        .frame(width: 28, height: 28)
        .accessibilityHidden(true)
    } else {
      NBPrivacyShieldIcon(tint: NBColor.privacy)
        .frame(width: 32, height: 32)
        .accessibilityHidden(true)
    }
  }
}

#if DEBUG
struct NBPrivacyNoticeCard_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: NBSpacing.md) {
      NBPrivacyNoticeCard()
      NBPrivacyNoticeCard(title: "저장 정책", message: "원본 전체 오디오는 저장하지 않습니다.")
    }
    .padding()
    .background(NBColor.background)
  }
}
#endif
