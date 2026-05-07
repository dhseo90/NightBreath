import Charts
import SwiftUI

struct HealthMetricsOverviewView: View {
  let samples: [UnifiedHealthMetricSample]
  let permissionState: HealthMetricPermissionState
  let isPreviewData: Bool

  @State private var selectedPeriod: HealthMetricTrendPeriod = .thirtyDays

  private let catalog = MetricCatalog.default
  private let calculator = MetricStatisticsCalculator()
  private let grouping = UnifiedHealthMetricOverviewGrouping()

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        header
        stateNotice
        HealthMetricPeriodPicker(selection: $selectedPeriod)

        if samples.isEmpty {
          HealthDataEmptyStateView(
            title: "표시할 건강 지표 샘플이 없습니다",
            message: "Apple 건강앱 read-only 연결 또는 Fitdays CSV 가져오기를 통해 샘플을 추가하면 지표별 통계와 그래프를 볼 수 있습니다."
          )
        } else {
          ForEach(grouping.groups()) { group in
            metricGroupSection(group)
          }
        }

        NBPrivacyNoticeCard(
          title: "개인 참고용 통계",
          messages: [
            "HealthKit read-only 샘플과 로컬 import 샘플을 한곳에서 정리합니다.",
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
  }

  private var selectedDateRange: HealthMetricDateRange {
    selectedPeriod.dateRange()
  }

  private var header: some View {
    NBReportSection(title: "전체 건강 지표", systemImage: "chart.line.uptrend.xyaxis") {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        Text("혈압, 체성분, 활동, 수면/앱 지표와 Fitdays 확장 지표를 기간별로 정리합니다.")
          .font(NBTypography.callout)
          .foregroundStyle(NBColor.secondaryText)

        Text("최근 값, 평균, 최소, 최대, 최근 변화와 측정 횟수를 출처별로 구분해 볼 수 있습니다.")
          .font(NBTypography.footnote)
          .foregroundStyle(NBColor.tertiaryText)
      }
    }
  }

  @ViewBuilder
  private var stateNotice: some View {
    if isPreviewData {
      NBStatusBadge(
        "연결 전 샘플은 예시 미리보기로 표시됩니다.",
        kind: .neutral,
        systemImage: "eye"
      )
    }

    switch permissionState {
    case .denied:
      NBStatusBadge(
        "Apple 건강앱 권한이 없어도 로컬 import 샘플은 볼 수 있습니다.",
        kind: .caution,
        systemImage: "lock.slash"
      )
    case .unavailable:
      NBStatusBadge(
        "HealthKit을 사용할 수 없어도 로컬 import 샘플은 볼 수 있습니다.",
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
                selectedPeriod: selectedPeriod
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
    let summary = calculator.summary(
      samples: samples,
      metricID: metadata.metricID,
      dateRange: selectedDateRange
    )
    let sources = calculator.sourceBreakdown(
      samples: samples,
      metricID: metadata.metricID,
      dateRange: selectedDateRange
    )

    return HStack(alignment: .center, spacing: NBSpacing.medium) {
      VStack(alignment: .leading, spacing: 0) {
        NBListRow(
          title: metadata.displayNameKo,
          value: summary.latestValue.map { UnifiedMetricFormatting.valueString($0, unit: metadata.unit) } ?? "--",
          subtitle: metricRowSubtitle(summary: summary, sources: sources),
          systemImage: metricIcon(for: metadata),
          tint: metricTint(for: metadata),
          accessibilityLabel: "\(metadata.displayNameKo), 샘플 \(summary.sampleCount)개"
        )

        MetricSourceBadgeStrip(
          metadata: metadata,
          sourceTypes: sources.map(\.sourceType)
        )
        .padding(.leading, 40)
        .padding(.bottom, NBSpacing.small)
      }

      Spacer()

      Image(systemName: "chevron.right")
        .font(.caption.weight(.semibold))
        .foregroundStyle(NBColor.tertiaryText)
    }
  }

  private func metricRowSubtitle(
    summary: MetricStatisticsSummary,
    sources: [MetricSourceBreakdown]
  ) -> String {
    var parts: [String] = ["\(selectedPeriod.displayName) 샘플 \(summary.sampleCount)개"]

    if let latestMeasuredAt = summary.latestMeasuredAt {
      parts.append("최근 \(SleepFormatters.shortDate(latestMeasuredAt))")
    }

    if !sources.isEmpty {
      let sourceNames = sources.prefix(2).map { $0.sourceType.displayName }.joined(separator: ", ")
      parts.append(sourceNames)
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

  @State private var period: MetricDetailPeriod
  @State private var sourceFilter: MetricDetailSourceFilter = .all

  private let catalog = MetricCatalog.default

  init(
    metric: MetricDisplayMetadata,
    samples: [UnifiedHealthMetricSample],
    selectedPeriod: HealthMetricTrendPeriod = .thirtyDays
  ) {
    self.metricID = metric.metricID
    self.samples = samples
    _period = State(initialValue: MetricDetailPeriod(trendPeriod: selectedPeriod))
  }

  init(
    metricID: UnifiedHealthMetricID,
    samples: [UnifiedHealthMetricSample],
    selectedPeriod: MetricDetailPeriod = .thirtyDays
  ) {
    self.metricID = metricID
    self.samples = samples
    _period = State(initialValue: selectedPeriod)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        header
        controls

        if let emptyState = viewModel.emptyStateReason {
          HealthDataEmptyStateView(
            title: emptyState.title,
            message: emptyState.message
          )
        }

        MetricSummaryCard(
          metric: metric,
          summary: viewModel.summary,
          sources: viewModel.sourceBreakdown,
          periodDisplayName: period.displayName
        )

        MetricChartView(
          metric: metric,
          points: viewModel.points,
          tint: metricTint(for: metric)
        )

        rawSampleListSection
        sourceSection
        manualInputPlaceholder

        NBPrivacyNoticeCard(
          title: "지표 안내",
          messages: MetricDetailExplanation.make(for: metric).messages,
          systemImage: "info.circle"
        )
      }
      .padding(NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
    .navigationTitle(metric.displayNameKo)
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
      period: period,
      sourceFilter: sourceFilter,
      catalog: catalog
    )
  }

  private var controls: some View {
    VStack(alignment: .leading, spacing: NBSpacing.medium) {
      MetricDetailPeriodPicker(selection: $period)
      MetricDetailSourceFilterMenu(selection: $sourceFilter)
    }
  }

  private var header: some View {
    NBReportSection(title: metric.displayNameKo, systemImage: metricIcon(for: metric)) {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        MetricSourceBadgeStrip(
          metadata: metric,
          sourceTypes: viewModel.metricSamples.map(\.sourceType)
        )

        MetricSourceContextNotice(
          metadata: metric,
          sourceTypes: viewModel.metricSamples.map(\.sourceType)
        )

        Text(metric.description)
          .font(NBTypography.callout)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.small) {
          NBMetricCard(
            title: "최근 값",
            value: viewModel.latestSample.map { UnifiedMetricFormatting.valueString($0.value, unit: $0.unit) } ?? "--",
            systemImage: metricIcon(for: metric),
            tint: metricTint(for: metric)
          )
          NBMetricCard(
            title: "단위",
            value: metric.unit.isEmpty ? "--" : metric.unit,
            systemImage: "ruler",
            tint: NBColor.privacyTint
          )
          NBMetricCard(
            title: "최근 측정",
            value: viewModel.latestSample.map { SleepFormatters.shortDate($0.measuredAt) } ?? "--",
            systemImage: "clock",
            tint: NBColor.dawn
          )
          NBMetricCard(
            title: "데이터 출처",
            value: viewModel.latestSample?.sourceType.displayName ?? "--",
            systemImage: "square.stack.3d.up",
            tint: NBColor.mistTeal
          )
        }
      }
    }
  }

  private var rawSampleListSection: some View {
    NBReportSection(title: "기록 목록", systemImage: "list.bullet.rectangle") {
      if viewModel.rawSampleList.isEmpty {
        NBEmptyStateView(
          title: "표시할 기록이 없습니다",
          message: "기간 또는 출처 필터를 바꾸면 다른 기록을 볼 수 있습니다.",
          systemImage: "tray"
        )
      } else {
        VStack(alignment: .leading, spacing: NBSpacing.small) {
          ForEach(viewModel.rawSampleList) { sample in
            MetricSampleListRow(
              sample: sample,
              metric: metric
            )
          }
        }
      }
    }
  }

  private var sourceSection: some View {
    NBReportSection(title: "데이터 출처", systemImage: "square.stack.3d.up") {
      if viewModel.sourceBreakdown.isEmpty {
        NBEmptyStateView(
          title: "선택한 기간에 출처가 없습니다",
          message: "다른 기간이나 출처 필터를 선택해 보세요.",
          systemImage: "tray"
        )
      } else {
        VStack(alignment: .leading, spacing: NBSpacing.small) {
          ForEach(viewModel.sourceBreakdown) { source in
            NBListRow(
              title: source.sourceType.displayName,
              value: "\(source.sampleCount)개",
              subtitle: "\(source.sourceName) · 최근 \(SleepFormatters.shortDate(source.latestMeasuredAt)) \(SleepFormatters.shortTime(source.latestMeasuredAt))",
              systemImage: sourceIcon(for: source.sourceType),
              tint: sourceTint(for: source.sourceType)
            )
          }
        }
      }
    }
  }

  private var manualInputPlaceholder: some View {
    NBReportSection(title: "수동 입력", systemImage: "pencil") {
      NBSecondaryButton(
        title: "수동 입력은 다음 작업에서 추가",
        systemImage: "plus",
        isDisabled: true
      ) {}
    }
  }
}

private struct MetricDetailPeriodPicker: View {
  @Binding var selection: MetricDetailPeriod

  var body: some View {
    NBCard {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        Label("기간 선택", systemImage: "calendar")
          .font(NBTypography.subheadline)
          .foregroundStyle(NBColor.primaryText)

        Picker("기간 선택", selection: $selection) {
          ForEach(MetricDetailPeriod.allCases) { period in
            Text(period.displayName).tag(period)
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
    NBCard {
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
  }

  private var options: [MetricDetailSourceFilter] {
    #if DEBUG
    MetricDetailSourceFilter.allCases
    #else
    MetricDetailSourceFilter.allCases.filter { $0 != .mock }
    #endif
  }
}

private struct MetricSampleListRow: View {
  let sample: UnifiedHealthMetricSample
  let metric: MetricDisplayMetadata

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      NBListRow(
        title: "\(SleepFormatters.shortDate(sample.measuredAt)) \(SleepFormatters.shortTime(sample.measuredAt))",
        value: UnifiedMetricFormatting.valueString(sample.value, unit: sample.unit),
        subtitle: "\(sample.sourceType.displayName) · \(sample.sourceName)",
        systemImage: sourceIcon(for: sample.sourceType),
        tint: sourceTint(for: sample.sourceType),
        accessibilityLabel: "\(metric.displayNameKo), \(UnifiedMetricFormatting.valueString(sample.value, unit: sample.unit))"
      )

      VStack(alignment: .leading, spacing: 3) {
        ForEach(sourceNotes, id: \.self) { note in
          Text(note)
        }
        if let notes = sample.notes, !notes.isEmpty {
          Text(notes)
        }
      }
      .font(NBTypography.caption)
      .foregroundStyle(NBColor.tertiaryText)
      .padding(.leading, 34)
    }
  }

  private var sourceNotes: [String] {
    var notes: [String] = []

    switch sample.sourceType {
    case .fitdaysCSV:
      notes.append("Fitdays CSV 로컬 import 샘플")
      notes.append("HealthKit에 저장하지 않음")
    case .manual:
      notes.append("기기 안에 저장된 수동 입력 샘플")
    case .appComputed:
      notes.append("밤숨 앱에서 기기 안에서 계산한 샘플")
    case .healthKit:
      notes.append("Apple 건강앱 read-only 샘플")
    case .mock:
      notes.append("예시 데이터 샘플")
    }

    if sample.importBatchId?.isEmpty == false {
      notes.append("가져오기 기록에 연결된 샘플")
    }

    if metric.isExtendedLocalOnly {
      notes.append("로컬 전용 지표")
    }

    return notes
  }
}

struct MetricChartView: View {
  let metric: MetricDisplayMetadata
  let points: [MetricTrendDataPoint]
  var tint: Color = NBColor.privacyTint

  var body: some View {
    NBReportSection(title: "그래프", systemImage: "chart.xyaxis.line") {
      if points.isEmpty {
        NBEmptyStateView(
          title: "선택한 기간에 표시할 샘플이 없습니다",
          message: "기간을 바꾸거나 HealthKit 연결, Fitdays CSV 가져오기 상태를 확인하세요.",
          systemImage: "chart.xyaxis.line"
        )
      } else {
        VStack(alignment: .leading, spacing: NBSpacing.medium) {
          Chart(points) { point in
            LineMark(
              x: .value("날짜", point.date),
              y: .value(metric.displayNameKo, point.value)
            )
            .foregroundStyle(by: .value("데이터 출처", sourceLabel(point)))
            .interpolationMethod(.catmullRom)

            PointMark(
              x: .value("날짜", point.date),
              y: .value(metric.displayNameKo, point.value)
            )
            .foregroundStyle(by: .value("데이터 출처", sourceLabel(point)))
            .symbolSize(48)
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
          .frame(height: 190)
          .accessibilityLabel("\(metric.displayNameKo) 추세 그래프")

          sourceLegend
        }
      }
    }
  }

  private var sourceLegend: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(uniqueSourceLabels, id: \.self) { source in
          Label(source, systemImage: "circle.fill")
            .font(.caption)
            .foregroundStyle(tint)
            .lineLimit(1)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private var uniqueSourceLabels: [String] {
    var seen = Set<String>()
    return points
      .map(sourceLabel)
      .filter { seen.insert($0).inserted }
  }

  private func sourceLabel(_ point: MetricTrendDataPoint) -> String {
    "\(point.sourceType.displayName) · \(point.sourceName)"
  }

  private var yDomain: ClosedRange<Double> {
    let values = points.map(\.value)
    guard let minimum = values.min(), let maximum = values.max() else {
      return 0...1
    }

    if minimum == maximum {
      let padding = max(abs(minimum) * 0.08, minimumChartPadding)
      return max(0, minimum - padding)...(maximum + padding)
    }

    let padding = max((maximum - minimum) * 0.25, minimumChartPadding)
    return max(0, minimum - padding)...(maximum + padding)
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
}

struct MetricSummaryCard: View {
  let metric: MetricDisplayMetadata
  let summary: MetricStatisticsSummary
  let sources: [MetricSourceBreakdown]
  let periodDisplayName: String

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
          summaryTile("평균", summary.average)
          summaryTile("최소", summary.min)
          summaryTile("최대", summary.max)
        }

        HStack(spacing: NBSpacing.small) {
          NBStatusBadge("측정 \(summary.sampleCount)개", kind: .neutral, systemImage: "number")
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

        Text(sourceText)
          .font(.caption)
          .foregroundStyle(NBColor.tertiaryText)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private var deltaText: String {
    guard let delta = summary.deltaFromPreviousPeriod else {
      return "이전 기간 비교 샘플 부족"
    }
    return "최근 변화 \(UnifiedMetricFormatting.signedValueString(delta, unit: metric.unit))"
  }

  private var sourceText: String {
    guard !sources.isEmpty else {
      return "데이터 출처: 없음"
    }
    return "데이터 출처: " + sources
      .map { "\($0.sourceType.displayName) \(sourceNameText($0.sourceName))" }
      .joined(separator: " · ")
  }

  private func sourceNameText(_ sourceName: String) -> String {
    sourceName.isEmpty ? "" : "(\(sourceName))"
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

private struct MetricSourceContextNotice: View {
  let metadata: MetricDisplayMetadata
  let sourceTypes: [HealthMetricSourceType]

  private var summary: MetricDetailSourceSummary {
    MetricDetailSourceSummary.make(for: metadata, sourceTypes: sourceTypes)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: NBSpacing.xSmall) {
      Label("출처 구분", systemImage: "square.stack.3d.up")
        .font(NBTypography.caption.weight(.semibold))
        .foregroundStyle(NBColor.primaryText)

      ForEach(summary.messages, id: \.self) { message in
        Text(message)
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
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

private func metricIcon(for metadata: MetricDisplayMetadata) -> String {
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

private func metricTint(for metadata: MetricDisplayMetadata) -> Color {
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
