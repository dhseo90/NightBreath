import SwiftUI

struct DailyHealthCardView: View {
  let content: DailyHealthCardContent

  init(
    nightReport: NightReport? = nil,
    morningCheckIn: MorningCheckIn? = nil,
    referenceDate: Date = Date()
  ) {
    let bundle = DailyRhythmMockFactory.makeBundle(
      referenceDate: referenceDate,
      nightReport: nightReport,
      morningCheckIn: morningCheckIn
    )
    self.content = bundle.cardContent
  }

  init(content: DailyHealthCardContent) {
    self.content = content
  }

  init(bundle: DailyRhythmMockBundle) {
    self.content = bundle.cardContent
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        header
        DailyHealthCardSurface(content: content)
        NBPrivacyNoticeCard(
          title: "하루 리듬 카드 안내",
          messages: [
            content.referenceText,
            "이 앱은 진단 목적의 의료기기가 아닙니다.",
            "HealthKit 연결 없이 mock data로 표시합니다.",
          ],
          systemImage: "rectangle.on.rectangle"
        )
      }
      .padding(NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .navigationTitle("하루 리듬 카드")
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: NBSpacing.sm) {
      Text("하루 리듬 카드")
        .font(NBTypography.titleLarge)
        .foregroundStyle(NBColor.primaryText)
      Text("오늘의 리듬을 한 장의 카드로 정리합니다.")
        .font(NBTypography.callout)
        .foregroundStyle(NBColor.secondaryText)
    }
  }
}

// Kept as one rendering surface so a future SwiftUI-to-image path can reuse it.
private struct DailyHealthCardSurface: View {
  let content: DailyHealthCardContent

  var body: some View {
    NBCard(background: NBColor.accent.opacity(0.08), stroke: NBColor.accent.opacity(0.18)) {
      VStack(alignment: .leading, spacing: NBSpacing.lg) {
        HStack(alignment: .top, spacing: NBSpacing.lg) {
          VStack(alignment: .leading, spacing: NBSpacing.xs) {
            Text(SleepFormatters.shortDate(content.date))
              .font(NBTypography.captionEmphasis)
              .foregroundStyle(NBColor.secondaryText)
            Text("오늘의 리듬")
              .font(NBTypography.titleLarge)
              .foregroundStyle(NBColor.primaryText)
          }

          Spacer()

          if let rhythmScore = content.rhythmScore {
            VStack(alignment: .trailing, spacing: 0) {
              Text("\(rhythmScore)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(DailyRhythmUI.scoreTint(rhythmScore))
              Text("점")
                .font(NBTypography.captionEmphasis)
                .foregroundStyle(NBColor.secondaryText)
            }
            .accessibilityLabel("오늘의 리듬 점수 \(rhythmScore)점")
          }
        }

        Text(content.summaryText)
          .font(NBTypography.callout)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)

        if content.keyMetrics.isEmpty {
          NBEmptyStateView(
            title: "표시할 핵심 지표가 없습니다",
            message: "사용 가능한 mock data가 생기면 카드에 표시합니다.",
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

        HStack(spacing: NBSpacing.xs) {
          NBStatusBadge(
            "데이터 품질 \(content.dataQuality.displayName)",
            kind: DailyRhythmUI.dataQualityStatus(content.dataQuality),
            systemImage: "checkmark.seal"
          )
          NBStatusBadge("개인 참고용", kind: .neutral, systemImage: "person.text.rectangle")
        }
      }
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
