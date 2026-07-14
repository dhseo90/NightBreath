import Charts
import SwiftUI

struct HealthMetricsOverviewView: View {
  let samples: [UnifiedHealthMetricSample]
  let permissionState: HealthMetricPermissionState
  let isPreviewData: Bool

  @State private var aggregationInterval: MetricAggregationInterval = .day

  private let catalog = MetricCatalog.default
  private let calculator = MetricStatisticsCalculator()
  private let grouping = UnifiedHealthMetricOverviewGrouping()

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        stateNotice
        MetricAggregationIntervalPicker(selection: $aggregationInterval)

        if samples.isEmpty {
          HealthDataEmptyStateView(
            title: "표시할 건강 지표 기록이 없습니다",
            message: "Apple 건강앱 read-only 연결 또는 Fitdays CSV 가져오기를 통해 기록을 추가하면 지표별 통계와 그래프를 볼 수 있습니다."
          )
        } else {
          ForEach(grouping.groups()) { group in
            metricGroupSection(group)
          }
        }

        NBPrivacyNoticeCard(
          title: "개인 참고용 통계",
          messages: [
            "HealthKit read-only 기록과 로컬 import 기록을 한곳에서 정리합니다.",
            "수치의 평균, 최소, 최대, 최근 변화는 참고용 계산입니다.",
            "HealthKit에 데이터를 쓰지 않고 서버로 전송하지 않습니다.",
          ],
          systemImage: "lock.shield"
        )
      }
      .padding(NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
    .navigationTitle("전체 건강 지표")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
  }

  private var selectedDateRange: HealthMetricDateRange {
    aggregationInterval.dateRange()
  }

  @ViewBuilder
  private var stateNotice: some View {
    if isPreviewData {
      NBStatusBadge(
        "연결 전 기록은 미리보기로 표시됩니다.",
        kind: .neutral,
        systemImage: "eye"
      )
    }

    switch permissionState {
    case .denied:
      NBStatusBadge(
        "Apple 건강앱 권한이 없어도 로컬 import 기록은 볼 수 있습니다.",
        kind: .caution,
        systemImage: "lock.slash"
      )
    case .unavailable:
      NBStatusBadge(
        "HealthKit을 사용할 수 없어도 로컬 import 기록은 볼 수 있습니다.",
        kind: .warning,
        systemImage: "exclamationmark.triangle"
      )
    case .notRequested, .readRequestCompleted, .mockDataOnly:
      EmptyView()
    }
  }

  private func metricGroupSection(_ group: UnifiedHealthMetricOverviewGroup) -> some View {
    NBReportSection(title: group.title, systemImage: groupIcon(for: group.id)) {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        ForEach(group.metricIDs, id: \.self) { metricID in
          if let metadata = catalog.metadata(for: metricID) {
            NavigationLink {
              MetricDetailView(
                metric: metadata,
                samples: samples,
                selectedInterval: aggregationInterval
              )
            } label: {
              metricRow(metadata)
            }
            .buttonStyle(.plain)

            if metricID != group.metricIDs.last {
              Divider().overlay(NBColor.divider)
            }
          }
        }
      }
    }
  }

  private func metricRow(_ metadata: MetricDisplayMetadata) -> some View {
    let summary = calculator.aggregatedSummary(
      samples: samples,
      metricID: metadata.metricID,
      dateRange: selectedDateRange,
      interval: aggregationInterval
    )

    return HStack(alignment: .center, spacing: NBSpacing.medium) {
      NBListRow(
        title: metadata.displayNameKo,
        value: summary.latestValue.map { UnifiedMetricFormatting.valueString($0, unit: metadata.unit) } ?? "--",
        subtitle: metricRowSubtitle(summary: summary),
        systemImage: metricIcon(for: metadata),
        tint: metricTint(for: metadata),
        accessibilityLabel: "\(metadata.displayNameKo), 기록 \(summary.sampleCount)개"
      )

      Spacer()

      Image(systemName: "chevron.right")
        .font(.caption.weight(.semibold))
        .foregroundStyle(NBColor.tertiaryText)
    }
  }

  private func metricRowSubtitle(summary: MetricStatisticsSummary) -> String {
    var parts: [String] = ["기록 \(summary.sampleCount)개"]

    if let latestMeasuredAt = summary.latestMeasuredAt {
      parts.append("최근 \(SleepFormatters.shortDate(latestMeasuredAt))")
    }

    return parts.joined(separator: " · ")
  }

  private func groupIcon(for groupID: UnifiedHealthMetricOverviewGroupID) -> String {
    switch groupID {
    case .bloodPressure:
      "heart"
    case .bodyComposition:
      "scalemass"
    case .activity:
      "figure.walk"
    case .recovery:
      "heart.text.square"
    case .sleepAndApp:
      "bed.double"
    case .fitdaysExtended:
      "square.and.arrow.down"
    }
  }
}

struct MetricDetailView: View {
  let metricID: UnifiedHealthMetricID
  let samples: [UnifiedHealthMetricSample]

  @State private var aggregationInterval: MetricAggregationInterval
  @State private var rangeAnchorDate = Date()
  @State private var sourceFilter: MetricDetailSourceFilter = .all
  @State private var isSourceDetailsExpanded = false

  private let catalog = MetricCatalog.default

  init(
    metric: MetricDisplayMetadata,
    samples: [UnifiedHealthMetricSample],
    selectedPeriod: HealthMetricTrendPeriod = .thirtyDays
  ) {
    self.metricID = metric.metricID
    self.samples = samples
    _aggregationInterval = State(initialValue: MetricAggregationInterval(trendPeriod: selectedPeriod))
  }

  init(
    metric: MetricDisplayMetadata,
    samples: [UnifiedHealthMetricSample],
    selectedInterval: MetricAggregationInterval
  ) {
    self.metricID = metric.metricID
    self.samples = samples
    _aggregationInterval = State(initialValue: selectedInterval)
  }

  init(
    metricID: UnifiedHealthMetricID,
    samples: [UnifiedHealthMetricSample],
    selectedPeriod: MetricDetailPeriod = .thirtyDays
  ) {
    self.metricID = metricID
    self.samples = samples
    _aggregationInterval = State(initialValue: Self.aggregationInterval(for: selectedPeriod))
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        controls

        MetricChartView(
          metric: metric,
          points: viewModel.aggregatedPoints,
          interval: aggregationInterval,
          tint: metricTint(for: metric),
          rangeTitle: rangeTitle,
          onPreviousRange: { moveRange(by: -1) },
          onNextRange: { moveRange(by: 1) },
          onTodayRange: { rangeAnchorDate = Date() }
        )
        .gesture(horizontalPagingGesture)

        MetricSummaryCard(
          metric: metric,
          summary: viewModel.aggregatedSummary,
          periodDisplayName: rangeTitle,
          averageTitle: aggregationInterval.averageTitle,
          countLabel: aggregationInterval.displayName
        )

        if let emptyState = viewModel.emptyStateReason {
          HealthDataEmptyStateView(
            title: emptyState.title,
            message: emptyState.message
          )
        }

        sourceDetailsSection
      }
      .padding(NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
    .navigationTitle(metric.displayNameKo)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
  }

  private var metric: MetricDisplayMetadata {
    catalog.metadata(for: metricID) ?? MetricDisplayMetadata(
      metricID: metricID,
      displayNameKo: metricID.rawValue,
      displayNameEn: metricID.rawValue,
      unit: "",
      category: .app,
      isHealthKitBacked: false,
      isExtendedLocalOnly: true,
      description: "개인 참고용으로 표시하는 지표입니다."
    )
  }

  private var viewModel: MetricDetailViewModel {
    MetricDetailViewModel(
      metricID: metricID,
      samples: samples,
      period: .all,
      aggregationInterval: aggregationInterval,
      sourceFilter: sourceFilter,
      endDate: rangeAnchorDate,
      catalog: catalog
    )
  }

  private var controls: some View {
    VStack(alignment: .leading, spacing: NBSpacing.small) {
      MetricAggregationIntervalPicker(selection: $aggregationInterval)
    }
  }

  private var sourceDetailsSection: some View {
    NBReportSection(title: "세부 데이터", systemImage: "square.stack.3d.up") {
      DisclosureGroup(isExpanded: $isSourceDetailsExpanded) {
        VStack(alignment: .leading, spacing: NBSpacing.medium) {
          MetricDetailSourceFilterMenu(selection: $sourceFilter)

          MetricDetailSourceSummaryLine(
            metric: metric,
            sources: viewModel.aggregationSourceBreakdown
          )

          if viewModel.aggregationSourceBreakdown.isEmpty {
            Text("선택한 구간에 표시할 출처 정보가 없습니다.")
              .font(NBTypography.caption)
              .foregroundStyle(NBColor.secondaryText)
          } else {
            ForEach(viewModel.aggregationSourceBreakdown) { source in
              MetricDetailSourceRow(source: source)
            }
          }
        }
        .padding(.top, NBSpacing.small)
      } label: {
        HStack(spacing: NBSpacing.small) {
          Image(systemName: "line.3.horizontal.decrease.circle")
            .foregroundStyle(NBColor.privacyTint)
          Text("출처와 필터")
            .font(NBTypography.callout.weight(.semibold))
            .foregroundStyle(NBColor.primaryText)
          Spacer()
          Text("\(viewModel.aggregationSourceBreakdown.count)개")
            .font(NBTypography.captionEmphasis)
            .foregroundStyle(NBColor.secondaryText)
        }
      }
    }
  }

  private var rangeTitle: String {
    let range = viewModel.aggregationDateRange
    switch aggregationInterval {
    case .day:
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "ko_KR")
      formatter.dateFormat = "yyyy년 M월"
      return formatter.string(from: range.start)
    case .week:
      return "\(SleepFormatters.shortDate(range.start))~\(SleepFormatters.shortDate(range.end))"
    case .month:
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "ko_KR")
      formatter.dateFormat = "yyyy.MM"
      return "\(formatter.string(from: range.start))~\(formatter.string(from: range.end))"
    }
  }

  private var horizontalPagingGesture: some Gesture {
    DragGesture(minimumDistance: 36)
      .onEnded { value in
        guard value.startLocation.x > 44,
              abs(value.translation.width) > abs(value.translation.height),
              abs(value.translation.width) > 48 else {
          return
        }
        moveRange(by: value.translation.width < 0 ? 1 : -1)
      }
  }

  private func moveRange(by offset: Int) {
    rangeAnchorDate = aggregationInterval.movingAnchor(
      rangeAnchorDate,
      byPageOffset: offset
    )
  }

  private static func aggregationInterval(for period: MetricDetailPeriod) -> MetricAggregationInterval {
    switch period {
    case .sevenDays, .thirtyDays:
      .day
    case .ninetyDays:
      .week
    case .oneYear, .all:
      .month
    }
  }

}

private struct MetricRangeNavigator: View {
  let title: String
  let onPrevious: () -> Void
  let onNext: () -> Void
  let onToday: () -> Void

  var body: some View {
    HStack(spacing: NBSpacing.small) {
      Button(action: onPrevious) {
        Image(systemName: "chevron.left")
          .frame(width: 34, height: 34)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("이전 구간")

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(NBTypography.subheadline.weight(.semibold))
          .foregroundStyle(NBColor.primaryText)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Button(action: onToday) {
        Text("최근")
          .font(NBTypography.caption.weight(.semibold))
          .foregroundStyle(NBColor.privacyTint)
          .padding(.horizontal, 10)
          .padding(.vertical, 7)
          .background(NBColor.privacyTint.opacity(0.10))
          .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
      }
      .buttonStyle(.plain)

      Button(action: onNext) {
        Image(systemName: "chevron.right")
          .frame(width: 34, height: 34)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("다음 구간")
    }
    .padding(.vertical, 2)
  }
}

struct MetricAggregationIntervalPicker: View {
  @Binding var selection: MetricAggregationInterval

  var body: some View {
    NBCard {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        Label("그래프 단위", systemImage: "chart.bar.xaxis")
          .font(NBTypography.subheadline)
          .foregroundStyle(NBColor.primaryText)

        Picker("그래프 단위", selection: $selection) {
          ForEach(MetricAggregationInterval.allCases) { interval in
            Text(interval.displayName).tag(interval)
          }
        }
        .pickerStyle(.segmented)
      }
    }
  }
}

private struct MetricDetailSourceFilterMenu: View {
  @Binding var selection: MetricDetailSourceFilter

  var body: some View {
    HStack(spacing: NBSpacing.medium) {
      Label("출처 필터", systemImage: "line.3.horizontal.decrease.circle")
        .font(NBTypography.subheadline)
        .foregroundStyle(NBColor.primaryText)

      Spacer()

      Menu {
        ForEach(options) { option in
          Button {
            selection = option
          } label: {
            Label(option.displayName, systemImage: selection == option ? "checkmark" : "circle")
          }
        }
      } label: {
        Label(selection.displayName, systemImage: "chevron.down")
          .font(.caption.weight(.semibold))
          .foregroundStyle(NBColor.privacyTint)
          .padding(.horizontal, NBSpacing.medium)
          .padding(.vertical, NBSpacing.small)
          .background(NBColor.privacyTint.opacity(0.10))
          .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
      }
    }
  }

  private var options: [MetricDetailSourceFilter] {
    #if DEBUG
    MetricDetailSourceFilter.allCases
    #else
    MetricDetailSourceFilter.allCases.filter { $0 != .mock }
    #endif
  }
}

private struct MetricDetailSourceRow: View {
  let source: MetricSourceBreakdown

  var body: some View {
    HStack(alignment: .top, spacing: NBSpacing.small) {
      Image(systemName: sourceIcon(for: source.sourceType))
        .font(.caption.weight(.semibold))
        .foregroundStyle(sourceTint(for: source.sourceType))
        .frame(width: 24, height: 24)
        .background(sourceTint(for: source.sourceType).opacity(0.10), in: RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 3) {
        HStack(alignment: .firstTextBaseline, spacing: NBSpacing.small) {
          Text(source.sourceType.displayName)
            .font(NBTypography.subheadline.weight(.semibold))
            .foregroundStyle(NBColor.primaryText)
          Spacer()
          Text("\(source.sampleCount)개")
            .font(NBTypography.captionEmphasis)
            .foregroundStyle(NBColor.secondaryText)
        }

        Text("\(source.sourceName) · 최근 \(SleepFormatters.shortDate(source.latestMeasuredAt))")
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(source.sourceType.displayName), \(source.sourceName), \(source.sampleCount)개")
  }
}

struct MetricChartView: View {
  let metric: MetricDisplayMetadata
  let points: [MetricTrendDataPoint]
  let interval: MetricAggregationInterval
  var tint: Color = NBColor.privacyTint
  let rangeTitle: String
  let onPreviousRange: () -> Void
  let onNextRange: () -> Void
  let onTodayRange: () -> Void
  var referenceRange: MetricReferenceRange?

  @State private var selectedPointID: UUID?

  var body: some View {
    NBReportSection(title: "그래프", systemImage: "chart.xyaxis.line") {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        MetricRangeNavigator(
          title: rangeTitle,
          onPrevious: onPreviousRange,
          onNext: onNextRange,
          onToday: onTodayRange
        )

        if points.isEmpty {
          NBEmptyStateView(
            title: "선택한 구간에 표시할 데이터가 없습니다",
            message: "그래프 단위를 바꾸거나 HealthKit 연결과 Fitdays CSV 가져오기 상태를 확인하세요.",
            systemImage: "chart.xyaxis.line"
          )
        } else {
          Chart {
            ForEach(points) { point in
              LineMark(
                x: .value("날짜", point.date),
                y: .value(metric.displayNameKo, point.value)
              )
              .foregroundStyle(tint)
              .interpolationMethod(.catmullRom)

              PointMark(
                x: .value("날짜", point.date),
                y: .value(metric.displayNameKo, point.value)
              )
              .foregroundStyle(tint)
              .symbolSize(48)
            }

            if let selectedPoint {
              RuleMark(x: .value("선택 구간", selectedPoint.date))
                .foregroundStyle(tint.opacity(0.42))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))

              PointMark(
                x: .value("선택 날짜", selectedPoint.date),
                y: .value(metric.displayNameKo, selectedPoint.value)
              )
              .foregroundStyle(tint)
              .symbolSize(118)
            }

            if let referenceRange,
               let lowerValue = referenceRange.lowerValue,
               shouldDrawReferenceValue(lowerValue) {
              RuleMark(y: .value("참고 범위 하단", lowerValue))
                .foregroundStyle(referenceRange.tint.opacity(0.76))
                .lineStyle(referenceRangeLineStyle)
            }

            if let referenceRange,
               let upperValue = referenceRange.upperValue,
               shouldDrawReferenceValue(upperValue) {
              RuleMark(y: .value("참고 범위 상단", upperValue))
                .foregroundStyle(referenceRange.tint.opacity(0.88))
                .lineStyle(referenceRangeLineStyle)
            }

            if let averageValue {
              RuleMark(y: .value("평균선", averageValue))
                .foregroundStyle(NBColor.secondaryText.opacity(0.65))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
          }
          .chartOverlay { proxy in
            GeometryReader { geometry in
              ZStack(alignment: .topLeading) {
                Rectangle()
                  .fill(.clear)
                  .contentShape(Rectangle())
                  .gesture(
                    SpatialTapGesture()
                      .onEnded { value in
                        selectNearestPoint(at: value.location, proxy: proxy, geometry: geometry)
                      }
                  )

                if let averageValue,
                   let position = averageOverlayPosition(proxy: proxy, geometry: geometry) {
                  MetricChartOverlayLabel(
                    title: "구간 평균",
                    value: formattedValue(averageValue),
                    tint: NBColor.secondaryText
                  )
                  .frame(width: averageOverlayLabelSize.width, height: averageOverlayLabelSize.height)
                  .position(position)
                  .allowsHitTesting(false)
                }

                if let selectedPoint,
                   let position = selectedOverlayPosition(
                    selectedPoint,
                    proxy: proxy,
                    geometry: geometry
                   ) {
                  MetricChartOverlayLabel(
                    title: selectedPointTitle(selectedPoint),
                    value: formattedValue(selectedPoint.value),
                    tint: tint,
                    isEmphasized: true
                  )
                  .frame(width: selectedOverlayLabelSize.width, height: selectedOverlayLabelSize.height)
                  .position(position)
                  .allowsHitTesting(false)
                }
              }
            }
          }
          .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) {
              AxisGridLine()
                .foregroundStyle(NBColor.divider)
              if interval == .month {
                AxisValueLabel(format: .dateTime.year().month())
                  .foregroundStyle(NBColor.secondaryText)
              } else {
                AxisValueLabel(format: .dateTime.month().day())
                  .foregroundStyle(NBColor.secondaryText)
              }
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
          .frame(height: 190)
          .accessibilityLabel("\(metric.displayNameKo) 추세 그래프")

          chartSummaryStrip
          referenceRangeLegend
        }
      }
    }
  }

  private var chartSummaryStrip: some View {
    HStack(spacing: NBSpacing.small) {
      MetricChartSummaryPill(
        title: "최근",
        value: latestPoint.map { formattedValue($0.value) } ?? "--"
      )
      MetricChartSummaryPill(
        title: "구간 평균",
        value: averageValue.map(formattedValue) ?? "--"
      )
      MetricChartSummaryPill(
        title: "범위",
        value: rangeText
      )
    }
  }

  @ViewBuilder
  private var referenceRangeLegend: some View {
    if let referenceRange {
      HStack(spacing: 6) {
        ReferenceRangeLegendLine(tint: referenceRange.tint)
          .frame(width: 28, height: 10)
          .accessibilityHidden(true)
        Text("\(referenceRange.label) · \(referenceRange.rangeText)\(referenceRangeVisibilityText)")
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityElement(children: .combine)
    }
  }

  private var averageValue: Double? {
    guard !points.isEmpty else { return nil }
    return points.map(\.value).reduce(0, +) / Double(points.count)
  }

  private var latestPoint: MetricTrendDataPoint? {
    points.max { $0.date < $1.date }
  }

  private var selectedPoint: MetricTrendDataPoint? {
    guard let selectedPointID else {
      return nil
    }
    return points.first { $0.id == selectedPointID }
  }

  private var rangeText: String {
    let values = points.map(\.value)
    guard let minimum = values.min(), let maximum = values.max() else {
      return "--"
    }
    return "\(formattedValue(minimum))~\(formattedValue(maximum))"
  }

  private func formattedValue(_ value: Double) -> String {
    UnifiedMetricFormatting.valueString(value, unit: metric.unit)
  }

  private func selectNearestPoint(
    at location: CGPoint,
    proxy: ChartProxy,
    geometry: GeometryProxy
  ) {
    guard !points.isEmpty else {
      selectedPointID = nil
      return
    }

    guard let plotFrame = plotFrame(proxy: proxy, geometry: geometry) else {
      return
    }
    guard plotFrame.contains(location) else {
      return
    }

    let xPosition = location.x - plotFrame.origin.x
    guard let selectedDate = proxy.value(atX: xPosition, as: Date.self) else {
      return
    }

    selectedPointID = nearestPoint(to: selectedDate)?.id
  }

  private func nearestPoint(to date: Date) -> MetricTrendDataPoint? {
    points.min { lhs, rhs in
      abs(lhs.date.timeIntervalSince(date)) < abs(rhs.date.timeIntervalSince(date))
    }
  }

  private func selectedPointTitle(_ point: MetricTrendDataPoint) -> String {
    switch interval {
    case .day:
      return dateTitle(point.date)
    case .week:
      return weekTitle(startingAt: point.date)
    case .month:
      return monthTitle(point.date)
    }
  }

  private func dateTitle(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "yyyy년 M월 d일"
    return formatter.string(from: date)
  }

  private func weekTitle(startingAt startDate: Date) -> String {
    let calendar = Calendar.current
    let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? startDate
    return "\(compactDateTitle(startDate))~\(compactDateTitle(endDate))"
  }

  private func monthTitle(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "yyyy년 M월"
    return formatter.string(from: date)
  }

  private func compactDateTitle(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "M월 d일"
    return formatter.string(from: date)
  }

  private func averageOverlayPosition(
    proxy: ChartProxy,
    geometry: GeometryProxy
  ) -> CGPoint? {
    guard let averageValue,
          let plotFrame = plotFrame(proxy: proxy, geometry: geometry),
          let yPosition = proxy.position(forY: averageValue) else {
      return nil
    }

    let y = plotFrame.minY + yPosition
    return clampedLabelCenter(
      CGPoint(
        x: averageOverlayFixedX(in: plotFrame),
        y: y - averageOverlayLabelSize.height / 2 - 8
      ),
      size: averageOverlayLabelSize,
      in: plotFrame
    )
  }

  private func averageOverlayFixedX(in plotFrame: CGRect) -> CGFloat {
    plotFrame.maxX - averageOverlayLabelSize.width / 2 - overlayLabelPadding
  }

  private func selectedOverlayPosition(
    _ point: MetricTrendDataPoint,
    proxy: ChartProxy,
    geometry: GeometryProxy
  ) -> CGPoint? {
    guard let plotFrame = plotFrame(proxy: proxy, geometry: geometry),
          let pointPosition = proxy.position(for: (x: point.date, y: point.value)) else {
      return nil
    }

    let pointLocation = CGPoint(
      x: plotFrame.minX + pointPosition.x,
      y: plotFrame.minY + pointPosition.y
    )
    let averageRect = averageOverlayPosition(proxy: proxy, geometry: geometry).map {
      labelRect(center: $0, size: averageOverlayLabelSize)
    }
    let candidateCenters = selectedOverlayCandidateCenters(
      near: pointLocation,
      in: plotFrame
    )

    for center in candidateCenters {
      let clamped = clampedLabelCenter(center, size: selectedOverlayLabelSize, in: plotFrame)
      let selectedRect = labelRect(center: clamped, size: selectedOverlayLabelSize)
      if averageRect?.intersects(selectedRect.insetBy(dx: -4, dy: -4)) != true {
        return clamped
      }
    }

    return candidateCenters.first.map {
      clampedLabelCenter($0, size: selectedOverlayLabelSize, in: plotFrame)
    }
  }

  private func selectedOverlayCandidateCenters(
    near point: CGPoint,
    in plotFrame: CGRect
  ) -> [CGPoint] {
    let above = CGPoint(
      x: point.x,
      y: point.y - selectedOverlayLabelSize.height / 2 - 12
    )
    let below = CGPoint(
      x: point.x,
      y: point.y + selectedOverlayLabelSize.height / 2 + 12
    )
    let left = CGPoint(
      x: point.x - selectedOverlayLabelSize.width / 2 - 14,
      y: point.y
    )
    let right = CGPoint(
      x: point.x + selectedOverlayLabelSize.width / 2 + 14,
      y: point.y
    )

    if point.y < plotFrame.midY {
      return point.x > plotFrame.midX ? [below, left, right, above] : [below, right, left, above]
    }
    return point.x > plotFrame.midX ? [above, left, right, below] : [above, right, left, below]
  }

  private func plotFrame(proxy: ChartProxy, geometry: GeometryProxy) -> CGRect? {
    guard let plotFrameAnchor = proxy.plotFrame else {
      return nil
    }
    return geometry[plotFrameAnchor]
  }

  private func clampedLabelCenter(
    _ center: CGPoint,
    size: CGSize,
    in plotFrame: CGRect
  ) -> CGPoint {
    let halfWidth = size.width / 2
    let halfHeight = size.height / 2
    return CGPoint(
      x: min(
        max(center.x, plotFrame.minX + halfWidth + overlayLabelPadding),
        plotFrame.maxX - halfWidth - overlayLabelPadding
      ),
      y: min(
        max(center.y, plotFrame.minY + halfHeight + overlayLabelPadding),
        plotFrame.maxY - halfHeight - overlayLabelPadding
      )
    )
  }

  private func labelRect(center: CGPoint, size: CGSize) -> CGRect {
    CGRect(
      x: center.x - size.width / 2,
      y: center.y - size.height / 2,
      width: size.width,
      height: size.height
    )
  }

  private var averageOverlayLabelSize: CGSize {
    CGSize(width: 132, height: 36)
  }

  private var selectedOverlayLabelSize: CGSize {
    CGSize(width: 168, height: 42)
  }

  private var overlayLabelPadding: CGFloat {
    6
  }

  private var yDomain: ClosedRange<Double> {
    let values = chartDataValues + referenceValuesForYDomain
    guard let minimum = values.min(), let maximum = values.max() else {
      return 0...1
    }

    if minimum == maximum {
      let padding = max(abs(minimum) * 0.015, minimumChartPadding * 2)
      return max(0, minimum - padding)...(maximum + padding)
    }

    let padding = max((maximum - minimum) * 0.25, minimumChartPadding)
    return max(0, minimum - padding)...(maximum + padding)
  }

  private var chartDataValues: [Double] {
    points.map(\.value).filter(\.isFinite)
  }

  private var referenceValuesForYDomain: [Double] {
    guard let referenceRange,
          !chartDataValues.isEmpty else {
      return []
    }
    return referenceRange.domainValues.filter(shouldIncludeReferenceValueInYDomain)
  }

  private func shouldDrawReferenceValue(_ value: Double) -> Bool {
    referenceValuesForYDomain.contains { abs($0 - value) < 0.0001 }
  }

  private func shouldIncludeReferenceValueInYDomain(_ value: Double) -> Bool {
    guard value.isFinite,
          let dataMinimum = chartDataValues.min(),
          let dataMaximum = chartDataValues.max() else {
      return false
    }

    if (dataMinimum...dataMaximum).contains(value) {
      return true
    }

    let distance: Double
    if value < dataMinimum {
      distance = dataMinimum - value
    } else {
      distance = value - dataMaximum
    }

    return distance <= nearbyReferenceBoundaryLimit
  }

  private var nearbyReferenceBoundaryLimit: Double {
    let values = chartDataValues
    guard let minimum = values.min(), let maximum = values.max() else {
      return minimumChartPadding * 8
    }

    let dataSpan = maximum - minimum
    let effectiveSpan = dataSpan > 0
      ? dataSpan
      : max(abs(maximum) * 0.02, minimumChartPadding * 2)
    return max(effectiveSpan * 2, minimumChartPadding * 8)
  }

  private var referenceRangeVisibilityText: String {
    guard let referenceRange else {
      return ""
    }

    let totalCount = referenceRange.domainValues.count
    let visibleCount = referenceValuesForYDomain.count
    guard totalCount > 0,
          visibleCount < totalCount else {
      return ""
    }

    return visibleCount > 0 ? " · 가까운 기준선만 표시" : " · 그래프 축 밖"
  }

  private var minimumChartPadding: Double {
    switch metric.metricID {
    case .systolicBloodPressure, .diastolicBloodPressure:
      4
    case .bodyMass, .leanBodyMass, .muscleMass, .skeletalMuscleMass:
      0.5
    case .bodyFatPercentage, .bodyMassIndex, .bodyWaterPercentage, .proteinPercentage,
         .subcutaneousFatPercentage, .visceralFatPercentage, .audioCoverageRatio:
      0.4
    case .stepCount:
      500
    case .activeEnergy, .basalMetabolicRate:
      40
    case .heartRate, .restingHeartRate:
      3
    case .sleepDuration:
      0.4
    case .respiratoryRate:
      0.4
    case .boneMass, .mineralMass:
      0.2
    case .visceralFatLevel, .metabolicAge, .bodyScore, .obesityLevel,
         .sleepSoundScore, .dailyRhythmScore:
      2
    }
  }

  private var referenceRangeLineStyle: StrokeStyle {
    StrokeStyle(lineWidth: 1.4, lineCap: .round, dash: [5, 4])
  }
}

private struct ReferenceRangeLegendLine: View {
  let tint: Color

  var body: some View {
    Path { path in
      path.move(to: CGPoint(x: 0, y: 5))
      path.addLine(to: CGPoint(x: 28, y: 5))
    }
    .stroke(tint, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, dash: [5, 4]))
  }
}

private struct MetricChartOverlayLabel: View {
  let title: String
  let value: String
  let tint: Color
  var isEmphasized = false

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(isEmphasized ? tint : NBColor.secondaryText)
        .lineLimit(1)
        .minimumScaleFactor(0.72)

      Text(value)
        .font(.caption.weight(.bold))
        .foregroundStyle(NBColor.primaryText)
        .lineLimit(1)
        .minimumScaleFactor(0.72)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .padding(.horizontal, 8)
    .background(NBColor.cardBackground.opacity(0.94), in: RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous)
        .stroke(tint.opacity(isEmphasized ? 0.42 : 0.24), lineWidth: 1)
    }
    .shadow(color: Color.black.opacity(0.06), radius: 6, y: 3)
  }
}

struct MetricReferenceRange {
  var label: String
  var lowerValue: Double?
  var upperValue: Double?
  var unit: String
  var tint: Color = NBColor.privacyTint

  var domainValues: [Double] {
    [lowerValue, upperValue].compactMap { $0 }
  }

  var rangeText: String {
    switch (lowerValue, upperValue) {
    case let (.some(lower), .some(upper)):
      "\(valueText(lower))~\(valueText(upper))"
    case let (.some(lower), .none):
      "\(valueText(lower)) 이상"
    case let (.none, .some(upper)):
      "\(valueText(upper)) 이하"
    case (.none, .none):
      "--"
    }
  }

  func valueText(_ value: Double) -> String {
    UnifiedMetricFormatting.valueString(value, unit: unit)
  }
}

private struct MetricChartSummaryPill: View {
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

struct MetricSummaryCard: View {
  let metric: MetricDisplayMetadata
  let summary: MetricStatisticsSummary
  let periodDisplayName: String
  let averageTitle: String
  let countLabel: String

  var body: some View {
    NBCard {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        HStack {
          Label("요약", systemImage: "list.bullet.rectangle")
            .font(.headline)
            .foregroundStyle(NBColor.primaryText)

          Spacer()

          Text(periodDisplayName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(NBColor.secondaryText)
        }

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.medium) {
          summaryTile("최근 값", summary.latestValue)
          summaryTile(averageTitle, summary.average)
          summaryTile("최소", summary.min)
          summaryTile("최대", summary.max)
        }

        HStack(spacing: NBSpacing.small) {
          NBStatusBadge("\(countLabel) \(summary.sampleCount)개", kind: .neutral, systemImage: "number")
          NBStatusBadge(deltaText, kind: .privacy, systemImage: "arrow.left.arrow.right")
        }

        if summary.firstMeasuredAt == nil && summary.latestMeasuredAt == nil {
          Text("선택한 기간에 계산할 샘플이 아직 없습니다.")
            .font(.caption)
            .foregroundStyle(NBColor.secondaryText)
        } else {
          VStack(alignment: .leading, spacing: 3) {
            if let firstMeasuredAt = summary.firstMeasuredAt {
              Text("첫 측정: \(SleepFormatters.shortDate(firstMeasuredAt)) \(SleepFormatters.shortTime(firstMeasuredAt))")
            }
            if let latestMeasuredAt = summary.latestMeasuredAt {
              Text("최근 측정: \(SleepFormatters.shortDate(latestMeasuredAt)) \(SleepFormatters.shortTime(latestMeasuredAt))")
            }
          }
          .font(.caption)
          .foregroundStyle(NBColor.secondaryText)
        }
      }
    }
  }

  private var deltaText: String {
    guard let delta = summary.deltaFromPreviousPeriod else {
      return "이전 기간 비교 샘플 부족"
    }
    return "최근 변화 \(UnifiedMetricFormatting.signedValueString(delta, unit: metric.unit))"
  }

  private func summaryTile(_ title: String, _ value: Double?) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.caption)
        .foregroundStyle(NBColor.secondaryText)
      Text(value.map { UnifiedMetricFormatting.valueString($0, unit: metric.unit) } ?? "--")
        .font(.callout.weight(.semibold))
        .foregroundStyle(NBColor.primaryText)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct MetricDetailSourceSummaryLine: View {
  let metric: MetricDisplayMetadata
  let sources: [MetricSourceBreakdown]

  var body: some View {
    Text(summaryText)
      .font(NBTypography.caption)
      .foregroundStyle(NBColor.secondaryText)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityLabel(summaryText)
  }

  private var summaryText: String {
    var parts: [String] = []
    if metric.isHealthKitBacked {
      parts.append("HealthKit read-only")
    }
    if metric.isExtendedLocalOnly {
      parts.append("로컬 전용")
    }
    if sources.isEmpty {
      parts.append("출처 없음")
    } else {
      let sourceText = sources
        .prefix(3)
        .map { $0.sourceType.displayName }
        .joined(separator: " · ")
      parts.append(sourceText)
    }
    parts.append("개인 참고용")
    return parts.joined(separator: " · ")
  }
}

struct MetricSourceBadgeStrip: View {
  let metadata: MetricDisplayMetadata
  let sourceTypes: [HealthMetricSourceType]

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: NBSpacing.small) {
        if metadata.isHealthKitBacked {
          NBStatusBadge("HealthKit 기반", kind: .privacy, systemImage: "heart.text.square")
        }

        if metadata.isExtendedLocalOnly {
          NBStatusBadge("로컬 전용", kind: .neutral, systemImage: "internaldrive")
        }

        ForEach(orderedSourceTypes) { sourceType in
          NBStatusBadge(
            sourceBadgeLabel(for: sourceType),
            kind: sourceBadgeKind(for: sourceType),
            systemImage: sourceIcon(for: sourceType)
          )
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .accessibilityLabel(accessibilityText)
  }

  private var orderedSourceTypes: [HealthMetricSourceType] {
    let sourceTypeSet = Set(sourceTypes)
    return HealthMetricSourceType.allCases.filter { sourceTypeSet.contains($0) }
  }

  private var accessibilityText: String {
    var parts: [String] = []
    if metadata.isHealthKitBacked {
      parts.append("HealthKit 기반")
    }
    if metadata.isExtendedLocalOnly {
      parts.append("로컬 전용")
    }
    parts.append(contentsOf: orderedSourceTypes.map { sourceBadgeLabel(for: $0) })
    return parts.joined(separator: ", ")
  }

  private func sourceBadgeLabel(for sourceType: HealthMetricSourceType) -> String {
    switch sourceType {
    case .healthKit:
      sourceType.displayName
    case .fitdaysCSV:
      "Fitdays CSV · 로컬"
    case .manual:
      "수동 입력 · 로컬"
    case .appComputed:
      sourceType.displayName
    case .mock:
      sourceType.displayName
    }
  }

  private func sourceBadgeKind(for sourceType: HealthMetricSourceType) -> NBStatusKind {
    switch sourceType {
    case .healthKit:
      .privacy
    case .fitdaysCSV:
      .neutral
    case .manual:
      .warning
    case .appComputed:
      .good
    case .mock:
      .debug
    }
  }
}

enum UnifiedMetricFormatting {
  static func valueString(_ value: Double, unit: String) -> String {
    switch unit {
    case "mmHg", "bpm", "걸음", "kcal", "점", "세", "레벨":
      return "\(Int(value.rounded())) \(unit)"
    case "BMI":
      return String(format: "%.1f", value)
    case "시간":
      return String(format: "%.1f시간", value)
    case "%":
      return String(format: "%.1f%%", value)
    case "":
      return String(format: "%.1f", value)
    default:
      return String(format: "%.1f %@", value, unit)
    }
  }

  static func signedValueString(_ value: Double, unit: String) -> String {
    let sign = value >= 0 ? "+" : ""
    return "\(sign)\(valueString(value, unit: unit))"
  }
}

func metricIcon(for metadata: MetricDisplayMetadata) -> String {
  switch metadata.metricID {
  case .systolicBloodPressure, .diastolicBloodPressure, .heartRate, .restingHeartRate:
    "heart"
  case .bodyMass, .bodyFatPercentage, .bodyMassIndex, .leanBodyMass,
       .visceralFatLevel, .visceralFatPercentage, .bodyWaterPercentage,
       .boneMass, .mineralMass, .skeletalMuscleMass, .muscleMass,
       .proteinPercentage, .subcutaneousFatPercentage, .metabolicAge,
       .bodyScore, .obesityLevel:
    "scalemass"
  case .stepCount:
    "figure.walk"
  case .activeEnergy, .basalMetabolicRate:
    "flame"
  case .sleepDuration:
    "bed.double"
  case .respiratoryRate:
    "lungs"
  case .sleepSoundScore:
    "waveform"
  case .dailyRhythmScore:
    "sun.max"
  case .audioCoverageRatio:
    "gauge.with.dots.needle.bottom.50percent"
  }
}

func metricTint(for metadata: MetricDisplayMetadata) -> Color {
  switch metadata.category {
  case .sleep:
    NBColor.sleepTint
  case .bloodPressure:
    NBColor.danger
  case .bodyComposition:
    metadata.isExtendedLocalOnly ? NBColor.mistTeal : NBColor.breathBlue
  case .activity:
    NBColor.success
  case .recovery:
    NBColor.privacyTint
  case .app:
    NBColor.dawn
  }
}

private func sourceIcon(for sourceType: HealthMetricSourceType) -> String {
  switch sourceType {
  case .healthKit:
    "heart.text.square"
  case .fitdaysCSV:
    "square.and.arrow.down"
  case .manual:
    "pencil"
  case .appComputed:
    "sparkles"
  case .mock:
    "testtube.2"
  }
}

private func sourceTint(for sourceType: HealthMetricSourceType) -> Color {
  switch sourceType {
  case .healthKit:
    NBColor.privacyTint
  case .fitdaysCSV:
    NBColor.mistTeal
  case .manual:
    NBColor.warning
  case .appComputed:
    NBColor.dawn
  case .mock:
    NBColor.lavender
  }
}

#if DEBUG
struct HealthMetricsOverviewView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      HealthMetricsOverviewView(
        samples: previewSamples,
        permissionState: .mockDataOnly,
        isPreviewData: true
      )
    }
  }

  private static var previewSamples: [UnifiedHealthMetricSample] {
    let mockHealthSamples = MockHealthDataService().samples.map {
      $0.unifiedSample(sourceType: .mock)
    }
    let now = Date()
    let fitdaysSamples = [
      UnifiedHealthMetricSample(
        metricID: .bodyWaterPercentage,
        value: 56.8,
        unit: "%",
        measuredAt: now.addingTimeInterval(-24 * 60 * 60),
        sourceType: .fitdaysCSV,
        sourceName: "Fitdays CSV Import"
      ),
      UnifiedHealthMetricSample(
        metricID: .skeletalMuscleMass,
        value: 31.2,
        unit: "kg",
        measuredAt: now.addingTimeInterval(-24 * 60 * 60),
        sourceType: .fitdaysCSV,
        sourceName: "Fitdays CSV Import"
      ),
      UnifiedHealthMetricSample(
        metricID: .basalMetabolicRate,
        value: 1_520,
        unit: "kcal/day",
        measuredAt: now.addingTimeInterval(-24 * 60 * 60),
        sourceType: .fitdaysCSV,
        sourceName: "Fitdays CSV Import"
      ),
    ]
    return mockHealthSamples + fitdaysSamples
  }
}
#endif
