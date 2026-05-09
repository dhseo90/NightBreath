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
              primaryMetric: .bodyMass,
              title: "기간별 체중 요약"
            )
            trendChartsSection
            HealthTrendSummaryRows(summaries: trendSummaries)
            HealthSourceSummarySection(
              sourceSummaries: calculator.sourceSummaries(
                samples: samples,
                metricTypes: metrics,
                period: selectedPeriod
              )
            )
            HealthDailyRhythmConnectionSection(
              focus: "하루 리듬 카드 참고 데이터",
              message: "체중과 체성분 샘플은 오늘의 리듬 점수와 건강 대시보드에서 개인 참고용으로 함께 정리할 수 있습니다."
            )
          }
        }

        NBPrivacyNoticeCard(
          title: "체성분 데이터 안내",
          message: "Apple 건강앱에서 읽은 체중/체성분 샘플을 기간별로 정리합니다. 수치에 대한 확정적 해석을 제공하지 않습니다.",
          systemImage: "scalemass"
        )
      }
      .padding(NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
    .navigationTitle("체중/체성분")
    .toolbar(.hidden, for: .tabBar)
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
    "Apple 건강앱에 체중/체성분 데이터가 없거나 항목별 읽기 권한이 제한되어 있을 수 있습니다. Fitdays 또는 다른 체중 기록 source의 Apple 건강앱 연동 상태를 확인하세요."
  }

  private var header: some View {
    NBReportSection(title: "체중/체성분 추세", systemImage: "scalemass") {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        Text("체중, 체지방률, BMI, 제지방량 샘플을 기간별로 보기 쉽게 정리합니다.")
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
          title: "\(selectedPeriod.displayName) \(metricType.dashboardSectionName) 그래프",
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
      footnote: sample.map { "\(SleepFormatters.shortDate($0.measuredAt)) \(SleepFormatters.shortTime($0.measuredAt)) · \($0.sourceName)" },
      accessibilityLabel: "\(metricType.displayName), \(sample.map { HealthMetricDashboardFormatting.valueString($0.value, unit: $0.unit) } ?? "데이터 없음")"
    )
  }
}
