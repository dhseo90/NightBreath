import SwiftUI

struct HealthCalendarView: View {
  let samples: [UnifiedHealthMetricSample]
  let sleepReports: [NightReport]
  let morningCheckIns: [MorningCheckIn]
  let eveningCheckIns: [EveningCheckIn]
  let permissionState: HealthMetricPermissionState
  let isPreviewData: Bool

  @State private var displayedMonth: Date
  @State private var selectedDate: Date

  private let calendar = Calendar.current
  private let builder = HealthCalendarBuilder()

  init(
    samples: [UnifiedHealthMetricSample],
    sleepReports: [NightReport],
    morningCheckIns: [MorningCheckIn] = [],
    eveningCheckIns: [EveningCheckIn] = [],
    permissionState: HealthMetricPermissionState,
    isPreviewData: Bool,
    initialMonth: Date = Date()
  ) {
    self.samples = samples
    self.sleepReports = sleepReports
    self.morningCheckIns = morningCheckIns
    self.eveningCheckIns = eveningCheckIns
    self.permissionState = permissionState
    self.isPreviewData = isPreviewData
    _displayedMonth = State(initialValue: initialMonth)
    _selectedDate = State(initialValue: initialMonth)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        stateNotice
        monthNavigator
        selectedDateInlineDetail
        weekdayHeader
        calendarGrid
      }
      .padding(NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
    .navigationTitle("건강 캘린더")
    .toolbar(.hidden, for: .tabBar)
    .onAppear(perform: selectDataDateIfCurrentSelectionIsEmpty)
    .onChange(of: dataAvailabilitySignature) { _, _ in
      selectDataDateIfCurrentSelectionIsEmpty()
    }
  }

  private var monthDates: [Date] {
    builder.monthGrid(containing: displayedMonth, calendar: calendar)
  }

  private var summariesByDay: [Date: CalendarDaySummary] {
    Dictionary(
      uniqueKeysWithValues: builder
        .summaries(
          forMonthContaining: displayedMonth,
          samples: samples,
          sleepReports: sleepReports,
          morningCheckIns: morningCheckIns,
          eveningCheckIns: eveningCheckIns,
          calendar: calendar
        )
        .map { ($0.date, $0) }
    )
  }

  @ViewBuilder
  private var stateNotice: some View {
    if isPreviewData {
      NBStatusBadge("연결 전 샘플은 예시 미리보기로 표시됩니다.", kind: .neutral, systemImage: "eye")
    }

    switch permissionState {
    case .denied:
      NBStatusBadge("HealthKit 권한이 없어도 로컬 import 샘플과 수면 데이터는 표시할 수 있습니다.", kind: .caution, systemImage: "lock.slash")
    case .unavailable:
      NBStatusBadge("HealthKit을 사용할 수 없어도 로컬 데이터는 표시할 수 있습니다.", kind: .warning, systemImage: "exclamationmark.triangle")
    case .notRequested, .readRequestCompleted, .mockDataOnly:
      EmptyView()
    }
  }

  private var monthNavigator: some View {
    NBCard {
      HStack(spacing: NBSpacing.medium) {
        Button {
          moveMonth(by: -1)
        } label: {
          Image(systemName: "chevron.left")
            .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("이전 월")

        VStack(alignment: .leading, spacing: 2) {
          Text(monthTitle)
            .font(NBTypography.headline)
            .foregroundStyle(NBColor.primaryText)
          Text("선택 \(SleepFormatters.shortDate(selectedDate))")
            .font(NBTypography.caption)
            .foregroundStyle(NBColor.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        Button {
          displayedMonth = Date()
          selectedDate = Date()
        } label: {
          Label("오늘", systemImage: "location")
            .font(.caption.weight(.semibold))
        }
        .buttonStyle(NBSecondaryButtonStyle())

        Button {
          moveMonth(by: 1)
        } label: {
          Image(systemName: "chevron.right")
            .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("다음 월")
      }
    }
  }

  private var weekdayHeader: some View {
    LazyVGrid(columns: calendarColumns, spacing: 6) {
      ForEach(Self.weekdays, id: \.self) { weekday in
        Text(weekday)
          .font(.caption.weight(.semibold))
          .foregroundStyle(NBColor.secondaryText)
          .frame(maxWidth: .infinity)
      }
    }
  }

  private var calendarGrid: some View {
    let dates = monthDates
    let summaries = summariesByDay

    return LazyVGrid(columns: calendarColumns, spacing: 8) {
      ForEach(dates, id: \.self) { date in
        let summary = summaries[calendar.startOfDay(for: date)] ?? emptySummary(for: date)

        Button {
          selectDate(date)
        } label: {
          CalendarDayCell(
            date: date,
            summary: summary,
            isCurrentMonth: calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month),
            isToday: calendar.isDateInToday(date),
            isSelected: calendar.isDate(date, inSameDayAs: selectedDate)
          )
        }
        .buttonStyle(.plain)
      }
    }
  }

  @ViewBuilder
  private var selectedDateInlineDetail: some View {
    DailyMeasurementDetailContent(
      detailData: selectedDetailData,
      allSamples: samples,
      headerTitle: SleepFormatters.shortDate(selectedDate)
    )
  }

  private var calendarColumns: [GridItem] {
    Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
  }

  private var monthTitle: String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "yyyy년 M월"
    return formatter.string(from: displayedMonth)
  }

  private var selectedDaySummary: CalendarDaySummary {
    summariesByDay[calendar.startOfDay(for: selectedDate)] ?? emptySummary(for: selectedDate)
  }

  private var selectedDetailData: DailyMeasurementDetailData {
    builder.detailData(
      for: selectedDate,
      samples: samples,
      sleepReports: sleepReports,
      morningCheckIns: morningCheckIns,
      eveningCheckIns: eveningCheckIns,
      calendar: calendar
    )
  }

  private var dataAvailabilitySignature: String {
    summariesByDay.values
      .filter(\.hasAnyData)
      .sorted { $0.date < $1.date }
      .map { summary in
        let timestamp = Int(summary.date.timeIntervalSinceReferenceDate)
        return [
          "\(timestamp)",
          "\(summary.sampleCount)",
          summary.hasSleepReport ? "sleep" : "",
          summary.hasBloodPressure ? "bp" : "",
          summary.hasBodyComposition ? "body" : "",
          summary.hasActivity ? "activity" : "",
          summary.hasMorningCheckIn ? "morning" : "",
          summary.hasEveningCheckIn ? "evening" : "",
        ].joined(separator: ":")
      }
      .joined(separator: "|")
  }

  private func moveMonth(by value: Int) {
    let nextMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
    let carriedDate = calendar.date(byAdding: .month, value: value, to: selectedDate) ?? nextMonth
    displayedMonth = nextMonth
    selectedDate = preferredDataDate(in: nextMonth, preferredDate: carriedDate) ?? carriedDate
  }

  private func selectDate(_ date: Date) {
    selectedDate = date
    if !calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month) {
      displayedMonth = date
    }
  }

  private func selectDataDateIfCurrentSelectionIsEmpty() {
    guard !selectedDaySummary.hasAnyData,
          let dataDate = preferredDataDate(in: displayedMonth) else {
      return
    }
    selectedDate = dataDate
  }

  private func preferredDataDate(in month: Date, preferredDate: Date? = nil) -> Date? {
    let summaries = builder.summaries(
      forMonthContaining: month,
      samples: samples,
      sleepReports: sleepReports,
      morningCheckIns: morningCheckIns,
      eveningCheckIns: eveningCheckIns,
      calendar: calendar
    )
    .filter {
      calendar.isDate($0.date, equalTo: month, toGranularity: .month)
        && $0.hasAnyData
    }

    guard !summaries.isEmpty else {
      return nil
    }

    if let preferredDate,
       let matchingPreferredDate = summaries.first(where: { calendar.isDate($0.date, inSameDayAs: preferredDate) }) {
      return matchingPreferredDate.date
    }

    let today = Date()
    if calendar.isDate(today, equalTo: month, toGranularity: .month),
       let todaySummary = summaries.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
      return todaySummary.date
    }

    return summaries.sorted { $0.date > $1.date }.first?.date
  }

  private func emptySummary(for date: Date) -> CalendarDaySummary {
    CalendarDaySummary(date: calendar.startOfDay(for: date))
  }

  private static let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
}

struct DailyMeasurementDetailView: View {
  let detailData: DailyMeasurementDetailData
  let allSamples: [UnifiedHealthMetricSample]

  var body: some View {
    ScrollView {
      DailyMeasurementDetailContent(
        detailData: detailData,
        allSamples: allSamples
      )
      .padding(NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
    .navigationTitle(SleepFormatters.shortDate(detailData.date))
    .toolbar(.hidden, for: .tabBar)
  }
}

struct DailyMeasurementDetailContent: View {
  let detailData: DailyMeasurementDetailData
  let allSamples: [UnifiedHealthMetricSample]
  var headerTitle: String = "이날 기록된 데이터"

  private let catalog = MetricCatalog.default

  var body: some View {
    VStack(alignment: .leading, spacing: NBSpacing.medium) {
      header

      if !detailData.summary.hasAnyData {
        HealthDataEmptyStateView(
          title: "해당 날짜에 데이터가 없습니다",
          message: "다른 날짜를 선택하거나 HealthKit 연결, Fitdays CSV 가져오기 상태를 확인하세요."
        )
      } else {
        if !detailData.sleepReports.isEmpty {
          sleepSection
        }
        if !detailData.morningCheckIns.isEmpty {
          morningCheckInSection
        }
        if !detailData.eveningCheckIns.isEmpty {
          eveningCheckInSection
        }
        if !detailData.bloodPressureSamples.isEmpty {
          metricSection(title: "혈압", systemImage: "heart", samples: detailData.bloodPressureSamples, emptyMessage: "")
        }
        if !detailData.bodyCompositionSamples.isEmpty {
          metricSection(title: "체성분", systemImage: "scalemass", samples: detailData.bodyCompositionSamples, emptyMessage: "")
        }
        if !detailData.fitdaysExtendedSamples.isEmpty {
          metricSection(title: "Fitdays 확장", systemImage: "square.and.arrow.down", samples: detailData.fitdaysExtendedSamples, emptyMessage: "")
        }
        if !detailData.activitySamples.isEmpty {
          metricSection(title: "활동", systemImage: "figure.walk", samples: detailData.activitySamples, emptyMessage: "")
        }
        if !detailData.appComputedSamples.isEmpty {
          metricSection(title: "앱 계산", systemImage: "sparkles", samples: detailData.appComputedSamples, emptyMessage: "")
        }

        Text("개인 참고용 보기입니다. 같은 날짜에 함께 보여도 인과관계를 의미하지 않습니다.")
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private var header: some View {
    NBCard {
      HStack(alignment: .center, spacing: NBSpacing.small) {
        VStack(alignment: .leading, spacing: 3) {
          Text(headerTitle)
            .font(NBTypography.headline)
            .foregroundStyle(NBColor.primaryText)
          Text(summaryText)
            .font(NBTypography.caption)
            .foregroundStyle(NBColor.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
        }
        Spacer(minLength: NBSpacing.small)
        NBStatusBadge(
          detailData.summary.dataQuality.displayName,
          kind: qualityBadgeKind(detailData.summary.dataQuality),
          systemImage: "checkmark.seal"
        )
      }
    }
  }

  private var summaryText: String {
    var parts: [String] = []
    if detailData.summary.sampleCount > 0 {
      parts.append("샘플 \(detailData.summary.sampleCount)개")
    }
    if detailData.summary.hasSleepReport {
      parts.append("수면")
    }
    if detailData.summary.hasBloodPressure {
      parts.append("혈압")
    }
    if detailData.summary.hasBodyComposition {
      parts.append("체성분")
    }
    if detailData.summary.hasActivity {
      parts.append("활동")
    }
    if detailData.summary.hasMorningCheckIn || detailData.summary.hasEveningCheckIn {
      parts.append("체크인")
    }
    return parts.isEmpty ? "표시할 데이터 없음" : parts.joined(separator: " · ")
  }

  private var sleepSection: some View {
    NBReportSection(title: "수면", systemImage: "bed.double") {
      if detailData.sleepReports.isEmpty {
        NBEmptyStateView(
          title: "수면 리포트 없음",
          message: "이날 생성된 수면 소리 리포트가 없습니다.",
          systemImage: "tray"
        )
      } else {
        VStack(alignment: .leading, spacing: NBSpacing.small) {
          ForEach(detailData.sleepReports) { report in
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.small) {
              NBMetricCard(title: "수면 소리 점수", value: "\(report.sleepSoundScore)점", systemImage: "waveform", tint: NBColor.sleepTint)
              NBMetricCard(title: "측정 품질", value: report.measurementQuality.displayName, systemImage: "gauge.with.dots.needle.bottom.50percent", tint: NBColor.privacyTint)
              NBMetricCard(title: "코골기", value: SleepFormatters.durationString(report.snoreTotalSeconds), systemImage: "waveform.path", tint: NBColor.warning)
              NBMetricCard(title: "오디오 수신", value: SleepFormatters.durationString(report.receivedAudioDuration), systemImage: "dot.radiowaves.left.and.right", tint: NBColor.audioTint)
            }

            NBListRow(
              title: "이갈이 의심 소리",
              value: "\(report.bruxismLikeCount)회",
              subtitle: "수면 중 소리 기반 지표입니다.",
              systemImage: "waveform.badge.magnifyingglass",
              tint: NBColor.lavender
            )
            NBListRow(
              title: "호흡정지 의심 구간",
              value: "\(report.suspectedPauseCount)회",
              subtitle: "개인 참고용 소리 지표입니다.",
              systemImage: "lungs",
              tint: NBColor.mistTeal
            )
            NBListRow(
              title: "주요 요약",
              value: report.mainDisturbanceReason,
              subtitle: "인과관계를 의미하지 않습니다.",
              systemImage: "text.bubble",
              tint: NBColor.sleepTint
            )
          }
        }
      }
    }
  }

  private var morningCheckInSection: some View {
    NBReportSection(title: "아침 컨디션", systemImage: "sunrise") {
      if detailData.morningCheckIns.isEmpty {
        NBEmptyStateView(
          title: "아침 체크인 없음",
          message: "이날 연결된 아침 컨디션 기록이 없습니다.",
          systemImage: "tray"
        )
      } else {
        VStack(alignment: .leading, spacing: NBSpacing.small) {
          ForEach(detailData.morningCheckIns) { checkIn in
            NBListRow(
              title: "컨디션",
              value: "개운함 \(checkIn.refreshScore)/5 · 피로 \(checkIn.fatigueScore)/5",
              subtitle: "기억한 각성 \(checkIn.rememberedAwakenings)회",
              systemImage: "sunrise",
              tint: NBColor.dawn
            )

            let flags = morningFlagText(checkIn)
            if !flags.isEmpty {
              NBListRow(
                title: "기록된 항목",
                value: flags,
                subtitle: checkIn.memo.isEmpty ? "메모 없음" : checkIn.memo,
                systemImage: "checklist",
                tint: NBColor.privacyTint
              )
            }
          }
        }
      }
    }
  }

  private var eveningCheckInSection: some View {
    NBReportSection(title: "저녁 체크인", systemImage: "moon.haze") {
      if detailData.eveningCheckIns.isEmpty {
        NBEmptyStateView(
          title: "저녁 체크인 없음",
          message: "이날 저장된 저녁 체크인 기록이 없습니다.",
          systemImage: "tray"
        )
      } else {
        VStack(alignment: .leading, spacing: NBSpacing.small) {
          ForEach(detailData.eveningCheckIns) { checkIn in
            NBListRow(
              title: "저녁 컨디션",
              value: "피로 \(checkIn.fatigueScore)/5 · 스트레스 \(checkIn.stressScore)/5",
              subtitle: checkIn.moodScore.map { "기분 \($0)/5" } ?? "기분 기록 없음",
              systemImage: "moon.haze",
              tint: NBColor.sleepTint
            )

            if !checkIn.lifestyleTags.isEmpty {
              NBListRow(
                title: "생활 태그",
                value: checkIn.lifestyleTags.map(\.displayName).joined(separator: " · "),
                subtitle: checkIn.memo.isEmpty ? "메모 없음" : checkIn.memo,
                systemImage: "tag",
                tint: NBColor.accent
              )
            }
          }
        }
      }
    }
  }

  private func metricSection(
    title: String,
    systemImage: String,
    samples: [UnifiedHealthMetricSample],
    emptyMessage: String
  ) -> some View {
    let visibleSamples = dailyDisplaySamples(samples)

    return NBReportSection(title: title, systemImage: systemImage) {
      if visibleSamples.isEmpty {
        NBEmptyStateView(
          title: "\(title) 데이터 없음",
          message: emptyMessage,
          systemImage: "tray"
        )
      } else {
        VStack(alignment: .leading, spacing: NBSpacing.small) {
          ForEach(visibleSamples) { sample in
            if let metadata = catalog.metadata(for: sample.metricID) {
              NavigationLink {
                MetricDetailView(
                  metric: metadata,
                  samples: allSamples,
                  selectedPeriod: .thirtyDays
                )
              } label: {
                DailyMetricSampleRow(
                  metadata: metadata,
                  sample: sample
                )
              }
              .buttonStyle(.plain)
            }
          }
        }
      }
    }
  }

  private func dailyDisplaySamples(_ samples: [UnifiedHealthMetricSample]) -> [UnifiedHealthMetricSample] {
    let cumulativeMetricSamples = samples.filter { $0.metricID.usesDailyCumulativeSum }
    let ordinarySamples = samples.filter { !$0.metricID.usesDailyCumulativeSum }
    let cumulativeDailyTotals = Dictionary(grouping: cumulativeMetricSamples, by: \.metricID)
      .compactMap { metricID, samples -> UnifiedHealthMetricSample? in
        guard let first = samples.sortedByMeasuredAtAscending().first else {
          return nil
        }
        let total = samples.map(\.value).reduce(0, +)
        let sourceNames = Set(samples.map(\.sourceName))
        return UnifiedHealthMetricSample(
          id: first.id,
          metricID: metricID,
          value: total,
          unit: first.unit,
          measuredAt: first.measuredAt,
          sourceType: first.sourceType,
          sourceName: sourceNames.count == 1 ? first.sourceName : "하루 합계",
          sourceBundleIdentifier: first.sourceBundleIdentifier,
          notes: "하루 합계로 표시합니다.",
          createdAt: first.createdAt
        )
      }

    return (ordinarySamples + cumulativeDailyTotals).sortedByMeasuredAtAscending()
  }

  private func morningFlagText(_ checkIn: MorningCheckIn) -> String {
    var flags: [String] = []
    if checkIn.headache { flags.append("두통") }
    if checkIn.dryMouth { flags.append("입 마름") }
    if checkIn.soreThroat { flags.append("목 불편감") }
    return flags.joined(separator: " · ")
  }

  private func qualityBadgeKind(_ quality: DailyDataQuality) -> NBStatusKind {
    switch quality {
    case .excellent, .good:
      .good
    case .limited:
      .warning
    case .poor:
      .caution
    case .insufficient:
      .neutral
    }
  }
}

private struct DailyMetricSampleRow: View {
  let metadata: MetricDisplayMetadata
  let sample: UnifiedHealthMetricSample

  var body: some View {
    HStack(alignment: .center, spacing: NBSpacing.small) {
      VStack(alignment: .leading, spacing: 0) {
        NBListRow(
          title: metadata.displayNameKo,
          value: UnifiedMetricFormatting.valueString(sample.value, unit: sample.unit),
          subtitle: "\(SleepFormatters.shortTime(sample.measuredAt)) · \(sample.sourceType.displayName) · \(sample.sourceName)",
          systemImage: calendarMetricIcon(for: sample.metricID),
          tint: calendarMetricTint(for: metadata),
          accessibilityLabel: "\(metadata.displayNameKo), \(UnifiedMetricFormatting.valueString(sample.value, unit: sample.unit)), \(sample.sourceName)"
        )

        MetricSourceBadgeStrip(
          metadata: metadata,
          sourceTypes: [sample.sourceType]
        )
        .padding(.leading, 40)
        .padding(.bottom, NBSpacing.small)
      }

      Image(systemName: "chevron.right")
        .font(.caption.weight(.semibold))
        .foregroundStyle(NBColor.tertiaryText)
    }
  }
}

private struct CalendarDayCell: View {
  let date: Date
  let summary: CalendarDaySummary
  let isCurrentMonth: Bool
  let isToday: Bool
  let isSelected: Bool

  private let calendar = Calendar.current

  var body: some View {
    VStack(spacing: 5) {
      Text("\(calendar.component(.day, from: date))")
        .font(.caption.weight(isToday ? .bold : .semibold))
        .foregroundStyle(isCurrentMonth ? NBColor.primaryText : NBColor.tertiaryText)
        .frame(width: 26, height: 26)
        .background(dayBackground)
        .clipShape(Circle())

      HStack(spacing: 3) {
        if summary.hasSleepReport { dot(NBColor.sleepTint) }
        if summary.hasBloodPressure { dot(NBColor.danger) }
        if summary.hasBodyComposition { dot(NBColor.mistTeal) }
        if summary.hasActivity { dot(NBColor.success) }
        if summary.hasMorningCheckIn || summary.hasEveningCheckIn { dot(NBColor.dawn) }
      }
      .frame(height: 6)
    }
    .frame(height: 48)
    .frame(maxWidth: .infinity)
    .background(cellBackground)
    .overlay(
      RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous)
        .stroke(isSelected ? NBColor.accent.opacity(0.65) : NBColor.divider.opacity(0.5), lineWidth: isSelected ? 1.2 : 0.7)
    )
    .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
    .opacity(isCurrentMonth ? 1 : 0.45)
    .accessibilityLabel(accessibilityText)
  }

  private var dayBackground: Color {
    if isToday { return NBColor.accent.opacity(0.18) }
    if isSelected { return NBColor.accent.opacity(0.12) }
    return .clear
  }

  private var cellBackground: Color {
    summary.hasAnyData ? NBColor.cardBackground : NBColor.cardBackground.opacity(0.55)
  }

  private func dot(_ color: Color) -> some View {
    Circle()
      .fill(color)
      .frame(width: 5, height: 5)
  }

  private var accessibilityText: String {
    let dateText = SleepFormatters.shortDate(date)
    guard summary.hasAnyData else {
      return "\(dateText), 데이터 없음"
    }
    let sources = summary.sourceTypes.map(\.displayName).joined(separator: ", ")
    let sourceText = sources.isEmpty ? "출처 없음" : "출처 \(sources)"
    return "\(dateText), 샘플 \(summary.sampleCount)개, \(sourceText), 데이터 품질 \(summary.dataQuality.displayName)"
  }
}

private func calendarMetricIcon(for metricID: UnifiedHealthMetricID) -> String {
  switch metricID {
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

private func calendarMetricTint(for metadata: MetricDisplayMetadata) -> Color {
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

#if DEBUG
struct HealthCalendarView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      HealthCalendarView(
        samples: previewSamples,
        sleepReports: [MockSleepDataFactory.latestBundle().2],
        morningCheckIns: [MockSleepDataFactory.latestBundle().3],
        eveningCheckIns: [
          EveningCheckIn(
            date: Date(),
            fatigueScore: 3,
            stressScore: 2,
            moodScore: 4,
            caffeine: true,
            exercise: true,
            memo: "Preview"
          ),
        ],
        permissionState: .mockDataOnly,
        isPreviewData: true
      )
    }
  }

  private static var previewSamples: [UnifiedHealthMetricSample] {
    MockHealthDataService().samples.map { $0.unifiedSample(sourceType: .mock) } + [
      UnifiedHealthMetricSample(
        metricID: .bodyWaterPercentage,
        value: 56.8,
        unit: "%",
        measuredAt: Date(),
        sourceType: .fitdaysCSV,
        sourceName: "Fitdays CSV Import"
      ),
      UnifiedHealthMetricSample(
        metricID: .sleepSoundScore,
        value: 82,
        unit: "점",
        measuredAt: Date(),
        sourceType: .appComputed,
        sourceName: "밤숨 앱"
      ),
    ]
  }
}
#endif
