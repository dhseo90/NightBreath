import SwiftUI

struct MorningBriefView: View {
  let bundle: DailyRhythmMockBundle

  init(
    nightReport: NightReport? = nil,
    morningCheckIn: MorningCheckIn? = nil,
    referenceDate: Date = Date()
  ) {
    self.bundle = DailyRhythmMockFactory.makeBundle(
      referenceDate: referenceDate,
      nightReport: nightReport,
      morningCheckIn: morningCheckIn
    )
  }

  init(bundle: DailyRhythmMockBundle) {
    self.bundle = bundle
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        header
        sleepSummarySection
        morningConditionSection
        morningHealthSection
        rhythmStartSection
        NBPrivacyNoticeCard(
          title: "아침 리포트 안내",
          messages: [
            "개인 참고용 리포트입니다.",
            "이 앱은 진단 목적의 의료기기가 아닙니다.",
            "건강 데이터는 mock source로 표시합니다.",
          ],
          systemImage: "sunrise"
        )
      }
      .padding(NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .navigationTitle("아침 리포트")
  }

  private var header: some View {
    NBCard(background: NBColor.dawn.opacity(0.10), stroke: NBColor.dawn.opacity(0.22)) {
      VStack(alignment: .leading, spacing: NBSpacing.md) {
        Label("오늘 아침 리포트", systemImage: "sunrise.fill")
          .font(NBTypography.titleLarge)
          .foregroundStyle(NBColor.primaryText)

        Text("수면 소리, 아침 컨디션, mock 건강 데이터를 사용 가능한 범위에서 함께 정리합니다.")
          .font(NBTypography.callout)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)

        HStack(spacing: NBSpacing.xs) {
          NBStatusBadge("개인 참고용", kind: .neutral, systemImage: "person.text.rectangle")
          NBStatusBadge(
            "데이터 품질 \(bundle.report.dataQuality.displayName)",
            kind: DailyRhythmUI.dataQualityStatus(bundle.report.dataQuality),
            systemImage: "checkmark.seal"
          )
        }
      }
    }
  }

  private var sleepSummarySection: some View {
    NBReportSection(title: "어젯밤 수면 요약", systemImage: "moon.zzz") {
      if let report = bundle.nightReport {
        VStack(spacing: NBSpacing.sm) {
          NBListRow(
            title: "수면 소리 점수",
            value: "\(report.sleepSoundScore)점",
            subtitle: "수면 중 소리 기반 웰니스 지표",
            systemImage: "waveform.path.ecg",
            tint: DailyRhythmUI.scoreTint(report.sleepSoundScore)
          )
          NBListRow(
            title: "측정 품질",
            value: report.measurementQuality.displayName,
            subtitle: "오디오 커버리지 \(percentString(report.audioCoverageRatio))",
            systemImage: "checkmark.seal",
            tint: NBColor.privacyTint
          )
          NBListRow(
            title: "코골기 시간",
            value: SleepFormatters.compactDurationString(report.snoreTotalSeconds),
            subtitle: "어젯밤 수면 소리 리포트에 기록된 값",
            systemImage: "waveform",
            tint: NBColor.audioTint
          )
        }
      } else {
        NBEmptyStateView(
          title: "수면 리포트가 없습니다",
          message: "수면 리포트가 생기면 아침 리포트의 수면 요약에 함께 표시합니다.",
          systemImage: "moon.zzz"
        )
      }
    }
  }

  private var morningConditionSection: some View {
    NBReportSection(title: "아침 컨디션", systemImage: "face.smiling") {
      if let checkIn = bundle.morningCheckIn {
        VStack(spacing: NBSpacing.sm) {
          NBListRow(
            title: "상쾌함",
            value: "\(checkIn.refreshScore)/5",
            subtitle: "사용자가 직접 남긴 아침 기록",
            systemImage: "sun.max",
            tint: NBColor.dawn
          )
          NBListRow(
            title: "피로감",
            value: "\(checkIn.fatigueScore)/5",
            subtitle: conditionFlags(from: checkIn),
            systemImage: "battery.50percent",
            tint: NBColor.warning
          )
          if !checkIn.memo.isEmpty {
            NBListRow(
              title: "메모",
              subtitle: checkIn.memo,
              systemImage: "note.text",
              tint: NBColor.accent
            )
          }
        }
      } else {
        NBEmptyStateView(
          title: "아침 체크인이 없습니다",
          message: "아침 컨디션을 남기면 회복 리듬 항목에 참고용으로 표시합니다.",
          systemImage: "sunrise"
        )
      }
    }
  }

  private var morningHealthSection: some View {
    NBReportSection(title: "아침 건강 mock data", systemImage: "heart.text.square") {
      if bundle.healthSamples.isEmpty {
        NBEmptyStateView(
          title: "건강 mock data가 없습니다",
          message: "mock source가 준비되면 혈압과 체중/체성분 데이터를 이 영역에 표시합니다.",
          systemImage: "tray"
        )
      } else {
        VStack(spacing: NBSpacing.sm) {
          bloodPressureRow
          metricRow(.bodyMass)
          metricRow(.bodyFatPercentage)
          metricRow(.bodyMassIndex)
          metricRow(.leanBodyMass)
        }
      }
    }
  }

  private var rhythmStartSection: some View {
    NBReportSection(title: "오늘의 리듬 시작 요약", systemImage: "sparkles") {
      VStack(alignment: .leading, spacing: NBSpacing.sm) {
        NBListRow(
          title: "오늘의 리듬 점수",
          value: "\(bundle.report.dailyRhythmScore.totalScore)점",
          subtitle: "수면·활동·컨디션·건강 데이터를 함께 정리한 참고용 점수",
          systemImage: "gauge.with.dots.needle.67percent",
          tint: DailyRhythmUI.scoreTint(bundle.report.dailyRhythmScore.totalScore)
        )
        NBListRow(
          title: "데이터 품질",
          value: bundle.report.dataQuality.displayName,
          subtitle: "없는 항목은 제한적으로 표시합니다.",
          systemImage: "checkmark.seal",
          tint: NBColor.privacyTint
        )
      }
    }
  }

  @ViewBuilder
  private var bloodPressureRow: some View {
    if let systolic = bundle.latestSample(.systolicBloodPressure),
       let diastolic = bundle.latestSample(.diastolicBloodPressure) {
      NBListRow(
        title: "아침 혈압 mock data",
        value: "\(Int(systolic.value.rounded()))/\(Int(diastolic.value.rounded())) mmHg",
        subtitle: "\(systolic.sourceName) · \(SleepFormatters.shortTime(systolic.measuredAt))",
        systemImage: "heart",
        tint: NBColor.danger
      )
    } else {
      NBListRow(
        title: "아침 혈압 mock data",
        value: "데이터 없음",
        subtitle: "해당 항목은 제한적으로 표시됩니다.",
        systemImage: "heart.slash",
        tint: NBColor.neutral
      )
    }
  }

  @ViewBuilder
  private func metricRow(_ metricType: HealthMetricType) -> some View {
    if let sample = bundle.latestSample(metricType) {
      NBListRow(
        title: metricType.displayName,
        value: DailyRhythmUI.valueString(sample.value, unit: sample.unit),
        subtitle: "\(sample.sourceName) · \(SleepFormatters.shortTime(sample.measuredAt))",
        systemImage: DailyRhythmUI.icon(for: metricType),
        tint: DailyRhythmUI.tint(for: metricType)
      )
    } else {
      NBListRow(
        title: metricType.displayName,
        value: "데이터 없음",
        subtitle: "mock sample이 없는 항목입니다.",
        systemImage: DailyRhythmUI.icon(for: metricType),
        tint: NBColor.neutral
      )
    }
  }

  private func conditionFlags(from checkIn: MorningCheckIn) -> String {
    var flags: [String] = []
    if checkIn.headache { flags.append("두통") }
    if checkIn.dryMouth { flags.append("입마름") }
    if checkIn.soreThroat { flags.append("목 불편감") }
    if checkIn.rememberedAwakenings > 0 {
      flags.append("기억나는 깸 \(checkIn.rememberedAwakenings)회")
    }
    return flags.isEmpty ? "추가 표시 항목 없음" : flags.joined(separator: " · ")
  }

  private func percentString(_ ratio: Double) -> String {
    String(format: "%.0f%%", min(max(ratio, 0), 1) * 100)
  }
}

#if DEBUG
struct MorningBriefView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      MorningBriefView(bundle: DailyRhythmMockFactory.makePreviewBundle())
    }
  }
}
#endif
