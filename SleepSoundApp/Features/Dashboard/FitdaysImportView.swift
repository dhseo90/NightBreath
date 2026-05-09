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
  @State private var visiblePastedExportText = ""
  @State private var pastedTextSummary: FitdaysPastedTextSummary?
  @State private var isPreviewingPaste = false
  @State private var pastePreviewTask: Task<Void, Never>?
  @State private var duplicateSummary: UnifiedHealthMetricImportDuplicateSummary?
  @State private var allowsChangedDuplicateOverwrite = false
  @State private var lastSaveConfirmation: FitdaysSaveConfirmation?
  @State private var didPreviewInitialFile = false
  @State private var savedBatches: [ImportBatch] = []
  @State private var savedSampleCountsByBatchID: [UUID: Int] = [:]
  @State private var batchPendingDeletion: ImportBatch?
  @State private var isDeleteBatchAlertPresented = false
  @State private var manualMetricID: UnifiedHealthMetricID = .bodyWaterPercentage
  @State private var manualValueText = ""
  @State private var manualMeasuredAt = Date()
  @State private var manualNotes = ""
  @State private var manualDuplicateSummary: UnifiedHealthMetricImportDuplicateSummary?
  @State private var allowsManualDuplicateOverwrite = false
  @State private var manualStatusMessage: String?
  @State private var manualErrorMessage: String?

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
        manualInputSection

        if let importResult {
          resultSection(importResult)
          previewDiagnosticsSection(importResult)
          previewSection(importResult)
        } else {
          emptyState
        }

        savedBatchesSection
        policySection
        exportUnavailableSection
        fallbackSection
      }
      .padding(NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
    .navigationTitle("Fitdays 가져오기")
    .toolbar(.hidden, for: .tabBar)
    .fileImporter(
      isPresented: $isFileImporterPresented,
      allowedContentTypes: [.commaSeparatedText, .plainText, .text],
      allowsMultipleSelection: false,
      onCompletion: handleFileImporterResult
    )
    .onAppear {
      previewInitialFileIfNeeded()
      reloadSavedImports()
    }
    .onDisappear {
      pastePreviewTask?.cancel()
    }
    .alert("가져오기 기록 삭제", isPresented: $isDeleteBatchAlertPresented) {
      Button("삭제", role: .destructive) {
        deletePendingBatch()
      }
      Button("취소", role: .cancel) {
        batchPendingDeletion = nil
      }
    } message: {
      Text("이 기록으로 저장된 로컬 샘플도 함께 삭제합니다. 원본 파일은 앱에 저장하지 않았기 때문에 삭제 대상이 아닙니다.")
    }
  }

  private var headerSection: some View {
    NBReportSection(title: "Fitdays 데이터 가져오기", systemImage: "square.and.arrow.down") {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        Text("월별 데이터 복사 텍스트나 사용자가 직접 확보한 CSV/text export 파일을 로컬에서만 정리합니다.")
          .font(NBTypography.callout)
          .foregroundStyle(NBColor.secondaryText)

        #if os(iOS)
        Button {
          pasteClipboardTextAndPreview()
        } label: {
          Label(isPreviewingPaste ? "미리보기 생성 중" : "클립보드에서 바로 미리보기", systemImage: "doc.on.clipboard")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.mistTeal))
        .disabled(isPreviewingPaste)
        #endif

        Button {
          isFileImporterPresented = true
        } label: {
          Label("파일 선택", systemImage: "doc.badge.plus")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.nbSecondary)

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

        if let pastedTextSummary {
          pastedTextSummaryView(pastedTextSummary)
        }

        ZStack(alignment: .topLeading) {
          TextEditor(text: pastedTextBinding)
            .font(.system(.footnote, design: .monospaced))
            .frame(minHeight: 96, maxHeight: 150)
            .padding(NBSpacing.small)
            .background(NBColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.medium, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: NBCornerRadius.medium, style: .continuous)
                .stroke(NBColor.divider)
            )
            .accessibilityLabel("Fitdays 월별 데이터 붙여넣기 입력")

          if visiblePastedExportText.isEmpty {
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
            Label(isPreviewingPaste ? "미리보기 생성 중" : "클립보드 붙여넣고 미리보기", systemImage: "doc.on.clipboard")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.mistTeal))
          .disabled(isPreviewingPaste)
          #endif

          HStack(spacing: NBSpacing.small) {
            Button {
              previewPastedText()
            } label: {
              Label("미리보기", systemImage: "eye")
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.nbSecondary)
            .disabled(trimmedPastedText.isEmpty || isPreviewingPaste)

            Button {
              clearPastedText()
            } label: {
              Label("비우기", systemImage: "xmark.circle")
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.nbSecondary)
            .disabled(pastedExportText.isEmpty || isPreviewingPaste)
          }
        }

        if isPreviewingPaste {
          HStack(spacing: NBSpacing.small) {
            ProgressView()
            Text("붙여넣은 데이터를 분석하는 중입니다.")
              .font(NBTypography.footnote)
              .foregroundStyle(NBColor.secondaryText)
          }
        }

        Text("붙여넣은 원문은 앱 밖이나 서버로 보내지 않고, 저장 버튼을 누른 뒤에도 변환된 로컬 샘플만 기기 안에 보관합니다.")
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private var manualInputSection: some View {
    NBReportSection(title: "Fitdays 고유 지표 수동 입력", systemImage: "square.and.pencil") {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        Text("CSV/export가 없을 때 체수분률, 내장지방 레벨처럼 HealthKit에서 직접 읽지 않는 Fitdays 고유 지표를 값 하나씩 로컬로 저장합니다.")
          .font(NBTypography.callout)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)

        Picker("지표", selection: $manualMetricID) {
          ForEach(FitdaysManualMetricEntryBuilder.supportedMetadata()) { metadata in
            Text("\(metadata.displayNameKo) · \(metadata.unit)")
              .tag(metadata.metricID)
          }
        }
        .pickerStyle(.menu)
        .accessibilityLabel("Fitdays 수동 입력 지표 선택")

        HStack(spacing: NBSpacing.small) {
          TextField("값", text: $manualValueText)
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
            .accessibilityLabel("Fitdays 수동 입력 값")

          Text(selectedManualMetricMetadata?.unit ?? "")
            .font(NBTypography.callout.weight(.semibold))
            .foregroundStyle(NBColor.secondaryText)
            .frame(minWidth: 58, alignment: .trailing)
        }

        DatePicker("측정 시각", selection: $manualMeasuredAt, displayedComponents: [.date, .hourAndMinute])
          .font(NBTypography.callout)

        TextField("메모 선택 입력", text: $manualNotes, axis: .vertical)
          .lineLimit(2...4)
          .textFieldStyle(.roundedBorder)
          .accessibilityLabel("Fitdays 수동 입력 메모")

        if let manualDuplicateSummary, manualDuplicateSummary.hasChangedDuplicates {
          Toggle(isOn: $allowsManualDuplicateOverwrite) {
            VStack(alignment: .leading, spacing: NBSpacing.xSmall) {
              Text("같은 측정 시각의 기존 수동 값을 이번 값으로 교체")
                .font(NBTypography.footnote.weight(.semibold))
                .foregroundStyle(NBColor.primaryText)
              Text("끄면 저장하지 않습니다. 켜면 같은 지표와 측정 시각의 수동 입력값을 새 값으로 바꿉니다.")
                .font(NBTypography.caption)
                .foregroundStyle(NBColor.secondaryText)
            }
          }
          .tint(NBColor.warning)
        }

        Button {
          saveManualMetricInput()
        } label: {
          Label("수동 입력 로컬 저장", systemImage: "tray.and.arrow.down")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.mistTeal))

        if let manualStatusMessage {
          NBStatusBadge(manualStatusMessage, kind: .good, systemImage: "checkmark.circle.fill")
        }

        if let manualErrorMessage {
          NBStatusBadge(manualErrorMessage, kind: .warning, systemImage: "exclamationmark.triangle")
        }

        Text("수동 입력 값은 수동 입력 source로만 저장되며 HealthKit에 쓰지 않습니다. Fitdays 서버/API, 로그인, 자동 동기화는 사용하지 않습니다.")
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
          value: "수동 입력",
          subtitle: "CSV/export 파일이 없어도 체수분률, 내장지방 레벨 같은 Fitdays 고유 지표는 사용자가 직접 입력해 로컬에 저장할 수 있습니다.",
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
    NBReportSection(title: "저장 전 미리보기", systemImage: "list.bullet.rectangle") {
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

        if let duplicateSummary, duplicateSummary.hasDuplicates {
          duplicateSummarySection(duplicateSummary)
        }

        Button {
          save(result)
        } label: {
          Label(saveButtonTitle(for: duplicateSummary), systemImage: "tray.and.arrow.down")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.sleepTint))
        .disabled(result.samples.isEmpty || isPreviewingPaste || requiresChangedDuplicateConfirmation)

        if let lastSaveConfirmation {
          NBStatusBadge(
            lastSaveConfirmation.displayMessage,
            kind: .good,
            systemImage: "checkmark.circle.fill"
          )

          savedDetailShortcut(for: lastSaveConfirmation)
        }
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

  private func previewDiagnosticsSection(_ result: FitdaysImportResult) -> some View {
    NBReportSection(title: "미리보기 판단", systemImage: "checklist") {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.medium) {
          NBMetricCard(
            title: "처리한 row",
            value: "\(result.batch.rowCount)",
            systemImage: "tablecells",
            tint: NBColor.mistTeal,
            footnote: result.batch.sourceName
          )

          NBMetricCard(
            title: "저장 가능",
            value: "\(result.samples.count)",
            systemImage: "checkmark.circle",
            tint: result.samples.isEmpty ? NBColor.warning : NBColor.success,
            footnote: "샘플"
          )
        }

        if result.samples.isEmpty {
          NBStatusBadge(
            FitdaysImportFallbackGuidance.noImportablePreviewMessage,
            kind: .caution,
            systemImage: "exclamationmark.circle"
          )
        }

        if result.skippedRowCount > 0 {
          diagnosticTextBlock(
            title: "건너뛴 row 해석",
            messages: [
              "\(result.skippedRowCount)개 row는 저장 가능한 지표 샘플로 바뀌지 않았습니다.",
              "빈 값, 측정일 누락, 지원하지 않는 지표명, 숫자 해석 실패 가능성을 확인해 주세요.",
            ]
          )
        }

        if !result.rowErrors.isEmpty {
          VStack(alignment: .leading, spacing: NBSpacing.xSmall) {
            Text("확인 필요 row")
              .font(NBTypography.caption.weight(.semibold))
              .foregroundStyle(NBColor.primaryText)

            ForEach(Array(result.rowErrors.prefix(6))) { error in
              Text("Row \(error.rowNumber): \(error.message)")
                .font(NBTypography.footnote)
                .foregroundStyle(NBColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            }

            if result.rowErrors.count > 6 {
              Text("외 \(result.rowErrors.count - 6)개 row")
                .font(NBTypography.caption)
                .foregroundStyle(NBColor.secondaryText)
            }
          }
        }

        if !result.unknownColumns.isEmpty {
          diagnosticTextBlock(
            title: "지원하지 않는 column",
            messages: [
              result.unknownColumns.joined(separator: ", "),
              "이 column은 저장하지 않고, 지원 지표만 로컬 샘플로 변환합니다.",
            ]
          )
        }
      }
    }
  }

  private var savedBatchesSection: some View {
    NBReportSection(title: "저장된 가져오기", systemImage: "externaldrive") {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        if savedBatches.isEmpty {
          VStack(alignment: .leading, spacing: NBSpacing.xSmall) {
            Text("아직 로컬에 저장한 Fitdays 가져오기 기록이 없습니다.")
              .font(NBTypography.callout)
              .foregroundStyle(NBColor.primaryText)
            Text("미리보기 확인 후 로컬에 저장을 누르면 이곳에서 저장된 기록과 샘플 수를 확인하고 삭제할 수 있습니다.")
              .font(NBTypography.footnote)
              .foregroundStyle(NBColor.secondaryText)
              .fixedSize(horizontal: false, vertical: true)
          }
        } else {
          ForEach(savedBatches) { batch in
            savedBatchRow(batch)

            if batch.id != savedBatches.last?.id {
              Divider().overlay(NBColor.divider)
            }
          }
        }

        Text("개인 정보가 파일명에 들어갈 수 있어 저장된 목록에는 실제 파일명이나 local path를 표시하지 않습니다.")
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private func savedBatchRow(_ batch: ImportBatch) -> some View {
    VStack(alignment: .leading, spacing: NBSpacing.small) {
      HStack(alignment: .top, spacing: NBSpacing.medium) {
        VStack(alignment: .leading, spacing: NBSpacing.xSmall) {
          Text(batch.sourceName)
            .font(NBTypography.callout.weight(.semibold))
            .foregroundStyle(NBColor.primaryText)
          Text("\(SleepFormatters.shortDate(batch.importedAt)) \(SleepFormatters.shortTime(batch.importedAt)) · \(batch.sourceType.displayName)")
            .font(NBTypography.caption)
            .foregroundStyle(NBColor.secondaryText)
        }

        Spacer(minLength: NBSpacing.small)

        Button(role: .destructive) {
          requestDeleteBatch(batch)
        } label: {
          Label("삭제", systemImage: "trash")
            .labelStyle(.iconOnly)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("가져오기 기록 삭제")
      }

      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.small) {
        NBMetricCard(
          title: "저장 샘플",
          value: "\(savedSampleCountsByBatchID[batch.id] ?? batch.sampleCount)",
          systemImage: "tray.full",
          tint: NBColor.mistTeal,
          footnote: "현재 저장소 기준"
        )

        NBMetricCard(
          title: "처리 row",
          value: "\(batch.rowCount)",
          systemImage: "tablecells",
          tint: NBColor.privacyTint,
          footnote: "가져오기 당시"
        )

        NBMetricCard(
          title: "건너뜀",
          value: "\(batch.skippedRowCount)",
          systemImage: "arrow.uturn.forward",
          tint: batch.skippedRowCount > 0 ? NBColor.warning : NBColor.success,
          footnote: "row"
        )

        NBMetricCard(
          title: "오류",
          value: "\(batch.errorCount)",
          systemImage: "exclamationmark.triangle",
          tint: batch.errorCount > 0 ? NBColor.warning : NBColor.success,
          footnote: "row"
        )
      }

      batchDetailShortcut(batch)

      if let notes = batch.notes, !notes.isEmpty {
        Text(notes)
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private func batchDetailShortcut(_ batch: ImportBatch) -> some View {
    let batchSamples = repository.fetchSamples(importBatchId: batch.id.uuidString)
    if let latestDate = importedDayStarts(from: batchSamples).last {
      let allSamples = repository.fetchSamples()
      let detailData = HealthCalendarBuilder().detailData(
        for: latestDate,
        samples: allSamples,
        sleepReports: []
      )

      NavigationLink {
        DailyMeasurementDetailView(
          detailData: detailData,
          allSamples: allSamples
        )
      } label: {
        HStack(spacing: NBSpacing.small) {
          Label("이 가져오기 최신 날짜 보기", systemImage: "calendar.badge.clock")
            .frame(maxWidth: .infinity, alignment: .leading)
          Text(SleepFormatters.shortDate(latestDate))
            .font(NBTypography.caption.weight(.semibold))
            .foregroundStyle(NBColor.secondaryText)
          Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
        }
      }
      .buttonStyle(NBSecondaryButtonStyle(tint: NBColor.privacyTint))
    }
  }

  private func diagnosticTextBlock(title: String, messages: [String]) -> some View {
    VStack(alignment: .leading, spacing: NBSpacing.xSmall) {
      Text(title)
        .font(NBTypography.caption.weight(.semibold))
        .foregroundStyle(NBColor.primaryText)

      ForEach(messages, id: \.self) { message in
        Text(message)
          .font(NBTypography.footnote)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func pastedTextSummaryView(_ summary: FitdaysPastedTextSummary) -> some View {
    VStack(alignment: .leading, spacing: NBSpacing.xSmall) {
      NBStatusBadge(
        "붙여넣음 · \(summary.lineCount)행 · \(summary.characterCount)자",
        kind: .good,
        systemImage: "checkmark.circle"
      )

      Text(summary.previewText)
        .font(.system(.caption, design: .monospaced))
        .foregroundStyle(NBColor.secondaryText)
        .lineLimit(3)
        .frame(maxWidth: .infinity, alignment: .leading)

      if summary.isTruncatedForDisplay {
        Text("입력창에는 앞부분만 표시하고, 미리보기와 저장은 전체 붙여넣기 원문으로 처리합니다.")
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func duplicateSummarySection(_ summary: UnifiedHealthMetricImportDuplicateSummary) -> some View {
    VStack(alignment: .leading, spacing: NBSpacing.small) {
      NBStatusBadge(
        duplicateSummaryMessage(summary),
        kind: summary.hasChangedDuplicates ? .caution : .neutral,
        systemImage: summary.hasChangedDuplicates ? "exclamationmark.triangle" : "arrow.triangle.2.circlepath"
      )

      if summary.hasChangedDuplicates {
        Toggle(isOn: $allowsChangedDuplicateOverwrite) {
          VStack(alignment: .leading, spacing: NBSpacing.xSmall) {
            Text("값이 다른 중복은 새 붙여넣기 기준으로 교체")
              .font(NBTypography.footnote.weight(.semibold))
              .foregroundStyle(NBColor.primaryText)
            Text("끄면 저장하지 않습니다. 켜면 기존 같은 날짜/시간 지표를 이번 값으로 바꿉니다.")
              .font(NBTypography.caption)
              .foregroundStyle(NBColor.secondaryText)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func duplicateSummaryMessage(_ summary: UnifiedHealthMetricImportDuplicateSummary) -> String {
    if summary.hasChangedDuplicates {
      return "중복 \(summary.duplicateSampleCount)개 중 \(summary.changedDuplicateCount)개는 기존 값과 다릅니다."
    }
    return "중복 \(summary.duplicateSampleCount)개는 기존 값과 같습니다. 새 항목 \(summary.newSampleCount)개를 함께 저장합니다."
  }

  @ViewBuilder
  private func savedDetailShortcut(for confirmation: FitdaysSaveConfirmation) -> some View {
    if let detailDate = confirmation.detailDate {
      let allSamples = repository.fetchSamples()
      let detailData = HealthCalendarBuilder().detailData(
        for: detailDate,
        samples: allSamples,
        sleepReports: []
      )

      VStack(alignment: .leading, spacing: NBSpacing.xSmall) {
        NavigationLink {
          DailyMeasurementDetailView(
            detailData: detailData,
            allSamples: allSamples
          )
        } label: {
          HStack(spacing: NBSpacing.small) {
            Label("가져온 최신 날짜 바로 보기", systemImage: "calendar.badge.clock")
              .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
              .font(.footnote.weight(.semibold))
          }
        }
        .buttonStyle(NBSecondaryButtonStyle(tint: NBColor.privacyTint))

        Text(confirmation.detailSummaryText)
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func saveButtonTitle(for summary: UnifiedHealthMetricImportDuplicateSummary?) -> String {
    guard let summary, summary.hasDuplicates else {
      return "로컬에 저장"
    }
    if summary.hasChangedDuplicates {
      return "중복 확인 후 저장"
    }
    return "중복 정리하고 저장"
  }

  private func saveSuccessMessage(
    result: FitdaysImportResult,
    duplicateSummary: UnifiedHealthMetricImportDuplicateSummary?
  ) -> String {
    guard let duplicateSummary, duplicateSummary.hasDuplicates else {
      return "로컬 저장소에 \(result.importedSampleCount)개 샘플을 저장했습니다."
    }

    if duplicateSummary.hasChangedDuplicates {
      return "새 샘플 \(duplicateSummary.newSampleCount)개를 저장하고 값이 다른 중복 \(duplicateSummary.changedDuplicateCount)개를 새 데이터 기준으로 교체했습니다."
    }

    return "새 샘플 \(duplicateSummary.newSampleCount)개를 저장하고 같은 중복 \(duplicateSummary.unchangedDuplicateCount)개를 정리했습니다."
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
      get: { visiblePastedExportText },
      set: { newValue in
        guard newValue != visiblePastedExportText else { return }
        stagePastedText(newValue, statusPrefix: nil)
      }
    )
  }

  private var requiresChangedDuplicateConfirmation: Bool {
    duplicateSummary?.hasChangedDuplicates == true && !allowsChangedDuplicateOverwrite
  }

  private var selectedManualMetricMetadata: MetricDisplayMetadata? {
    MetricCatalog.default.metadata(for: manualMetricID)
  }

  private func clearPastedText() {
    pastedExportText = ""
    visiblePastedExportText = ""
    pastedTextSummary = nil
    clearPastedPreviewState()
  }

  private func clearPastedPreviewState() {
    pastePreviewTask?.cancel()
    isPreviewingPaste = false
    importResult = nil
    duplicateSummary = nil
    allowsChangedDuplicateOverwrite = false
    lastSaveConfirmation = nil
    statusMessage = nil
    errorMessage = nil
  }

  private func saveManualMetricInput() {
    manualStatusMessage = nil
    manualErrorMessage = nil

    guard let value = parseManualValue(manualValueText) else {
      manualErrorMessage = "0 이상의 숫자 값을 입력해 주세요."
      return
    }

    do {
      let sample = try FitdaysManualMetricEntryBuilder.makeSample(
        metricID: manualMetricID,
        value: value,
        measuredAt: manualMeasuredAt,
        notes: manualNotes
      )
      let duplicateSummary = UnifiedHealthMetricImportDuplicateSummary(
        existingSamples: repository.fetchSamples(),
        incomingSamples: [sample]
      )

      if duplicateSummary.hasChangedDuplicates && !allowsManualDuplicateOverwrite {
        manualDuplicateSummary = duplicateSummary
        manualErrorMessage = "같은 측정 시각의 기존 수동 입력값과 다릅니다. 교체 여부를 선택해 주세요."
        return
      }

      let batch = FitdaysManualMetricEntryBuilder.makeBatch(for: sample)
      var sampleForSave = sample
      sampleForSave.importBatchId = batch.id.uuidString
      try repository.save(batch: batch, samples: [sampleForSave])
      manualDuplicateSummary = nil
      allowsManualDuplicateOverwrite = false
      manualValueText = ""
      manualNotes = ""
      manualStatusMessage = manualSaveSuccessMessage(sample: sampleForSave, duplicateSummary: duplicateSummary)
      statusMessage = manualStatusMessage
      errorMessage = nil
      reloadSavedImports()
    } catch {
      manualErrorMessage = userFacingManualInputErrorMessage(error)
    }
  }

  private func parseManualValue(_ text: String) -> Double? {
    let normalizedText = text
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: ",", with: ".")
    guard let value = Double(normalizedText), value.isFinite, value >= 0 else {
      return nil
    }
    return value
  }

  private func manualSaveSuccessMessage(
    sample: UnifiedHealthMetricSample,
    duplicateSummary: UnifiedHealthMetricImportDuplicateSummary
  ) -> String {
    let metricName = selectedManualMetricMetadata?.displayNameKo ?? sample.metricID.rawValue
    if duplicateSummary.hasChangedDuplicates {
      return "\(metricName) 수동 입력값을 새 값으로 교체했습니다."
    }
    if duplicateSummary.hasDuplicates {
      return "\(metricName) 수동 입력값을 같은 값으로 다시 저장했습니다."
    }
    return "\(metricName) 수동 입력값을 로컬에 저장했습니다."
  }

  private func userFacingManualInputErrorMessage(_ error: Error) -> String {
    guard let manualError = error as? FitdaysManualMetricEntryError,
          let description = manualError.errorDescription else {
      return "수동 입력 저장에 실패했습니다: \(error.localizedDescription)"
    }
    return description
  }

  private func stagePastedText(_ text: String, statusPrefix: String?) {
    pastePreviewTask?.cancel()
    let summary = FitdaysPastedTextSummary(text: text)
    pastedExportText = text
    visiblePastedExportText = summary.visibleText
    pastedTextSummary = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : summary
    importResult = nil
    duplicateSummary = nil
    allowsChangedDuplicateOverwrite = false
    lastSaveConfirmation = nil
    errorMessage = nil
    if let statusPrefix, let pastedTextSummary {
      statusMessage = "\(statusPrefix) · \(pastedTextSummary.lineCount)행 · \(pastedTextSummary.characterCount)자"
    } else {
      statusMessage = nil
    }
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
    lastSaveConfirmation = nil

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

    stagePastedText(clipboardText, statusPrefix: "클립보드 텍스트를 받았습니다")
    previewPastedText(clipboardText)
  }
  #endif

  private func previewPastedText(_ textOverride: String? = nil) {
    pastePreviewTask?.cancel()
    errorMessage = nil
    statusMessage = "붙여넣은 데이터 미리보기를 준비하고 있습니다."
    importResult = nil
    duplicateSummary = nil
    allowsChangedDuplicateOverwrite = false
    lastSaveConfirmation = nil
    isPreviewingPaste = true

    let text = textOverride ?? pastedExportText
    let service = service

    pastePreviewTask = Task {
      let previewResult = await Task.detached(priority: .userInitiated) {
        Result {
          try service.previewImport(fromPastedText: text)
        }
      }.value

      await MainActor.run {
        guard !Task.isCancelled else { return }
        isPreviewingPaste = false

        switch previewResult {
        case .success(let result):
          importResult = result
          duplicateSummary = UnifiedHealthMetricImportDuplicateSummary(
            existingSamples: repository.fetchSamples(),
            incomingSamples: result.samples
          )
          statusMessage = "붙여넣은 월별 데이터에서 저장 전 미리보기를 만들었습니다."
        case .failure(let error):
          importResult = nil
          duplicateSummary = nil
          errorMessage = userFacingImportErrorMessage(error)
        }
      }
    }
  }

  private func save(_ result: FitdaysImportResult) {
    guard !requiresChangedDuplicateConfirmation else {
      errorMessage = "값이 다른 중복 데이터가 있습니다. 새 붙여넣기 기준으로 교체할지 먼저 선택해 주세요."
      return
    }

    do {
      try repository.save(batch: result.batch, samples: result.samples)
      let importedDates = importedDayStarts(from: result.samples)
      let confirmation = FitdaysSaveConfirmation(
        message: saveSuccessMessage(result: result, duplicateSummary: duplicateSummary),
        savedAt: Date(),
        sampleCount: result.samples.count,
        importedDayCount: importedDates.count,
        detailDate: importedDates.last
      )
      lastSaveConfirmation = confirmation
      statusMessage = confirmation.message
      errorMessage = nil
      duplicateSummary = nil
      allowsChangedDuplicateOverwrite = false
      reloadSavedImports()
    } catch {
      lastSaveConfirmation = nil
      errorMessage = "저장에 실패했습니다: \(error.localizedDescription)"
    }
  }

  private func importedDayStarts(from samples: [UnifiedHealthMetricSample]) -> [Date] {
    let calendar = Calendar.current
    return Array(Set(samples.map { calendar.startOfDay(for: $0.measuredAt) }))
      .sorted()
  }

  private func reloadSavedImports() {
    let batches = repository.fetchBatches()
    savedBatches = batches
    savedSampleCountsByBatchID = Dictionary(
      uniqueKeysWithValues: batches.map { batch in
        (batch.id, repository.fetchSamples(importBatchId: batch.id.uuidString).count)
      }
    )
  }

  private func requestDeleteBatch(_ batch: ImportBatch) {
    batchPendingDeletion = batch
    isDeleteBatchAlertPresented = true
  }

  private func deletePendingBatch() {
    guard let batch = batchPendingDeletion else { return }

    do {
      try repository.deleteBatch(id: batch.id)
      statusMessage = "선택한 Fitdays 가져오기 기록과 관련 샘플을 삭제했습니다."
      errorMessage = nil
      batchPendingDeletion = nil
      reloadSavedImports()
    } catch {
      errorMessage = "batch 삭제에 실패했습니다: \(error.localizedDescription)"
      batchPendingDeletion = nil
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

private struct FitdaysPastedTextSummary: Equatable {
  private static let displayCharacterLimit = 1_600

  var lineCount: Int
  var characterCount: Int
  var visibleText: String
  var previewText: String
  var isTruncatedForDisplay: Bool

  init(text: String) {
    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    let lines = trimmedText
      .split(whereSeparator: \.isNewline)
      .map(String.init)

    lineCount = lines.count
    characterCount = text.count
    previewText = lines.prefix(3).joined(separator: "\n")

    if text.count > Self.displayCharacterLimit {
      let prefix = String(text.prefix(Self.displayCharacterLimit))
      visibleText = "\(prefix)\n…"
      isTruncatedForDisplay = true
    } else {
      visibleText = text
      isTruncatedForDisplay = false
    }
  }
}

private struct FitdaysSaveConfirmation: Equatable {
  var message: String
  var savedAt: Date
  var sampleCount: Int
  var importedDayCount: Int
  var detailDate: Date?

  var displayMessage: String {
    "\(message) · \(SleepFormatters.shortTime(savedAt))"
  }

  var detailSummaryText: String {
    guard let detailDate else {
      return "저장된 날짜가 없으면 상세 화면으로 이동하지 않습니다."
    }

    let dayText = SleepFormatters.shortDate(detailDate)
    if importedDayCount > 1 {
      return "\(importedDayCount)일치 \(sampleCount)개 샘플 중 최신 날짜 \(dayText)를 엽니다."
    }

    return "\(sampleCount)개 샘플이 들어간 \(dayText)를 엽니다."
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
