import SwiftUI

struct HealthDashboardView: View {
  private let service = MockHealthKitService()
  private let chartBuilder = HealthMetricChartDataBuilder()
  private let primaryMetrics: [HealthMetricType] = [
    .bodyMass,
    .bodyFatPercentage,
    .bodyMassIndex,
    .restingHeartRate,
  ]

  private var samples: [HealthMetricSample] {
    service.samples
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.xLarge) {
        header
        bloodPressureSection
        metricSection(.bodyMass, tint: NBColor.breathBlue)
        metricSection(.bodyFatPercentage, tint: NBColor.mistTeal)
        metricSection(.bodyMassIndex, tint: NBColor.lavender)
        recentChangeSection
        dataSourceSection

        NBPrivacyNoticeCard(
          title: "Mock architecture",
          message: "이 화면은 실제 건강앱 권한 요청 없이 mock data로 UI와 데이터 흐름만 검증합니다.",
          systemImage: "lock.shield"
        )
      }
      .padding(NBSpacing.large)
    }
    .background(NBColor.pageBackground)
    .navigationTitle("건강 데이터 준비")
  }

  private var header: some View {
    NBReportSection(title: "건강 데이터 대시보드 준비 중", systemImage: "heart.text.square") {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        Text("장기적으로 Apple 건강앱을 통해 혈압, 체중, 체성분, 심박수, 수면 시간을 한 화면에서 확인할 수 있게 준비합니다.")
          .font(.callout)
          .foregroundStyle(.secondary)

        Button {} label: {
          Label("건강앱 권한 요청은 다음 단계", systemImage: "heart.text.square")
        }
        .buttonStyle(.nbSecondary)
        .disabled(true)

        Text(service.authorizationStatusDescription())
          .font(.footnote)
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
        samples: samples,
        tint: NBColor.danger
      )

      Text("Omron Connect에서 Apple 건강앱으로 동기화될 혈압 데이터를 가정한 mock sample입니다.")
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
  }

  private func metricSection(_ metricType: HealthMetricType, tint: Color) -> some View {
    NBReportSection(title: metricType.dashboardSectionName, systemImage: icon(for: metricType)) {
      latestMetricCard(metricType, tint: tint)
      HealthMetricChartView(metricType: metricType, samples: samples, tint: tint)
      Text(sourceDescription(for: metricType))
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
  }

  private var recentChangeSection: some View {
    NBReportSection(title: "최근 변화", systemImage: "arrow.up.arrow.down") {
      VStack(spacing: NBSpacing.small) {
        ForEach(primaryMetrics) { metricType in
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

  private func latestMetricCard(_ metricType: HealthMetricType, tint: Color) -> NBMetricCard {
    let sample = samples.latestSample(metricType: metricType)
    return NBMetricCard(
      title: metricType.displayName,
      value: sample.map { valueString($0.value, unit: $0.unit) } ?? "--",
      systemImage: icon(for: metricType),
      tint: tint,
      footnote: sample.map { "\(SleepFormatters.shortDate($0.measuredAt)) · \($0.sourceName)" }
    )
  }

  private var sourceRows: [(name: String, bundleIdentifier: String)] {
    let unique = Dictionary(grouping: samples, by: \.sourceBundleIdentifier)
      .compactMap { bundleIdentifier, samples -> (name: String, bundleIdentifier: String)? in
        guard let sample = samples.first else { return nil }
        return (sample.sourceName, bundleIdentifier)
      }

    return unique.sorted { $0.name < $1.name }
  }

  private func changeText(for metricType: HealthMetricType) -> String {
    guard let change = chartBuilder.latestChange(samples: samples, metricType: metricType) else {
      return "--"
    }
    let sign = change >= 0 ? "+" : ""
    return "\(sign)\(valueString(change, unit: metricType.unitLabel))"
  }

  private func changeTint(for metricType: HealthMetricType) -> Color {
    guard let change = chartBuilder.latestChange(samples: samples, metricType: metricType) else {
      return NBColor.mutedText
    }

    switch metricType {
    case .bodyMass, .bodyFatPercentage, .bodyMassIndex:
      return change <= 0 ? NBColor.success : NBColor.warning
    default:
      return NBColor.neutral
    }
  }

  private func sourceDescription(for metricType: HealthMetricType) -> String {
    switch metricType {
    case .bodyMass, .bodyFatPercentage, .bodyMassIndex, .leanBodyMass:
      "Fitdays에서 Apple 건강앱으로 동기화될 체중/체성분 데이터를 가정한 mock sample입니다."
    case .restingHeartRate, .sleepDuration, .respiratoryRate:
      "Apple 건강앱에서 읽을 수 있는 생체/수면 지표를 가정한 mock sample입니다."
    case .systolicBloodPressure, .diastolicBloodPressure:
      "Omron Connect에서 Apple 건강앱으로 동기화될 혈압 데이터를 가정한 mock sample입니다."
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
