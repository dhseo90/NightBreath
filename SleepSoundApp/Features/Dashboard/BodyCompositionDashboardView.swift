import SwiftUI

struct BodyCompositionDashboardView: View {
  let samples: [UnifiedHealthMetricSample]
  let permissionState: HealthMetricPermissionState
  let isPreviewData: Bool

  @State private var selectedMetricID: UnifiedHealthMetricID = .bodyMass
  @State private var aggregationInterval: MetricAggregationInterval = .day
  @State private var rangeAnchorDate = Date()
  @State private var isReferenceDetailsExpanded = false
  @State private var heightCentimetersText = ""
  @AppStorage("nightbreath.bodyComposition.referenceHeightCentimeters")
  private var referenceHeightCentimeters: Double = 0
  @FocusState private var isHeightInputFocused: Bool

  private let analyzer = BodyCompositionReferenceAnalyzer()
  private let calculator = MetricStatisticsCalculator()
  private let catalog = MetricCatalog.default

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        HealthDataAccessStateView(
          permissionState: permissionState,
          isPreviewData: isPreviewData
        )

        if shouldShowDashboardContent {
          if bodyCompositionSamples.isEmpty {
            HealthDataEmptyStateView(
              title: "표시할 체성분 기록이 없습니다",
              message: "Apple 건강앱 read-only 연결 또는 Fitdays CSV 가져오기를 통해 체중, BMI, 체지방률, 근육량 기록을 추가하면 종합 보기를 볼 수 있습니다."
            )
          } else {
            heightInputSection
            referenceSummarySection
            graphControlSection
            graphSection
            trendNoticeSection
            latestValuesSection
            referenceDetailsSection
          }
        }

        NBPrivacyNoticeCard(
          title: "개인 참고용 체성분 보기",
          messages: [
            "BMI 참고 구간과 최근 변화만 기기 안에서 계산합니다.",
            "근육량 계열은 고정 기준보다 같은 출처의 변화 흐름을 우선 표시합니다.",
            "HealthKit에 데이터를 쓰지 않고 서버로 전송하지 않습니다.",
          ],
          systemImage: "lock.shield"
        )
      }
      .padding(NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
    .navigationTitle("체성분 종합")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItemGroup(placement: .keyboard) {
        Spacer()
        Button("완료") {
          commitHeightInput()
        }
      }
    }
    .onAppear(perform: syncHeightInputText)
  }

  private var shouldShowDashboardContent: Bool {
    switch permissionState {
    case .denied, .unavailable:
      !bodyCompositionSamples.isEmpty
    case .notRequested, .mockDataOnly, .readRequestCompleted:
      true
    }
  }

  private var bodyCompositionSamples: [UnifiedHealthMetricSample] {
    let metricIDs = Set(BodyCompositionReferenceAnalyzer.metricIDs)
    return samples
      .filter { metricIDs.contains($0.metricID) }
      .sortedByMeasuredAtAscending()
  }

  private var summary: BodyCompositionReferenceSummary {
    analyzer.summary(samples: bodyCompositionSamples, endingAt: rangeAnchorDate)
  }

  private var referenceHeightMeters: Double? {
    guard (120...220).contains(referenceHeightCentimeters) else {
      return nil
    }
    return referenceHeightCentimeters / 100
  }

  private var parsedHeightCentimeters: Double? {
    let normalized = heightCentimetersText
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: ",", with: ".")
    guard let value = Double(normalized),
          (120...220).contains(value) else {
      return nil
    }
    return value
  }

  private var referenceBoundary: BodyCompositionReferenceBoundary? {
    analyzer.referenceBoundary(
      weightKg: summary.latestWeightKg,
      heightMeters: referenceHeightMeters,
      bmiCategory: summary.bmiCategory
    )
  }

  private var activeMetricID: UnifiedHealthMetricID {
    let availableIDs = availableGraphMetrics.map(\.metricID)
    if availableIDs.contains(selectedMetricID) {
      return selectedMetricID
    }
    return availableIDs.first ?? selectedMetricID
  }

  private var activeMetric: MetricDisplayMetadata? {
    catalog.metadata(for: activeMetricID)
  }

  private var selectedDateRange: HealthMetricDateRange {
    aggregationInterval.dateRange(anchorDate: rangeAnchorDate)
  }

  private var activePoints: [MetricTrendDataPoint] {
    calculator.aggregatedPoints(
      samples: bodyCompositionSamples,
      metricID: activeMetricID,
      dateRange: selectedDateRange,
      interval: aggregationInterval
    )
  }

  private var availableGraphMetrics: [MetricDisplayMetadata] {
    let availableIDs = Set(bodyCompositionSamples.map(\.metricID))
    let metricIDs: [UnifiedHealthMetricID] = [
      .bodyMass,
      .bodyMassIndex,
      .bodyFatPercentage,
      .skeletalMuscleMass,
      .muscleMass,
      .leanBodyMass,
      .bodyWaterPercentage,
      .visceralFatLevel,
      .basalMetabolicRate,
    ]

    return metricIDs
    .filter { availableIDs.contains($0) }
    .compactMap { catalog.metadata(for: $0) }
  }

  private var referenceSummarySection: some View {
    NBReportSection(title: "BMI 참고 구간", systemImage: "scalemass") {
      BodyCompositionReferenceSummaryCard(
        summary: summary,
        referenceBoundary: referenceBoundary,
        referenceHeightCentimeters: referenceHeightCentimeters
      )
    }
  }

  private var heightInputSection: some View {
    NBReportSection(title: "키 입력", systemImage: "ruler") {
      NBCard {
        VStack(alignment: .leading, spacing: NBSpacing.medium) {
          HStack(alignment: .firstTextBaseline, spacing: NBSpacing.small) {
            VStack(alignment: .leading, spacing: 3) {
              Text("체중 참고 범위 계산")
                .font(NBTypography.callout.weight(.semibold))
                .foregroundStyle(NBColor.primaryText)
              Text(heightInputHelpText)
                .font(NBTypography.caption)
                .foregroundStyle(NBColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: NBSpacing.small)

            if let referenceHeightMeters {
              Text(heightDisplayText(referenceHeightMeters * 100))
                .font(NBTypography.headline)
                .foregroundStyle(NBColor.privacyTint)
                .monospacedDigit()
                .lineLimit(1)
            }
          }

          HStack(spacing: NBSpacing.small) {
            TextField("예: 176", text: $heightCentimetersText)
              .keyboardType(.decimalPad)
              .textInputAutocapitalization(.never)
              .disableAutocorrection(true)
              .focused($isHeightInputFocused)
              .font(NBTypography.callout.monospacedDigit())
              .padding(.horizontal, NBSpacing.medium)
              .padding(.vertical, NBSpacing.small)
              .background(NBColor.cardBackground.opacity(0.78), in: RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
              .overlay {
                RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous)
                  .stroke(parsedHeightCentimeters == nil && !heightCentimetersText.isEmpty ? NBColor.warning.opacity(0.5) : NBColor.border.opacity(0.7), lineWidth: 1)
              }

            Text("cm")
              .font(NBTypography.callout)
              .foregroundStyle(NBColor.secondaryText)

            Button("저장") {
              commitHeightInput()
            }
            .buttonStyle(NBSecondaryButtonStyle())
            .disabled(parsedHeightCentimeters == nil)
          }

          if referenceHeightMeters != nil {
            Button("입력한 키 삭제") {
              clearReferenceHeight()
            }
            .font(NBTypography.captionEmphasis)
            .foregroundStyle(NBColor.secondaryText)
            .buttonStyle(.plain)
          }
        }
      }
    }
  }

  private var graphControlSection: some View {
    VStack(alignment: .leading, spacing: NBSpacing.medium) {
      if !availableGraphMetrics.isEmpty {
        NBCard {
          HStack(spacing: NBSpacing.medium) {
            Label("그래프 지표", systemImage: "waveform.path.ecg")
              .font(NBTypography.subheadline)
              .foregroundStyle(NBColor.primaryText)

            Spacer()

            Menu {
              ForEach(availableGraphMetrics) { metric in
                Button {
                  selectedMetricID = metric.metricID
                } label: {
                  Label(
                    metric.displayNameKo,
                    systemImage: activeMetricID == metric.metricID ? "checkmark" : "circle"
                  )
                }
              }
            } label: {
              Label(activeMetric?.displayNameKo ?? "지표 선택", systemImage: "chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(NBColor.privacyTint)
                .padding(.horizontal, NBSpacing.medium)
                .padding(.vertical, NBSpacing.small)
                .background(NBColor.privacyTint.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
            }
            .buttonStyle(.plain)
          }
        }
      }

      MetricAggregationIntervalPicker(selection: $aggregationInterval)
    }
  }

  @ViewBuilder
  private var graphSection: some View {
    if let activeMetric {
      MetricChartView(
        metric: activeMetric,
        points: activePoints,
        interval: aggregationInterval,
        tint: metricTint(for: activeMetric),
        rangeTitle: rangeTitle,
        onPreviousRange: { moveRange(by: -1) },
        onNextRange: { moveRange(by: 1) },
        onTodayRange: { rangeAnchorDate = Date() },
        referenceRange: graphReferenceRange
      )
      .gesture(horizontalPagingGesture)
    }
  }

  private var trendNoticeSection: some View {
    NBReportSection(title: "변화 알림", systemImage: "bell.badge") {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        ForEach(summary.trendNotices) { notice in
          BodyCompositionTrendNoticeRow(notice: notice)

          if notice.id != summary.trendNotices.last?.id {
            Divider().overlay(NBColor.divider)
          }
        }
      }
    }
  }

  @ViewBuilder
  private var latestValuesSection: some View {
    if !latestMetricRows.isEmpty {
      NBReportSection(title: "최근 체성분", systemImage: "clock") {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.medium) {
          ForEach(latestMetricRows) { row in
            BodyCompositionLatestMetricTile(row: row)
          }
        }
      }
    }
  }

  private var referenceDetailsSection: some View {
    NBReportSection(title: "기준과 계산", systemImage: "info.circle") {
      DisclosureGroup(isExpanded: $isReferenceDetailsExpanded) {
        VStack(alignment: .leading, spacing: NBSpacing.small) {
          BodyCompositionReferenceDetailLine(
            "BMI 구간은 대한비만학회 2022 비만 진료지침의 한국 성인 BMI 기준을 참고합니다."
          )
          BodyCompositionReferenceDetailLine(
            "참고 구간 경계 체중은 BMI 기준값 x 키(m)^2로 계산합니다. 현재 화면은 HealthKit 키 값을 읽지 않으며 사용자가 입력한 키가 있을 때만 계산합니다."
          )
          BodyCompositionReferenceDetailLine(
            "근육량은 체중계와 앱마다 산출 방식이 달라 고정 구간보다 최근 30일 평균 변화를 우선 표시합니다."
          )
          BodyCompositionReferenceDetailLine(
            "허리둘레 기록은 아직 앱 지표에 없어 복부 둘레 비교는 표시하지 않습니다."
          )
          BodyCompositionReferenceDetailLine(
            "이 화면은 개인 패턴을 살펴보기 위한 참고용 보기이며 의료 판단이나 조치를 제안하지 않습니다."
          )
        }
        .padding(.top, NBSpacing.small)
      } label: {
        HStack(spacing: NBSpacing.small) {
          Image(systemName: "list.bullet.clipboard")
            .foregroundStyle(NBColor.privacyTint)
          Text("BMI 구간과 추세 계산 방식")
            .font(NBTypography.callout.weight(.semibold))
            .foregroundStyle(NBColor.primaryText)
          Spacer()
        }
      }
    }
  }

  private var latestMetricRows: [BodyCompositionLatestMetricRowModel] {
    let metricIDs: [UnifiedHealthMetricID] = [
      .bodyMass,
      .bodyMassIndex,
      .bodyFatPercentage,
      .skeletalMuscleMass,
      .muscleMass,
      .leanBodyMass,
      .bodyWaterPercentage,
      .visceralFatLevel,
      .basalMetabolicRate,
    ]

    return metricIDs
      .compactMap { metricID -> BodyCompositionLatestMetricRowModel? in
        guard let metadata = catalog.metadata(for: metricID),
              let sample = latestSample(metricID) else {
          return nil
        }

        return BodyCompositionLatestMetricRowModel(
          id: metricID,
          title: metadata.displayNameKo,
          value: UnifiedMetricFormatting.valueString(sample.value, unit: sample.unit),
          subtitle: "\(SleepFormatters.shortDate(sample.measuredAt)) · \(sample.sourceType.displayName)",
          systemImage: metricIcon(for: metadata),
          tint: metricTint(for: metadata)
        )
      }
  }

  private var graphReferenceRange: MetricReferenceRange? {
    switch activeMetricID {
    case .bodyMassIndex:
      return MetricReferenceRange(
        label: "BMI 참고 범위",
        lowerValue: 18.5,
        upperValue: 23,
        unit: "BMI",
        tint: NBColor.privacyTint
      )
    case .bodyMass:
      guard let heightMeters = referenceHeightMeters else {
        return nil
      }
      return MetricReferenceRange(
        label: "입력 키 기준 체중 참고 범위",
        lowerValue: 18.5 * heightMeters * heightMeters,
        upperValue: 23 * heightMeters * heightMeters,
        unit: "kg",
        tint: NBColor.privacyTint
      )
    default:
      return nil
    }
  }

  private var rangeTitle: String {
    let range = selectedDateRange
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

  private func latestSample(_ metricID: UnifiedHealthMetricID) -> UnifiedHealthMetricSample? {
    bodyCompositionSamples
      .filter { $0.metricID == metricID }
      .sortedByMeasuredAtDescending()
      .first
  }

  private var heightInputHelpText: String {
    if referenceHeightMeters != nil {
      return "입력한 키는 이 기기 안 앱 설정에만 저장하고 HealthKit에 쓰지 않습니다."
    }

    if !heightCentimetersText.isEmpty && parsedHeightCentimeters == nil {
      return "120~220cm 사이의 숫자를 입력해 주세요."
    }

    return "HealthKit 키 값을 읽지 않으므로 체중 참고 범위는 키를 직접 입력한 뒤 계산합니다."
  }

  private func syncHeightInputText() {
    guard (120...220).contains(referenceHeightCentimeters) else {
      heightCentimetersText = ""
      return
    }
    heightCentimetersText = heightDisplayText(referenceHeightCentimeters)
  }

  private func saveReferenceHeight() {
    guard let parsedHeightCentimeters else {
      return
    }
    referenceHeightCentimeters = parsedHeightCentimeters
    heightCentimetersText = heightDisplayText(parsedHeightCentimeters)
    isHeightInputFocused = false
  }

  private func clearReferenceHeight() {
    referenceHeightCentimeters = 0
    heightCentimetersText = ""
    isHeightInputFocused = false
  }

  private func commitHeightInput() {
    if parsedHeightCentimeters != nil {
      saveReferenceHeight()
    } else {
      isHeightInputFocused = false
    }
  }

  private func heightDisplayText(_ centimeters: Double) -> String {
    if abs(centimeters.rounded() - centimeters) < 0.05 {
      return String(format: "%.0f", centimeters)
    }
    return String(format: "%.1f", centimeters)
  }
}

private struct BodyCompositionReferenceSummaryCard: View {
  let summary: BodyCompositionReferenceSummary
  let referenceBoundary: BodyCompositionReferenceBoundary?
  let referenceHeightCentimeters: Double

  var body: some View {
    VStack(alignment: .leading, spacing: NBSpacing.medium) {
      HStack(alignment: .top, spacing: NBSpacing.medium) {
        VStack(alignment: .leading, spacing: NBSpacing.xs) {
          Text(categoryText)
            .font(NBTypography.headline)
            .foregroundStyle(NBColor.primaryText)
            .fixedSize(horizontal: false, vertical: true)

          Text(primarySubtitle)
            .font(NBTypography.caption)
            .foregroundStyle(NBColor.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
        }

        Spacer(minLength: NBSpacing.small)

        Text(bmiText)
          .font(NBTypography.title)
          .foregroundStyle(NBColor.privacyTint)
          .monospacedDigit()
          .lineLimit(1)
          .minimumScaleFactor(0.72)
      }

      if let boundaryText {
        HStack(alignment: .firstTextBaseline, spacing: NBSpacing.small) {
          Image(systemName: "arrow.left.and.right")
            .foregroundStyle(NBColor.privacyTint)
            .accessibilityHidden(true)
          Text(boundaryText)
            .font(NBTypography.callout.weight(.semibold))
            .foregroundStyle(NBColor.primaryText)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(NBSpacing.small)
        .background(NBColor.privacyTint.opacity(0.08), in: RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
      }

      if let latestMeasuredAt = summary.latestMeasuredAt {
        Text("최근 기록 \(SleepFormatters.shortDate(latestMeasuredAt)) · 기록 \(summary.sampleCount)개")
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
      }
    }
    .accessibilityElement(children: .combine)
  }

  private var categoryText: String {
    summary.bmiCategory?.displayName ?? "BMI 참고 구간 대기"
  }

  private var bmiText: String {
    guard let bmi = summary.latestBMI else {
      return "--"
    }
    return String(format: "%.1f", bmi)
  }

  private var primarySubtitle: String {
    var parts: [String] = []
    if let weight = summary.latestWeightKg {
      parts.append("체중 \(String(format: "%.1fkg", weight))")
    }
    if (120...220).contains(referenceHeightCentimeters) {
      parts.append("입력 키 \(heightText(referenceHeightCentimeters)) 기준")
    } else if summary.latestBMI != nil {
      parts.append("키 입력 후 참고 체중 계산")
    }
    return parts.isEmpty ? "BMI와 체중 기록이 있으면 참고 구간 비교를 표시합니다." : parts.joined(separator: " · ")
  }

  private var boundaryText: String? {
    guard let boundary = referenceBoundary else {
      return nil
    }

    let delta = abs(boundary.deltaKg)
    let deltaText = String(format: "%.1fkg", delta)
    let boundaryWeightText = String(format: "%.1fkg", boundary.boundaryWeightKg)

    switch boundary.kind {
    case .lowerReference:
      return "참고 범위 하단까지 \(deltaText) · BMI \(String(format: "%.1f", boundary.bmiBoundary)) 기준 \(boundaryWeightText)"
    case .upperReference:
      if boundary.deltaKg > 0.05 {
        return "참고 범위 상단보다 \(deltaText) 위 · BMI \(String(format: "%.1f", boundary.bmiBoundary)) 기준 \(boundaryWeightText)"
      }
      if boundary.deltaKg < -0.05 {
        return "참고 범위 상단까지 \(deltaText) · BMI \(String(format: "%.1f", boundary.bmiBoundary)) 기준 \(boundaryWeightText)"
      }
      return "참고 범위 상단과 거의 같은 수준 · BMI \(String(format: "%.1f", boundary.bmiBoundary)) 기준 \(boundaryWeightText)"
    }
  }

  private func heightText(_ centimeters: Double) -> String {
    if abs(centimeters.rounded() - centimeters) < 0.05 {
      return "\(String(format: "%.0f", centimeters))cm"
    }
    return "\(String(format: "%.1f", centimeters))cm"
  }
}

private struct BodyCompositionTrendNoticeRow: View {
  let notice: BodyCompositionTrendNotice

  var body: some View {
    HStack(alignment: .top, spacing: NBSpacing.small) {
      Image(systemName: systemImage)
        .font(.caption.weight(.semibold))
        .foregroundStyle(tint)
        .frame(width: 26, height: 26)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 3) {
        HStack(alignment: .firstTextBaseline, spacing: NBSpacing.small) {
          Text(notice.title)
            .font(NBTypography.subheadline.weight(.semibold))
            .foregroundStyle(NBColor.primaryText)
            .fixedSize(horizontal: false, vertical: true)
          Spacer(minLength: NBSpacing.small)
          if let changeValue = notice.changeValue {
            Text(UnifiedMetricFormatting.signedValueString(changeValue, unit: notice.unit))
              .font(NBTypography.captionEmphasis)
              .foregroundStyle(tint)
              .lineLimit(1)
          }
        }
        Text(notice.message)
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(.vertical, 2)
    .accessibilityElement(children: .combine)
  }

  private var systemImage: String {
    switch notice.kind {
    case .muscleDecrease, .weightAndMuscleDecrease, .consecutiveDecrease:
      "figure.strengthtraining.traditional"
    case .bodyFatIncrease:
      "percent"
    case .insufficientSamples:
      "clock"
    }
  }

  private var tint: Color {
    switch notice.kind {
    case .insufficientSamples:
      NBColor.secondaryText
    case .bodyFatIncrease:
      NBColor.warning
    case .muscleDecrease, .weightAndMuscleDecrease, .consecutiveDecrease:
      NBColor.mistTeal
    }
  }
}

private struct BodyCompositionLatestMetricRowModel: Identifiable {
  let id: UnifiedHealthMetricID
  let title: String
  let value: String
  let subtitle: String
  let systemImage: String
  let tint: Color
}

private struct BodyCompositionLatestMetricTile: View {
  let row: BodyCompositionLatestMetricRowModel

  var body: some View {
    VStack(alignment: .leading, spacing: NBSpacing.xs) {
      HStack(spacing: NBSpacing.small) {
        Image(systemName: row.systemImage)
          .font(.caption.weight(.semibold))
          .foregroundStyle(row.tint)
          .frame(width: 24, height: 24)
          .background(row.tint.opacity(0.10), in: RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
          .accessibilityHidden(true)

        Text(row.title)
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
          .lineLimit(1)
          .minimumScaleFactor(0.78)
      }

      Text(row.value)
        .font(NBTypography.callout.weight(.semibold))
        .foregroundStyle(NBColor.primaryText)
        .lineLimit(1)
        .minimumScaleFactor(0.75)

      Text(row.subtitle)
        .font(.caption2)
        .foregroundStyle(NBColor.tertiaryText)
        .lineLimit(1)
        .minimumScaleFactor(0.72)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(NBSpacing.small)
    .background(NBColor.cardBackground.opacity(0.72), in: RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous)
        .stroke(NBColor.border.opacity(0.52), lineWidth: 1)
    }
    .accessibilityElement(children: .combine)
  }
}

private struct BodyCompositionReferenceDetailLine: View {
  let text: String

  init(_ text: String) {
    self.text = text
  }

  var body: some View {
    HStack(alignment: .top, spacing: NBSpacing.small) {
      Circle()
        .fill(NBColor.privacyTint.opacity(0.65))
        .frame(width: 5, height: 5)
        .padding(.top, 7)
        .accessibilityHidden(true)

      Text(text)
        .font(NBTypography.caption)
        .foregroundStyle(NBColor.secondaryText)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}
