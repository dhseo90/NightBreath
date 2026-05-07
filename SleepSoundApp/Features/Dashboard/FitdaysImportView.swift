import SwiftUI
import UniformTypeIdentifiers
#if os(iOS)
import UIKit
#endif

struct FitdaysImportView: View {
  private let service: FitdaysImportService
  private let repository: any UnifiedHealthMetricSampleRepositoryProtocol
  private let initialFileURL: URL?
  private let initialFileStatusMessage: String?

  @State private var isFileImporterPresented = false
  @State private var importResult: FitdaysImportResult?
  @State private var statusMessage: String?
  @State private var errorMessage: String?
  @State private var pastedExportText = ""
  @State private var didPreviewInitialFile = false

  init(
    service: FitdaysImportService = FitdaysImportService(),
    repository: any UnifiedHealthMetricSampleRepositoryProtocol = JSONUnifiedHealthMetricSampleRepository(),
    initialFileURL: URL? = nil,
    initialImportResult: FitdaysImportResult? = nil,
    initialStatusMessage: String? = nil,
    initialErrorMessage: String? = nil
  ) {
    self.service = service
    self.repository = repository
    self.initialFileURL = initialFileURL
    self.initialFileStatusMessage = initialStatusMessage
    _importResult = State(initialValue: initialImportResult)
    _statusMessage = State(initialValue: initialStatusMessage)
    _errorMessage = State(initialValue: initialErrorMessage)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        headerSection
        pastedTextSection
        policySection
        exportUnavailableSection
        fallbackSection

        if let importResult {
          resultSection(importResult)
          previewSection(importResult)
        } else {
          emptyState
        }
      }
      .padding(NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
    .navigationTitle("Fitdays 가져오기")
    .fileImporter(
      isPresented: $isFileImporterPresented,
      allowedContentTypes: [.commaSeparatedText, .plainText, .text],
      allowsMultipleSelection: false,
      onCompletion: handleFileImporterResult
    )
    .onAppear(perform: previewInitialFileIfNeeded)
  }

  private var headerSection: some View {
    NBReportSection(title: "Fitdays CSV 가져오기", systemImage: "square.and.arrow.down") {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        Text("사용자가 직접 확보한 Fitdays CSV 또는 text 기반 export 파일이 있을 때만 로컬에서 체성분 지표를 정리합니다.")
          .font(NBTypography.callout)
          .foregroundStyle(NBColor.secondaryText)

        Button {
          isFileImporterPresented = true
        } label: {
          Label("파일 선택", systemImage: "doc.badge.plus")
        }
        .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.mistTeal))

        Text(FitdaysImportFallbackGuidance.supportedFileSummary)
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)

        Text(FitdaysImportFallbackGuidance.supportedPasteSummary)
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)

        if let statusMessage {
          NBStatusBadge(statusMessage, kind: .good, systemImage: "checkmark.circle")
        }

        if let errorMessage {
          NBStatusBadge(errorMessage, kind: .warning, systemImage: "exclamationmark.triangle")
        }
      }
    }
  }

  private var pastedTextSection: some View {
    NBReportSection(title: "월별 데이터 붙여넣기", systemImage: "doc.on.clipboard") {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        Text("Fitdays에서 월별 데이터를 복사했다면 표 형태의 텍스트를 여기에 붙여넣고 저장 전 미리보기를 확인합니다.")
          .font(NBTypography.callout)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)

        ZStack(alignment: .topLeading) {
          TextEditor(text: pastedTextBinding)
            .font(.system(.footnote, design: .monospaced))
            .frame(minHeight: 150)
            .padding(NBSpacing.small)
            .background(NBColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.medium, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: NBCornerRadius.medium, style: .continuous)
                .stroke(NBColor.divider)
            )
            .accessibilityLabel("Fitdays 월별 데이터 붙여넣기 입력")

          if pastedExportText.isEmpty {
            Text("Fitdays에서 복사한 월별 데이터 표를 붙여넣거나 아래 버튼을 누르세요.")
              .font(NBTypography.footnote)
              .foregroundStyle(NBColor.secondaryText)
              .padding(.horizontal, NBSpacing.medium)
              .padding(.vertical, NBSpacing.medium)
              .allowsHitTesting(false)
          }
        }

        VStack(spacing: NBSpacing.small) {
          #if os(iOS)
          Button {
            pasteClipboardTextAndPreview()
          } label: {
            Label("클립보드 붙여넣고 미리보기", systemImage: "doc.on.clipboard")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.mistTeal))
          #endif

          HStack(spacing: NBSpacing.small) {
            Button {
              previewPastedText()
            } label: {
              Label("입력 내용 미리보기", systemImage: "eye")
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.nbSecondary)
            .disabled(trimmedPastedText.isEmpty)

            Button {
              clearPastedText()
            } label: {
              Label("비우기", systemImage: "xmark.circle")
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.nbSecondary)
            .disabled(pastedExportText.isEmpty)
          }
        }

        Text("붙여넣은 원문은 앱 밖이나 서버로 보내지 않고, 저장 버튼을 누른 뒤에도 변환된 로컬 샘플만 기기 안에 보관합니다.")
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private var policySection: some View {
    NBPrivacyNoticeCard(
      title: "로컬 파일 import",
      messages: FitdaysImportFallbackGuidance.privacyMessages,
      systemImage: "lock.doc"
    )
  }

  private var emptyState: some View {
    NBEmptyStateView(
      title: "가져온 파일이 없습니다",
      message: FitdaysImportFallbackGuidance.emptyStateMessage,
      systemImage: "doc.text.magnifyingglass",
      actionTitle: "파일 선택"
    ) {
      isFileImporterPresented = true
    }
  }

  private var exportUnavailableSection: some View {
    NBReportSection(title: FitdaysImportFallbackGuidance.exportUnavailableTitle, systemImage: "questionmark.folder") {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        ForEach(FitdaysImportFallbackGuidance.exportUnavailableSteps, id: \.self) { step in
          HStack(alignment: .top, spacing: NBSpacing.small) {
            Image(systemName: "checkmark.circle")
              .foregroundStyle(NBColor.privacyTint)
              .font(.caption)
              .padding(.top, 2)
              .accessibilityHidden(true)

            Text(step)
              .font(NBTypography.footnote)
              .foregroundStyle(NBColor.secondaryText)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private var fallbackSection: some View {
    NBReportSection(title: "파일이 없어도 괜찮습니다", systemImage: "heart.text.square") {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        NBListRow(
          title: FitdaysImportFallbackGuidance.healthDashboardFallbackTitle,
          value: "표준 지표",
          subtitle: "혈압, 체중, 체지방률처럼 건강앱에 동기화된 표준 지표는 HealthKit read-only 연결로 볼 수 있습니다.",
          systemImage: "heart.text.square",
          tint: NBColor.privacyTint
        )

        Divider().overlay(NBColor.divider)

        NBListRow(
          title: FitdaysImportFallbackGuidance.localOnlyFollowUpTitle,
          value: "보류",
          subtitle: "CSV/export 파일이 없으면 체수분률, 내장지방 레벨 같은 Fitdays 고유 지표는 수동 입력 또는 로컬 입력 기능으로 분리합니다.",
          systemImage: "square.and.pencil",
          tint: NBColor.mistTeal
        )

        NavigationLink {
          HealthDashboardView()
        } label: {
          Label("건강 데이터 대시보드 보기", systemImage: "heart.text.square")
        }
        .buttonStyle(.nbSecondary)

        Text("NightBreath는 Fitdays 로그인, 서버/API 연결, 자동 동기화, 비공식 연결 방식을 사용하지 않습니다.")
          .font(NBTypography.footnote)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private func resultSection(_ result: FitdaysImportResult) -> some View {
    NBReportSection(title: "가져오기 결과", systemImage: "list.bullet.rectangle") {
      VStack(spacing: NBSpacing.medium) {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.medium) {
          NBMetricCard(
            title: "생성 샘플",
            value: "\(result.importedSampleCount)",
            systemImage: "number",
            tint: NBColor.mistTeal,
            footnote: "저장 전 미리보기"
          )

          NBMetricCard(
            title: "건너뛴 row",
            value: "\(result.skippedRowCount)",
            systemImage: "arrow.uturn.forward",
            tint: result.skippedRowCount > 0 ? NBColor.warning : NBColor.success,
            footnote: "오류 \(result.errorCount)개"
          )
        }

        if !result.unknownColumns.isEmpty {
          VStack(alignment: .leading, spacing: NBSpacing.xSmall) {
            Text("알 수 없는 column")
              .font(NBTypography.caption.weight(.semibold))
              .foregroundStyle(NBColor.primaryText)
            Text(result.unknownColumns.joined(separator: ", "))
              .font(NBTypography.footnote)
              .foregroundStyle(NBColor.secondaryText)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }

        if !result.rowErrors.isEmpty {
          VStack(alignment: .leading, spacing: NBSpacing.xSmall) {
            Text("확인 필요")
              .font(NBTypography.caption.weight(.semibold))
              .foregroundStyle(NBColor.primaryText)
            ForEach(result.rowErrors.prefix(4)) { error in
              Text("Row \(error.rowNumber): \(error.message)")
                .font(NBTypography.footnote)
                .foregroundStyle(NBColor.secondaryText)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }

        if result.samples.isEmpty {
          NBStatusBadge(
            FitdaysImportFallbackGuidance.noImportablePreviewMessage,
            kind: .caution,
            systemImage: "exclamationmark.circle"
          )
        }

        Button {
          save(result)
        } label: {
          Label("로컬에 저장", systemImage: "tray.and.arrow.down")
        }
        .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.sleepTint))
        .disabled(result.samples.isEmpty)
      }
    }
  }

  private func previewSection(_ result: FitdaysImportResult) -> some View {
    NBReportSection(title: "미리보기", systemImage: "eye") {
      VStack(spacing: NBSpacing.small) {
        ForEach(result.samples.prefix(8)) { sample in
          if let displayModel = sample.displayModel() {
            NBListRow(
              title: displayModel.metadata.displayNameKo,
              value: displayModel.valueText,
              subtitle: "\(SleepFormatters.shortDate(sample.measuredAt)) · \(displayModel.sourceText)",
              systemImage: icon(for: displayModel.metadata.category),
              tint: tint(for: displayModel.metadata.category)
            )
          }
        }

        if result.samples.count > 8 {
          Text("외 \(result.samples.count - 8)개 샘플")
            .font(NBTypography.footnote)
            .foregroundStyle(NBColor.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
  }

  private func handleFileImporterResult(_ result: Result<[URL], Error>) {
    errorMessage = nil
    statusMessage = nil

    do {
      guard let url = try result.get().first else {
        return
      }
      preview(fileURL: url, successMessage: "저장 전 미리보기를 만들었습니다.")
    } catch {
      importResult = nil
      errorMessage = userFacingImportErrorMessage(error)
    }
  }

  private var trimmedPastedText: String {
    pastedExportText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var pastedTextBinding: Binding<String> {
    Binding(
      get: { pastedExportText },
      set: { newValue in
        guard newValue != pastedExportText else { return }
        pastedExportText = newValue
        clearPastedPreviewState()
      }
    )
  }

  private func clearPastedText() {
    pastedExportText = ""
    clearPastedPreviewState()
  }

  private func clearPastedPreviewState() {
    importResult = nil
    statusMessage = nil
    errorMessage = nil
  }

  private func userFacingImportErrorMessage(_ error: Error) -> String {
    guard let fitdaysError = error as? FitdaysImportError,
          let description = fitdaysError.errorDescription else {
      return error.localizedDescription
    }

    return "\(description) \(FitdaysImportFallbackGuidance.importErrorRecoveryMessage)"
  }

  private func previewInitialFileIfNeeded() {
    guard !didPreviewInitialFile, let initialFileURL else { return }
    didPreviewInitialFile = true
    preview(
      fileURL: initialFileURL,
      successMessage: initialFileStatusMessage ?? "공유/export 파일 미리보기를 만들었습니다."
    )
  }

  private func preview(fileURL: URL, successMessage: String) {
    errorMessage = nil
    statusMessage = nil

    do {
      let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
      defer {
        if didStartAccessing {
          fileURL.stopAccessingSecurityScopedResource()
        }
      }

      importResult = try service.previewImport(from: fileURL)
      statusMessage = successMessage
    } catch {
      importResult = nil
      errorMessage = error.localizedDescription
    }
  }

  #if os(iOS)
  private func pasteClipboardTextAndPreview() {
    errorMessage = nil
    statusMessage = nil

    guard let clipboardText = UIPasteboard.general.string,
          !clipboardText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      importResult = nil
      errorMessage = "클립보드에 붙여넣을 Fitdays 텍스트가 없습니다."
      return
    }

    pastedExportText = clipboardText
    previewPastedText(clipboardText)
  }
  #endif

  private func previewPastedText(_ textOverride: String? = nil) {
    errorMessage = nil
    statusMessage = nil

    do {
      importResult = try service.previewImport(fromPastedText: textOverride ?? pastedExportText)
      statusMessage = "붙여넣은 월별 데이터에서 저장 전 미리보기를 만들었습니다."
    } catch {
      importResult = nil
      errorMessage = userFacingImportErrorMessage(error)
    }
  }

  private func save(_ result: FitdaysImportResult) {
    do {
      try repository.save(batch: result.batch, samples: result.samples)
      statusMessage = "로컬 저장소에 \(result.importedSampleCount)개 샘플을 저장했습니다."
      errorMessage = nil
    } catch {
      errorMessage = "저장에 실패했습니다: \(error.localizedDescription)"
    }
  }

  private func icon(for category: MetricCategory) -> String {
    switch category {
    case .sleep:
      "moon.zzz"
    case .bloodPressure:
      "heart"
    case .bodyComposition:
      "scalemass"
    case .activity:
      "figure.walk"
    case .recovery:
      "waveform.path.ecg"
    case .app:
      "sparkles"
    }
  }

  private func tint(for category: MetricCategory) -> Color {
    switch category {
    case .sleep:
      NBColor.sleepTint
    case .bloodPressure:
      NBColor.danger
    case .bodyComposition:
      NBColor.mistTeal
    case .activity:
      NBColor.success
    case .recovery:
      NBColor.privacyTint
    case .app:
      NBColor.dawn
    }
  }
}

#if DEBUG
struct FitdaysImportView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      FitdaysImportView(repository: InMemoryUnifiedHealthMetricSampleRepository())
    }
  }
}
#endif
