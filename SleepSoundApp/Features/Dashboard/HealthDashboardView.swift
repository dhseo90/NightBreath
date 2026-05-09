import SwiftUI

struct HealthDashboardView: View {
  private let service: any HealthKitServiceProtocol
  private let unifiedSampleRepository: any UnifiedHealthMetricSampleRepositoryProtocol
  private let userSettings: UserSettingsProviding
  private let mockService = MockHealthKitService()
  private let calculator = HealthMetricTrendCalculator()
  private let calendarBuilder = HealthCalendarBuilder()
  private let healthKitDashboardLookbackDays = 370

  @EnvironmentObject private var appState: AppState
  @State private var permissionState: HealthMetricPermissionState = .notRequested
  @State private var healthSamples: [HealthMetricSample] = []
  @State private var importedUnifiedSamples: [UnifiedHealthMetricSample] = []
  @State private var isLoading = false
  @State private var statusMessage: String?
  @State private var hasRequestedHealthKitReadAccess: Bool

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
        recentMeasurementShortcutSection
        stateNotice
        dataStateSection
        dashboardEntrySection

        if dataStateSummary.shouldShowEmptyState {
          HealthDataEmptyStateView(
            title: dataStateSummary.title,
            message: dataStateSummary.message
          )
        } else if !visibleSamples.isEmpty {
          overviewSection
          HealthSourceSummarySection(sourceSummaries: calculator.sourceSummaries(samples: visibleSamples))
        }

        if !importedUnifiedSamples.isEmpty {
          localImportOverviewSection
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
    calendarReports.flatMap { report in
      [
        UnifiedHealthMetricSample(
          metricID: .sleepSoundScore,
          value: Double(report.sleepSoundScore),
          unit: "점",
          measuredAt: report.generatedAt,
          sourceType: .appComputed,
          sourceName: "밤숨 앱"
        ),
        UnifiedHealthMetricSample(
          metricID: .audioCoverageRatio,
          value: report.audioCoverageRatio * 100,
          unit: "%",
          measuredAt: report.generatedAt,
          sourceType: .appComputed,
          sourceName: "밤숨 앱"
        ),
      ]
    }
  }

  private var header: some View {
    NBReportSection(title: "건강 데이터 허브", systemImage: "heart.text.square") {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        Text("Apple 건강앱 read-only 샘플, 밤숨 수면 결과, Fitdays 로컬 import 데이터를 날짜와 지표별로 함께 정리합니다.")
          .font(NBTypography.callout)
          .foregroundStyle(NBColor.secondaryText)

        Button {
          connectHealthData()
        } label: {
          Label(
            isLoading ? "건강앱 읽는 중" : healthConnectButtonTitle,
            systemImage: "heart.text.square"
          )
        }
        .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.privacyTint))
        .disabled(isLoading || !service.isAvailable)

        if !service.isAvailable {
          Text(service.authorizationStatusDescription())
            .font(NBTypography.footnote)
            .foregroundStyle(NBColor.warning)
        } else {
          Text("버튼을 누를 때만 Apple 건강앱 읽기 권한을 요청합니다. 첫 실행이나 수면 측정 시작 시에는 요청하지 않습니다.")
            .font(NBTypography.footnote)
            .foregroundStyle(NBColor.secondaryText)
          Text("이전 달 데이터가 비어 있으면 항목별 HealthKit 권한, Apple 건강앱에 실제 샘플이 있는지, Omron/Fitdays 같은 원본 앱의 Apple 건강앱 동기화 상태를 확인하세요.")
            .font(NBTypography.footnote)
            .foregroundStyle(NBColor.tertiaryText)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
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

  private var dashboardEntrySection: some View {
    NBReportSection(title: "대시보드", systemImage: "rectangle.grid.1x2") {
      VStack(spacing: NBSpacing.medium) {
        NavigationLink {
          HealthMetricsOverviewView(
            samples: unifiedDashboardSamples,
            permissionState: permissionState,
            isPreviewData: isPreviewData
          )
        } label: {
          HealthDashboardEntryCard(
            title: "전체 건강 지표",
            subtitle: "HealthKit, Fitdays CSV, 수동/앱 계산 지표 통계",
            systemImage: "chart.line.uptrend.xyaxis",
            tint: NBColor.privacyTint,
            sampleCount: unifiedDashboardSamples.count,
            latestDate: unifiedDashboardLatestDate
          )
        }
        .buttonStyle(.plain)

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
          HealthDashboardEntryCard(
            title: "건강 캘린더",
            subtitle: "날짜별 수면·건강·체크인 데이터 보기",
            systemImage: "calendar",
            tint: NBColor.dawn,
            sampleCount: unifiedDashboardSamples.count + calendarReports.count,
            latestDate: healthCalendarLatestDate
          )
        }
        .buttonStyle(.plain)

        NavigationLink {
          BloodPressureDashboardView(
            samples: visibleSamples,
            permissionState: permissionState,
            isPreviewData: isPreviewData
          )
        } label: {
          HealthDashboardEntryCard(
            title: "혈압",
            subtitle: "혈압 데이터를 보기 쉽게 정리합니다",
            systemImage: "heart",
            tint: NBColor.danger,
            sampleCount: categorySampleCount(HealthDashboardMetrics.bloodPressure),
            latestDate: latestDate(for: HealthDashboardMetrics.bloodPressure)
          )
        }
        .buttonStyle(.plain)

        NavigationLink {
          BodyCompositionDashboardView(
            samples: visibleSamples,
            permissionState: permissionState,
            isPreviewData: isPreviewData
          )
        } label: {
          HealthDashboardEntryCard(
            title: "체중/체성분",
            subtitle: "체중, 체지방률, BMI, 제지방량 추세",
            systemImage: "scalemass",
            tint: NBColor.mistTeal,
            sampleCount: categorySampleCount(HealthDashboardMetrics.bodyComposition),
            latestDate: latestDate(for: HealthDashboardMetrics.bodyComposition)
          )
        }
        .buttonStyle(.plain)

        NavigationLink {
          FitdaysImportView()
        } label: {
          HealthDashboardEntryCard(
            title: "Fitdays 붙여넣기/CSV",
            subtitle: "월별 데이터 복사 텍스트와 로컬 파일 가져오기",
            systemImage: "square.and.arrow.down",
            tint: NBColor.mistTeal,
            sampleCount: importedUnifiedSamples.count,
            latestDate: latestImportedUnifiedDate
          )
        }
        .buttonStyle(.plain)

        NavigationLink {
          CrossMetricDashboardView(
            reports: appState.trendReports(days: 90),
            samples: visibleSamples,
            permissionState: permissionState,
            isPreviewData: isPreviewData
          )
        } label: {
          HealthDashboardEntryCard(
            title: "수면 소리 × 건강",
            subtitle: "개인 패턴을 살펴보기 위한 참고용 보기",
            systemImage: "chart.dots.scatter",
            tint: NBColor.sleepTint,
            sampleCount: crossMetricHealthSampleCount,
            latestDate: crossMetricLatestDate
          )
        }
        .buttonStyle(.plain)
      }
    }
  }

  @ViewBuilder
  private var recentMeasurementShortcutSection: some View {
    NBReportSection(
      title: "바로가기",
      subtitle: "자주 보는 건강 데이터 화면을 한 번에 엽니다.",
      systemImage: "arrow.up.right.square"
    ) {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        if let latestDate = healthCalendarLatestDate {
          let detailData = calendarBuilder.detailData(
            for: latestDate,
            samples: unifiedDashboardSamples,
            sleepReports: calendarReports,
            morningCheckIns: calendarMorningCheckIns,
            eveningCheckIns: calendarEveningCheckIns
          )

          NavigationLink {
            DailyMeasurementDetailView(
              detailData: detailData,
              allSamples: unifiedDashboardSamples
            )
          } label: {
            HealthDashboardShortcutCard(
              title: "최근 날짜 자세히 보기",
              subtitle: "수면, 혈압, 체성분, Fitdays import를 한 날짜에서 확인",
              systemImage: "calendar.badge.clock",
              tint: NBColor.dawn
            )
          }
          .buttonStyle(.plain)
        }

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
          HealthDashboardShortcutCard(
            title: "건강 캘린더",
            subtitle: "날짜별 수면·건강·체크인 데이터 보기",
            systemImage: "calendar",
            tint: NBColor.privacyTint
          )
        }
        .buttonStyle(.plain)

        NavigationLink {
          FitdaysImportView()
        } label: {
          HealthDashboardShortcutCard(
            title: "Fitdays 붙여넣기",
            subtitle: "월별 복사 텍스트나 CSV 파일을 로컬로 저장",
            systemImage: "doc.on.clipboard",
            tint: NBColor.mistTeal
          )
        }
        .buttonStyle(.plain)

        Text("최근 날짜는 로컬 import, Apple 건강앱 read-only 샘플, 밤숨 앱 계산 지표 중 가장 최신 측정일 기준입니다.")
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private var dataStateSection: some View {
    NBReportSection(title: "데이터 상태", systemImage: "waveform.path.ecg.rectangle") {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        VStack(alignment: .leading, spacing: NBSpacing.xSmall) {
          Text(dataStateSummary.title)
            .font(NBTypography.callout.weight(.semibold))
            .foregroundStyle(NBColor.primaryText)
          Text(dataStateSummary.message)
            .font(NBTypography.footnote)
            .foregroundStyle(NBColor.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
        }

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.small) {
          NBMetricCard(
            title: isPreviewData ? "예시" : "Apple 건강앱",
            value: "\(dataStateSummary.healthOrPreviewSampleCount)",
            systemImage: isPreviewData ? "eye" : "heart.text.square",
            tint: NBColor.privacyTint,
            footnote: isPreviewData ? "미리보기" : "read-only"
          )

          NBMetricCard(
            title: "로컬 import",
            value: "\(dataStateSummary.localImportSampleCount)",
            systemImage: "square.and.arrow.down",
            tint: NBColor.mistTeal,
            footnote: "Fitdays CSV"
          )

          NBMetricCard(
            title: "앱 계산",
            value: "\(dataStateSummary.appComputedSampleCount)",
            systemImage: "sparkles",
            tint: NBColor.dawn,
            footnote: "기기 안"
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
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.medium) {
        latestMetricCard(.systolicBloodPressure)
        latestMetricCard(.diastolicBloodPressure)
        latestMetricCard(.bodyMass)
        latestMetricCard(.bodyFatPercentage)
      }
    }
  }

  private var localImportOverviewSection: some View {
    NBReportSection(title: "로컬 import 최근 값", systemImage: "square.and.arrow.down") {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        ForEach(importedUnifiedSamples.sortedByMeasuredAtDescending().prefix(6)) { sample in
          if let displayModel = sample.displayModel() {
            NBListRow(
              title: displayModel.metadata.displayNameKo,
              value: displayModel.valueText,
              subtitle: "\(SleepFormatters.shortDate(sample.measuredAt)) · \(sample.sourceType.displayName)",
              systemImage: "internaldrive",
              tint: NBColor.mistTeal,
              accessibilityLabel: "\(displayModel.metadata.displayNameKo), \(displayModel.valueText), 로컬 import"
            )
          }
        }

        Text("Fitdays CSV/text import 값은 HealthKit에 쓰지 않고 기기 안의 로컬 샘플로만 표시합니다.")
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private func connectHealthData() {
    isLoading = true
    statusMessage = nil

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
    statusMessage = "이전에 연결한 Apple 건강앱 데이터를 다시 읽고 있습니다."

    Task {
      let fetchedSamples = await fetchDashboardSamples()

      await MainActor.run {
        healthSamples = fetchedSamples
        statusMessage = message(for: .readRequestCompleted, sampleCount: fetchedSamples.count)
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

  private func latestMetricCard(_ metricType: HealthMetricType) -> NBMetricCard {
    let sample = visibleSamples.latestSample(metricType: metricType)
    return NBMetricCard(
      title: metricType.displayName,
      value: sample.map {
        HealthMetricDashboardFormatting.valueString($0.value, unit: $0.unit)
      } ?? "--",
      systemImage: HealthMetricDashboardFormatting.icon(for: metricType),
      tint: HealthMetricDashboardFormatting.tint(for: metricType),
      footnote: sample.map { "\(SleepFormatters.shortDate($0.measuredAt)) · \($0.sourceName)" },
      accessibilityLabel: "\(metricType.displayName), \(sample.map { HealthMetricDashboardFormatting.valueString($0.value, unit: $0.unit) } ?? "데이터 없음")"
    )
  }

  private func categorySampleCount(_ metricTypes: [HealthMetricType]) -> Int {
    let metricSet = Set(metricTypes)
    return visibleSamples.filter { metricSet.contains($0.metricType) }.count
  }

  private func latestDate(for metricTypes: [HealthMetricType]) -> Date? {
    let metricSet = Set(metricTypes)
    return visibleSamples
      .filter { metricSet.contains($0.metricType) }
      .sortedByMeasuredAtDescending()
      .first?
      .measuredAt
  }

  private var crossMetricHealthSampleCount: Int {
    let metricSet = Set(CrossMetricAnalyzer.supportedHealthMetrics)
    return visibleSamples.filter { metricSet.contains($0.metricType) }.count
  }

  private var crossMetricLatestDate: Date? {
    let metricSet = Set(CrossMetricAnalyzer.supportedHealthMetrics)
    let latestHealthDate = visibleSamples
      .filter { metricSet.contains($0.metricType) }
      .sortedByMeasuredAtDescending()
      .first?
      .measuredAt
    let latestSleepDate = appState.trendReports(days: 90).last?.generatedAt

    return [latestHealthDate, latestSleepDate].compactMap { $0 }.max()
  }

  private var unifiedDashboardLatestDate: Date? {
    unifiedDashboardSamples.sortedByMeasuredAtDescending().first?.measuredAt
  }

  private var latestImportedUnifiedDate: Date? {
    importedUnifiedSamples.sortedByMeasuredAtDescending().first?.measuredAt
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

private struct HealthDashboardEntryCard: View {
  let title: String
  let subtitle: String
  let systemImage: String
  let tint: Color
  let sampleCount: Int
  let latestDate: Date?

  var body: some View {
    NBCard {
      HStack(spacing: NBSpacing.medium) {
        NBListRow(
          title: title,
          value: latestText,
          subtitle: subtitle,
          systemImage: systemImage,
          tint: tint,
          accessibilityLabel: "\(title), \(subtitle), \(latestText)"
        )
        .frame(maxWidth: .infinity)
        Spacer()

        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(NBColor.tertiaryText)
      }
    }
  }

  private var latestText: String {
    guard let latestDate else {
      return "샘플 \(sampleCount)개"
    }
    return "샘플 \(sampleCount)개 · 최근 \(SleepFormatters.shortDate(latestDate))"
  }
}

private struct HealthDashboardShortcutCard: View {
  let title: String
  let subtitle: String
  let systemImage: String
  let tint: Color

  var body: some View {
    HStack(spacing: NBSpacing.medium) {
      Image(systemName: systemImage)
        .font(.headline)
        .foregroundStyle(tint)
        .frame(width: 32, height: 32)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: NBCornerRadius.small))
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(NBTypography.callout.weight(.semibold))
          .foregroundStyle(NBColor.primaryText)
          .lineLimit(1)
        Text(subtitle)
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer(minLength: NBSpacing.small)

      Image(systemName: "chevron.right")
        .font(.caption.weight(.semibold))
        .foregroundStyle(NBColor.tertiaryText)
        .accessibilityHidden(true)
    }
    .padding(NBSpacing.small)
    .background(NBColor.cardBackground.opacity(0.72), in: RoundedRectangle(cornerRadius: NBCornerRadius.small))
    .overlay {
      RoundedRectangle(cornerRadius: NBCornerRadius.small)
        .stroke(NBColor.border.opacity(0.7), lineWidth: 1)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(title), \(subtitle)")
  }
}
