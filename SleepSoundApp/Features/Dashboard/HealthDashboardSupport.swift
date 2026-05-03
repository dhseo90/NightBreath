import SwiftUI

enum HealthDashboardMetrics {
  static let bloodPressure: [HealthMetricType] = [
    .systolicBloodPressure,
    .diastolicBloodPressure,
  ]

  static let bodyComposition: [HealthMetricType] = [
    .bodyMass,
    .bodyFatPercentage,
    .bodyMassIndex,
    .leanBodyMass,
  ]
}

enum HealthMetricDashboardFormatting {
  static func valueString(_ value: Double, unit: String) -> String {
    switch unit {
    case "mmHg", "bpm", "걸음", "kcal":
      "\(Int(value.rounded())) \(unit)"
    case "BMI":
      String(format: "%.1f", value)
    case "시간":
      String(format: "%.1f시간", value)
    default:
      String(format: "%.1f %@", value, unit)
    }
  }

  static func signedValueString(_ value: Double, unit: String) -> String {
    let sign = value >= 0 ? "+" : ""
    return "\(sign)\(valueString(value, unit: unit))"
  }

  static func icon(for metricType: HealthMetricType) -> String {
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
    case .stepCount:
      "figure.walk"
    case .activeEnergy:
      "flame"
    case .heartRate:
      "heart"
    case .restingHeartRate:
      "heart.fill"
    case .sleepDuration:
      "bed.double"
    case .respiratoryRate:
      "lungs"
    }
  }

  static func tint(for metricType: HealthMetricType) -> Color {
    switch metricType {
    case .bodyMass:
      NBColor.breathBlue
    case .bodyFatPercentage:
      NBColor.mistTeal
    case .bodyMassIndex:
      NBColor.lavender
    case .leanBodyMass:
      NBColor.quietIndigo
    case .stepCount:
      NBColor.mistTeal
    case .activeEnergy:
      NBColor.warning
    case .heartRate:
      NBColor.danger
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
}

struct HealthMetricPeriodPicker: View {
  @Binding var selection: HealthMetricTrendPeriod

  var body: some View {
    Picker("기간", selection: $selection) {
      ForEach(HealthMetricTrendPeriod.allCases) { period in
        Text(period.displayName).tag(period)
      }
    }
    .pickerStyle(.segmented)
  }
}

struct HealthDataAccessStateView: View {
  let permissionState: HealthMetricPermissionState
  let isPreviewData: Bool

  var body: some View {
    switch permissionState {
    case .notRequested:
      if isPreviewData {
        NBStatusBadge(
          "연결 전: 예시 미리보기로 그래프를 확인합니다.",
          kind: .neutral,
          systemImage: "eye"
        )
      }
    case .mockDataOnly:
      NBStatusBadge(
        "예시 데이터만 표시",
        kind: .neutral,
        systemImage: "sparkles"
      )
    case .readRequestCompleted:
      EmptyView()
    case .denied:
      NBCard {
        NBEmptyStateView(
          title: "건강 데이터 읽기 권한이 필요합니다",
          message: "iOS 설정 또는 Apple 건강앱에서 밤숨의 읽기 권한을 관리할 수 있습니다.",
          systemImage: "lock.slash"
        )
      }
    case .unavailable:
      NBCard {
        NBEmptyStateView(
          title: "건강 데이터 읽기를 사용할 수 없습니다",
          message: "지원되는 iPhone 실기기에서 Apple 건강앱 연결을 확인해 주세요.",
          systemImage: "exclamationmark.triangle"
        )
      }
    }
  }
}

struct HealthDataEmptyStateView: View {
  let title: String
  let message: String

  var body: some View {
    NBCard {
      NBEmptyStateView(
        title: title,
        message: message,
        systemImage: "tray"
      )
    }
  }
}

struct HealthPeriodOverviewSection: View {
  let samples: [HealthMetricSample]
  let metricTypes: [HealthMetricType]
  let primaryMetric: HealthMetricType
  let title: String

  private let calculator = HealthMetricTrendCalculator()

  var body: some View {
    NBReportSection(title: title, systemImage: "calendar.badge.clock") {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        ForEach(periodSummaries, id: \.period) { summary in
          NBListRow(
            title: summary.period.displayName,
            value: "\(sampleCount(for: summary.period))개",
            subtitle: periodSubtitle(for: summary),
            systemImage: "chart.line.uptrend.xyaxis",
            tint: HealthMetricDashboardFormatting.tint(for: primaryMetric)
          )

          if summary.period != periodSummaries.last?.period {
            Divider().overlay(NBColor.divider)
          }
        }
      }
    }
  }

  private var periodSummaries: [HealthMetricTrendSummary] {
    calculator.periodSummaries(
      samples: samples,
      metricType: primaryMetric
    )
  }

  private func sampleCount(for period: HealthMetricTrendPeriod) -> Int {
    calculator.samples(
      samples,
      metricTypes: metricTypes,
      period: period
    )
    .count
  }

  private func periodSubtitle(for summary: HealthMetricTrendSummary) -> String {
    var parts: [String] = []

    if let average = summary.average {
      parts.append(
        "평균 \(HealthMetricDashboardFormatting.valueString(average, unit: primaryMetric.unitLabel))"
      )
    } else {
      parts.append("평균 계산 샘플 부족")
    }

    if let change = summary.changeFromPreviousPeriod {
      parts.append(
        "이전 \(summary.period.displayName) 평균 대비 \(HealthMetricDashboardFormatting.signedValueString(change, unit: primaryMetric.unitLabel))"
      )
    } else {
      parts.append("이전 기간 비교 샘플 부족")
    }

    return parts.joined(separator: " · ")
  }
}

struct HealthLatestSampleDetailSection: View {
  let title: String
  let metricTypes: [HealthMetricType]
  let samples: [HealthMetricSample]

  var body: some View {
    NBReportSection(title: title, systemImage: "clock.badge.checkmark") {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        ForEach(metricTypes) { metricType in
          latestRow(metricType)

          if metricType != metricTypes.last {
            Divider().overlay(NBColor.divider)
          }
        }
      }
    }
  }

  private func latestRow(_ metricType: HealthMetricType) -> NBListRow {
    guard let sample = samples.latestSample(metricType: metricType) else {
      return NBListRow(
        title: metricType.displayName,
        value: "--",
        subtitle: "선택한 기간에 표시할 샘플이 없습니다.",
        systemImage: HealthMetricDashboardFormatting.icon(for: metricType),
        tint: HealthMetricDashboardFormatting.tint(for: metricType)
      )
    }

    return NBListRow(
      title: metricType.displayName,
      value: HealthMetricDashboardFormatting.valueString(sample.value, unit: sample.unit),
      subtitle: "\(SleepFormatters.shortDate(sample.measuredAt)) \(SleepFormatters.shortTime(sample.measuredAt)) · \(sample.sourceName)",
      systemImage: HealthMetricDashboardFormatting.icon(for: metricType),
      tint: HealthMetricDashboardFormatting.tint(for: metricType),
      accessibilityLabel:
        "\(metricType.displayName), \(HealthMetricDashboardFormatting.valueString(sample.value, unit: sample.unit)), \(SleepFormatters.shortDate(sample.measuredAt)) \(SleepFormatters.shortTime(sample.measuredAt)), \(sample.sourceName)"
    )
  }
}

struct HealthDailyRhythmConnectionSection: View {
  let focus: String
  let message: String

  var body: some View {
    NBReportSection(title: "Daily Rhythm 연결", systemImage: "sun.max") {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        NBStatusBadge(focus, kind: .privacy, systemImage: "heart.text.square")

        Text(message)
          .font(NBTypography.callout)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)

        Text("수면 소리 지표와 건강 데이터를 함께 볼 수 있지만, 원인과 결과를 의미하지 않습니다.")
          .font(NBTypography.footnote)
          .foregroundStyle(NBColor.tertiaryText)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

struct HealthSourceSummarySection: View {
  let sourceSummaries: [HealthMetricSourceSummary]

  var body: some View {
    NBReportSection(title: "데이터 출처", systemImage: "square.stack.3d.up") {
      if sourceSummaries.isEmpty {
        NBEmptyStateView(
          title: "표시할 데이터 출처가 없습니다",
          message: "Apple 건강앱에서 읽을 수 있는 source 정보가 있으면 여기에 표시합니다.",
          systemImage: "tray"
        )
      } else {
        VStack(alignment: .leading, spacing: NBSpacing.small) {
          ForEach(sourceSummaries, id: \.sourceBundleIdentifier) { source in
            NBListRow(
              title: source.sourceName,
              subtitle:
                "\(source.sourceBundleIdentifier) · \(source.sampleCount)개 · 최근 \(SleepFormatters.shortDate(source.latestMeasuredAt))",
              systemImage: "app.connected.to.app.below.fill",
              tint: NBColor.privacyTint,
              accessibilityLabel: "\(source.sourceName), \(source.sampleCount)개, 최근 \(SleepFormatters.shortDate(source.latestMeasuredAt))"
            )
          }
        }
      }
    }
  }
}

struct HealthTrendSummaryRows: View {
  let summaries: [HealthMetricTrendSummary]

  var body: some View {
    NBReportSection(title: "요약", systemImage: "list.bullet.rectangle") {
      VStack(spacing: NBSpacing.small) {
        ForEach(summaries, id: \.metricType) { summary in
          VStack(alignment: .leading, spacing: 6) {
            HStack {
              Label(
                summary.metricType.displayName,
                systemImage: HealthMetricDashboardFormatting.icon(for: summary.metricType)
              )
              .font(.callout.weight(.semibold))
              .foregroundStyle(NBColor.primaryText)

              Spacer()

              Text("\(summary.sampleCount)개")
                .font(.caption.weight(.semibold))
                .foregroundStyle(NBColor.secondaryText)
            }

            LazyVGrid(
              columns: [GridItem(.flexible()), GridItem(.flexible())],
              spacing: NBSpacing.small
            ) {
              summaryValue("평균", summary.average, unit: summary.metricType.unitLabel)
              summaryValue("최근", summary.latest?.value, unit: summary.metricType.unitLabel)
              summaryValue("최소", summary.minimum, unit: summary.metricType.unitLabel)
              summaryValue("최대", summary.maximum, unit: summary.metricType.unitLabel)
            }

            if let latest = summary.latest {
              Text("최근 측정: \(SleepFormatters.shortDate(latest.measuredAt)) \(SleepFormatters.shortTime(latest.measuredAt)) · \(latest.sourceName)")
                .font(.caption)
                .foregroundStyle(NBColor.secondaryText)
            }

            if let change = summary.changeFromPreviousPeriod {
              Text("이전 \(summary.period.displayName) 평균 대비 \(HealthMetricDashboardFormatting.signedValueString(change, unit: summary.metricType.unitLabel))")
                .font(.caption)
                .foregroundStyle(NBColor.secondaryText)
            } else {
              Text("이전 기간과 비교할 샘플이 아직 부족합니다.")
                .font(.caption)
                .foregroundStyle(NBColor.secondaryText)
            }
          }
          .padding(.vertical, 4)
        }
      }
    }
  }

  private func summaryValue(_ title: String, _ value: Double?, unit: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
        .font(.caption2)
        .foregroundStyle(NBColor.secondaryText)
      Text(value.map { HealthMetricDashboardFormatting.valueString($0, unit: unit) } ?? "--")
        .font(.caption.weight(.semibold))
        .foregroundStyle(NBColor.primaryText)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
