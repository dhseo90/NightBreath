import SwiftUI

struct NBLoadingStateView: View {
  let title: String
  var message: String?

  var body: some View {
    VStack(spacing: NBSpacing.md) {
      ProgressView()
        .tint(NBColor.accent)
        .controlSize(.large)
        .accessibilityHidden(true)

      VStack(spacing: NBSpacing.xs) {
        Text(title)
          .font(NBTypography.headline)
          .foregroundStyle(NBColor.primaryText)
          .multilineTextAlignment(.center)
        if let message {
          Text(message)
            .font(NBTypography.body)
            .foregroundStyle(NBColor.secondaryText)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
    .padding(NBSpacing.cardPadding)
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .combine)
  }
}

#if DEBUG
struct NBLoadingStateView_Previews: PreviewProvider {
  static var previews: some View {
    NBLoadingStateView(
      title: "리포트를 준비하는 중",
      message: "분석은 iPhone 안에서 수행됩니다."
    )
    .padding()
    .background(NBColor.background)
  }
}
#endif
