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
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        header
        stateNotice
        monthNavigator
        weekdayHeader
        calendarGrid
        selectedDatePanel
        legend

        NBPrivacyNoticeCard(
          title: "날짜별 데이터 안내",
          messages: [
            "캘린더는 기기 안의 수면 리포트, HealthKit read-only 샘플, 로컬 import 샘플을 날짜 기준으로 묶어 보여줍니다.",
            "같은 날짜에 여러 데이터가 있어도 인과관계를 의미하지 않습니다.",
            "서버로 전송하지 않고 HealthKit에 데이터를 쓰지 않습니다.",
          ],
          systemImage: "lock.shield"
        )
      }
      .padding(NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
    .navigationTitle("건강 캘린더")
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

  private var header: some View {
    NBReportSection(title: "월별 건강 캘린더", systemImage: "calendar") {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        Text("수면, 혈압, 체성분, 활동, 체크인과 앱 계산 지표를 날짜별로 모아봅니다.")
          .font(NBTypography.callout)
          .foregroundStyle(NBColor.secondaryText)

        Text("날짜를 선택하면 이날 기록된 데이터를 카테고리별로 확인할 수 있습니다.")
          .font(NBTypography.footnote)
          .foregroundStyle(NBColor.tertiaryText)
      }
    }
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
          Text("선택 \(SleepFormatters.shortDate(selectedDate)) · 오늘 \(SleepFormatters.shortDate(Date()))")
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

  private var selectedDatePanel: some View {
    let summary = selectedDaySummary

    return NBReportSection(title: "선택 날짜", systemImage: "calendar.badge.clock") {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        HStack(alignment: .top, spacing: NBSpacing.small) {
          VStack(alignment: .leading, spacing: 4) {
            Text(SleepFormatters.shortDate(selectedDate))
              .font(NBTypography.headline)
              .foregroundStyle(NBColor.primaryText)

            Text(summary.hasAnyData ? "이 날짜의 데이터를 카테고리와 출처별로 확인합니다." : "이 날짜에는 표시할 데이터가 없습니다.")
              .font(NBTypography.caption)
              .foregroundStyle(NBColor.secondaryText)
              .fixedSize(horizontal: false, vertical: true)
          }

          Spacer(minLength: NBSpacing.small)

          NBStatusBadge(
            summary.dataQuality.displayName,
            kind: qualityBadgeKind(summary.dataQuality),
            systemImage: "checkmark.seal"
          )
        }

        if summary.hasAnyData {
          VStack(alignment: .leading, spacing: NBSpacing.small) {
            CalendarSelectedCategoryStrip(summary: summary)
            CalendarSelectedSourceStrip(sourceTypes: summary.sourceTypes)
          }
        } else {
          NBEmptyStateView(
            title: "데이터 없는 날짜",
            message: "다른 날짜를 선택하거나 HealthKit read-only 연결, Fitdays CSV 가져오기 상태를 확인하세요.",
            systemImage: "tray"
          )
        }

        NavigationLink {
          DailyMeasurementDetailView(
            detailData: selectedDetailData,
            allSamples: samples
          )
        } label: {
          Label("이 날짜 자세히 보기", systemImage: "list.bullet.rectangle")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.privacyTint))
      }
    }
  }

  private var legend: some View {
    NBReportSection(title: "표시 기준", systemImage: "circle.grid.2x2") {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        VStack(alignment: .leading, spacing: NBSpacing.small) {
          Text("분류 dot")
            .font(NBTypography.captionEmphasis)
            .foregroundStyle(NBColor.secondaryText)

          LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.small) {
            CalendarLegendItem(label: "수면", tint: NBColor.sleepTint)
            CalendarLegendItem(label: "혈압", tint: NBColor.danger)
            CalendarLegendItem(label: "체성분", tint: NBColor.mistTeal)
            CalendarLegendItem(label: "활동", tint: NBColor.success)
            CalendarLegendItem(label: "체크인", tint: NBColor.dawn)
          }
        }

        Divider().overlay(NBColor.divider)

        VStack(alignment: .leading, spacing: NBSpacing.small) {
          Text("출처 dot")
            .font(NBTypography.captionEmphasis)
            .foregroundStyle(NBColor.secondaryText)

          LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.small) {
            CalendarLegendItem(label: "Apple 건강앱", tint: calendarSourceTint(for: .healthKit))
            CalendarLegendItem(label: "Fitdays CSV", tint: calendarSourceTint(for: .fitdaysCSV))
            CalendarLegendItem(label: "앱 계산값", tint: calendarSourceTint(for: .appComputed))
            CalendarLegendItem(label: "예시 데이터", tint: calendarSourceTint(for: .mock))
          }
        }
      }
    }
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

  private func moveMonth(by value: Int) {
    let nextMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
    displayedMonth = nextMonth

    if !calendar.isDate(selectedDate, equalTo: nextMonth, toGranularity: .month) {
      selectedDate = calendar.date(byAdding: .month, value: value, to: selectedDate) ?? nextMonth
    }
  }

  private func selectDate(_ date: Date) {
    selectedDate = date
    if !calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month) {
      displayedMonth = date
    }
  }

  private func emptySummary(for date: Date) -> CalendarDaySummary {
    CalendarDaySummary(date: calendar.startOfDay(for: date))
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

  private static let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
}

struct DailyMeasurementDetailView: View {
  let detailData: DailyMeasurementDetailData
  let allSamples: [UnifiedHealthMetricSample]

  private let catalog = MetricCatalog.default

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        header

        if !detailData.summary.hasAnyData {
          HealthDataEmptyStateView(
            title: "해당 날짜에 데이터가 없습니다",
            message: "다른 날짜를 선택하거나 HealthKit 연결, Fitdays CSV 가져오기 상태를 확인하세요."
          )
        }

        sleepSection
        morningCheckInSection
        eveningCheckInSection
        metricSection(title: "혈압", systemImage: "heart", samples: detailData.bloodPressureSamples, emptyMessage: "이날 기록된 혈압 샘플이 없습니다.")
        metricSection(title: "체성분", systemImage: "scalemass", samples: detailData.bodyCompositionSamples, emptyMessage: "이날 기록된 체성분 샘플이 없습니다.")
        metricSection(title: "Fitdays 확장 체성분", systemImage: "square.and.arrow.down", samples: detailData.fitdaysExtendedSamples, emptyMessage: "이날 가져온 Fitdays 확장 지표가 없습니다.")
        metricSection(title: "활동", systemImage: "figure.walk", samples: detailData.activitySamples, emptyMessage: "이날 기록된 활동 샘플이 없습니다.")
        metricSection(title: "앱 계산 지표", systemImage: "sparkles", samples: detailData.appComputedSamples, emptyMessage: "이날 앱 계산 지표 샘플이 없습니다.")
        sourceSection

        NBPrivacyNoticeCard(
          title: "개인 참고용 보기",
          messages: [
            "이날 기록된 데이터를 한곳에 모아 보여줍니다.",
            "서로 다른 지표가 같은 날짜에 있어도 인과관계를 의미하지 않습니다.",
            "이 화면은 개인 참고용이며 확정적 해석을 제공하지 않습니다.",
          ],
          systemImage: "info.circle"
        )
      }
      .padding(NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
    .navigationTitle(SleepFormatters.shortDate(detailData.date))
  }

  private var header: some View {
    NBReportSection(title: "이날 기록된 데이터", systemImage: "calendar.badge.clock") {
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.medium) {
        NBMetricCard(
          title: "건강 샘플",
          value: "\(detailData.summary.sampleCount)개",
          systemImage: "number",
          tint: NBColor.privacyTint
        )
        NBMetricCard(
          title: "데이터 품질",
          value: detailData.summary.dataQuality.displayName,
          systemImage: "checkmark.seal",
          tint: qualityTint(detailData.summary.dataQuality)
        )
      }
    }
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
    NBReportSection(title: title, systemImage: systemImage) {
      if samples.isEmpty {
        NBEmptyStateView(
          title: "\(title) 데이터 없음",
          message: emptyMessage,
          systemImage: "tray"
        )
      } else {
        VStack(alignment: .leading, spacing: NBSpacing.small) {
          ForEach(samples) { sample in
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

  private var sourceSection: some View {
    NBReportSection(title: "데이터 출처", systemImage: "square.stack.3d.up") {
      if sourceBreakdown.isEmpty && detailData.sleepReports.isEmpty && detailData.morningCheckIns.isEmpty && detailData.eveningCheckIns.isEmpty {
        NBEmptyStateView(
          title: "표시할 데이터 출처가 없습니다",
          message: "해당 날짜에 샘플이나 리포트가 없습니다.",
          systemImage: "tray"
        )
      } else {
        VStack(alignment: .leading, spacing: NBSpacing.small) {
          if !detailData.sleepReports.isEmpty {
            NBListRow(
              title: "밤숨 앱",
              value: "수면 리포트 \(detailData.sleepReports.count)개",
              subtitle: "온디바이스 수면 소리 분석 결과",
              systemImage: "iphone",
              tint: NBColor.sleepTint
            )
          }

          if !detailData.morningCheckIns.isEmpty || !detailData.eveningCheckIns.isEmpty {
            NBListRow(
              title: "밤숨 앱",
              value: "체크인 \(detailData.morningCheckIns.count + detailData.eveningCheckIns.count)개",
              subtitle: "사용자가 직접 남긴 컨디션 기록",
              systemImage: "checklist",
              tint: NBColor.dawn
            )
          }

          ForEach(sourceBreakdown) { source in
            NBListRow(
              title: source.sourceType.displayName,
              value: "\(source.sampleCount)개",
              subtitle: "\(source.sourceName) · 최근 \(SleepFormatters.shortTime(source.latestMeasuredAt))",
              systemImage: calendarSourceIcon(for: source.sourceType),
              tint: calendarSourceTint(for: source.sourceType)
            )
          }
        }
      }
    }
  }

  private var sourceBreakdown: [MetricSourceBreakdown] {
    Dictionary(grouping: detailData.samples) { sample in
      "\(sample.sourceType.rawValue)|\(sample.sourceName)"
    }
    .compactMap { _, samples in
      guard let latest = samples.sortedByMeasuredAtDescending().first else {
        return nil
      }
      return MetricSourceBreakdown(
        sourceType: latest.sourceType,
        sourceName: latest.sourceName,
        sampleCount: samples.count,
        latestMeasuredAt: latest.measuredAt
      )
    }
    .sorted { $0.latestMeasuredAt > $1.latestMeasuredAt }
  }

  private func morningFlagText(_ checkIn: MorningCheckIn) -> String {
    var flags: [String] = []
    if checkIn.headache { flags.append("두통") }
    if checkIn.dryMouth { flags.append("입 마름") }
    if checkIn.soreThroat { flags.append("목 불편감") }
    return flags.joined(separator: " · ")
  }

  private func qualityTint(_ quality: DailyDataQuality) -> Color {
    switch quality {
    case .excellent, .good:
      NBColor.success
    case .limited:
      NBColor.warning
    case .poor, .insufficient:
      NBColor.caution
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

      CalendarDaySourceDotStrip(sourceTypes: summary.sourceTypes)
        .frame(height: 6)

      Text(summary.sampleCount > 0 ? "\(summary.sampleCount)" : " ")
        .font(.caption2.monospacedDigit())
        .foregroundStyle(summary.hasAnyData ? NBColor.secondaryText : NBColor.tertiaryText)
    }
    .frame(height: 72)
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

private struct CalendarDaySourceDotStrip: View {
  let sourceTypes: [HealthMetricSourceType]

  var body: some View {
    HStack(spacing: 2) {
      ForEach(sourceTypes.prefix(4)) { sourceType in
        Circle()
          .fill(calendarSourceTint(for: sourceType))
          .frame(width: 4, height: 4)
          .accessibilityHidden(true)
      }

      if sourceTypes.count > 4 {
        Text("+")
          .font(.system(size: 6, weight: .bold))
          .foregroundStyle(NBColor.secondaryText)
      }
    }
    .frame(maxWidth: .infinity)
    .accessibilityLabel(sourceTypes.isEmpty ? "source 없음" : "source \(sourceTypes.map(\.displayName).joined(separator: ", "))")
  }
}

struct CalendarSelectedCategoryStrip: View {
  let summary: CalendarDaySummary

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: NBSpacing.small) {
        if summary.hasSleepReport { CalendarSelectionBadge(label: "수면", tint: NBColor.sleepTint, systemImage: "bed.double") }
        if summary.hasBloodPressure { CalendarSelectionBadge(label: "혈압", tint: NBColor.danger, systemImage: "heart") }
        if summary.hasBodyComposition { CalendarSelectionBadge(label: "체성분", tint: NBColor.mistTeal, systemImage: "scalemass") }
        if summary.hasActivity { CalendarSelectionBadge(label: "활동", tint: NBColor.success, systemImage: "figure.walk") }
        if summary.hasMorningCheckIn || summary.hasEveningCheckIn { CalendarSelectionBadge(label: "체크인", tint: NBColor.dawn, systemImage: "checklist") }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

struct CalendarSelectedSourceStrip: View {
  let sourceTypes: [HealthMetricSourceType]

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: NBSpacing.small) {
        ForEach(sourceTypes) { sourceType in
          CalendarSelectionBadge(
            label: sourceType.displayName,
            tint: calendarSourceTint(for: sourceType),
            systemImage: calendarSourceIcon(for: sourceType)
          )
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

private struct CalendarSelectionBadge: View {
  let label: String
  let tint: Color
  let systemImage: String

  var body: some View {
    Label(label, systemImage: systemImage)
      .font(NBTypography.captionEmphasis)
      .foregroundStyle(tint)
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(tint.opacity(0.10))
      .clipShape(Capsule())
  }
}

private struct CalendarLegendItem: View {
  let label: String
  let tint: Color

  var body: some View {
    HStack(spacing: NBSpacing.small) {
      Circle()
        .fill(tint)
        .frame(width: 8, height: 8)
      Text(label)
        .font(.caption.weight(.semibold))
        .foregroundStyle(NBColor.secondaryText)
      Spacer()
    }
    .frame(maxWidth: .infinity)
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

private func calendarSourceIcon(for sourceType: HealthMetricSourceType) -> String {
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

private func calendarSourceTint(for sourceType: HealthMetricSourceType) -> Color {
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
