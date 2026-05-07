import Charts
import SwiftUI

struct HealthMetricChartView: View {
  let metricType: HealthMetricType
  let samples: [HealthMetricSample]
  var tint: Color = NBColor.privacyTint

  private let builder = HealthMetricChartDataBuilder()

  var body: some View {
    let chartPoints = points

    VStack(alignment: .leading, spacing: NBSpacing.small) {
      Chart {
        ForEach(chartPoints) { point in
          LineMark(
            x: .value("날짜", point.date),
            y: .value(metricType.displayName, point.value)
          )
          .foregroundStyle(tint)
          .interpolationMethod(.catmullRom)

          PointMark(
            x: .value("날짜", point.date),
            y: .value(metricType.displayName, point.value)
          )
          .foregroundStyle(tint)
          .symbolSize(46)
        }

        if let average = averageValue(for: chartPoints) {
          RuleMark(y: .value("평균선", average))
            .foregroundStyle(NBColor.secondaryText.opacity(0.65))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .annotation(position: .top, alignment: .trailing) {
              Text("평균 \(HealthMetricDashboardFormatting.valueString(average, unit: metricType.unitLabel))")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(NBColor.secondaryText)
            }
        }
      }
      .chartXAxis {
        AxisMarks(values: .automatic(desiredCount: 4)) {
          AxisGridLine()
            .foregroundStyle(NBColor.divider)
          AxisValueLabel(format: .dateTime.month().day())
            .foregroundStyle(NBColor.secondaryText)
        }
      }
      .chartYAxis {
        AxisMarks(position: .leading) {
          AxisGridLine()
            .foregroundStyle(NBColor.divider)
          AxisValueLabel()
            .foregroundStyle(NBColor.secondaryText)
        }
      }
      .chartYScale(domain: yDomain(for: chartPoints))
      .frame(height: 170)
      .accessibilityLabel("\(metricType.displayName) 추세 그래프")

      chartSummaryStrip(points: chartPoints)
    }
  }

  private var points: [HealthMetricChartDataPoint] {
    builder.points(samples: samples, metricType: metricType)
  }

  private func yDomain(for points: [HealthMetricChartDataPoint]) -> ClosedRange<Double> {
    let values = points.map(\.value)
    guard let minimum = values.min(), let maximum = values.max() else {
      return 0...1
    }

    let padding = max((maximum - minimum) * 0.25, metricType.minimumChartPadding)
    return max(0, minimum - padding)...(maximum + padding)
  }

  private func averageValue(for points: [HealthMetricChartDataPoint]) -> Double? {
    guard !points.isEmpty else { return nil }
    return points.map(\.value).reduce(0, +) / Double(points.count)
  }

  @ViewBuilder
  private func chartSummaryStrip(points: [HealthMetricChartDataPoint]) -> some View {
    if let latest = points.last,
       let minimum = points.map(\.value).min(),
       let maximum = points.map(\.value).max() {
      HStack(spacing: NBSpacing.small) {
        HealthChartSummaryPill(
          title: "최근",
          value: HealthMetricDashboardFormatting.valueString(latest.value, unit: metricType.unitLabel)
        )
        HealthChartSummaryPill(
          title: "측정",
          value: "\(points.count)개"
        )
        HealthChartSummaryPill(
          title: "범위",
          value: "\(HealthMetricDashboardFormatting.valueString(minimum, unit: metricType.unitLabel))~\(HealthMetricDashboardFormatting.valueString(maximum, unit: metricType.unitLabel))"
        )
      }
    }
  }
}

private struct HealthChartSummaryPill: View {
  var title: String
  var value: String

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(NBColor.secondaryText)
      Text(value)
        .font(.caption.weight(.semibold))
        .foregroundStyle(NBColor.primaryText)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 8)
    .padding(.horizontal, 10)
    .background(NBColor.cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(NBColor.divider.opacity(0.7), lineWidth: 0.8)
    }
  }
}

private extension HealthMetricType {
  var minimumChartPadding: Double {
    switch self {
    case .systolicBloodPressure, .diastolicBloodPressure:
      4
    case .bodyMass, .leanBodyMass:
      0.5
    case .bodyFatPercentage, .bodyMassIndex:
      0.4
    case .stepCount:
      500
    case .activeEnergy:
      40
    case .heartRate, .restingHeartRate:
      3
    case .sleepDuration:
      0.4
    case .respiratoryRate:
      0.4
    }
  }
}
