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

        if let exportErrorMessage {
          NBStatusBadge(exportErrorMessage, kind: .warning, systemImage: "exclamationmark.triangle")
        }
      }
    }
  }

  private var exportButton: some View {
    Button {
      Task { await renderImageForSharing() }
    } label: {
      Label(isRenderingExport ? "이미지 만드는 중" : "이미지 만들기", systemImage: "photo")
    }
    .buttonStyle(.borderedProminent)
    .disabled(isRenderingExport)
    .accessibilityLabel("현재 하루 리듬 카드 이미지 만들기")
  }

  @ViewBuilder
  private var shareButton: some View {
    if let shareURL {
      ShareLink(item: shareURL) {
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
  private func renderImageForSharing() async {
    isRenderingExport = true
    exportErrorMessage = nil
    exportResult = nil
    shareURL = nil

    do {
      let renderer = DailyHealthCardImageRenderer()
      let output = try renderer.render(content: content, reportId: bundle.report.id)
      exportResult = output.result
      shareURL = output.fileURL
    } catch {
      exportErrorMessage = "이미지 만들기에 실패했습니다. 다시 시도해 주세요."
    }

    isRenderingExport = false
  }

  private func resetExportState() {
    if let shareURL {
      try? FileManager.default.removeItem(at: shareURL)
    }
    exportResult = nil
    shareURL = nil
    exportErrorMessage = nil
  }
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
