import SwiftUI

struct BodyCompositionDashboardView: View {
  let samples: [HealthMetricSample]
  let permissionState: HealthMetricPermissionState
  let isPreviewData: Bool

  @State private var selectedPeriod: HealthMetricTrendPeriod = .sevenDays

  private let calculator = HealthMetricTrendCalculator()
  private let metrics = HealthDashboardMetrics.bodyComposition

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.xLarge) {
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
            trendChartsSection
            HealthTrendSummaryRows(summaries: trendSummaries)
            HealthSourceSummarySection(sourceSummaries: calculator.sourceSummaries(samples: periodSamples))
          }
        }

        NBPrivacyNoticeCard(
          title: "체성분 데이터 안내",
          message: "Apple 건강앱에서 읽은 체중/체성분 sample을 기간별로 정리합니다. 수치에 대한 확정적 해석을 제공하지 않습니다.",
          systemImage: "scalemass"
        )
      }
      .padding(NBSpacing.large)
    }
    .background(NBColor.pageBackground)
    .navigationTitle("체중/체성분")
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
    "Apple 건강앱에 체중/체성분 데이터가 없거나 항목별 읽기 권한이 제한되어 있을 수 있습니다. Fitdays 또는 다른 체중 기록 source의 Apple 건강앱 연동 상태를 확인하세요."
  }

  private var header: some View {
    NBReportSection(title: "체중/체성분 추세", systemImage: "scalemass") {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        Text("체중, 체지방률, BMI, 제지방량 sample을 기간별로 비교합니다.")
          .font(.callout)
          .foregroundStyle(.secondary)
        if let latestMeasuredAt {
          Text("최근 측정: \(SleepFormatters.shortDate(latestMeasuredAt)) \(SleepFormatters.shortTime(latestMeasuredAt))")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  private var latestSection: some View {
    NBReportSection(title: "최근 체성분", systemImage: "clock") {
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.medium) {
        ForEach(metrics) { metricType in
          latestMetricCard(metricType)
        }
      }
    }
  }

  private var trendChartsSection: some View {
    VStack(alignment: .leading, spacing: NBSpacing.large) {
      ForEach(metrics) { metricType in
        NBReportSection(
          title: "\(metricType.dashboardSectionName) 그래프",
          systemImage: HealthMetricDashboardFormatting.icon(for: metricType)
        ) {
          HealthMetricChartView(
            metricType: metricType,
            samples: periodSamples,
            tint: HealthMetricDashboardFormatting.tint(for: metricType)
          )
        }
      }
    }
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
      footnote: sample.map { "\(SleepFormatters.shortDate($0.measuredAt)) · \($0.sourceName)" }
    )
  }
}
