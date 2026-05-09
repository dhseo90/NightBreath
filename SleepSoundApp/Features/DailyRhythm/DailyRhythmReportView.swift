import SwiftUI

struct DailyRhythmReportView: View {
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
        DailyRhythmDataReadinessSection(summary: bundle.dataReadinessSummary)
        componentSection
        insightSection
        NBPrivacyNoticeCard(
          title: "리듬 리포트 안내",
          messages: [
            bundle.report.cautionText,
            "인과관계를 의미하지 않습니다.",
            "서버로 전송하지 않고 iPhone 안에서 사용 가능한 데이터로 구성합니다.",
          ],
          systemImage: "lock.shield"
        )
      }
      .padding(NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
    .navigationTitle("오늘의 리듬")
  }

  private var header: some View {
    NBCard(background: NBColor.accent.opacity(0.08), stroke: NBColor.accent.opacity(0.18)) {
      HStack(alignment: .center, spacing: NBSpacing.large) {
        DailyRhythmScoreRing(score: bundle.report.dailyRhythmScore.totalScore)

        VStack(alignment: .leading, spacing: NBSpacing.sm) {
          Text("오늘의 리듬 점수")
            .font(NBTypography.titleLarge)
            .foregroundStyle(NBColor.primaryText)

          Text("수면·활동·컨디션·건강 데이터를 함께 정리한 참고용 점수입니다.")
            .font(NBTypography.callout)
            .foregroundStyle(NBColor.secondaryText)
            .fixedSize(horizontal: false, vertical: true)

          ViewThatFits(in: .horizontal) {
            HStack(spacing: NBSpacing.xs) {
              rhythmHeaderBadges
            }
            VStack(alignment: .leading, spacing: NBSpacing.xs) {
              rhythmHeaderBadges
            }
          }
        }
      }
    }
  }

  @ViewBuilder
  private var rhythmHeaderBadges: some View {
    NBStatusBadge(
      "데이터 품질 \(bundle.report.dataQuality.displayName)",
      kind: DailyRhythmUI.dataQualityStatus(bundle.report.dataQuality),
      systemImage: "checkmark.seal"
    )
    NBStatusBadge("개인 참고용", kind: .neutral, systemImage: "person.text.rectangle")
  }

  private var componentSection: some View {
    NBReportSection(title: "구성 점수", systemImage: "slider.horizontal.3") {
      VStack(spacing: NBSpacing.md) {
        ComponentScoreRow(
          title: "수면",
          score: bundle.report.sleepComponentScore,
          systemImage: "moon.zzz",
          tint: NBColor.sleepTint
        )
        ComponentScoreRow(
          title: "회복 리듬",
          score: bundle.report.recoveryComponentScore,
          systemImage: "sunrise",
          tint: NBColor.dawn
        )
        ComponentScoreRow(
          title: "활동",
          score: bundle.report.activityComponentScore,
          systemImage: "figure.walk",
          tint: NBColor.mistTeal
        )
        ComponentScoreRow(
          title: "혈압",
          score: bundle.report.bloodPressureComponentScore,
          systemImage: "heart",
          tint: NBColor.danger
        )
        ComponentScoreRow(
          title: "체성분",
          score: bundle.report.bodyMetricComponentScore,
          systemImage: "scalemass",
          tint: NBColor.breathBlue
        )
      }
    }
  }

  private var insightSection: some View {
    NBReportSection(title: "Daily Insight", systemImage: "list.bullet.rectangle") {
      if bundle.report.insights.isEmpty {
        NBEmptyStateView(
          title: "표시할 인사이트가 없습니다",
          message: "비교 가능한 데이터가 쌓이면 관찰 중심의 문장을 표시합니다.",
          systemImage: "tray"
        )
      } else {
        VStack(spacing: NBSpacing.sm) {
          ForEach(bundle.report.insights) { insight in
            DailyInsightRow(insight: insight)
          }
        }
      }
    }
  }
}

private struct ComponentScoreRow: View {
  let title: String
  let score: Int
  let systemImage: String
  let tint: Color

  var body: some View {
    VStack(alignment: .leading, spacing: NBSpacing.xs) {
      HStack(spacing: NBSpacing.sm) {
        Image(systemName: systemImage)
          .font(.body.weight(.semibold))
          .foregroundStyle(tint)
          .frame(width: 28, height: 28)
          .background(tint.opacity(0.10))
          .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
          .accessibilityHidden(true)

        Text(title)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(NBColor.primaryText)

        Spacer()

        Text("\(score)점")
          .font(.subheadline.monospacedDigit().weight(.semibold))
          .foregroundStyle(NBColor.secondaryText)
      }

      ProgressView(value: Double(DailyRhythmScore.clampedScore(score)), total: 100)
        .tint(tint)
        .accessibilityLabel("\(title) 구성 점수 \(score)점")
    }
    .padding(.vertical, NBSpacing.xs)
  }
}

private struct DailyInsightRow: View {
  let insight: DailyInsight

  var body: some View {
    HStack(alignment: .top, spacing: NBSpacing.sm) {
      NBListRow(
        title: insight.title,
        value: insight.type.displayName,
        subtitle: insight.message,
        systemImage: DailyRhythmUI.icon(for: insight.type),
        tint: DailyRhythmUI.tint(for: nil)
      )
      .frame(maxWidth: .infinity)

      NBStatusBadge(
        insight.severity.displayName,
        kind: DailyRhythmUI.insightStatus(insight.severity)
      )
    }
  }
}

#if DEBUG
struct DailyRhythmReportView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      DailyRhythmReportView(bundle: DailyRhythmMockFactory.makePreviewBundle())
    }
  }
}
#endif
