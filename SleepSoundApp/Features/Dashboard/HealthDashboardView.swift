import SwiftUI

struct HealthDashboardView: View {
  private let service: any HealthKitServiceProtocol
  private let mockService = MockHealthKitService()
  private let calculator = HealthMetricTrendCalculator()

  @EnvironmentObject private var appState: AppState
  @State private var permissionState: HealthMetricPermissionState = .notRequested
  @State private var healthSamples: [HealthMetricSample] = []
  @State private var isLoading = false
  @State private var statusMessage: String?

  init(service: any HealthKitServiceProtocol = HealthKitService()) {
    self.service = service
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.xLarge) {
        header
        stateNotice
        dashboardEntrySection

        if shouldShowEmptyState {
          emptyState
        } else if !visibleSamples.isEmpty {
          overviewSection
          HealthSourceSummarySection(sourceSummaries: calculator.sourceSummaries(samples: visibleSamples))
        }

        NBPrivacyNoticeCard(
          title: "Apple 건강앱 read-only",
          message: "권한을 허용해도 밤숨은 건강앱 데이터를 읽어 화면에 표시할 뿐, HealthKit에 데이터를 쓰지 않습니다.",
          systemImage: "lock.shield"
        )
      }
      .padding(NBSpacing.large)
    }
    .background(NBColor.pageBackground)
    .navigationTitle("건강 데이터")
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

  private var shouldShowEmptyState: Bool {
    permissionState == .readRequestCompleted && healthSamples.isEmpty
  }

  private var header: some View {
    NBReportSection(title: "건강 데이터 대시보드", systemImage: "heart.text.square") {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        Text("Apple 건강앱에서 혈압, 체중, 체성분, 심박수, 호흡수 데이터를 읽어 로컬 화면에 표시합니다.")
          .font(.callout)
          .foregroundStyle(.secondary)

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
            .font(.footnote)
            .foregroundStyle(NBColor.warning)
        } else {
          Text("버튼을 누를 때만 Apple 건강앱 읽기 권한을 요청합니다. 첫 실행이나 수면 측정 시작 시에는 요청하지 않습니다.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  @ViewBuilder
  private var stateNotice: some View {
    switch permissionState {
    case .notRequested:
      NBStatusBadge(
        "연결 전: 아래 값은 mock preview입니다.",
        systemImage: "eye",
        tint: NBColor.neutral
      )
    case .mockDataOnly:
      NBStatusBadge(
        "Mock data only",
        systemImage: "sparkles",
        tint: NBColor.neutral
      )
    case .readRequestCompleted:
      if healthSamples.isEmpty {
        NBStatusBadge(
          "읽을 수 있는 건강 데이터가 아직 없습니다.",
          systemImage: "tray",
          tint: NBColor.warning
        )
      } else {
        NBStatusBadge(
          "Apple 건강앱에서 읽은 데이터입니다.",
          systemImage: "checkmark.circle",
          tint: NBColor.success
        )
      }
    case .denied:
      NBStatusBadge(
        "건강 데이터 읽기 권한이 필요합니다.",
        systemImage: "lock.slash",
        tint: NBColor.warning
      )
    case .unavailable:
      NBStatusBadge(
        "이 기기에서는 건강 데이터 읽기를 사용할 수 없습니다.",
        systemImage: "exclamationmark.triangle",
        tint: NBColor.warning
      )
    }

    if let statusMessage {
      Text(statusMessage)
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
  }

  private var dashboardEntrySection: some View {
    NBReportSection(title: "대시보드", systemImage: "rectangle.grid.1x2") {
      VStack(spacing: NBSpacing.medium) {
        NavigationLink {
          BloodPressureDashboardView(
            samples: visibleSamples,
            permissionState: permissionState,
            isPreviewData: isPreviewData
          )
        } label: {
          HealthDashboardEntryCard(
            title: "혈압",
            subtitle: "수축기/이완기 혈압과 측정 시간대 추세",
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
          CrossMetricDashboardView(
            reports: appState.trendReports(days: 90),
            samples: visibleSamples,
            permissionState: permissionState,
            isPreviewData: isPreviewData
          )
        } label: {
          HealthDashboardEntryCard(
            title: "수면 소리 × 건강",
            subtitle: "수면 소리 지표와 건강 sample을 날짜 기준으로 함께 보기",
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

  private var emptyState: some View {
    HealthDataEmptyStateView(
      title: "Apple 건강앱에 해당 데이터가 없습니다.",
      message: "Omron Connect 또는 Fitdays 연동 상태를 확인하세요. 특정 앱 설치를 강제하지 않으며, Apple 건강앱에 저장된 source만 읽습니다."
    )
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
        ? "건강앱 sample \(sampleCount)개를 로컬에서 읽었습니다."
        : "권한이 허용되었더라도 항목별 권한 또는 데이터 유무에 따라 값이 비어 있을 수 있습니다."
    case .denied:
      "건강 데이터 권한이 허용되지 않았습니다. 앱은 기존 수면 소리 기능을 계속 사용할 수 있습니다."
    case .unavailable:
      "이 기기에서는 건강앱 read-only 연결을 사용할 수 없습니다."
    case .mockDataOnly:
      "Mock data로 화면을 표시합니다."
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
      footnote: sample.map { "\(SleepFormatters.shortDate($0.measuredAt)) · \($0.sourceName)" }
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
        Image(systemName: systemImage)
          .font(.title3.weight(.semibold))
          .foregroundStyle(tint)
          .frame(width: 34, height: 34)
          .background(tint.opacity(0.12))
          .clipShape(RoundedRectangle(cornerRadius: 8))

        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(NBTypography.sectionTitle)
            .foregroundStyle(.primary)
          Text(subtitle)
            .font(.callout)
            .foregroundStyle(.secondary)
          Text(latestText)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
      }
    }
  }

  private var latestText: String {
    guard let latestDate else {
      return "sample \(sampleCount)개"
    }
    return "sample \(sampleCount)개 · 최근 \(SleepFormatters.shortDate(latestDate))"
  }
}
