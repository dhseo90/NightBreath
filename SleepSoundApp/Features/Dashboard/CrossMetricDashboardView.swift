import Charts
import SwiftUI

struct CrossMetricDashboardView: View {
  let reports: [NightReport]
  let samples: [HealthMetricSample]
  let permissionState: HealthMetricPermissionState
  let isPreviewData: Bool

  @State private var selectedPeriod: HealthMetricTrendPeriod = .thirtyDays
  @State private var selectedSleepMetric: TrendMetricType = .snoreTotalSeconds
  @State private var selectedHealthMetric: HealthMetricType = .systolicBloodPressure

  private let analyzer = CrossMetricAnalyzer()

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
          metricSelectionSection
          matchingGuideSection

          if summary.hasEnoughData {
            chartSection
            summarySection
            HealthSourceSummarySection(sourceSummaries: summary.sourceSummaries)
          } else {
            insufficientDataSection
          }
        }

        NBPrivacyNoticeCard(
          title: "로컬 교차 보기",
          message: "수면 소리 리포트와 Apple 건강앱 read-only sample을 기기 안에서만 나란히 표시합니다. HealthKit에 데이터를 쓰지 않습니다.",
          systemImage: "lock.shield"
        )
      }
      .padding(NBSpacing.large)
    }
    .background(NBColor.pageBackground)
    .navigationTitle("수면 소리 × 건강")
  }

  private var shouldShowDashboardContent: Bool {
    switch permissionState {
    case .denied, .unavailable:
      false
    case .notRequested, .mockDataOnly, .readRequestCompleted:
      true
    }
  }

  private var matchedPoints: [CrossMetricMatchedPoint] {
    analyzer.matchedPoints(
      reports: reports,
      samples: samples,
      sleepMetric: selectedSleepMetric,
      healthMetric: selectedHealthMetric,
      period: selectedPeriod
    )
  }

  private var includedPoints: [CrossMetricMatchedPoint] {
    matchedPoints.filter(\.isIncludedInSummary)
  }

  private var excludedPoints: [CrossMetricMatchedPoint] {
    matchedPoints.filter { !$0.isIncludedInSummary }
  }

  private var summary: CrossMetricSummary {
    analyzer.summary(
      reports: reports,
      samples: samples,
      sleepMetric: selectedSleepMetric,
      healthMetric: selectedHealthMetric,
      period: selectedPeriod
    )
  }

  private var header: some View {
    NBReportSection(title: "개인 패턴 탐색", systemImage: "chart.dots.scatter") {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        Text("수면 소리 지표와 건강 지표를 날짜 기준으로 함께 표시합니다.")
          .font(.callout)
          .foregroundStyle(.secondary)
        Text(summary.cautionText)
          .font(.footnote)
          .foregroundStyle(NBColor.warning)
      }
    }
  }

  private var metricSelectionSection: some View {
    NBReportSection(title: "비교 항목", systemImage: "slider.horizontal.3") {
      VStack(spacing: NBSpacing.medium) {
        Picker("수면 지표", selection: $selectedSleepMetric) {
          ForEach(CrossMetricAnalyzer.supportedSleepMetrics) { metric in
            Text(metric.displayName).tag(metric)
          }
        }
        .pickerStyle(.menu)

        Picker("건강 지표", selection: $selectedHealthMetric) {
          ForEach(CrossMetricAnalyzer.supportedHealthMetrics) { metric in
            Text(metric.displayName).tag(metric)
          }
        }
        .pickerStyle(.menu)
      }
    }
  }

  private var matchingGuideSection: some View {
    NBReportSection(title: "날짜 매칭", systemImage: "calendar.badge.clock") {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        Text(analyzer.matchingWindowDescription(for: selectedHealthMetric))
          .font(.callout)
          .foregroundStyle(.secondary)
        HStack(spacing: NBSpacing.small) {
          NBStatusBadge(selectedPeriod.displayName, systemImage: "calendar", tint: NBColor.sleepTint)
          NBStatusBadge(summary.matchingStrategy.displayName, systemImage: "clock", tint: NBColor.privacyTint)
        }
        Text("오디오 커버리지가 낮은 수면 리포트는 그래프에서 구분하고 요약 계산에서는 제외합니다.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var chartSection: some View {
    NBReportSection(title: "산점도", systemImage: "chart.dots.scatter") {
      Chart {
        ForEach(includedPoints) { point in
          PointMark(
            x: .value(selectedSleepMetric.displayName, point.sleepValue),
            y: .value(selectedHealthMetric.displayName, point.healthValue)
          )
          .foregroundStyle(NBColor.breathBlue)
          .symbol(.circle)
          .symbolSize(52)
        }

        ForEach(excludedPoints) { point in
          PointMark(
            x: .value(selectedSleepMetric.displayName, point.sleepValue),
            y: .value(selectedHealthMetric.displayName, point.healthValue)
          )
          .foregroundStyle(NBColor.warning)
          .symbol(.diamond)
          .symbolSize(64)
        }
      }
      .chartXAxis {
        AxisMarks(position: .bottom)
      }
      .chartYAxis {
        AxisMarks(position: .leading)
      }
      .frame(height: 240)
      .accessibilityLabel("수면 소리 지표와 건강 지표 산점도")

      HStack(spacing: NBSpacing.medium) {
        NBStatusBadge("요약 포함", systemImage: "circle.fill", tint: NBColor.breathBlue)
        if !excludedPoints.isEmpty {
          NBStatusBadge("측정 품질 낮음", systemImage: "diamond.fill", tint: NBColor.warning)
        }
      }
    }
  }

  private var summarySection: some View {
    NBReportSection(title: "요약", systemImage: "list.bullet.rectangle") {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        Text(summary.trendDescription)
          .font(.callout)
          .foregroundStyle(.secondary)

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.medium) {
          summaryTile("비교 sample", "\(summary.matchedSampleCount)개", "link")
          summaryTile("데이터 품질", summary.dataQuality.displayName, "checkmark.seal")
          summaryTile("구분 표시", "\(summary.lowQualityExcludedCount)개", "exclamationmark.triangle")
          summaryTile("건강 source", sourceNamesText, "square.stack.3d.up")
        }

        Text(summary.cautionText)
          .font(.footnote)
          .foregroundStyle(NBColor.warning)
      }
    }
  }

  private var insufficientDataSection: some View {
    HealthDataEmptyStateView(
      title: "비교 가능한 데이터가 아직 부족합니다.",
      message: "같은 기간에 매칭되는 수면 리포트와 건강 sample이 3개 이상 모이면 그래프와 요약을 표시합니다. 측정 품질 낮음으로 표시된 수면 리포트는 요약 계산에서 제외합니다."
    )
  }

  private var sourceNamesText: String {
    guard !summary.healthSourceNames.isEmpty else {
      return "--"
    }
    return summary.healthSourceNames.prefix(2).joined(separator: ", ")
  }

  private func summaryTile(_ title: String, _ value: String, _ systemImage: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Label(title, systemImage: systemImage)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
      Text(value)
        .font(.callout.weight(.semibold))
        .lineLimit(2)
        .minimumScaleFactor(0.85)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(NBSpacing.medium)
    .background(NBColor.elevatedSurface)
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }
}
