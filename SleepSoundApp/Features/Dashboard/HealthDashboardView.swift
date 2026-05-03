import SwiftUI

struct HealthDashboardView: View {
  private let service: any HealthKitServiceProtocol
  private let mockService = MockHealthKitService()
  private let chartBuilder = HealthMetricChartDataBuilder()
  private let displayMetrics: [HealthMetricType] = [
    .bodyMass,
    .bodyFatPercentage,
    .bodyMassIndex,
    .leanBodyMass,
    .restingHeartRate,
    .respiratoryRate,
  ]
  private let recentChangeMetrics: [HealthMetricType] = [
    .bodyMass,
    .bodyFatPercentage,
    .bodyMassIndex,
    .leanBodyMass,
  ]

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

        if shouldShowEmptyState {
          emptyState
        } else {
          bloodPressureSection

          ForEach(displayMetrics) { metricType in
            metricSection(metricType, tint: tint(for: metricType))
          }

          recentChangeSection
          dataSourceSection
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
    if permissionState == .readRequestCompleted {
      return healthSamples
    }
    return mockService.samples
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
        "권한이 허용되지 않았습니다. Apple 건강앱에서 권한을 관리할 수 있습니다.",
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

  private var emptyState: some View {
    NBCard {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        Label("표시할 건강 데이터가 없습니다", systemImage: "tray")
          .font(NBTypography.sectionTitle)
        Text("권한을 허용했더라도 Apple 건강앱에 해당 항목이 없거나 항목별 권한이 제한되어 있으면 값이 비어 있을 수 있습니다.")
          .font(.callout)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var bloodPressureSection: some View {
    NBReportSection(title: "혈압", systemImage: "heart") {
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.medium) {
        latestMetricCard(.systolicBloodPressure, tint: NBColor.danger)
        latestMetricCard(.diastolicBloodPressure, tint: NBColor.warning)
      }

      HealthMetricChartView(
        metricType: .systolicBloodPressure,
        samples: visibleSamples,
        tint: NBColor.danger
      )

      Text(sourceDescription(for: .systolicBloodPressure))
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
  }

  private func metricSection(_ metricType: HealthMetricType, tint: Color) -> some View {
    NBReportSection(title: metricType.dashboardSectionName, systemImage: icon(for: metricType)) {
      latestMetricCard(metricType, tint: tint)
      HealthMetricChartView(metricType: metricType, samples: visibleSamples, tint: tint)
      Text(sourceDescription(for: metricType))
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
  }

  private var recentChangeSection: some View {
    NBReportSection(title: "최근 변화", systemImage: "arrow.up.arrow.down") {
      VStack(spacing: NBSpacing.small) {
        ForEach(recentChangeMetrics) { metricType in
          HStack {
            Label(metricType.displayName, systemImage: icon(for: metricType))
              .font(.callout.weight(.semibold))
            Spacer()
            Text(changeText(for: metricType))
              .font(.callout.weight(.semibold))
              .foregroundStyle(changeTint(for: metricType))
          }
          .padding(.vertical, 2)
        }
      }
    }
  }

  private var dataSourceSection: some View {
    NBReportSection(title: "데이터 출처", systemImage: "square.stack.3d.up") {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        ForEach(sourceRows, id: \.bundleIdentifier) { row in
          NBListRow(
            title: row.name,
            subtitle: row.bundleIdentifier,
            systemImage: "app.connected.to.app.below.fill",
            tint: NBColor.privacyTint
          )
        }
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

  private func latestMetricCard(_ metricType: HealthMetricType, tint: Color) -> NBMetricCard {
    let sample = visibleSamples.latestSample(metricType: metricType)
    return NBMetricCard(
      title: metricType.displayName,
      value: sample.map { valueString($0.value, unit: $0.unit) } ?? "--",
      systemImage: icon(for: metricType),
      tint: tint,
      footnote: sample.map { "\(SleepFormatters.shortDate($0.measuredAt)) · \($0.sourceName)" }
    )
  }

  private var sourceRows: [(name: String, bundleIdentifier: String)] {
    let unique = Dictionary(grouping: visibleSamples, by: \.sourceBundleIdentifier)
      .compactMap { bundleIdentifier, samples -> (name: String, bundleIdentifier: String)? in
        guard let sample = samples.first else { return nil }
        return (sample.sourceName, bundleIdentifier)
      }

    return unique.sorted { $0.name < $1.name }
  }

  private func changeText(for metricType: HealthMetricType) -> String {
    guard let change = chartBuilder.latestChange(samples: visibleSamples, metricType: metricType) else {
      return "--"
    }
    let sign = change >= 0 ? "+" : ""
    return "\(sign)\(valueString(change, unit: metricType.unitLabel))"
  }

  private func changeTint(for metricType: HealthMetricType) -> Color {
    guard let change = chartBuilder.latestChange(samples: visibleSamples, metricType: metricType) else {
      return NBColor.mutedText
    }

    switch metricType {
    case .bodyMass, .bodyFatPercentage, .bodyMassIndex, .leanBodyMass:
      return change <= 0 ? NBColor.success : NBColor.warning
    default:
      return NBColor.neutral
    }
  }

  private func sourceDescription(for metricType: HealthMetricType) -> String {
    let prefix = permissionState == .readRequestCompleted ? "Apple 건강앱에서 읽은" : "연결 전 mock preview"

    switch metricType {
    case .bodyMass, .bodyFatPercentage, .bodyMassIndex, .leanBodyMass:
      return "\(prefix) 체중/체성분 데이터입니다. Fitdays 동기화 데이터는 Apple 건강앱 source로 표시될 수 있습니다."
    case .restingHeartRate, .respiratoryRate:
      return "\(prefix) 생체 지표입니다."
    case .systolicBloodPressure, .diastolicBloodPressure:
      return "\(prefix) 혈압 데이터입니다. Omron Connect 동기화 데이터는 Apple 건강앱 source로 표시될 수 있습니다."
    case .sleepDuration:
      return "\(prefix) 수면 시간 데이터입니다."
    }
  }

  private func tint(for metricType: HealthMetricType) -> Color {
    switch metricType {
    case .bodyMass:
      NBColor.breathBlue
    case .bodyFatPercentage:
      NBColor.mistTeal
    case .bodyMassIndex:
      NBColor.lavender
    case .leanBodyMass:
      NBColor.quietIndigo
    case .restingHeartRate:
      NBColor.danger
    case .respiratoryRate:
      NBColor.audioTint
    case .systolicBloodPressure:
      NBColor.danger
    case .diastolicBloodPressure:
      NBColor.warning
    case .sleepDuration:
      NBColor.sleepTint
    }
  }

  private func icon(for metricType: HealthMetricType) -> String {
    switch metricType {
    case .systolicBloodPressure, .diastolicBloodPressure:
      "heart"
    case .bodyMass:
      "scalemass"
    case .bodyFatPercentage:
      "percent"
    case .bodyMassIndex:
      "figure"
    case .leanBodyMass:
      "figure.strengthtraining.traditional"
    case .restingHeartRate:
      "heart.fill"
    case .sleepDuration:
      "bed.double"
    case .respiratoryRate:
      "lungs"
    }
  }

  private func valueString(_ value: Double, unit: String) -> String {
    switch unit {
    case "mmHg", "bpm":
      return "\(Int(value.rounded())) \(unit)"
    case "BMI":
      return String(format: "%.1f", value)
    case "시간":
      return String(format: "%.1f시간", value)
    default:
      return String(format: "%.1f %@", value, unit)
    }
  }
}
