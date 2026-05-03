import Charts
import SwiftUI

struct TrendDashboardView: View {
  @EnvironmentObject private var appState: AppState
  @State private var selectedPeriod: TrendPeriod = .sevenDays

  private let aggregator = TrendAggregator()
  private let mainMetrics: [TrendMetricType] = [
    .sleepSoundScore,
    .snoreTotalSeconds,
    .suspectedBreathingPauseCount,
    .bruxismLikeCount,
    .coughLikeCount,
    .gaspLikeCount,
    .environmentalNoiseCount,
    .awakeningSuspectedCount,
  ]

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        periodPicker
        overviewSection

        if reports.isEmpty {
          emptyState
        } else {
          ForEach(mainMetrics) { metricType in
            TrendMetricSection(
              metricType: metricType,
              points: dataPoints(for: metricType),
              summary: summary(for: metricType),
              tint: tint(for: metricType)
            )
          }

          TrendMetricSection(
            metricType: .audioCoverageRatio,
            points: dataPoints(for: .audioCoverageRatio),
            summary: summary(for: .audioCoverageRatio),
            tint: NBColor.mistTeal,
            showsCoverageGuide: true
          )
        }

        NBPrivacyNoticeCard(
          title: "앱 내부 리포트 기반",
          messages: [
            "트렌드는 밤숨에 저장된 NightReport만 사용합니다.",
            "개인 패턴을 살펴보기 위한 참고용 보기입니다.",
            "서버로 전송하지 않습니다.",
          ],
          systemImage: "chart.line.uptrend.xyaxis"
        )
      }
      .padding(.horizontal, NBSpacing.screenHorizontal)
      .padding(.vertical, NBSpacing.sectionVertical)
    }
    .background(NBColor.pageBackground)
    .navigationTitle("수면 트렌드")
  }

  private var reports: [NightReport] {
    appState.trendReports(days: selectedPeriod.rawValue)
  }

  private var periodPicker: some View {
    Picker("기간", selection: $selectedPeriod) {
      ForEach(TrendPeriod.allCases) { period in
        Text(period.title).tag(period)
      }
    }
    .pickerStyle(.segmented)
  }

  private var overviewSection: some View {
    NBReportSection(title: "\(selectedPeriod.title) 수면 소리 요약", systemImage: "calendar") {
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.medium) {
        NBMetricCard(
          title: "리포트",
          value: "\(reports.count)개",
          systemImage: "doc.text",
          tint: NBColor.breathBlue
        )
        NBMetricCard(
          title: "낮은 측정 품질",
          value: "\(lowQualityReportCount)개",
          systemImage: "exclamationmark.triangle",
          tint: lowQualityReportCount > 0 ? NBColor.warning : NBColor.success
        )
      }

      HStack(spacing: NBSpacing.xs) {
        NBStatusBadge(selectedPeriod.title, kind: .neutral, systemImage: "calendar")
        NBStatusBadge(
          lowQualityReportCount > 0 ? "낮은 측정 품질 \(lowQualityReportCount)개" : "측정 품질 낮음 없음",
          kind: lowQualityReportCount > 0 ? .caution : .good,
          systemImage: lowQualityReportCount > 0 ? "exclamationmark.triangle" : "checkmark.circle"
        )
      }

      Text("측정 품질 낮음으로 표시된 리포트는 차트에는 남기고 평균, 최솟값, 최댓값 계산에서는 제외합니다.")
        .font(.footnote)
        .foregroundStyle(NBColor.secondaryText)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var emptyState: some View {
    NBCard {
      NBEmptyStateView(
        title: "아직 표시할 트렌드가 없습니다",
        message: "수면 기록이 쌓이면 최근 7일, 30일, 90일의 수면 소리 지표가 이 화면에 표시됩니다.",
        systemImage: "chart.xyaxis.line",
        illustration: .emptyReport
      )
    }
  }

  private var lowQualityReportCount: Int {
    reports.filter { report in
      report.measurementQuality == .limited || report.measurementQuality == .poor
    }.count
  }

  private func dataPoints(for metricType: TrendMetricType) -> [TrendDataPoint] {
    aggregator.dataPoints(
      reports: reports,
      metricType: metricType,
      periodDays: selectedPeriod.rawValue
    )
  }

  private func summary(for metricType: TrendMetricType) -> TrendSummary {
    aggregator.summary(
      reports: reports,
      metricType: metricType,
      periodDays: selectedPeriod.rawValue
    )
  }

  private func tint(for metricType: TrendMetricType) -> Color {
    switch metricType {
    case .sleepSoundScore:
      return NBColor.breathBlue
    case .audioCoverageRatio:
      return NBColor.mistTeal
    case .snoreTotalSeconds:
      return SleepEventType.snore.tintColor
    case .bruxismLikeCount:
      return SleepEventType.bruxismLike.tintColor
    case .coughLikeCount:
      return SleepEventType.coughLike.tintColor
    case .gaspLikeCount:
      return SleepEventType.gaspLike.tintColor
    case .suspectedBreathingPauseCount:
      return SleepEventType.breathingPauseSuspected.tintColor
    case .environmentalNoiseCount:
      return SleepEventType.environmentalNoise.tintColor
    case .awakeningSuspectedCount:
      return SleepEventType.awakeningSuspected.tintColor
    }
  }
}

private enum TrendPeriod: Int, CaseIterable, Identifiable {
  case sevenDays = 7
  case thirtyDays = 30
  case ninetyDays = 90

  var id: Int { rawValue }

  var title: String {
    "\(rawValue)일"
  }
}

private struct TrendMetricSection: View {
  let metricType: TrendMetricType
  let points: [TrendDataPoint]
  let summary: TrendSummary
  let tint: Color
  var showsCoverageGuide = false

  var body: some View {
    NBReportSection(title: "\(metricType.displayName) 추세", systemImage: systemImage) {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        summaryGrid

        if points.isEmpty {
          NBEmptyStateView(
            title: "표시할 데이터가 부족합니다",
            message: "\(metricType.displayName) 지표가 포함된 리포트가 더 쌓이면 추세를 표시합니다.",
            systemImage: systemImage,
            illustration: .emptyReport
          )
        } else {
          chart
        }

        if summary.lowQualityDataCount > 0 {
          NBStatusBadge(
            "측정 품질 낮음 \(summary.lowQualityDataCount)개: 평균 계산에서 제외",
            kind: .caution,
            systemImage: "exclamationmark.triangle"
          )
        }

        if let changeText {
          Text(changeText)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(changeColor)
        }
      }
    }
  }

  private var summaryGrid: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.small) {
      TrendSummaryItem(title: "평균", value: valueString(summary.average), systemImage: "chart.bar", tint: tint)
      TrendSummaryItem(title: "최근", value: valueString(summary.latest), systemImage: "clock", tint: tint)
      TrendSummaryItem(title: "최소", value: valueString(summary.min), systemImage: "arrow.down.to.line", tint: NBColor.neutral)
      TrendSummaryItem(title: "최대", value: valueString(summary.max), systemImage: "arrow.up.to.line", tint: NBColor.neutral)
    }
  }

  private var chart: some View {
    Chart {
      ForEach(points) { point in
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
        .foregroundStyle(point.isLowMeasurementQuality ? NBColor.warning : tint)
        .symbol(point.isLowMeasurementQuality ? .diamond : .circle)
        .symbolSize(point.isLowMeasurementQuality ? 78 : 46)
      }

      if showsCoverageGuide {
        RuleMark(y: .value("측정 품질 낮음 기준", 85))
          .foregroundStyle(NBColor.warning.opacity(0.55))
          .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
      }
    }
    .chartYScale(domain: yDomain)
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
    .frame(height: 190)
    .accessibilityLabel("\(metricType.displayName) 추세 차트")
  }

  private var systemImage: String {
    switch metricType {
    case .sleepSoundScore:
      return "gauge.with.dots.needle.bottom.100percent"
    case .audioCoverageRatio:
      return "waveform.badge.checkmark"
    case .snoreTotalSeconds:
      return SleepEventType.snore.symbolName
    case .bruxismLikeCount:
      return SleepEventType.bruxismLike.symbolName
    case .coughLikeCount:
      return SleepEventType.coughLike.symbolName
    case .gaspLikeCount:
      return SleepEventType.gaspLike.symbolName
    case .suspectedBreathingPauseCount:
      return SleepEventType.breathingPauseSuspected.symbolName
    case .environmentalNoiseCount:
      return SleepEventType.environmentalNoise.symbolName
    case .awakeningSuspectedCount:
      return SleepEventType.awakeningSuspected.symbolName
    }
  }

  private var yDomain: ClosedRange<Double> {
    switch metricType {
    case .sleepSoundScore, .audioCoverageRatio:
      return 0...100
    default:
      let pointMax = points.map(\.value).max() ?? 0
      let summaryMax = summary.max ?? 0
      let upper = max(1, max(pointMax, summaryMax) * 1.25)
      return 0...upper
    }
  }

  private var changeText: String? {
    guard let change = summary.changeFromPreviousPeriod else { return nil }
    let prefix = change >= 0 ? "+" : ""
    return "이전 같은 기간 대비 \(prefix)\(valueString(change, includesUnit: true))"
  }

  private var changeColor: Color {
    guard let change = summary.changeFromPreviousPeriod else { return NBColor.mutedText }

    switch metricType {
    case .sleepSoundScore, .audioCoverageRatio:
      return change >= 0 ? NBColor.success : NBColor.warning
    default:
      return change <= 0 ? NBColor.success : NBColor.warning
    }
  }

  private func valueString(_ value: Double?, includesUnit: Bool = true) -> String {
    guard let value else { return "--" }
    let unit = includesUnit ? metricType.unitLabel : ""
    let absoluteValue = abs(value)
    let sign = value < 0 ? "-" : ""

    switch metricType {
    case .sleepSoundScore, .audioCoverageRatio:
      return "\(sign)\(Int(absoluteValue.rounded()))\(unit)"
    case .snoreTotalSeconds:
      return String(format: "%@%.1f%@", sign, absoluteValue, unit)
    case .bruxismLikeCount, .coughLikeCount, .gaspLikeCount,
         .suspectedBreathingPauseCount, .environmentalNoiseCount, .awakeningSuspectedCount:
      return "\(sign)\(Int(absoluteValue.rounded()))\(unit)"
    }
  }
}

private struct TrendSummaryItem: View {
  let title: String
  let value: String
  let systemImage: String
  let tint: Color

  var body: some View {
    NBMetricCard(
      title: title,
      value: value,
      systemImage: systemImage,
      tint: tint,
      accessibilityLabel: "\(title) \(value)"
    )
  }
}
