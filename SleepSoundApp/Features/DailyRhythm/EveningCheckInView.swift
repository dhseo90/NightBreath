import SwiftUI

struct EveningCheckInView: View {
  @State private var fatigueScore = 3
  @State private var stressScore = 3
  @State private var hasMoodScore = false
  @State private var moodScore = 3
  @State private var caffeine = false
  @State private var alcohol = false
  @State private var lateMeal = false
  @State private var exercise = false
  @State private var nap = false
  @State private var memo = ""
  @State private var savedCheckIn: EveningCheckIn?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        header
        scoreSection
        lifestyleSection
        memoSection
        saveSection
      }
      .padding(NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
    .navigationTitle("저녁 체크인")
  }

  private var header: some View {
    NBCard(background: NBColor.sleep.opacity(0.08), stroke: NBColor.sleep.opacity(0.18)) {
      VStack(alignment: .leading, spacing: NBSpacing.sm) {
        Label("저녁 체크인", systemImage: "moon.haze")
          .font(NBTypography.titleLarge)
          .foregroundStyle(NBColor.primaryText)
        Text("하루 피로도, 스트레스, 생활 태그를 회복 리듬에 참고용으로 남깁니다.")
          .font(NBTypography.callout)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
        NBStatusBadge("기기 안 예시 저장", kind: .neutral, systemImage: "sparkles")
      }
    }
  }

  private var scoreSection: some View {
    NBReportSection(title: "컨디션", systemImage: "slider.horizontal.3") {
      VStack(spacing: NBSpacing.md) {
        scoreStepper(title: "하루 피로도", value: $fatigueScore, systemImage: "battery.50percent", tint: NBColor.warning)
        scoreStepper(title: "스트레스", value: $stressScore, systemImage: "bolt.heart", tint: NBColor.danger)

        Toggle(isOn: $hasMoodScore) {
          Label("기분 기록", systemImage: "face.smiling")
            .font(.subheadline.weight(.semibold))
        }
        .tint(NBColor.dawn)

        if hasMoodScore {
          scoreStepper(title: "기분", value: $moodScore, systemImage: "face.smiling", tint: NBColor.dawn)
        }
      }
    }
  }

  private var lifestyleSection: some View {
    NBReportSection(title: "생활 태그", systemImage: "tag") {
      VStack(spacing: NBSpacing.sm) {
        Toggle("카페인", isOn: $caffeine)
        Toggle("음주", isOn: $alcohol)
        Toggle("야식", isOn: $lateMeal)
        Toggle("운동", isOn: $exercise)
        Toggle("낮잠", isOn: $nap)
      }
      .tint(NBColor.accent)
      .font(.subheadline.weight(.semibold))
    }
  }

  private var memoSection: some View {
    NBReportSection(title: "메모", systemImage: "note.text") {
      TextField("오늘 컨디션 메모", text: $memo, axis: .vertical)
        .lineLimit(3...6)
        .textFieldStyle(.roundedBorder)
    }
  }

  private var saveSection: some View {
    VStack(alignment: .leading, spacing: NBSpacing.md) {
      Button {
        saveCheckIn()
      } label: {
        Label("저녁 체크인 저장", systemImage: "checkmark.circle.fill")
      }
      .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.sleepTint))

      if let savedCheckIn {
        NBReportSection(title: "저장된 체크인", systemImage: "checkmark.seal") {
          VStack(spacing: NBSpacing.sm) {
            NBListRow(
              title: "저녁 컨디션",
              value: "피로 \(savedCheckIn.fatigueScore)/5 · 스트레스 \(savedCheckIn.stressScore)/5",
              subtitle: savedCheckIn.moodScore.map { "기분 \($0)/5" } ?? "기분 기록 없음",
              systemImage: "moon.haze",
              tint: NBColor.sleepTint
            )
            if !savedCheckIn.lifestyleTags.isEmpty {
              NBListRow(
                title: "생활 태그",
                value: savedCheckIn.lifestyleTags.map(\.displayName).joined(separator: " · "),
                subtitle: "하루 리듬 카드에 참고용으로 표시합니다.",
                systemImage: "tag",
                tint: NBColor.accent
              )
            }
          }
        }
      } else {
        NBEmptyStateView(
          title: "아직 저장된 체크인이 없습니다",
          message: "이번 단계에서는 저장 구조가 없어 화면 안에서만 임시로 보관합니다.",
          systemImage: "tray"
        )
      }
    }
  }

  private func scoreStepper(
    title: String,
    value: Binding<Int>,
    systemImage: String,
    tint: Color
  ) -> some View {
    HStack(spacing: NBSpacing.md) {
      Image(systemName: systemImage)
        .font(.body.weight(.semibold))
        .foregroundStyle(tint)
        .frame(width: 30, height: 30)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
        .accessibilityHidden(true)

      Stepper(value: value, in: 1...5) {
        HStack {
          Text(title)
            .font(.subheadline.weight(.semibold))
          Spacer()
          Text("\(value.wrappedValue)/5")
            .font(.subheadline.monospacedDigit().weight(.semibold))
            .foregroundStyle(NBColor.secondaryText)
        }
      }
    }
  }

  private func saveCheckIn() {
    // TODO: Wire this to a local Daily Rhythm repository when persistence is added.
    savedCheckIn = EveningCheckIn(
      date: Date(),
      fatigueScore: fatigueScore,
      stressScore: stressScore,
      moodScore: hasMoodScore ? moodScore : nil,
      caffeine: caffeine,
      alcohol: alcohol,
      lateMeal: lateMeal,
      exercise: exercise,
      nap: nap,
      memo: memo
    )
  }
}

#if DEBUG
struct EveningCheckInView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      EveningCheckInView()
    }
  }
}
#endif
