import SwiftUI
import UIKit

struct DailyHealthCardPreviewView: View {
  let bundle: DailyRhythmMockBundle
  @State private var template: DailyHealthCardTemplate = .healthSummary
  @State private var privacyLevel: DailyHealthCardPrivacyLevel = .standard
  @State private var isRenderingExport = false
  @State private var exportResult: DailyHealthCardImageResult?
  @State private var shareURL: URL?
  @State private var exportErrorMessage: String?
  @State private var exportState: DailyHealthCardExportState = .preview
  @State private var isShowingSensitiveExportConfirmation = false
  @State private var isShowingShareSheet = false

  init(
    nightReport: NightReport? = nil,
    morningCheckIn: MorningCheckIn? = nil,
    referenceDate: Date = Date()
  ) {
    self.bundle = DailyRhythmMockFactory.makeBundle(
      referenceDate: referenceDate,
      nightReport: nightReport,
      morningCheckIn: morningCheckIn
    )
  }

  init(bundle: DailyRhythmMockBundle) {
    self.bundle = bundle
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        controls
        DailyHealthCardSurface(content: content)
        exportSection
        rendererNotice
      }
      .padding(NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
    .navigationTitle("카드 미리보기")
    .onChange(of: template) { _, _ in
      resetExportState()
    }
    .onChange(of: privacyLevel) { _, _ in
      resetExportState()
    }
    .sheet(isPresented: $isShowingSensitiveExportConfirmation) {
      DailyHealthCardExportConfirmationSheet(
        content: content,
        onCancel: {
          exportState = .cancelled
          isShowingSensitiveExportConfirmation = false
        },
        onConfirm: {
          isShowingSensitiveExportConfirmation = false
          Task { await renderImageForSharing() }
        }
      )
      .presentationDetents([.medium, .large])
    }
    .sheet(isPresented: $isShowingShareSheet, onDismiss: handleShareSheetDismiss) {
      if let shareURL {
        DailyHealthCardActivityView(itemURL: shareURL) { completed in
          exportState = completed ? .completed : .cancelled
          isShowingShareSheet = false
        }
      }
    }
  }

  private var controls: some View {
    NBReportSection(title: "카드 설정", systemImage: "slider.horizontal.3") {
      VStack(alignment: .leading, spacing: NBSpacing.md) {
        Text("템플릿")
          .font(NBTypography.captionEmphasis)
          .foregroundStyle(NBColor.secondaryText)
        Picker("템플릿", selection: $template) {
          ForEach(DailyHealthCardTemplate.allCases) { template in
            Text(template.shortDisplayName).tag(template)
          }
        }
        .pickerStyle(.segmented)

        Text("표시 수준")
          .font(NBTypography.captionEmphasis)
          .foregroundStyle(NBColor.secondaryText)
        Picker("표시 수준", selection: $privacyLevel) {
          ForEach(DailyHealthCardPrivacyLevel.allCases) { level in
            Text(level.displayName).tag(level)
          }
        }
        .pickerStyle(.segmented)
        .disabled(template == .privacyMinimal)

        Text(effectivePrivacyLevel.description)
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private var rendererNotice: some View {
    NBPrivacyNoticeCard(
      title: "이미지 카드 내보내기 안내",
      messages: [
        "이미지 만들기를 누른 경우에만 현재 카드 상태를 로컬 PNG로 렌더링합니다.",
        "공유는 이미지가 준비된 뒤 사용자가 공유 버튼을 선택할 때만 열립니다.",
        "자동 공유와 서버 업로드는 없습니다.",
        "이 앱은 진단 목적의 의료기기가 아닙니다.",
      ],
      systemImage: "lock.shield"
    )
  }

  private var exportSection: some View {
    NBReportSection(title: "이미지 내보내기", systemImage: "square.and.arrow.up") {
      VStack(alignment: .leading, spacing: NBSpacing.md) {
        Text("현재 선택한 템플릿과 표시 수준으로 하루 리듬 카드를 로컬 이미지로 만듭니다.")
          .font(NBTypography.callout)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)

        NBPrivacyNoticeCard(
          title: content.containsSensitiveHealthValues ? "공유 전 확인" : "공유 안전장치",
          messages: content.exportPrivacyNoticeMessages,
          systemImage: content.containsSensitiveHealthValues ? "exclamationmark.shield" : "lock.shield"
        )

        ViewThatFits(in: .horizontal) {
          HStack(spacing: NBSpacing.sm) {
            exportButton
            shareButton
          }
          VStack(alignment: .leading, spacing: NBSpacing.sm) {
            exportButton
            shareButton
          }
        }

        if let exportResult {
          NBStatusBadge(
            exportResult.fileName.map { "로컬 이미지 준비됨: \($0)" } ?? "로컬 이미지 준비됨",
            kind: .good,
            systemImage: "checkmark.circle"
          )
        }

        if exportState != .preview {
          NBStatusBadge(exportState.displayText, kind: exportState.statusKind, systemImage: exportState.systemImage)
        }

        if let exportErrorMessage {
          NBStatusBadge(exportErrorMessage, kind: .warning, systemImage: "exclamationmark.triangle")
        }
      }
    }
  }

  private var exportButton: some View {
    Button {
      requestImageRender()
    } label: {
      Label(isRenderingExport ? "이미지 만드는 중" : "이미지 만들기", systemImage: "photo")
    }
    .buttonStyle(.borderedProminent)
    .disabled(isRenderingExport)
    .accessibilityLabel("현재 하루 리듬 카드 이미지 만들기")
  }

  @ViewBuilder
  private var shareButton: some View {
    if shareURL != nil {
      Button {
        exportState = .shareRequested
        isShowingShareSheet = true
      } label: {
        Label("공유", systemImage: "square.and.arrow.up")
      }
      .buttonStyle(.bordered)
      .accessibilityLabel("준비된 하루 리듬 카드 이미지 공유")
    } else {
      Button {} label: {
        Label("공유", systemImage: "square.and.arrow.up")
      }
      .buttonStyle(.bordered)
      .disabled(true)
      .accessibilityLabel("이미지를 만든 뒤 공유할 수 있습니다")
    }
  }

  private var content: DailyHealthCardContent {
    DailyHealthCardContent.make(
      date: bundle.date,
      report: bundle.report,
      nightReport: bundle.nightReport,
      healthMetricSamples: bundle.healthSamples,
      template: template,
      privacyLevel: privacyLevel
    )
  }

  private var effectivePrivacyLevel: DailyHealthCardPrivacyLevel {
    template.effectivePrivacyLevel ?? privacyLevel
  }

  @MainActor
  private func requestImageRender() {
    if content.requiresSensitiveExportConfirmation {
      exportState = .confirmationRequired
      isShowingSensitiveExportConfirmation = true
    } else {
      Task { await renderImageForSharing() }
    }
  }

  @MainActor
  private func renderImageForSharing() async {
    isRenderingExport = true
    exportErrorMessage = nil
    exportResult = nil
    shareURL = nil
    exportState = .rendering

    do {
      let renderer = DailyHealthCardImageRenderer()
      let output = try renderer.render(content: content, reportId: bundle.report.id)
      exportResult = output.result
      shareURL = output.fileURL
      exportState = .imageReady
    } catch {
      exportErrorMessage = "이미지 만들기에 실패했습니다. 다시 시도해 주세요."
      exportState = .failed
    }

    isRenderingExport = false
  }

  private func handleShareSheetDismiss() {
    if exportState == .shareRequested {
      exportState = .cancelled
    }
  }

  private func resetExportState() {
    if let shareURL {
      try? FileManager.default.removeItem(at: shareURL)
    }
    exportResult = nil
    shareURL = nil
    exportErrorMessage = nil
    exportState = .preview
    isShowingSensitiveExportConfirmation = false
    isShowingShareSheet = false
  }
}

private enum DailyHealthCardExportState: Equatable {
  case preview
  case confirmationRequired
  case rendering
  case imageReady
  case shareRequested
  case cancelled
  case completed
  case failed

  var displayText: String {
    switch self {
    case .preview:
      "표시 항목을 확인한 뒤 이미지를 만들 수 있습니다."
    case .confirmationRequired:
      "건강 관련 수치가 포함되어 공유 전 확인이 필요합니다."
    case .rendering:
      "로컬 이미지를 만드는 중입니다."
    case .imageReady:
      "로컬 이미지가 준비되었습니다. 공유는 사용자가 선택할 때만 열립니다."
    case .shareRequested:
      "공유 sheet를 열었습니다."
    case .cancelled:
      "공유를 취소했거나 진행하지 않았습니다."
    case .completed:
      "공유를 완료했습니다."
    case .failed:
      "이미지 만들기에 실패했습니다."
    }
  }

  var statusKind: NBStatusKind {
    switch self {
    case .preview:
      .neutral
    case .confirmationRequired:
      .privacy
    case .rendering:
      .debug
    case .imageReady:
      .good
    case .shareRequested:
      .neutral
    case .cancelled:
      .caution
    case .completed:
      .good
    case .failed:
      .warning
    }
  }

  var systemImage: String {
    switch self {
    case .preview:
      "rectangle.on.rectangle"
    case .confirmationRequired:
      "exclamationmark.shield"
    case .rendering:
      "photo"
    case .imageReady:
      "checkmark.circle"
    case .shareRequested:
      "square.and.arrow.up"
    case .cancelled:
      "xmark.circle"
    case .completed:
      "checkmark.seal"
    case .failed:
      "exclamationmark.triangle"
    }
  }
}

private struct DailyHealthCardExportConfirmationSheet: View {
  let content: DailyHealthCardContent
  let onCancel: () -> Void
  let onConfirm: () -> Void

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
          NBPrivacyNoticeCard(
            title: "공유 전 표시 항목 확인",
            messages: content.exportPrivacyNoticeMessages,
            systemImage: "exclamationmark.shield"
          )

          VStack(alignment: .leading, spacing: NBSpacing.sm) {
            Text("포함되는 항목")
              .font(NBTypography.headline)
            ForEach(content.keyMetrics) { metric in
              HStack(spacing: NBSpacing.sm) {
                Image(systemName: metric.sensitivity == .sensitiveHealth ? "heart.text.square" : "checkmark.circle")
                  .foregroundStyle(metric.sensitivity == .sensitiveHealth ? NBColor.privacyTint : NBColor.success)
                VStack(alignment: .leading, spacing: 2) {
                  Text(metric.title)
                    .font(NBTypography.captionEmphasis)
                  Text(metric.sensitivity == .sensitiveHealth ? "건강 관련 수치 포함" : "일반 표시 항목")
                    .font(NBTypography.caption)
                    .foregroundStyle(NBColor.secondaryText)
                }
              }
            }
          }

          ViewThatFits(in: .horizontal) {
            HStack(spacing: NBSpacing.sm) {
              confirmButton
              cancelButton
            }
            VStack(spacing: NBSpacing.sm) {
              confirmButton
              cancelButton
            }
          }
        }
        .padding(NBSpacing.screenHorizontal)
      }
      .background(NBColor.pageBackground)
      .navigationTitle("공유 전 확인")
    }
  }

  private var confirmButton: some View {
    Button {
      onConfirm()
    } label: {
      Label("확인하고 이미지 만들기", systemImage: "photo")
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.privacyTint))
  }

  private var cancelButton: some View {
    Button(role: .cancel) {
      onCancel()
    } label: {
      Label("취소", systemImage: "xmark.circle")
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.nbSecondary)
  }
}

private struct DailyHealthCardActivityView: UIViewControllerRepresentable {
  let itemURL: URL
  let onComplete: (Bool) -> Void

  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(activityItems: [itemURL], applicationActivities: nil)
    controller.completionWithItemsHandler = { _, completed, _, _ in
      DispatchQueue.main.async {
        onComplete(completed)
      }
    }
    return controller
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

@MainActor
private struct DailyHealthCardImageRenderer {
  func render(
    content: DailyHealthCardContent,
    reportId: UUID
  ) throws -> (result: DailyHealthCardImageResult, fileURL: URL) {
    let renderedAt = Date()
    let exportView = DailyHealthCardExportSurface(content: content)
    let renderer = ImageRenderer(content: exportView)
    renderer.scale = UIScreen.main.scale

    guard let uiImage = renderer.uiImage, let imageData = uiImage.pngData() else {
      throw DailyHealthCardImageRenderError.renderingFailed
    }

    let fileName = "nightbreath-daily-health-card-\(UUID().uuidString.prefix(8)).png"
    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    try imageData.write(to: fileURL, options: [.atomic])

    let result = DailyHealthCardImageResult(
      reportId: reportId,
      template: content.template,
      privacyLevel: content.privacyLevel,
      renderedAt: renderedAt,
      fileName: fileName,
      imageData: imageData
    )
    return (result, fileURL)
  }
}

private struct DailyHealthCardExportSurface: View {
  let content: DailyHealthCardContent

  var body: some View {
    DailyHealthCardSurface(content: content)
      .padding(24)
      .frame(width: 468)
      .background(NBColor.pageBackground)
      .environment(\.colorScheme, .light)
  }
}

private enum DailyHealthCardImageRenderError: Error {
  case renderingFailed
}

#if DEBUG
struct DailyHealthCardPreviewView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      DailyHealthCardPreviewView(bundle: DailyRhythmMockFactory.makePreviewBundle())
    }
  }
}
#endif
