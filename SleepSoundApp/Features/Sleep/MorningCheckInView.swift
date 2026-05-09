import SwiftUI

struct MorningCheckInView: View {
  @EnvironmentObject private var appState: AppState

  let sessionId: UUID

  @State private var refreshScore = 3
  @State private var fatigueScore = 3
  @State private var headache = false
  @State private var dryMouth = false
  @State private var soreThroat = false
  @State private var rememberedAwakenings = 0
  @State private var memo = ""
  @State private var didLoadExisting = false
  @State private var saved = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        headerCard
        scoreSummary
        conditionSection
        symptomSection
        memoSection
        NBPrivacyNoticeCard(
          title: "아침 컨디션 기록",
          messages: [
            "주관적으로 느낀 컨디션을 수면 리포트와 함께 기록합니다.",
            "이 앱은 진단 목적의 의료기기가 아닙니다.",
          ],
          systemImage: "heart.text.square"
        )
        saveButton
      }
      .padding(.horizontal, NBSpacing.screenHorizontal)
      .padding(.vertical, NBSpacing.sectionVertical)
    }
    .navigationTitle("아침 체크인")
    .background(NBColor.pageBackground)
    .toolbar(.hidden, for: .tabBar)
    .onAppear(perform: loadExistingIfNeeded)
  }

  private var headerCard: some View {
    NBCard(background: NBColor.sleep.opacity(0.08), stroke: NBColor.sleep.opacity(0.18)) {
      HStack(alignment: .center, spacing: NBSpacing.lg) {
        NBIllustration(kind: .moonSleep)
          .frame(width: 116, height: 76)
          .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: NBSpacing.sm) {
          HStack(spacing: NBSpacing.xs) {
            NBStatusBadge("주관적 기록", kind: .neutral, systemImage: "pencil.and.list.clipboard")
            if saved {
              NBStatusBadge("저장됨", kind: .good, systemImage: "checkmark.circle")
            }
          }

          Text("아침 컨디션")
            .font(NBTypography.title)
            .foregroundStyle(NBColor.primaryText)

          Text("잠에서 깬 뒤 느낀 개운함, 피로감, 기억나는 각성을 간단히 남깁니다.")
            .font(NBTypography.body)
            .foregroundStyle(NBColor.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
    .accessibilityElement(children: .combine)
  }

  private var scoreSummary: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.md) {
      NBMetricCard(
        title: "개운함",
        value: "\(refreshScore)",
        unit: "/5",
        subtitle: checkInTone(for: refreshScore, highIsPositive: true),
        systemImage: "sun.horizon",
        tint: NBColor.dawn,
        status: refreshScore >= 4 ? .good : .neutral,
        accessibilityLabel: "개운함 \(refreshScore)점, 5점 만점"
      )

      NBMetricCard(
        title: "피로감",
        value: "\(fatigueScore)",
        unit: "/5",
        subtitle: checkInTone(for: fatigueScore, highIsPositive: false),
        systemImage: "moon.zzz",
        tint: fatigueScore >= 4 ? NBColor.caution : NBColor.sleep,
        status: fatigueScore >= 4 ? .caution : .neutral,
        accessibilityLabel: "피로감 \(fatigueScore)점, 5점 만점"
      )

      NBMetricCard(
        title: "기억나는 각성",
        value: "\(rememberedAwakenings)",
        unit: "회",
        subtitle: "직접 기억한 횟수",
        systemImage: "eye",
        tint: rememberedAwakenings == 0 ? NBColor.success : NBColor.warning,
        status: rememberedAwakenings == 0 ? .good : .caution,
        accessibilityLabel: "기억나는 중간 각성 \(rememberedAwakenings)회"
      )

      NBMetricCard(
        title: "기록 상태",
        value: saved ? "저장됨" : "작성 중",
        subtitle: saved ? "체크인이 반영되었습니다" : "저장 버튼을 눌러 반영합니다",
        systemImage: saved ? "checkmark.circle" : "square.and.pencil",
        tint: saved ? NBColor.success : NBColor.breath,
        status: saved ? .good : .neutral,
        accessibilityLabel: saved ? "아침 체크인 저장됨" : "아침 체크인 작성 중"
      )
    }
  }

  private var conditionSection: some View {
    NBReportSection(
      title: "컨디션 점수",
      subtitle: "점수는 사용자의 주관적인 느낌을 기록하기 위한 값입니다.",
      systemImage: "slider.horizontal.3"
    ) {
      VStack(spacing: NBSpacing.md) {
        CheckInStepperRow(
          title: "개운함",
          subtitle: "높을수록 더 개운하게 느껴진 상태",
          systemImage: "sun.horizon",
          value: $refreshScore,
          range: 1...5,
          suffix: "/5",
          tint: NBColor.dawn
        )

        Divider().background(NBColor.divider)

        CheckInStepperRow(
          title: "피로감",
          subtitle: "높을수록 더 피곤하게 느껴진 상태",
          systemImage: "moon.zzz",
          value: $fatigueScore,
          range: 1...5,
          suffix: "/5",
          tint: NBColor.sleep
        )

        Divider().background(NBColor.divider)

        CheckInStepperRow(
          title: "기억나는 중간 각성",
          subtitle: "잠에서 깬 것으로 기억하는 횟수",
          systemImage: "eye",
          value: $rememberedAwakenings,
          range: 0...20,
          suffix: "회",
          tint: NBColor.warning
        )
      }
    }
  }

  private var symptomSection: some View {
    NBReportSection(
      title: "느껴진 상태",
      subtitle: "아침에 직접 느낀 항목만 켜 주세요.",
      systemImage: "checklist"
    ) {
      VStack(spacing: NBSpacing.md) {
        SymptomToggleRow(
          title: "두통",
          subtitle: "일어나서 머리가 불편하게 느껴졌나요?",
          systemImage: "brain.head.profile",
          isOn: $headache,
          tint: NBColor.warning
        )

        Divider().background(NBColor.divider)

        SymptomToggleRow(
          title: "입마름",
          subtitle: "입이 마른 느낌이 있었나요?",
          systemImage: "drop",
          isOn: $dryMouth,
          tint: NBColor.breath
        )

        Divider().background(NBColor.divider)

        SymptomToggleRow(
          title: "목아픔",
          subtitle: "목이 따갑거나 불편하게 느껴졌나요?",
          systemImage: "waveform",
          isOn: $soreThroat,
          tint: NBColor.caution
        )
      }
    }
  }

  private var memoSection: some View {
    NBReportSection(
      title: "메모",
      subtitle: "기억나는 수면 환경이나 아침 느낌을 자유롭게 남길 수 있습니다.",
      systemImage: "text.alignleft"
    ) {
      TextEditor(text: $memo)
        .font(NBTypography.body)
        .foregroundStyle(NBColor.primaryText)
        .scrollContentBackground(.hidden)
        .frame(minHeight: 140)
        .padding(NBSpacing.sm)
        .background(NBColor.elevatedCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.medium, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: NBCornerRadius.medium, style: .continuous)
            .stroke(NBColor.border.opacity(0.65), lineWidth: 0.7)
        )
        .accessibilityLabel("아침 체크인 메모")
    }
  }

  private var saveButton: some View {
    VStack(alignment: .leading, spacing: NBSpacing.sm) {
      NBPrimaryButton(
        title: saved ? "저장됨" : "체크인 저장",
        systemImage: saved ? "checkmark.circle.fill" : "tray.and.arrow.down"
      ) {
        save()
      }
      .accessibilityLabel(saved ? "아침 체크인 저장됨" : "아침 체크인 저장")

      if saved {
        NBInlineStatus(
          title: "아침 체크인 저장 완료",
          detail: "저장한 컨디션 기록이 이 수면 리포트와 기기 안 로컬 데이터에 반영됩니다.",
          kind: .good,
          systemImage: "checkmark.circle.fill"
        )
      }
    }
  }

  private func loadExistingIfNeeded() {
    guard !didLoadExisting else { return }
    didLoadExisting = true

    guard appState.morningCheckIn.sessionId == sessionId else { return }
    refreshScore = appState.morningCheckIn.refreshScore
    fatigueScore = appState.morningCheckIn.fatigueScore
    headache = appState.morningCheckIn.headache
    dryMouth = appState.morningCheckIn.dryMouth
    soreThroat = appState.morningCheckIn.soreThroat
    rememberedAwakenings = appState.morningCheckIn.rememberedAwakenings
    memo = appState.morningCheckIn.memo
  }

  private func save() {
    let checkIn = MorningCheckIn(
      sessionId: sessionId,
      refreshScore: refreshScore,
      fatigueScore: fatigueScore,
      headache: headache,
      dryMouth: dryMouth,
      soreThroat: soreThroat,
      rememberedAwakenings: rememberedAwakenings,
      memo: memo
    )
    appState.saveMorningCheckIn(checkIn)
    saved = true
  }

  private func checkInTone(for value: Int, highIsPositive: Bool) -> String {
    switch (value, highIsPositive) {
    case (4...5, true):
      return "가볍게 시작"
    case (1...2, true):
      return "조금 무거움"
    case (4...5, false):
      return "피로감 높음"
    case (1...2, false):
      return "피로감 낮음"
    default:
      return "보통"
    }
  }
}

private struct CheckInStepperRow: View {
  let title: String
  let subtitle: String
  let systemImage: String
  @Binding var value: Int
  let range: ClosedRange<Int>
  let suffix: String
  let tint: Color

  var body: some View {
    Stepper(value: $value, in: range) {
      HStack(alignment: .center, spacing: NBSpacing.md) {
        Image(systemName: systemImage)
          .font(.body.weight(.semibold))
          .foregroundStyle(tint)
          .frame(width: 34, height: 34)
          .background(tint.opacity(0.12))
          .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
          .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: NBSpacing.xxs) {
          Text(title)
            .font(NBTypography.bodyEmphasis)
            .foregroundStyle(NBColor.primaryText)
          Text(subtitle)
            .font(NBTypography.caption)
            .foregroundStyle(NBColor.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
        }

        Spacer(minLength: NBSpacing.sm)

        Text("\(value)\(suffix)")
          .font(NBTypography.bodyEmphasis.monospacedDigit())
          .foregroundStyle(NBColor.primaryText)
          .lineLimit(1)
          .accessibilityHidden(true)
      }
      .padding(.vertical, NBSpacing.xs)
    }
    .accessibilityLabel("\(title) \(value)\(suffix)")
  }
}

private struct SymptomToggleRow: View {
  let title: String
  let subtitle: String
  let systemImage: String
  @Binding var isOn: Bool
  let tint: Color

  var body: some View {
    Toggle(isOn: $isOn) {
      HStack(alignment: .center, spacing: NBSpacing.md) {
        Image(systemName: systemImage)
          .font(.body.weight(.semibold))
          .foregroundStyle(tint)
          .frame(width: 34, height: 34)
          .background(tint.opacity(0.12))
          .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
          .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: NBSpacing.xxs) {
          HStack(spacing: NBSpacing.xs) {
            Text(title)
              .font(NBTypography.bodyEmphasis)
              .foregroundStyle(NBColor.primaryText)
            NBStatusBadge(isOn ? "기록" : "없음", kind: isOn ? .caution : .neutral)
          }

          Text(subtitle)
            .font(NBTypography.caption)
            .foregroundStyle(NBColor.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      .padding(.vertical, NBSpacing.xs)
    }
    .tint(tint)
    .accessibilityLabel("\(title) \(isOn ? "있음" : "없음")")
  }
}
