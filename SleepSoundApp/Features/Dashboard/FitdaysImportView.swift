import SwiftUI
import UniformTypeIdentifiers

struct FitdaysImportView: View {
  private let service: FitdaysImportService
  private let repository: any UnifiedHealthMetricSampleRepositoryProtocol
  private let initialFileURL: URL?
  private let initialFileStatusMessage: String?

  @State private var isFileImporterPresented = false
  @State private var importResult: FitdaysImportResult?
  @State private var statusMessage: String?
  @State private var errorMessage: String?
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
        policySection

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

        if let statusMessage {
          NBStatusBadge(statusMessage, kind: .good, systemImage: "checkmark.circle")
        }

        if let errorMessage {
          NBStatusBadge(errorMessage, kind: .warning, systemImage: "exclamationmark.triangle")
        }
      }
    }
  }

  private var policySection: some View {
    NBPrivacyNoticeCard(
      title: "로컬 파일 import",
      messages: [
        "Fitdays 서버나 비공식 API에 연결하지 않습니다.",
        "선택한 파일은 기기 안에서만 parsing합니다.",
        "CSV/export가 보이지 않으면 Apple 건강앱 read-only 지표만 사용합니다.",
        "HealthKit에 데이터를 쓰지 않습니다.",
        "가져온 값은 개인 참고용 보기로만 표시합니다.",
      ],
      systemImage: "lock.doc"
    )
  }

  private var emptyState: some View {
    NBEmptyStateView(
      title: "가져온 파일이 없습니다",
      message: "CSV 또는 text 기반 export 파일을 확보한 경우에만 선택합니다. 파일이 없다면 건강앱 read-only 지표만 사용해도 됩니다.",
      systemImage: "doc.text.magnifyingglass",
      actionTitle: "파일 선택"
    ) {
      isFileImporterPresented = true
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
      errorMessage = error.localizedDescription
    }
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
