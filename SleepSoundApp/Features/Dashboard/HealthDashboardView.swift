import SwiftUI

struct HealthDashboardView: View {
  private let service: any HealthKitServiceProtocol
  private let unifiedSampleRepository: any UnifiedHealthMetricSampleRepositoryProtocol
  private let mockService = MockHealthKitService()
  private let calculator = HealthMetricTrendCalculator()

  @EnvironmentObject private var appState: AppState
  @State private var permissionState: HealthMetricPermissionState = .notRequested
  @State private var healthSamples: [HealthMetricSample] = []
  @State private var importedUnifiedSamples: [UnifiedHealthMetricSample] = []
  @State private var isLoading = false
  @State private var statusMessage: String?

  init(
    service: any HealthKitServiceProtocol = RealHealthKitService(),
    unifiedSampleRepository: any UnifiedHealthMetricSampleRepositoryProtocol = JSONUnifiedHealthMetricSampleRepository()
  ) {
    self.service = service
    self.unifiedSampleRepository = unifiedSampleRepository
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        header
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
      .padding(NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
    .navigationTitle("건강 데이터")
    .onAppear {
      loadImportedUnifiedSamples()
    }
  }

  private var visibleSamples: [HealthMetricSample] {
    switch permissionState {
    case .notRequested, .mockDataOnly:
      mockService.samples
    case .readRequestCompleted:
      healthSamples
    case .denied, .unavailable:
      []
    }
  }

  private var isPreviewData: Bool {
    permissionState == .notRequested || permissionState == .mockDataOnly
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
    NBReportSection(title: "건강 데이터 대시보드", systemImage: "heart.text.square") {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
          Text("Apple 건강앱에서 혈압, 체중, 체성분, 활동, 심박수, 호흡수 데이터를 읽어 보기 쉽게 정리합니다.")
          .font(NBTypography.callout)
          .foregroundStyle(NBColor.secondaryText)

        Button {
          connectHealthData()
        } label: {
          Label(
            isLoading ? "연결 확인 중" : "건강 데이터 연결",
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
          "읽을 수 있는 건강 데이터가 아직 없습니다.",
          kind: .caution,
          systemImage: "tray"
        )
      } else {
        NBStatusBadge(
          "Apple 건강앱에서 읽은 데이터입니다.",
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
            eveningCheckIns: [],
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
            title: "Fitdays CSV 가져오기",
            subtitle: "HealthKit에 없는 체성분 지표를 로컬 파일로 추가",
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
        statusMessage = message(for: nextPermissionState, sampleCount: fetchedSamples.count)
        isLoading = false
      }
    }
  }

  private func loadImportedUnifiedSamples() {
    importedUnifiedSamples = unifiedSampleRepository.fetchSamples()
  }

  private func fetchDashboardSamples() async -> [HealthMetricSample] {
    let dateRange = HealthMetricDateRange.days(90, endingAt: Date())
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
        ? "건강앱 샘플 \(sampleCount)개를 로컬에서 읽었습니다. 허용된 항목만 표시됩니다."
        : "권한이 허용되었더라도 항목별 권한 또는 데이터 유무에 따라 값이 비어 있을 수 있습니다."
    case .denied:
      "건강 데이터 권한이 허용되지 않았습니다. 앱은 기존 수면 소리 기능을 계속 사용할 수 있습니다."
    case .unavailable:
      "이 기기에서는 건강앱 read-only 연결을 사용할 수 없습니다."
    case .mockDataOnly:
      "예시 데이터로 화면을 표시합니다."
    }
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
