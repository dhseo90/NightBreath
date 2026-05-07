import SwiftUI
import UIKit
import Photos
import UniformTypeIdentifiers

struct DailyHealthCardPreviewView: View {
  let bundle: DailyRhythmMockBundle
  @State private var template: DailyHealthCardTemplate = .healthSummary
  @State private var privacyLevel: DailyHealthCardPrivacyLevel = .standard
  @State private var isRenderingExport = false
  @State private var isSavingToPhotos = false
  @State private var exportResult: DailyHealthCardImageResult?
  @State private var shareURL: URL?
  @State private var fileExportDocument = DailyHealthCardPNGDocument.empty
  @State private var exportErrorMessage: String?
  @State private var exportState: DailyHealthCardExportState = .preview
  @State private var isShowingSensitiveExportConfirmation = false
  @State private var isShowingShareSheet = false
  @State private var isShowingFileExporter = false

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

  init(bundle: DailyRhythmMockBundle, initialExportPreview: Bool = false) {
    self.bundle = bundle
    _template = State(initialValue: bundle.cardContent.template)
    _privacyLevel = State(initialValue: bundle.cardContent.privacyLevel)
    if initialExportPreview {
      _exportResult = State(initialValue: DailyHealthCardImageResult(
        reportId: bundle.report.id,
        template: bundle.cardContent.template,
        privacyLevel: bundle.cardContent.privacyLevel,
        fileName: "nightbreath-daily-health-card-preview.png",
        imageData: Data("screenshot-preview-only".utf8)
      ))
      _exportState = State(initialValue: .imageReady)
    }
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
    .fileExporter(
      isPresented: $isShowingFileExporter,
      document: fileExportDocument,
      contentType: .png,
      defaultFilename: fileExportDefaultName,
      onCompletion: handleFileExportCompletion
    )
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
        "사진 앱 또는 파일 앱 저장도 사용자가 명시적으로 선택한 경우에만 진행됩니다.",
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

        actionButtons

        if let exportResult {
          NBStatusBadge(
            exportResult.imageData == nil ? "이미지 준비 상태를 확인할 수 없습니다." : "로컬 이미지 준비됨",
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

  private var actionButtons: some View {
    ViewThatFits(in: .horizontal) {
      HStack(spacing: NBSpacing.sm) {
        exportButton
        shareButton
        photoSaveButton
        fileSaveButton
      }
      VStack(alignment: .leading, spacing: NBSpacing.sm) {
        exportButton
        shareButton
        photoSaveButton
        fileSaveButton
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
  private var photoSaveButton: some View {
    if exportResult?.imageData != nil {
      Button {
        Task { await saveImageToPhotos() }
      } label: {
        Label(isSavingToPhotos ? "사진 저장 중" : "사진에 저장", systemImage: "photo.badge.plus")
      }
      .buttonStyle(.bordered)
      .disabled(isSavingToPhotos)
      .accessibilityLabel("준비된 하루 리듬 카드 이미지를 사진 앱에 저장")
    } else {
      Button {} label: {
        Label("사진에 저장", systemImage: "photo.badge.plus")
      }
      .buttonStyle(.bordered)
      .disabled(true)
      .accessibilityLabel("이미지를 만든 뒤 사진 앱에 저장할 수 있습니다")
    }
  }

  @ViewBuilder
  private var fileSaveButton: some View {
    if exportResult?.imageData != nil {
      Button {
        requestFileExport()
      } label: {
        Label("파일에 저장", systemImage: "folder.badge.plus")
      }
      .buttonStyle(.bordered)
      .accessibilityLabel("준비된 하루 리듬 카드 이미지를 파일 앱에 저장")
    } else {
      Button {} label: {
        Label("파일에 저장", systemImage: "folder.badge.plus")
      }
      .buttonStyle(.bordered)
      .disabled(true)
      .accessibilityLabel("이미지를 만든 뒤 파일 앱에 저장할 수 있습니다")
    }
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

  private var fileExportDefaultName: String {
    exportResult?.fileName ?? "nightbreath-daily-health-card.png"
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

  @MainActor
  private func saveImageToPhotos() async {
    guard let imageData = exportResult?.imageData else {
      exportErrorMessage = "이미지를 만든 뒤 다시 시도해 주세요."
      exportState = .failed
      return
    }

    isSavingToPhotos = true
    exportErrorMessage = nil
    exportState = .photoSaveRequested

    do {
      try await DailyHealthCardPhotoSaver.savePNGData(imageData)
      exportState = .photoSaved
    } catch DailyHealthCardPhotoSaveError.notAuthorized {
      exportErrorMessage = "사진 앱 저장 권한이 허용되지 않았습니다."
      exportState = .failed
    } catch {
      exportErrorMessage = "사진 앱 저장에 실패했습니다. 다시 시도해 주세요."
      exportState = .failed
    }

    isSavingToPhotos = false
  }

  @MainActor
  private func requestFileExport() {
    guard let imageData = exportResult?.imageData else {
      exportErrorMessage = "이미지를 만든 뒤 다시 시도해 주세요."
      exportState = .failed
      return
    }

    fileExportDocument = DailyHealthCardPNGDocument(data: imageData)
    exportErrorMessage = nil
    exportState = .fileExportRequested
    isShowingFileExporter = true
  }

  private func handleFileExportCompletion(_ result: Result<URL, Error>) {
    fileExportDocument = .empty

    switch result {
    case .success:
      exportState = .fileSaved
    case .failure:
      exportState = .cancelled
      exportErrorMessage = "파일 저장을 완료하지 않았습니다. 필요하면 다시 시도해 주세요."
    }
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
    fileExportDocument = .empty
    exportErrorMessage = nil
    exportState = .preview
    isSavingToPhotos = false
    isShowingSensitiveExportConfirmation = false
    isShowingShareSheet = false
    isShowingFileExporter = false
  }
}

private enum DailyHealthCardExportState: Equatable {
  case preview
  case confirmationRequired
  case rendering
  case imageReady
  case shareRequested
  case photoSaveRequested
  case photoSaved
  case fileExportRequested
  case fileSaved
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
      "로컬 이미지가 준비되었습니다. 공유 또는 저장은 사용자가 선택할 때만 진행됩니다."
    case .shareRequested:
      "공유 sheet를 열었습니다."
    case .photoSaveRequested:
      "사진 앱에 저장하는 중입니다."
    case .photoSaved:
      "사진 앱에 저장했습니다."
    case .fileExportRequested:
      "파일 앱 저장 위치를 선택하는 중입니다."
    case .fileSaved:
      "파일 앱에 저장했습니다."
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
    case .shareRequested, .fileExportRequested:
      .neutral
    case .photoSaveRequested:
      .debug
    case .photoSaved, .fileSaved:
      .good
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
    case .photoSaveRequested:
      "photo.badge.plus"
    case .photoSaved:
      "checkmark.seal"
    case .fileExportRequested:
      "folder.badge.plus"
    case .fileSaved:
      "checkmark.seal"
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

private struct DailyHealthCardPNGDocument: FileDocument {
  static let empty = DailyHealthCardPNGDocument(data: Data())
  static var readableContentTypes: [UTType] { [.png] }

  var data: Data

  init(data: Data) {
    self.data = data
  }

  init(configuration: ReadConfiguration) throws {
    data = configuration.file.regularFileContents ?? Data()
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    FileWrapper(regularFileWithContents: data)
  }
}

private enum DailyHealthCardPhotoSaveError: Error {
  case notAuthorized
  case saveFailed
}

private struct DailyHealthCardPhotoSaver {
  static func savePNGData(_ data: Data) async throws {
    let status = await requestAddOnlyAuthorizationIfNeeded()
    guard status == .authorized || status == .limited else {
      throw DailyHealthCardPhotoSaveError.notAuthorized
    }

    try await withCheckedThrowingContinuation { continuation in
      PHPhotoLibrary.shared().performChanges {
        let request = PHAssetCreationRequest.forAsset()
        request.addResource(with: .photo, data: data, options: nil)
      } completionHandler: { success, error in
        if success {
          continuation.resume()
        } else {
          continuation.resume(throwing: error ?? DailyHealthCardPhotoSaveError.saveFailed)
        }
      }
    }
  }

  private static func requestAddOnlyAuthorizationIfNeeded() async -> PHAuthorizationStatus {
    let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
    guard status == .notDetermined else { return status }

    return await withCheckedContinuation { continuation in
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
        continuation.resume(returning: newStatus)
      }
    }
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
