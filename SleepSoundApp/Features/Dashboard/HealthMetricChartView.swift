import Charts
import SwiftUI

struct HealthMetricChartView: View {
  let metricType: HealthMetricType
  let samples: [HealthMetricSample]
  var tint: Color = NBColor.privacyTint

  private let builder = HealthMetricChartDataBuilder()

  var body: some View {
    Chart(points) { point in
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
    .chartYScale(domain: yDomain)
    .frame(height: 170)
    .accessibilityLabel("\(metricType.displayName) 추세 그래프")
  }

  private var points: [HealthMetricChartDataPoint] {
    builder.points(samples: samples, metricType: metricType)
  }

  private var yDomain: ClosedRange<Double> {
    let values = points.map(\.value)
    guard let minimum = values.min(), let maximum = values.max() else {
      return 0...1
    }

    let padding = max((maximum - minimum) * 0.25, metricType.minimumChartPadding)
    return max(0, minimum - padding)...(maximum + padding)
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
    case .restingHeartRate:
      3
    case .sleepDuration:
      0.4
    case .respiratoryRate:
      0.4
    }
  }
}
