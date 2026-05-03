import SwiftUI

struct NBStatusBadge: View {
  let text: String
  let systemImage: String?
  let tint: Color

  init(_ text: String, systemImage: String? = nil, tint: Color = NBColor.breathBlue) {
    self.text = text
    self.systemImage = systemImage
    self.tint = tint
  }

  var body: some View {
    HStack(spacing: NBSpacing.xSmall) {
      if let systemImage {
        Image(systemName: systemImage)
          .font(.caption.weight(.semibold))
      }
      Text(text)
        .font(.caption.weight(.semibold))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .foregroundStyle(tint)
    .background(tint.opacity(0.12))
    .clipShape(Capsule())
    .accessibilityElement(children: .combine)
  }
}
