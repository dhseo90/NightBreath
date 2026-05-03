import Charts
import SwiftUI

struct BloodPressureDashboardView: View {
  let samples: [HealthMetricSample]
  let permissionState: HealthMetricPermissionState
  let isPreviewData: Bool

  @State private var selectedPeriod: HealthMetricTrendPeriod = .sevenDays

  private let calculator = HealthMetricTrendCalculator()
  private let metrics = HealthDashboardMetrics.bloodPressure

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        header
        HealthDataAccessStateView(
          permissionState: permissionState,
          isPreviewData: isPreviewData
        )

        if shouldShowDashboardContent {
          HealthMetricPeriodPicker(selection: $selectedPeriod)

          if periodSamples.isEmpty {
            HealthDataEmptyStateView(
              title: "Apple 건강앱에 해당 데이터가 없습니다.",
              message: emptyDataMessage
            )
          } else {
            latestSection
            BloodPressureTrendChart(samples: periodSamples)
            timeOfDaySection
            HealthTrendSummaryRows(summaries: trendSummaries)
            HealthSourceSummarySection(sourceSummaries: calculator.sourceSummaries(samples: periodSamples))
          }
        }

        NBPrivacyNoticeCard(
          title: "혈압 데이터 안내",
          message: "Apple 건강앱에서 읽은 측정값을 정리해 보여줍니다. 수치에 대한 확정적 해석이나 조치 안내를 제공하지 않습니다.",
          systemImage: "heart.text.square"
        )
      }
      .padding(NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .navigationTitle("혈압")
  }

  private var shouldShowDashboardContent: Bool {
    switch permissionState {
    case .denied, .unavailable:
      false
    case .notRequested, .mockDataOnly, .readRequestCompleted:
      true
    }
  }

  private var periodSamples: [HealthMetricSample] {
    calculator.samples(
      samples,
      metricTypes: metrics,
      period: selectedPeriod
    )
  }

  private var trendSummaries: [HealthMetricTrendSummary] {
    metrics.map { metricType in
      calculator.summary(
        samples: samples,
        metricType: metricType,
        period: selectedPeriod
      )
    }
  }

  private var latestMeasuredAt: Date? {
    periodSamples.sortedByMeasuredAtDescending().first?.measuredAt
  }

  private var emptyDataMessage: String {
    "Apple 건강앱에 혈압 데이터가 없거나 항목별 읽기 권한이 제한되어 있을 수 있습니다. Omron Connect 또는 다른 혈압 기록 source의 Apple 건강앱 연동 상태를 확인하세요."
  }

  private var header: some View {
    NBReportSection(title: "혈압 추세", systemImage: "heart") {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        Text("혈압 데이터를 보기 쉽게 정리합니다. 수축기/이완기 혈압 sample을 기간별로 비교합니다.")
          .font(NBTypography.callout)
          .foregroundStyle(NBColor.secondaryText)
        if let latestMeasuredAt {
          Text("최근 측정: \(SleepFormatters.shortDate(latestMeasuredAt)) \(SleepFormatters.shortTime(latestMeasuredAt))")
            .font(NBTypography.footnote)
            .foregroundStyle(NBColor.secondaryText)
        }
      }
    }
  }

  private var latestSection: some View {
    NBReportSection(title: "최근 혈압", systemImage: "clock") {
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.medium) {
        latestMetricCard(.systolicBloodPressure)
        latestMetricCard(.diastolicBloodPressure)
      }
    }
  }

  private var timeOfDaySection: some View {
    NBReportSection(title: "측정 시간대", systemImage: "sun.and.horizon") {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        NBListRow(
          title: "아침",
          value: "\(timeOfDayCounts.morning)개",
          subtitle: "정오 이전 측정 sample",
          systemImage: "sunrise",
          tint: NBColor.warning
        )
        Divider().overlay(NBColor.divider)
        NBListRow(
          title: "저녁",
          value: "\(timeOfDayCounts.evening)개",
          subtitle: "정오 이후 측정 sample",
          systemImage: "moon",
          tint: NBColor.sleep
        )
        Text("수축기 혈압 sample의 측정 시각 기준입니다.")
          .font(NBTypography.footnote)
          .foregroundStyle(NBColor.secondaryText)
      }
    }
  }

  private var timeOfDayCounts: (morning: Int, evening: Int) {
    let systolicSamples = calculator.samples(
      samples,
      metricType: .systolicBloodPressure,
      period: selectedPeriod
    )
    let morningCount = systolicSamples.filter { sample in
      Calendar.current.component(.hour, from: sample.measuredAt) < 12
    }.count
    return (morningCount, max(0, systolicSamples.count - morningCount))
  }

  private func latestMetricCard(_ metricType: HealthMetricType) -> NBMetricCard {
    let sample = periodSamples.latestSample(metricType: metricType)
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
}

private struct BloodPressureTrendChart: View {
  let samples: [HealthMetricSample]

  private let builder = HealthMetricChartDataBuilder()

  var body: some View {
    NBReportSection(title: "그래프", systemImage: "chart.xyaxis.line") {
      Chart {
        ForEach(systolicPoints) { point in
          LineMark(
            x: .value("날짜", point.date),
            y: .value("수축기 혈압", point.value)
          )
          .foregroundStyle(NBColor.danger)
          .interpolationMethod(.catmullRom)

          PointMark(
            x: .value("날짜", point.date),
            y: .value("수축기 혈압", point.value)
          )
          .foregroundStyle(NBColor.danger)
          .symbolSize(44)
        }

        ForEach(diastolicPoints) { point in
          LineMark(
            x: .value("날짜", point.date),
            y: .value("이완기 혈압", point.value)
          )
          .foregroundStyle(NBColor.warning)
          .interpolationMethod(.catmullRom)

          PointMark(
            x: .value("날짜", point.date),
            y: .value("이완기 혈압", point.value)
          )
          .foregroundStyle(NBColor.warning)
          .symbolSize(44)
        }
      }
      .chartXAxis {
        AxisMarks(values: .automatic(desiredCount: 4)) {
          AxisGridLine()
          AxisValueLabel(format: .dateTime.month().day())
        }
      }
      .chartYAxis {
        AxisMarks(position: .leading)
      }
      .chartYScale(domain: yDomain)
      .frame(height: 220)
      .accessibilityLabel("혈압 추세 그래프")

      HStack(spacing: NBSpacing.medium) {
        NBStatusBadge("수축기", systemImage: "heart", tint: NBColor.danger)
        NBStatusBadge("이완기", systemImage: "heart", tint: NBColor.warning)
      }
    }
  }

  private var systolicPoints: [HealthMetricChartDataPoint] {
    builder.points(samples: samples, metricType: .systolicBloodPressure)
  }

  private var diastolicPoints: [HealthMetricChartDataPoint] {
    builder.points(samples: samples, metricType: .diastolicBloodPressure)
  }

  private var yDomain: ClosedRange<Double> {
    let values = (systolicPoints + diastolicPoints).map(\.value)
    guard let minimum = values.min(), let maximum = values.max() else {
      return 0...1
    }

    let padding = max((maximum - minimum) * 0.2, 6)
    return max(0, minimum - padding)...(maximum + padding)
  }
}
