import SwiftUI

struct DailyHealthCardView: View {
  let content: DailyHealthCardContent

  init(
    nightReport: NightReport? = nil,
    morningCheckIn: MorningCheckIn? = nil,
    referenceDate: Date = Date(),
    template: DailyHealthCardTemplate = .healthSummary,
    privacyLevel: DailyHealthCardPrivacyLevel = .standard
  ) {
    let bundle = DailyRhythmMockFactory.makeBundle(
      referenceDate: referenceDate,
      nightReport: nightReport,
      morningCheckIn: morningCheckIn
    )
    self.content = DailyHealthCardContent.make(
      date: bundle.date,
      report: bundle.report,
      nightReport: bundle.nightReport,
      healthMetricSamples: bundle.healthSamples,
      template: template,
      privacyLevel: privacyLevel
    )
  }

  init(content: DailyHealthCardContent) {
    self.content = content
  }

  init(
    bundle: DailyRhythmMockBundle,
    template: DailyHealthCardTemplate = .healthSummary,
    privacyLevel: DailyHealthCardPrivacyLevel = .standard
  ) {
    self.content = DailyHealthCardContent.make(
      date: bundle.date,
      report: bundle.report,
      nightReport: bundle.nightReport,
      healthMetricSamples: bundle.healthSamples,
      template: template,
      privacyLevel: privacyLevel
    )
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        header
        DailyHealthCardSurface(content: content)
        NBPrivacyNoticeCard(
          title: "개인정보 안내",
          messages: [
            content.referenceText,
            "\(content.privacyLevel.displayName) 표시 수준으로 구성했습니다.",
            "이 앱은 진단 목적의 의료기기가 아닙니다.",
            "이미지 내보내기와 공유는 사용자가 명시적으로 선택할 때만 진행합니다.",
          ],
          systemImage: "lock.shield"
        )
      }
      .padding(NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
    .navigationTitle("하루 리듬 카드")
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: NBSpacing.sm) {
      Text("공유 전 미리보기")
        .font(NBTypography.titleLarge)
        .foregroundStyle(NBColor.primaryText)
      Text("오늘의 리듬을 개인 참고용 이미지 카드로 정리합니다.")
        .font(NBTypography.callout)
        .foregroundStyle(NBColor.secondaryText)
      HStack(spacing: NBSpacing.xs) {
        NBStatusBadge(content.template.displayName, kind: .neutral, systemImage: "rectangle.3.group")
        NBStatusBadge(content.privacyLevel.displayName, kind: privacyStatus, systemImage: "lock.shield")
      }
    }
  }

  private var privacyStatus: NBStatusKind {
    switch content.privacyLevel {
    case .minimal:
      .privacy
    case .standard:
      .neutral
    case .detailed:
      .debug
    }
  }
}

// Kept as one rendering surface so a future SwiftUI-to-image path can reuse it.
struct DailyHealthCardSurface: View {
  let content: DailyHealthCardContent

  var body: some View {
    NBCard(padding: NBSpacing.xl, background: templateTint.opacity(0.09), stroke: templateTint.opacity(0.20)) {
      VStack(alignment: .leading, spacing: NBSpacing.lg) {
        cardHeader

        Text(content.summaryText)
          .font(NBTypography.callout)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)

        if content.privacyLevel == .minimal {
          minimalScoreBlock
        } else if content.keyMetrics.isEmpty {
          NBEmptyStateView(
            title: "표시할 핵심 지표가 없습니다",
            message: "사용 가능한 예시 데이터가 생기면 카드에 표시합니다.",
            systemImage: "tray"
          )
        } else {
          VStack(spacing: NBSpacing.sm) {
            ForEach(content.keyMetrics) { metric in
              NBListRow(
                title: metric.title,
                value: metric.value,
                subtitle: metric.subtitle,
                systemImage: DailyRhythmUI.icon(for: metric.metricType),
                tint: DailyRhythmUI.tint(for: metric.metricType)
              )
            }
          }
        }

        footer
      }
    }
    .frame(maxWidth: 420)
    .frame(maxWidth: .infinity)
  }

  private var cardHeader: some View {
    HStack(alignment: .top, spacing: NBSpacing.lg) {
      VStack(alignment: .leading, spacing: NBSpacing.xs) {
        Text("NightBreath / 밤숨")
          .font(NBTypography.captionEmphasis)
          .foregroundStyle(NBColor.secondaryText)
        Text(SleepFormatters.shortDate(content.date))
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
        Text("오늘의 리듬")
          .font(NBTypography.titleLarge)
          .foregroundStyle(NBColor.primaryText)
      }

      Spacer()

      if let rhythmScore = content.rhythmScore {
        VStack(alignment: .trailing, spacing: 0) {
          Text("\(rhythmScore)")
            .font(.system(size: content.privacyLevel == .minimal ? 54 : 40, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(DailyRhythmUI.scoreTint(rhythmScore))
          Text("점")
            .font(NBTypography.captionEmphasis)
            .foregroundStyle(NBColor.secondaryText)
        }
        .accessibilityLabel("오늘의 리듬 점수 \(rhythmScore)점")
      }
    }
  }

  private var minimalScoreBlock: some View {
    VStack(alignment: .leading, spacing: NBSpacing.md) {
      if let rhythmScore = content.rhythmScore {
        DailyRhythmScoreRing(score: rhythmScore, title: "오늘의 리듬 점수", tint: DailyRhythmUI.scoreTint(rhythmScore))
          .frame(maxWidth: .infinity)
      }
      Text("민감 수치를 줄인 카드입니다.")
        .font(NBTypography.caption)
        .foregroundStyle(NBColor.secondaryText)
    }
  }

  private var footer: some View {
    VStack(alignment: .leading, spacing: NBSpacing.sm) {
      HStack(spacing: NBSpacing.xs) {
        if content.privacyLevel != .minimal {
          NBStatusBadge(
            "데이터 품질 \(content.dataQuality.displayName)",
            kind: DailyRhythmUI.dataQualityStatus(content.dataQuality),
            systemImage: "checkmark.seal"
          )
        }
        NBStatusBadge("개인 참고용", kind: .neutral, systemImage: "person.text.rectangle")
      }

      Text("자동 공유 없음")
        .font(NBTypography.caption)
        .foregroundStyle(NBColor.tertiaryText)
    }
  }

  private var templateTint: Color {
    switch content.template {
    case .simple:
      NBColor.accent
    case .sleepFocused:
      NBColor.sleepTint
    case .healthSummary:
      NBColor.privacyTint
    case .privacyMinimal:
      NBColor.neutral
    }
  }
}

#if DEBUG
struct DailyHealthCardView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      DailyHealthCardView(bundle: DailyRhythmMockFactory.makePreviewBundle())
    }
  }
}
#endif
