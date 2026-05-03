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
    case "mmHg", "bpm":
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
          "연결 전: mock preview로 그래프를 확인합니다.",
          systemImage: "eye",
          tint: NBColor.neutral
        )
      }
    case .mockDataOnly:
      NBStatusBadge(
        "Mock data only",
        systemImage: "sparkles",
        tint: NBColor.neutral
      )
    case .readRequestCompleted:
      EmptyView()
    case .denied:
      NBCard {
        VStack(alignment: .leading, spacing: NBSpacing.small) {
          Label("건강 데이터 읽기 권한이 필요합니다.", systemImage: "lock.slash")
            .font(NBTypography.sectionTitle)
          Text("iOS 설정 또는 Apple 건강앱에서 밤숨의 읽기 권한을 관리할 수 있습니다.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
      }
    case .unavailable:
      NBCard {
        VStack(alignment: .leading, spacing: NBSpacing.small) {
          Label("이 기기에서는 건강 데이터 읽기를 사용할 수 없습니다.", systemImage: "exclamationmark.triangle")
            .font(NBTypography.sectionTitle)
          Text("지원되는 iPhone 실기기에서 Apple 건강앱 연결을 확인해 주세요.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
      }
    }
  }
}

struct HealthDataEmptyStateView: View {
  let title: String
  let message: String

  var body: some View {
    NBCard {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        Label(title, systemImage: "tray")
          .font(NBTypography.sectionTitle)
        Text(message)
          .font(.callout)
          .foregroundStyle(.secondary)
      }
    }
  }
}

struct HealthSourceSummarySection: View {
  let sourceSummaries: [HealthMetricSourceSummary]

  var body: some View {
    NBReportSection(title: "데이터 출처", systemImage: "square.stack.3d.up") {
      if sourceSummaries.isEmpty {
        Text("표시할 source 정보가 없습니다.")
          .font(.callout)
          .foregroundStyle(.secondary)
      } else {
        VStack(alignment: .leading, spacing: NBSpacing.small) {
          ForEach(sourceSummaries, id: \.sourceBundleIdentifier) { source in
            NBListRow(
              title: source.sourceName,
              subtitle:
                "\(source.sourceBundleIdentifier) · \(source.sampleCount)개 · 최근 \(SleepFormatters.shortDate(source.latestMeasuredAt))",
              systemImage: "app.connected.to.app.below.fill",
              tint: NBColor.privacyTint
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

              Spacer()

              Text("\(summary.sampleCount)개")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            }

            HStack {
              summaryValue("평균", summary.average, unit: summary.metricType.unitLabel)
              summaryValue("최소", summary.minimum, unit: summary.metricType.unitLabel)
              summaryValue("최대", summary.maximum, unit: summary.metricType.unitLabel)
            }

            if let change = summary.changeFromPreviousPeriod {
              Text("이전 \(summary.period.displayName) 평균 대비 \(HealthMetricDashboardFormatting.signedValueString(change, unit: summary.metricType.unitLabel))")
                .font(.caption)
                .foregroundStyle(.secondary)
            } else {
              Text("이전 기간과 비교할 sample이 아직 부족합니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
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
        .foregroundStyle(.secondary)
      Text(value.map { HealthMetricDashboardFormatting.valueString($0, unit: unit) } ?? "--")
        .font(.caption.weight(.semibold))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
