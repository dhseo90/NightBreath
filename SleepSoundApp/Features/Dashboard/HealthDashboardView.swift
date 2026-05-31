import SwiftUI

struct HealthDashboardView: View {
  private let service: any HealthKitServiceProtocol
  private let unifiedSampleRepository: any UnifiedHealthMetricSampleRepositoryProtocol
  private let userSettings: UserSettingsProviding
  private let mockService = MockHealthKitService()
  private let calculator = HealthMetricTrendCalculator()
  private let healthKitDashboardLookbackDays = 370

  @EnvironmentObject private var appState: AppState
  @State private var permissionState: HealthMetricPermissionState = .notRequested
  @State private var healthSamples: [HealthMetricSample] = []
  @State private var importedUnifiedSamples: [UnifiedHealthMetricSample] = []
  @State private var isLoading = false
  @State private var statusMessage: String?
  @State private var refreshFeedback: HealthDataRefreshFeedback = .idle
  @State private var hasRequestedHealthKitReadAccess: Bool
  @State private var isDataDetailsExpanded = false

  init(
    service: any HealthKitServiceProtocol = RealHealthKitService(),
    unifiedSampleRepository: any UnifiedHealthMetricSampleRepositoryProtocol = JSONUnifiedHealthMetricSampleRepository(),
    userSettings: UserSettingsProviding = UserSettings()
  ) {
    self.service = service
    self.unifiedSampleRepository = unifiedSampleRepository
    self.userSettings = userSettings
    _hasRequestedHealthKitReadAccess = State(initialValue: userSettings.hasRequestedHealthKitReadAccess)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        header
        stateNotice
        calendarShortcutSection
        dashboardEntrySection
        dataStateSection

        if dataStateSummary.shouldShowEmptyState {
          HealthDataEmptyStateView(
            title: dataStateSummary.title,
            message: dataStateSummary.message
          )
        } else if !visibleSamples.isEmpty {
          overviewSection
        }

        if shouldShowDataDetailsSection {
          hiddenDataDetailsSection
        }

        NBPrivacyNoticeCard(
          title: "Apple 건강앱 read-only",
          messages: [
            "권한을 허용해도 밤숨은 건강앱 데이터를 읽어 화면에 표시할 뿐입니다.",
            "HealthKit에 데이터를 쓰지 않습니다.",
            "서버로 전송하지 않습니다.",
            "건강 데이터 연결 버튼을 선택할 때만 읽기 권한을 요청합니다.",
          ],
          systemImage: "lock.shield"
        )
      }
      .padding(.horizontal, NBSpacing.screenHorizontal)
      .padding(.top, NBSpacing.sm)
      .padding(.bottom, NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
    .navigationTitle("건강 데이터")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      loadImportedUnifiedSamples()
      refreshHealthDataIfPreviouslyConnected()
    }
  }

  private var visibleSamples: [HealthMetricSample] {
    switch permissionState {
    case .notRequested, .mockDataOnly:
      shouldShowPreviewHealthSamples ? mockService.samples : []
    case .readRequestCompleted:
      healthSamples
    case .denied, .unavailable:
      []
    }
  }

  private var isPreviewData: Bool {
    permissionState == .notRequested || permissionState == .mockDataOnly
  }

  private var shouldShowPreviewHealthSamples: Bool {
    isPreviewData && importedUnifiedSamples.isEmpty && !hasRequestedHealthKitReadAccess
  }

  private var unifiedDashboardSamples: [UnifiedHealthMetricSample] {
    let healthSourceType: HealthMetricSourceType = isPreviewData ? .mock : .healthKit
    return (
      visibleSamples.map { $0.unifiedSample(sourceType: healthSourceType) }
        + appComputedCalendarSamples
        + importedUnifiedSamples
    )
    .sortedByMeasuredAtAscending()
  }

  private var calendarReports: [NightReport] {
    appState.trendReports(days: 370)
  }

  private var dataStateSummary: HealthDashboardDataStateSummary {
    HealthDashboardDataStateSummary.make(
      permissionState: permissionState,
      isPreviewData: isPreviewData,
      healthOrPreviewSampleCount: visibleSamples.count,
      localImportSampleCount: importedUnifiedSamples.count,
      appComputedSampleCount: appComputedCalendarSamples.count
    )
  }

  private var calendarMorningCheckIns: [MorningCheckIn] {
    calendarReports.compactMap { appState.checkIn(for: $0.sessionId) }
  }

  private var calendarEveningCheckIns: [EveningCheckIn] {
    let cutoff = Calendar.current.date(byAdding: .day, value: -healthKitDashboardLookbackDays, to: Date()) ?? .distantPast
    return appState.eveningCheckIns.filter { $0.date >= cutoff }
  }

  private var appComputedCalendarSamples: [UnifiedHealthMetricSample] {
    let calendar = Calendar.current
    let summaries = Dictionary(grouping: calendarReports) { report in
      calendar.startOfDay(for: report.generatedAt)
    }
    .values
    .compactMap { DailySleepReportSummary(reports: $0) }
    .sorted { $0.latestGeneratedAt < $1.latestGeneratedAt }

    return summaries.flatMap { summary in
      let sourceName = summary.isAggregated ? "밤숨 앱 · 하루 합산" : "밤숨 앱"
      let notes = summary.isAggregated ? "\(summary.reportCount)개 수면 기록을 하루 단위로 합산했습니다." : nil
      return [
        UnifiedHealthMetricSample(
          metricID: .sleepSoundScore,
          value: Double(summary.sleepSoundScore),
          unit: "점",
          measuredAt: summary.latestGeneratedAt,
          sourceType: .appComputed,
          sourceName: sourceName,
          notes: notes
        ),
        UnifiedHealthMetricSample(
          metricID: .audioCoverageRatio,
          value: summary.audioCoverageRatio * 100,
          unit: "%",
          measuredAt: summary.latestGeneratedAt,
          sourceType: .appComputed,
          sourceName: sourceName,
          notes: notes
        ),
      ]
    }
  }

  private var header: some View {
    NBCard {
      VStack(alignment: .leading, spacing: NBSpacing.sm) {
        HStack(alignment: .center, spacing: NBSpacing.md) {
          Image(systemName: "heart.text.square")
            .font(.title3.weight(.semibold))
            .foregroundStyle(NBColor.privacyTint)
            .frame(width: 32, height: 32)
            .accessibilityHidden(true)

          VStack(alignment: .leading, spacing: NBSpacing.xs) {
            Text("Apple 건강앱")
              .font(NBTypography.headline)
              .foregroundStyle(NBColor.primaryText)
              .lineLimit(1)

            Text(service.isAvailable ? "버튼을 누를 때만 권한 요청" : service.authorizationStatusDescription())
              .font(NBTypography.caption)
              .foregroundStyle(service.isAvailable ? NBColor.secondaryText : NBColor.warning)
              .lineLimit(2)
          }

          Spacer(minLength: NBSpacing.sm)

          Button {
            connectHealthData()
          } label: {
            compactHealthConnectButtonLabel
          }
          .buttonStyle(.plain)
          .disabled(isLoading || !service.isAvailable)
          .opacity(isLoading || !service.isAvailable ? 0.68 : 1)
          .accessibilityHint(isLoading ? "이미 건강 데이터를 읽는 중입니다." : "버튼을 누를 때만 Apple 건강앱 읽기 권한을 요청합니다.")
        }

        healthRefreshFeedbackSummary
        healthDataRefreshFeedbackView
      }
    }
  }

  @ViewBuilder
  private var compactHealthConnectButtonLabel: some View {
    HStack(spacing: NBSpacing.sm) {
      if isLoading {
        ProgressView()
          .controlSize(.small)
          .tint(.white)
        Text("건강앱 읽는 중")
      } else {
        Image(systemName: healthConnectButtonIcon)
          .imageScale(.medium)
        Text(compactHealthConnectButtonTitle)
      }
    }
    .font(NBTypography.subheadline)
    .foregroundStyle(.white)
    .lineLimit(1)
    .minimumScaleFactor(0.82)
    .padding(.horizontal, NBSpacing.md)
    .frame(minWidth: 112, minHeight: 42)
    .background(NBColor.privacyTint)
    .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder
  private var healthRefreshFeedbackSummary: some View {
    if hasRequestedHealthKitReadAccess || permissionState == .readRequestCompleted || refreshFeedback.isActive {
      HealthRefreshFeedbackSummary(feedback: refreshFeedback, isLoading: isLoading)
    }
  }

  @ViewBuilder
  private var healthDataRefreshFeedbackView: some View {
    switch refreshFeedback {
    case .idle:
      if hasRequestedHealthKitReadAccess || permissionState == .readRequestCompleted {
        NBInlineStatus(
          title: "아직 이번 화면에서 새로고침 전",
          detail: "버튼을 누르면 진행 중 표시와 완료 시간이 여기에 남습니다.",
          kind: .neutral,
          systemImage: "clock"
        )
      }
    case let .reading(message, startedAt):
      NBInlineStatus(
        title: message,
        detail: "요청 시각 \(SleepFormatters.shortTime(startedAt)) · 완료되기 전까지 버튼은 비활성화됩니다.",
        kind: .privacy,
        systemImage: "arrow.triangle.2.circlepath",
        isLoading: true
      )
    case let .finished(sampleCount, completedAt):
      NBInlineStatus(
        title: "새로고침 완료 · \(SleepFormatters.shortTime(completedAt))",
        detail: "HealthKit 샘플 \(sampleCount)개를 최근 1년 범위에서 읽었습니다.",
        kind: sampleCount > 0 ? .good : .caution,
        systemImage: sampleCount > 0 ? "checkmark.circle" : "tray"
      )
    case let .blocked(message):
      NBInlineStatus(
        title: "새로고침 완료 안 됨",
        detail: message,
        kind: .caution,
        systemImage: "exclamationmark.circle"
      )
    }
  }

  @ViewBuilder
  private var stateNotice: some View {
    switch permissionState {
    case .notRequested:
      NBStatusBadge(
        "연결 전: 아래 값은 예시 미리보기입니다.",
        kind: .neutral,
        systemImage: "eye"
      )
    case .mockDataOnly:
      NBStatusBadge(
        "예시 데이터만 표시",
        kind: .neutral,
        systemImage: "sparkles"
      )
    case .readRequestCompleted:
      if healthSamples.isEmpty {
        NBStatusBadge(
          "최근 1년 범위에서 읽을 수 있는 건강 데이터가 아직 없습니다.",
          kind: .caution,
          systemImage: "tray"
        )
      } else {
        NBStatusBadge(
          "Apple 건강앱에서 최근 1년 데이터를 읽었습니다.",
          kind: .good,
          systemImage: "checkmark.circle"
        )
      }
    case .denied:
      NBStatusBadge(
        "건강 데이터 읽기 권한이 필요합니다.",
        kind: .caution,
        systemImage: "lock.slash"
      )
    case .unavailable:
      NBStatusBadge(
        "이 기기에서는 건강 데이터 읽기를 사용할 수 없습니다.",
        kind: .warning,
        systemImage: "exclamationmark.triangle"
      )
    }

    if let statusMessage {
      Text(statusMessage)
        .font(NBTypography.footnote)
        .foregroundStyle(NBColor.secondaryText)
    }
  }

  private var calendarShortcutSection: some View {
    NavigationLink {
      HealthCalendarView(
        samples: unifiedDashboardSamples,
        sleepReports: calendarReports,
        morningCheckIns: calendarMorningCheckIns,
        eveningCheckIns: calendarEveningCheckIns,
        permissionState: permissionState,
        isPreviewData: isPreviewData
      )
    } label: {
      HealthCalendarPrimaryCard(
        sampleCount: unifiedDashboardSamples.count + calendarReports.count,
        latestDate: healthCalendarLatestDate
      )
    }
    .buttonStyle(.plain)
  }

  private var dashboardEntrySection: some View {
    NBReportSection(title: "건강 화면", systemImage: "rectangle.grid.1x2") {
      VStack(spacing: NBSpacing.medium) {
        NavigationLink {
          BodyCompositionDashboardView(
            samples: unifiedDashboardSamples,
            permissionState: permissionState,
            isPreviewData: isPreviewData
          )
        } label: {
          HealthDashboardEntryCard(
            title: "체성분 종합",
            subtitle: "BMI 참고 구간과 변화",
            systemImage: "figure.strengthtraining.traditional",
            tint: NBColor.breathBlue,
            sampleCount: bodyCompositionDashboardSamples.count,
            latestDate: latestBodyCompositionDate
          )
        }
        .buttonStyle(.plain)

        NavigationLink {
          FitdaysImportView()
        } label: {
          HealthDashboardEntryCard(
            title: "Fitdays 가져오기",
            subtitle: "붙여넣기 또는 파일",
            systemImage: "square.and.arrow.down",
            tint: NBColor.mistTeal,
            sampleCount: importedUnifiedSamples.count,
            latestDate: latestImportedUnifiedDate
          )
        }
        .buttonStyle(.plain)
      }
    }
  }

  private var dataStateSection: some View {
    NBReportSection(title: "데이터 상태", systemImage: "waveform.path.ecg.rectangle") {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        VStack(alignment: .leading, spacing: 4) {
          Text(dataStateSummary.title)
            .font(NBTypography.callout.weight(.semibold))
            .foregroundStyle(NBColor.primaryText)
          Text(dataStateSummary.message)
            .font(NBTypography.footnote)
            .foregroundStyle(NBColor.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
        }

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: NBSpacing.small)], spacing: NBSpacing.small) {
          HealthDataStatePill(
            title: isPreviewData ? "예시" : "Apple 건강앱",
            value: "\(dataStateSummary.healthOrPreviewSampleCount)",
            systemImage: isPreviewData ? "eye" : "heart.text.square",
            tint: NBColor.privacyTint,
            caption: isPreviewData ? "미리보기" : "read-only"
          )

          HealthDataStatePill(
            title: "로컬",
            value: "\(dataStateSummary.localImportSampleCount)",
            systemImage: "square.and.arrow.down",
            tint: NBColor.mistTeal,
            caption: "Fitdays"
          )

          HealthDataStatePill(
            title: "앱 계산",
            value: "\(dataStateSummary.appComputedSampleCount)",
            systemImage: "sparkles",
            tint: NBColor.dawn,
            caption: "기기 안"
          )
        }

        if let healthKitFetchSummary {
          Text(healthKitFetchSummary)
            .font(NBTypography.caption)
            .foregroundStyle(NBColor.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
        }

        if let bloodPressureFetchSummary {
          NBStatusBadge(
            bloodPressureFetchSummary.message,
            kind: bloodPressureFetchSummary.kind,
            systemImage: bloodPressureFetchSummary.systemImage
          )
        }
      }
    }
  }

  private var overviewSection: some View {
    NBReportSection(title: "최근 값", systemImage: "clock") {
      VStack(spacing: NBSpacing.small) {
        latestMetricRow(.systolicBloodPressure)
        Divider().overlay(NBColor.divider)
        latestMetricRow(.diastolicBloodPressure)
        Divider().overlay(NBColor.divider)
        latestMetricRow(.bodyMass)
        Divider().overlay(NBColor.divider)
        latestMetricRow(.bodyFatPercentage)
      }
    }
  }

  private var hiddenDataDetailsSection: some View {
    NBReportSection(title: "세부 데이터", systemImage: "line.3.horizontal.decrease.circle") {
      DisclosureGroup(isExpanded: $isDataDetailsExpanded) {
        VStack(alignment: .leading, spacing: NBSpacing.medium) {
          if !visibleSamples.isEmpty {
            HealthDataDetailGroupTitle("데이터 출처")
            ForEach(calculator.sourceSummaries(samples: visibleSamples), id: \.sourceBundleIdentifier) { source in
              HealthDataDetailRow(
                title: source.sourceName,
                value: "\(source.sampleCount)개",
                subtitle: "\(source.sourceBundleIdentifier) · 최근 \(SleepFormatters.shortDate(source.latestMeasuredAt))",
                systemImage: "app.connected.to.app.below.fill",
                tint: NBColor.privacyTint
              )
            }
          }

          if !importedUnifiedSamples.isEmpty {
            HealthDataDetailGroupTitle("로컬 import 값")
            ForEach(importedUnifiedSamples.sortedByMeasuredAtDescending().prefix(6)) { sample in
              if let displayModel = sample.displayModel() {
                HealthDataDetailRow(
                  title: displayModel.metadata.displayNameKo,
                  value: displayModel.valueText,
                  subtitle: "\(SleepFormatters.shortDate(sample.measuredAt)) · \(sample.sourceType.displayName)",
                  systemImage: "internaldrive",
                  tint: NBColor.mistTeal
                )
              }
            }
          }

          Text("Fitdays CSV/text import 값은 HealthKit에 쓰지 않고 로컬 샘플로만 표시합니다.")
            .font(NBTypography.caption)
            .foregroundStyle(NBColor.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, NBSpacing.small)
      } label: {
        HStack(spacing: NBSpacing.small) {
          Image(systemName: "internaldrive")
            .foregroundStyle(NBColor.mistTeal)
          Text("출처와 로컬 import 값")
            .font(NBTypography.callout.weight(.semibold))
            .foregroundStyle(NBColor.primaryText)
          Spacer()
          Text("\(hiddenDataDetailCount)개")
            .font(NBTypography.captionEmphasis)
            .foregroundStyle(NBColor.secondaryText)
        }
      }
    }
  }

  private func connectHealthData() {
    guard !isLoading else {
      return
    }

    isLoading = true
    let isRefresh = hasRequestedHealthKitReadAccess || permissionState == .readRequestCompleted
    refreshFeedback = .reading(message: isRefresh ? "새로고침 요청됨 · 읽는 중" : "건강 데이터 연결 요청됨 · 읽는 중", startedAt: Date())
    statusMessage = "Apple 건강앱 read-only 데이터를 읽기 시작했습니다."

    Task {
      let nextPermissionState = await service.requestReadPermission()
      let fetchedSamples: [HealthMetricSample]

      if nextPermissionState.canFetchSamples {
        fetchedSamples = await fetchDashboardSamples()
      } else {
        fetchedSamples = []
      }

      await MainActor.run {
        permissionState = nextPermissionState
        healthSamples = fetchedSamples
        hasRequestedHealthKitReadAccess = nextPermissionState == .readRequestCompleted
        userSettings.hasRequestedHealthKitReadAccess = hasRequestedHealthKitReadAccess
        statusMessage = message(for: nextPermissionState, sampleCount: fetchedSamples.count)
        refreshFeedback = feedback(for: nextPermissionState, sampleCount: fetchedSamples.count, completedAt: Date())
        isLoading = false
      }
    }
  }

  private func refreshHealthDataIfPreviouslyConnected() {
    guard userSettings.hasRequestedHealthKitReadAccess,
          service.isAvailable,
          permissionState != .readRequestCompleted,
          !isLoading else {
      return
    }

    hasRequestedHealthKitReadAccess = true
    permissionState = .readRequestCompleted
    isLoading = true
    refreshFeedback = .reading(message: "이전 연결 상태 확인 중 · 읽는 중", startedAt: Date())
    statusMessage = "이전에 연결한 Apple 건강앱 데이터를 다시 읽고 있습니다."

    Task {
      let fetchedSamples = await fetchDashboardSamples()

      await MainActor.run {
        healthSamples = fetchedSamples
        statusMessage = message(for: .readRequestCompleted, sampleCount: fetchedSamples.count)
        refreshFeedback = .finished(sampleCount: fetchedSamples.count, completedAt: Date())
        isLoading = false
      }
    }
  }

  private func loadImportedUnifiedSamples() {
    importedUnifiedSamples = unifiedSampleRepository.fetchSamples()
  }

  private func fetchDashboardSamples() async -> [HealthMetricSample] {
    let dateRange = HealthMetricDateRange.days(healthKitDashboardLookbackDays, endingAt: Date())
    var fetchedSamples: [HealthMetricSample] = []

    for metricType in HealthMetricType.readOnlyHealthKitMetrics {
      let metricSamples = await service.fetchSamples(
        metricType: metricType,
        dateRange: dateRange
      )
      fetchedSamples.append(contentsOf: metricSamples)
    }

    return fetchedSamples.sortedByMeasuredAtAscending()
  }

  private func message(
    for state: HealthMetricPermissionState,
    sampleCount: Int
  ) -> String {
    switch state {
    case .notRequested:
      "아직 건강 데이터 연결을 요청하지 않았습니다."
    case .readRequestCompleted:
      sampleCount > 0
        ? "건강앱 샘플 \(sampleCount)개를 최근 1년 범위에서 로컬로 읽었습니다. 허용된 항목만 표시됩니다."
        : "권한이 허용되었더라도 항목별 권한, 실제 데이터 유무, 원본 앱의 Apple 건강앱 동기화 상태에 따라 값이 비어 있을 수 있습니다."
    case .denied:
      "건강 데이터 권한이 허용되지 않았습니다. 앱은 기존 수면 소리 기능을 계속 사용할 수 있습니다."
    case .unavailable:
      "이 기기에서는 건강앱 read-only 연결을 사용할 수 없습니다."
    case .mockDataOnly:
      "예시 데이터로 화면을 표시합니다."
    }
  }

  private var healthConnectButtonTitle: String {
    hasRequestedHealthKitReadAccess || permissionState == .readRequestCompleted
      ? "건강 데이터 새로고침"
      : "건강 데이터 연결"
  }

  private var compactHealthConnectButtonTitle: String {
    hasRequestedHealthKitReadAccess || permissionState == .readRequestCompleted
      ? "새로고침"
      : "연결"
  }

  private var healthConnectButtonIcon: String {
    hasRequestedHealthKitReadAccess || permissionState == .readRequestCompleted
      ? "arrow.triangle.2.circlepath"
      : "heart.text.square"
  }

  private func feedback(
    for state: HealthMetricPermissionState,
    sampleCount: Int,
    completedAt: Date
  ) -> HealthDataRefreshFeedback {
    switch state {
    case .readRequestCompleted:
      .finished(sampleCount: sampleCount, completedAt: completedAt)
    case .denied:
      .blocked(message: "건강 데이터 읽기 권한이 허용되지 않았습니다. 설정 앱에서 권한을 확인한 뒤 다시 눌러 주세요.")
    case .unavailable:
      .blocked(message: "이 기기에서는 건강 데이터 읽기를 사용할 수 없습니다.")
    case .notRequested, .mockDataOnly:
      .blocked(message: "건강 데이터 연결이 아직 완료되지 않았습니다.")
    }
  }

  private var healthKitFetchSummary: String? {
    guard permissionState == .readRequestCompleted else {
      return nil
    }
    guard let first = healthSamples.first?.measuredAt,
          let latest = healthSamples.last?.measuredAt else {
      return "HealthKit 읽기 결과: 최근 1년 범위에서 샘플 0개"
    }
    return "HealthKit 읽기 결과: \(healthSamples.count)개 · \(SleepFormatters.shortDate(first))~\(SleepFormatters.shortDate(latest))"
  }

  private var bloodPressureFetchSummary: (message: String, kind: NBStatusKind, systemImage: String)? {
    guard permissionState == .readRequestCompleted else {
      return nil
    }

    let bloodPressureSamples = healthSamples
      .filter { HealthDashboardMetrics.bloodPressure.contains($0.metricType) }

    guard let first = bloodPressureSamples.first?.measuredAt,
          let latest = bloodPressureSamples.last?.measuredAt else {
      return (
        "혈압 HealthKit 샘플 0개입니다. Apple 건강앱의 혈압 항목 권한과 Omron/측정 앱의 Apple 건강앱 동기화를 확인하세요.",
        .caution,
        "heart.slash"
      )
    }

    return (
      "혈압 HealthKit 샘플 \(bloodPressureSamples.count)개 · \(SleepFormatters.shortDate(first))~\(SleepFormatters.shortDate(latest))",
      .good,
      "heart.text.square"
    )
  }

  private var shouldShowDataDetailsSection: Bool {
    !visibleSamples.isEmpty || !importedUnifiedSamples.isEmpty
  }

  private var hiddenDataDetailCount: Int {
    calculator.sourceSummaries(samples: visibleSamples).count + importedUnifiedSamples.count
  }

  private func latestMetricRow(_ metricType: HealthMetricType) -> NBListRow {
    guard let sample = visibleSamples.latestSample(metricType: metricType) else {
      return NBListRow(
        title: metricType.displayName,
        value: "--",
        subtitle: "최근 값 없음",
        systemImage: HealthMetricDashboardFormatting.icon(for: metricType),
        tint: HealthMetricDashboardFormatting.tint(for: metricType)
      )
    }

    let value = HealthMetricDashboardFormatting.valueString(sample.value, unit: sample.unit)
    return NBListRow(
      title: metricType.displayName,
      value: value,
      subtitle: "최근 \(SleepFormatters.shortDate(sample.measuredAt))",
      systemImage: HealthMetricDashboardFormatting.icon(for: metricType),
      tint: HealthMetricDashboardFormatting.tint(for: metricType),
      accessibilityLabel: "\(metricType.displayName), \(value), 최근 \(SleepFormatters.shortDate(sample.measuredAt))"
    )
  }

  private var unifiedDashboardLatestDate: Date? {
    unifiedDashboardSamples.sortedByMeasuredAtDescending().first?.measuredAt
  }

  private var latestImportedUnifiedDate: Date? {
    importedUnifiedSamples.sortedByMeasuredAtDescending().first?.measuredAt
  }

  private var bodyCompositionDashboardSamples: [UnifiedHealthMetricSample] {
    let metricIDs = Set(BodyCompositionReferenceAnalyzer.metricIDs)
    return unifiedDashboardSamples
      .filter { metricIDs.contains($0.metricID) }
      .sortedByMeasuredAtAscending()
  }

  private var latestBodyCompositionDate: Date? {
    bodyCompositionDashboardSamples.sortedByMeasuredAtDescending().first?.measuredAt
  }

  private var healthCalendarLatestDate: Date? {
    [
      unifiedDashboardLatestDate,
      calendarReports.sorted { $0.generatedAt > $1.generatedAt }.first?.generatedAt,
    ]
    .compactMap { $0 }
    .max()
  }
}

private enum HealthDataRefreshFeedback {
  case idle
  case reading(message: String, startedAt: Date)
  case finished(sampleCount: Int, completedAt: Date)
  case blocked(message: String)

  var isActive: Bool {
    switch self {
    case .idle:
      return false
    case .reading, .finished, .blocked:
      return true
    }
  }
}

private struct HealthRefreshFeedbackSummary: View {
  let feedback: HealthDataRefreshFeedback
  let isLoading: Bool

  var body: some View {
    HStack(spacing: NBSpacing.sm) {
      if isLoading {
        ProgressView()
          .controlSize(.small)
          .tint(kind.tint)
          .accessibilityHidden(true)
      } else {
        Image(systemName: systemImage)
          .foregroundStyle(kind.tint)
          .frame(width: 22)
          .accessibilityHidden(true)
      }

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(NBTypography.captionEmphasis)
          .foregroundStyle(NBColor.primaryText)
        Text(detail)
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
      }

      Spacer(minLength: NBSpacing.sm)
    }
    .padding(NBSpacing.sm)
    .background(kind.tint.opacity(0.08), in: RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous)
        .stroke(kind.tint.opacity(0.18), lineWidth: 1)
    }
    .accessibilityElement(children: .combine)
  }

  private var title: String {
    switch feedback {
    case .idle:
      "새로고침 대기 중"
    case let .reading(message, _):
      message
    case let .finished(sampleCount, completedAt):
      "완료 · \(SleepFormatters.shortTime(completedAt)) · \(sampleCount)개"
    case .blocked:
      "완료 안 됨"
    }
  }

  private var detail: String {
    switch feedback {
    case .idle:
      "버튼을 누르면 진행 상태가 이곳에 남습니다."
    case let .reading(_, startedAt):
      "요청 \(SleepFormatters.shortTime(startedAt)) · 읽는 중"
    case let .finished(sampleCount, _):
      sampleCount > 0 ? "읽은 샘플이 화면에 반영되었습니다." : "읽을 수 있는 샘플이 없어 빈 상태로 반영되었습니다."
    case let .blocked(message):
      message
    }
  }

  private var kind: NBStatusKind {
    switch feedback {
    case .idle:
      .neutral
    case .reading:
      .privacy
    case let .finished(sampleCount, _):
      sampleCount > 0 ? .good : .caution
    case .blocked:
      .caution
    }
  }

  private var systemImage: String {
    switch feedback {
    case .idle:
      "clock"
    case .reading:
      "arrow.triangle.2.circlepath"
    case let .finished(sampleCount, _):
      sampleCount > 0 ? "checkmark.circle" : "tray"
    case .blocked:
      "exclamationmark.circle"
    }
  }
}

#if DEBUG
struct HealthRefreshStateQAView: View {
  private let referenceDate = Date(timeIntervalSinceReferenceDate: 800_000_000)

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        NBReportSection(title: "건강 데이터 새로고침 상태", systemImage: "arrow.triangle.2.circlepath") {
          VStack(spacing: NBSpacing.small) {
            HealthRefreshFeedbackSummary(feedback: .idle, isLoading: false)
            HealthRefreshFeedbackSummary(
              feedback: .reading(message: "건강 데이터를 읽는 중", startedAt: referenceDate.addingTimeInterval(-18)),
              isLoading: true
            )
            HealthRefreshFeedbackSummary(
              feedback: .finished(sampleCount: 24, completedAt: referenceDate),
              isLoading: false
            )
            HealthRefreshFeedbackSummary(
              feedback: .finished(sampleCount: 0, completedAt: referenceDate.addingTimeInterval(30)),
              isLoading: false
            )
            HealthRefreshFeedbackSummary(
              feedback: .blocked(message: "HealthKit을 사용할 수 없는 환경입니다."),
              isLoading: false
            )
          }
        }

        NBPrivacyNoticeCard(
          title: "QA 기준",
          messages: [
            "버튼을 누른 직후 진행 중 상태가 보여야 합니다.",
            "완료 시각과 샘플 수가 남아 두 번 눌렀는지 헷갈리지 않아야 합니다.",
            "샘플 0개와 차단 상태를 오류처럼 과장하지 않고 구분합니다.",
            "DEBUG 전용 예시 상태이며 실제 HealthKit 데이터를 읽지 않습니다.",
          ],
          systemImage: "checkmark.seal"
        )
      }
      .padding(.horizontal, NBSpacing.screenHorizontal)
      .padding(.vertical, NBSpacing.sectionVertical)
    }
    .background(NBColor.pageBackground)
    .navigationTitle("새로고침 QA")
    .toolbar(.hidden, for: .tabBar)
    .nbAvoidFloatingTabBar()
  }
}
#endif

private struct HealthCalendarPrimaryCard: View {
  let sampleCount: Int
  let latestDate: Date?

  var body: some View {
    NBCard(background: NBColor.dawn.opacity(0.10), stroke: NBColor.dawn.opacity(0.24)) {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        HStack(alignment: .top, spacing: NBSpacing.medium) {
          Image(systemName: "calendar.badge.clock")
            .font(.title3.weight(.semibold))
            .foregroundStyle(NBColor.dawn)
            .frame(width: 42, height: 42)
            .background(NBColor.dawn.opacity(0.14), in: RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
            .accessibilityHidden(true)

          VStack(alignment: .leading, spacing: 4) {
            Text("캘린더 지표 종합")
              .font(NBTypography.headline.weight(.semibold))
              .foregroundStyle(NBColor.primaryText)
              .lineLimit(1)
              .minimumScaleFactor(0.82)

            Text("날짜별 수면, 체성분, 활동 기록을 한 화면에서 봅니다.")
              .font(NBTypography.footnote)
              .foregroundStyle(NBColor.secondaryText)
              .fixedSize(horizontal: false, vertical: true)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }

        HStack(spacing: NBSpacing.small) {
          HealthDashboardEntryBadge(text: "기록 \(sampleCount)개", tint: NBColor.dawn)
          if let latestDate {
            HealthDashboardEntryBadge(text: "최근 \(SleepFormatters.shortDate(latestDate))", tint: NBColor.breathBlue)
          }

          Spacer(minLength: NBSpacing.small)

          Label("캘린더 보기", systemImage: "arrow.right.circle.fill")
            .font(NBTypography.subheadline.weight(.semibold))
            .foregroundStyle(NBColor.dawn)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
        }
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel("캘린더 지표 종합, 날짜별 수면 체성분 활동 기록 보기, \(latestText)")
    }
  }

  private var latestText: String {
    guard let latestDate else {
      return "기록 \(sampleCount)개"
    }
    return "기록 \(sampleCount)개, 최근 \(SleepFormatters.shortDate(latestDate))"
  }
}

private struct HealthDashboardEntryCard: View {
  let title: String
  let subtitle: String
  let systemImage: String
  let tint: Color
  let sampleCount: Int
  let latestDate: Date?

  var body: some View {
    NBCard {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        HStack(spacing: NBSpacing.medium) {
          Image(systemName: systemImage)
            .font(.body.weight(.semibold))
            .foregroundStyle(tint)
            .frame(width: 32, height: 32)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
            .accessibilityHidden(true)

          VStack(alignment: .leading, spacing: 3) {
            Text(title)
              .font(NBTypography.callout.weight(.semibold))
              .foregroundStyle(NBColor.primaryText)
              .lineLimit(1)
            Text(subtitle)
              .font(NBTypography.caption)
              .foregroundStyle(NBColor.secondaryText)
              .lineLimit(1)
              .minimumScaleFactor(0.82)
          }
          .frame(maxWidth: .infinity, alignment: .leading)

          Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(NBColor.tertiaryText)
            .accessibilityHidden(true)
        }

        HStack(spacing: NBSpacing.small) {
          HealthDashboardEntryBadge(text: "기록 \(sampleCount)개", tint: tint)
          if let latestDate {
            HealthDashboardEntryBadge(text: "최근 \(SleepFormatters.shortDate(latestDate))", tint: NBColor.dawn)
          }
        }
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel("\(title), \(subtitle), \(latestText)")
    }
  }

  private var latestText: String {
    guard let latestDate else {
      return "샘플 \(sampleCount)개"
    }
    return "샘플 \(sampleCount)개 · 최근 \(SleepFormatters.shortDate(latestDate))"
  }
}

private struct HealthDashboardEntryBadge: View {
  let text: String
  let tint: Color

  var body: some View {
    Text(text)
      .font(NBTypography.captionEmphasis)
      .foregroundStyle(tint)
      .lineLimit(1)
      .padding(.horizontal, 8)
      .padding(.vertical, 5)
      .background(tint.opacity(0.10), in: Capsule())
  }
}

private struct HealthDataStatePill: View {
  let title: String
  let value: String
  let systemImage: String
  let tint: Color
  let caption: String

  var body: some View {
    HStack(spacing: NBSpacing.small) {
      Image(systemName: systemImage)
        .font(.caption.weight(.bold))
        .foregroundStyle(tint)
        .frame(width: 24, height: 24)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 1) {
        Text(title)
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
          .lineLimit(1)
        HStack(alignment: .firstTextBaseline, spacing: 4) {
          Text(value)
            .font(NBTypography.callout.weight(.semibold))
            .foregroundStyle(NBColor.primaryText)
            .monospacedDigit()
          Text(caption)
            .font(NBTypography.caption)
            .foregroundStyle(NBColor.tertiaryText)
            .lineLimit(1)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, NBSpacing.small)
    .padding(.vertical, 8)
    .background(NBColor.cardBackground.opacity(0.72), in: RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous)
        .stroke(NBColor.border.opacity(0.52), lineWidth: 1)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(title), \(value)개, \(caption)")
  }
}

private struct HealthDataDetailGroupTitle: View {
  let title: String

  init(_ title: String) {
    self.title = title
  }

  var body: some View {
    Text(title)
      .font(NBTypography.captionEmphasis)
      .foregroundStyle(NBColor.secondaryText)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct HealthDataDetailRow: View {
  let title: String
  let value: String
  let subtitle: String
  let systemImage: String
  let tint: Color

  var body: some View {
    HStack(alignment: .top, spacing: NBSpacing.small) {
      Image(systemName: systemImage)
        .font(.caption.weight(.semibold))
        .foregroundStyle(tint)
        .frame(width: 24, height: 24)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 3) {
        HStack(alignment: .firstTextBaseline, spacing: NBSpacing.small) {
          Text(title)
            .font(NBTypography.subheadline.weight(.semibold))
            .foregroundStyle(NBColor.primaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
          Spacer()
          Text(value)
            .font(NBTypography.captionEmphasis)
            .foregroundStyle(NBColor.secondaryText)
            .lineLimit(1)
        }
        Text(subtitle)
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(.vertical, 2)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(title), \(value), \(subtitle)")
  }
}
