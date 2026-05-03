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
            HealthLatestSampleDetailSection(
              title: "최근 측정 세부 정보",
              metricTypes: metrics,
              samples: periodSamples
            )
            HealthPeriodOverviewSection(
              samples: samples,
              metricTypes: metrics,
              primaryMetric: .systolicBloodPressure,
              title: "기간별 혈압 요약"
            )
            BloodPressureTrendChart(samples: periodSamples, period: selectedPeriod)
            timeOfDaySection
            HealthTrendSummaryRows(summaries: trendSummaries)
            HealthSourceSummarySection(
              sourceSummaries: calculator.sourceSummaries(
                samples: samples,
                metricTypes: metrics,
                period: selectedPeriod
              )
            )
            HealthDailyRhythmConnectionSection(
              focus: "오늘의 리듬 참고 데이터",
              message: "혈압 샘플은 아침 리포트와 하루 리듬 카드에서 날짜별 참고 데이터로 함께 정리할 수 있습니다."
            )
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
    .nbAvoidFloatingTabBar()
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
    calculator.summaries(
      samples: samples,
      metricTypes: metrics,
      period: selectedPeriod
    )
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
        Text("혈압 데이터를 보기 쉽게 정리합니다. 수축기/이완기 혈압 샘플을 기간별로 비교합니다.")
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
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        BloodPressureLatestPairCard(
          systolic: latestSystolicSample,
          diastolic: latestDiastolicSample
        )

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.medium) {
          latestMetricCard(.systolicBloodPressure)
          latestMetricCard(.diastolicBloodPressure)
        }
      }
    }
  }

  private var timeOfDaySection: some View {
    NBReportSection(title: "측정 시간대", systemImage: "sun.and.horizon") {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        NBListRow(
          title: "아침",
          value: "\(timeOfDayCounts.morning)개",
          subtitle: "정오 이전 측정 샘플",
          systemImage: "sunrise",
          tint: NBColor.warning
        )
        Divider().overlay(NBColor.divider)
        NBListRow(
          title: "저녁",
          value: "\(timeOfDayCounts.evening)개",
          subtitle: "정오 이후 측정 샘플",
          systemImage: "moon",
          tint: NBColor.sleep
        )
        Text("수축기 혈압 샘플의 측정 시각 기준입니다.")
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

  private var latestSystolicSample: HealthMetricSample? {
    periodSamples.latestSample(metricType: .systolicBloodPressure)
  }

  private var latestDiastolicSample: HealthMetricSample? {
    periodSamples.latestSample(metricType: .diastolicBloodPressure)
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
      footnote: sample.map { "\(SleepFormatters.shortDate($0.measuredAt)) \(SleepFormatters.shortTime($0.measuredAt)) · \($0.sourceName)" },
      accessibilityLabel: "\(metricType.displayName), \(sample.map { HealthMetricDashboardFormatting.valueString($0.value, unit: $0.unit) } ?? "데이터 없음")"
    )
  }
}

private struct BloodPressureLatestPairCard: View {
  let systolic: HealthMetricSample?
  let diastolic: HealthMetricSample?

  var body: some View {
    VStack(alignment: .leading, spacing: NBSpacing.small) {
      HStack(alignment: .firstTextBaseline) {
        Label("최근 측정값", systemImage: "heart.text.square")
          .font(.callout.weight(.semibold))
          .foregroundStyle(NBColor.primaryText)

        Spacer()

        NBStatusBadge(timeOfDayLabel, systemImage: timeOfDayIcon, tint: NBColor.danger)
      }

      HStack(alignment: .firstTextBaseline, spacing: NBSpacing.xSmall) {
        Text(pairValue)
          .font(NBTypography.metricNumber)
          .foregroundStyle(NBColor.primaryText)
          .lineLimit(1)
          .minimumScaleFactor(0.72)

        Text("mmHg")
          .font(NBTypography.captionEmphasis)
          .foregroundStyle(NBColor.secondaryText)
      }

      Text(detailText)
        .font(NBTypography.caption)
        .foregroundStyle(NBColor.secondaryText)
        .fixedSize(horizontal: false, vertical: true)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("최근 혈압, \(pairValue) mmHg, \(detailText)")
  }

  private var pairValue: String {
    guard let systolic, let diastolic else { return "--/--" }
    return "\(Int(systolic.value.rounded()))/\(Int(diastolic.value.rounded()))"
  }

  private var latestSample: HealthMetricSample? {
    [systolic, diastolic]
      .compactMap { $0 }
      .sortedByMeasuredAtDescending()
      .first
  }

  private var detailText: String {
    guard let latestSample else {
      return "선택한 기간에 함께 표시할 혈압 샘플이 없습니다."
    }

    return "\(SleepFormatters.shortDate(latestSample.measuredAt)) \(SleepFormatters.shortTime(latestSample.measuredAt)) · \(latestSample.sourceName)"
  }

  private var timeOfDayLabel: String {
    guard let latestSample else { return "데이터 없음" }
    let hour = Calendar.current.component(.hour, from: latestSample.measuredAt)
    return hour < 12 ? "아침 측정" : "저녁 측정"
  }

  private var timeOfDayIcon: String {
    guard let latestSample else { return "tray" }
    let hour = Calendar.current.component(.hour, from: latestSample.measuredAt)
    return hour < 12 ? "sunrise" : "moon"
  }
}

private struct BloodPressureTrendChart: View {
  let samples: [HealthMetricSample]
  let period: HealthMetricTrendPeriod

  private let builder = HealthMetricChartDataBuilder()

  var body: some View {
    NBReportSection(title: "\(period.displayName) 그래프", systemImage: "chart.xyaxis.line") {
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
