import SwiftUI

struct DailyHealthCardPreviewView: View {
  let bundle: DailyRhythmMockBundle
  @State private var template: DailyHealthCardTemplate = .healthSummary
  @State private var privacyLevel: DailyHealthCardPrivacyLevel = .standard

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
        controls
        DailyHealthCardSurface(content: content)
        rendererNotice
      }
      .padding(NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .navigationTitle("카드 미리보기")
  }

  private var controls: some View {
    NBReportSection(title: "카드 설정", systemImage: "slider.horizontal.3") {
      VStack(alignment: .leading, spacing: NBSpacing.md) {
        Text("템플릿")
          .font(NBTypography.captionEmphasis)
          .foregroundStyle(NBColor.secondaryText)
        Picker("템플릿", selection: $template) {
          ForEach(DailyHealthCardTemplate.allCases) { template in
            Text(template.shortDisplayName).tag(template)
          }
        }
        .pickerStyle(.segmented)

        Text("표시 수준")
          .font(NBTypography.captionEmphasis)
          .foregroundStyle(NBColor.secondaryText)
        Picker("표시 수준", selection: $privacyLevel) {
          ForEach(DailyHealthCardPrivacyLevel.allCases) { level in
            Text(level.displayName).tag(level)
          }
        }
        .pickerStyle(.segmented)
        .disabled(template == .privacyMinimal)

        Text(effectivePrivacyLevel.description)
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private var rendererNotice: some View {
    NBPrivacyNoticeCard(
      title: "이미지 카드 export 준비",
      messages: [
        "현재는 미리보기와 placeholder renderer만 준비되어 있습니다.",
        "민감 데이터가 포함된 이미지는 사용자가 명시적으로 선택할 때만 내보내는 방향입니다.",
        "자동 공유와 서버 업로드는 없습니다.",
        "이 앱은 진단 목적의 의료기기가 아닙니다.",
      ],
      systemImage: "lock.shield"
    )
  }

  private var content: DailyHealthCardContent {
    DailyHealthCardContent.make(
      date: bundle.date,
      report: bundle.report,
      nightReport: bundle.nightReport,
      healthMetricSamples: bundle.healthSamples,
      template: template,
      privacyLevel: privacyLevel
    )
  }

  private var effectivePrivacyLevel: DailyHealthCardPrivacyLevel {
    template.effectivePrivacyLevel ?? privacyLevel
  }
}

#if DEBUG
struct DailyHealthCardPreviewView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      DailyHealthCardPreviewView(bundle: DailyRhythmMockFactory.makePreviewBundle())
    }
  }
}
#endif
