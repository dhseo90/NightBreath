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
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        header
        HealthDataAccessStateView(
          permissionState: permissionState,
          isPreviewData: isPreviewData
        )

        if shouldShowDashboardContent {
          HealthMetricPeriodPicker(selection: $selectedPeriod)
          metricSelectionSection
          matchingGuideSection
          matchingStateSection

          if summary.hasEnoughData {
            chartSection
            matchedPointSection
            summarySection
            HealthSourceSummarySection(sourceSummaries: summary.sourceSummaries)
          } else {
            if !matchedPoints.isEmpty {
              matchedPointSection
            }
            insufficientDataSection
          }
        }

        NBPrivacyNoticeCard(
          title: "로컬 교차 보기",
          messages: [
            "개인 패턴을 살펴보기 위한 참고용 보기입니다.",
            "인과관계를 의미하지 않습니다.",
            "수면 소리 리포트와 Apple 건강앱 read-only 샘플을 기기 안에서만 나란히 표시합니다.",
            "HealthKit에 데이터를 쓰지 않습니다.",
          ],
          systemImage: "lock.shield"
        )
      }
      .padding(NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
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
        Text("개인 패턴을 살펴보기 위한 참고용 보기입니다.")
          .font(NBTypography.callout)
          .foregroundStyle(NBColor.secondaryText)
        Text("수면 소리 지표와 건강 지표를 날짜 기준으로 함께 표시하며, 인과관계를 의미하지 않습니다.")
          .font(NBTypography.footnote)
          .foregroundStyle(NBColor.secondaryText)
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
        Text(summary.matchingWindowDescription)
          .font(NBTypography.callout)
          .foregroundStyle(NBColor.secondaryText)
        HStack(spacing: NBSpacing.small) {
          NBStatusBadge(selectedPeriod.displayName, kind: .neutral, systemImage: "calendar")
          NBStatusBadge(summary.matchingStrategy.displayName, kind: .privacy, systemImage: "clock")
        }
        Text("오디오 커버리지가 낮은 수면 리포트는 그래프에서 구분하고 요약 계산에서는 제외합니다.")
          .font(NBTypography.footnote)
          .foregroundStyle(NBColor.secondaryText)
      }
    }
  }

  private var matchedPointSection: some View {
    NBReportSection(title: "날짜별 매칭", systemImage: "calendar.badge.checkmark") {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        ForEach(recentMatchedPoints) { point in
          NBListRow(
            title: SleepFormatters.shortDate(point.sleepReportDate),
            value: point.isIncludedInSummary ? "요약 포함" : "구분 표시",
            subtitle: matchedPointSubtitle(point),
            systemImage: point.isIncludedInSummary ? "link.circle" : "exclamationmark.triangle",
            tint: point.isIncludedInSummary ? NBColor.breathBlue : NBColor.warning,
            accessibilityLabel: matchedPointAccessibilityLabel(point)
          )

          if point.id != recentMatchedPoints.last?.id {
            Divider().overlay(NBColor.divider)
          }
        }

        if matchedPoints.count > recentMatchedPoints.count {
          Text("최근 \(recentMatchedPoints.count)개 매칭만 표시합니다.")
            .font(NBTypography.footnote)
            .foregroundStyle(NBColor.secondaryText)
        }
      }
    }
  }

  private var matchingStateSection: some View {
    NBReportSection(title: "매칭 상태", systemImage: "point.3.connected.trianglepath.dotted") {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        VStack(alignment: .leading, spacing: NBSpacing.xs) {
          Text(summary.hasEnoughData ? summary.trendDescription : summary.insufficientReasonTitle)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(NBColor.primaryText)
            .fixedSize(horizontal: false, vertical: true)

          Text(summary.hasEnoughData ? summary.cautionText : summary.insufficientReasonMessage)
            .font(NBTypography.caption)
            .foregroundStyle(NBColor.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
        }

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.medium) {
          summaryTile("날짜 매칭", "\(summary.totalMatchedSampleCount)개", "link", .neutral)
          summaryTile("요약 포함", "\(summary.matchedSampleCount)개", "checkmark.circle", summaryStatusKind)
          summaryTile("구분 제외", "\(summary.lowQualityExcludedCount)개", "exclamationmark.triangle", summary.lowQualityExcludedCount > 0 ? .caution : .neutral)
          summaryTile("필요 샘플", requiredSampleText, "number", summary.hasEnoughData ? .good : .warning)
        }
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
        AxisMarks(position: .bottom) {
          AxisGridLine()
            .foregroundStyle(NBColor.divider)
          AxisValueLabel()
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
      .frame(height: 240)
      .accessibilityLabel("수면 소리 지표와 건강 지표 산점도")

      HStack(spacing: NBSpacing.medium) {
        NBStatusBadge("요약 포함", kind: .good, systemImage: "circle.fill")
        if !excludedPoints.isEmpty {
          NBStatusBadge("측정 품질 낮음", kind: .caution, systemImage: "diamond.fill")
        }
      }
    }
  }

  private var summarySection: some View {
    NBReportSection(title: "요약", systemImage: "list.bullet.rectangle") {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        Text(summary.trendDescription)
          .font(NBTypography.callout)
          .foregroundStyle(NBColor.secondaryText)

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.medium) {
          summaryTile("비교 샘플", "\(summary.matchedSampleCount)개", "link", .neutral)
          summaryTile("데이터 품질", summary.dataQuality.displayName, "checkmark.seal", summaryStatusKind)
          summaryTile("구분 표시", "\(summary.lowQualityExcludedCount)개", "exclamationmark.triangle", .caution)
          summaryTile("건강 source", sourceNamesText, "square.stack.3d.up", .privacy)
        }

        Text("인과관계를 의미하지 않습니다. \(summary.cautionText)")
          .font(NBTypography.footnote)
          .foregroundStyle(NBColor.secondaryText)
      }
    }
  }

  private var insufficientDataSection: some View {
    HealthDataEmptyStateView(
      title: summary.insufficientReasonTitle,
      message: "\(summary.insufficientReasonMessage) 측정 품질 낮음으로 표시된 수면 리포트는 요약 계산에서 제외합니다."
    )
  }

  private var requiredSampleText: String {
    summary.hasEnoughData ? "충족" : "\(summary.includedSampleShortfall)개 더"
  }

  private var sourceNamesText: String {
    guard !summary.healthSourceNames.isEmpty else {
      return "--"
    }
    return summary.healthSourceNames.prefix(2).joined(separator: ", ")
  }

  private var summaryStatusKind: NBStatusKind {
    switch summary.dataQuality {
    case .sufficient:
      .good
    case .limited:
      .caution
    case .insufficientData:
      .neutral
    }
  }

  private var recentMatchedPoints: [CrossMetricMatchedPoint] {
    Array(matchedPoints
      .sorted { lhs, rhs in
        if lhs.sleepReportDate == rhs.sleepReportDate {
          return lhs.id < rhs.id
        }
        return lhs.sleepReportDate > rhs.sleepReportDate
      }
      .prefix(8)
      .reversed())
  }

  private func matchedPointSubtitle(_ point: CrossMetricMatchedPoint) -> String {
    [
      "\(selectedSleepMetric.displayName) \(formattedSleepValue(point.sleepValue))",
      "\(selectedHealthMetric.displayName) \(HealthMetricDashboardFormatting.valueString(point.healthValue, unit: selectedHealthMetric.unitLabel))",
      "건강 샘플 \(SleepFormatters.shortDate(point.healthSampleDate)) \(SleepFormatters.shortTime(point.healthSampleDate))",
      point.healthSourceName,
      "커버리지 \(percentString(point.audioCoverageRatio))",
    ].joined(separator: " · ")
  }

  private func matchedPointAccessibilityLabel(_ point: CrossMetricMatchedPoint) -> String {
    "\(SleepFormatters.shortDate(point.sleepReportDate)), \(matchedPointSubtitle(point)), \(point.isIncludedInSummary ? "요약 포함" : "측정 품질 낮음으로 구분 표시")"
  }

  private func formattedSleepValue(_ value: Double) -> String {
    switch selectedSleepMetric {
    case .sleepSoundScore:
      "\(Int(value.rounded()))점"
    case .audioCoverageRatio:
      "\(Int(value.rounded()))%"
    case .snoreTotalSeconds:
      String(format: "%.1f분", value)
    case .bruxismLikeCount, .coughLikeCount, .gaspLikeCount,
         .suspectedBreathingPauseCount, .environmentalNoiseCount, .awakeningSuspectedCount:
      "\(Int(value.rounded()))회"
    }
  }

  private func percentString(_ ratio: Double) -> String {
    "\(Int((min(max(ratio, 0), 1) * 100).rounded()))%"
  }

  private func summaryTile(
    _ title: String,
    _ value: String,
    _ systemImage: String,
    _ status: NBStatusKind
  ) -> some View {
    NBMetricCard(
      title: title,
      value: value,
      systemImage: systemImage,
      tint: status.tint,
      status: status,
      accessibilityLabel: "\(title), \(value)"
    )
  }
}
