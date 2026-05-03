import SwiftUI

struct NBEmptyStateView: View {
  let title: String
  let message: String
  var systemImage: String = "moon.zzz"
  var actionTitle: String?
  var action: (() -> Void)?

  var body: some View {
    VStack(spacing: NBSpacing.md) {
      Image(systemName: systemImage)
        .font(.system(size: 36, weight: .semibold))
        .foregroundStyle(NBColor.sleep)
        .frame(width: 64, height: 64)
        .background(NBColor.sleep.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.card, style: .continuous))
        .accessibilityHidden(true)

      VStack(spacing: NBSpacing.xs) {
        Text(title)
          .font(NBTypography.headline)
          .foregroundStyle(NBColor.primaryText)
          .multilineTextAlignment(.center)
        Text(message)
          .font(NBTypography.body)
          .foregroundStyle(NBColor.secondaryText)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }

      if let actionTitle, let action {
        NBSecondaryButton(title: actionTitle, action: action)
      }
    }
    .padding(NBSpacing.cardPadding)
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .combine)
  }
}

#if DEBUG
struct NBEmptyStateView_Previews: PreviewProvider {
  static var previews: some View {
    NBEmptyStateView(
      title: "아직 리포트가 없습니다",
      message: "수면 시작 후 아침 리포트에서 수면 중 소리 기반 지표를 확인할 수 있습니다.",
      actionTitle: "수면 시작"
    ) {}
    .padding()
    .background(NBColor.background)
  }
}
#endif
