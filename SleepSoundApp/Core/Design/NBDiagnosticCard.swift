import SwiftUI

struct NBDiagnosticItem: Identifiable {
  let id: String
  let title: String
  let value: String
  var detail: String?
  var status: NBStatusKind?

  init(
    id: String? = nil,
    title: String,
    value: String,
    detail: String? = nil,
    status: NBStatusKind? = nil
  ) {
    self.id = id ?? title
    self.title = title
    self.value = value
    self.detail = detail
    self.status = status
  }
}

struct NBDiagnosticItemList: View {
  let items: [NBDiagnosticItem]
  let showsDetails: Bool

  var body: some View {
    VStack(spacing: NBSpacing.sm) {
      ForEach(items) { item in
        NBListRow(
          title: item.title,
          value: item.value,
          subtitle: showsDetails ? item.detail : nil,
          systemImage: item.status?.defaultSystemImage ?? "waveform.path.ecg",
          tint: item.status?.tint ?? NBColor.audioTint
        )
        if item.id != items.last?.id {
          Divider()
            .overlay(NBColor.divider)
        }
      }
    }
  }
}

struct NBDiagnosticCard<Content: View>: View {
  let title: String
  let summary: String?
  let systemImage: String
  private let content: Content

  init(
    title: String,
    summary: String? = nil,
    systemImage: String = "waveform.and.magnifyingglass",
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.summary = summary
    self.systemImage = systemImage
    self.content = content()
  }

  var body: some View {
    NBCard(background: NBColor.audioTint.opacity(0.08), stroke: NBColor.audioTint.opacity(0.18)) {
      VStack(alignment: .leading, spacing: NBSpacing.md) {
        Label(title, systemImage: systemImage)
          .font(NBTypography.sectionTitle)
          .foregroundStyle(NBColor.audioTint)

        if let summary {
          Text(summary)
            .font(NBTypography.caption)
            .foregroundStyle(NBColor.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
        }

        content
      }
    }
  }
}

extension NBDiagnosticCard where Content == NBDiagnosticItemList {
  init(
    title: String = "Detector 진단 요약",
    summary: String? = nil,
    items: [NBDiagnosticItem],
    showsDetails: Bool = false,
    systemImage: String = "waveform.and.magnifyingglass"
  ) {
    self.title = title
    self.summary = summary
    self.systemImage = systemImage
    self.content = NBDiagnosticItemList(items: items, showsDetails: showsDetails)
  }
}

#if DEBUG
struct NBDiagnosticCard_Previews: PreviewProvider {
  static var previews: some View {
    NBDiagnosticCard(
      summary: "일반 화면에서는 요약 중심, DEBUG 화면에서는 상세 항목을 함께 표시합니다.",
      items: [
        NBDiagnosticItem(title: "raw 후보 수", value: "18", status: .neutral),
        NBDiagnosticItem(title: "smoothing 전/후", value: "18 / 9", detail: "짧은 후보와 가까운 이벤트를 정리했습니다.", status: .good),
        NBDiagnosticItem(title: "detector backend", value: "rule-based", status: .debug),
        NBDiagnosticItem(title: "fallback count", value: "0", status: .good),
      ],
      showsDetails: true
    )
    .padding()
    .background(NBColor.background)
  }
}
#endif
