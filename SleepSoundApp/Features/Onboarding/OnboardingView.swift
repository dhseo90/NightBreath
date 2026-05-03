import SwiftUI

struct OnboardingView: View {
  @EnvironmentObject private var appState: AppState
  @State private var step: OnboardingStep = .intro
  @State private var isRequestingPermission = false

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        ProgressView(value: progress)
          .tint(NBColor.sleepTint)
          .padding(.horizontal, NBSpacing.large)
          .padding(.top, NBSpacing.large)

        ScrollView {
          VStack(alignment: .leading, spacing: NBSpacing.xLarge) {
            header
            content
          }
          .padding(NBSpacing.large)
        }

        footer
      }
      .background(NBColor.pageBackground)
      .navigationTitle("밤숨 시작하기")
    }
  }

  private var progress: Double {
    Double(step.index + 1) / Double(OnboardingStep.allCases.count)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: NBSpacing.small) {
      NBIllustration(kind: step.illustration)
        .frame(height: 156)
        .padding(.bottom, NBSpacing.sm)

      Label(step.shortTitle, systemImage: step.systemImage)
        .font(.caption.weight(.semibold))
        .foregroundStyle(NBColor.sleepTint)
      Text(step.title)
        .font(.largeTitle.bold())
        .foregroundStyle(NBColor.nightInk)
      Text(step.subtitle)
        .font(.callout)
        .foregroundStyle(NBColor.secondaryText)
    }
  }

  @ViewBuilder
  private var content: some View {
    switch step {
    case .intro:
      IntroStep()
    case .privacy:
      PrincipleList(
        rows: [
          .init(systemImage: "iphone", title: "온디바이스 분석", description: "수면 중 들어온 소리 기반 지표는 iPhone 안에서 처리합니다."),
          .init(systemImage: "wifi.slash", title: "서버 전송 없음", description: "계정, 클라우드 처리, 원격 분석 SDK를 사용하지 않습니다."),
          .init(systemImage: "text.bubble", title: "잠꼬대 텍스트 변환 없음", description: "말소리를 텍스트로 바꾸는 기능은 넣지 않습니다."),
        ]
      )
    case .noFullNightAudio:
      PrincipleList(
        rows: [
          .init(systemImage: "moon.zzz", title: "전체 밤 오디오 미저장", description: "기본 동작으로 밤새 원본 오디오 전체를 파일로 남기지 않습니다."),
          .init(systemImage: "doc.text", title: "로컬 요약 중심", description: "수면 세션, 이벤트, 리포트 같은 요약 metadata만 로컬에 저장합니다."),
          .init(systemImage: "trash", title: "삭제 가능", description: "설정에서 수면 데이터와 이벤트 오디오 샘플을 따로 삭제할 수 있습니다."),
        ]
      )
    case .eventSamples:
      EventAudioOptInStep()
    case .placement:
      PlacementStep()
    case .microphone:
      MicrophoneStep(isRequestingPermission: isRequestingPermission) {
        requestMicrophonePermission()
      }
    case .calibration:
      CalibrationView(showsTitle: false)
    }
  }

  private var footer: some View {
    VStack(spacing: NBSpacing.small) {
      HStack(spacing: NBSpacing.medium) {
        Button {
          moveBackward()
        } label: {
          Label("이전", systemImage: "chevron.left")
        }
        .buttonStyle(.nbSecondary)
        .disabled(step == OnboardingStep.allCases.first)

        Button {
          moveForwardOrFinish()
        } label: {
          Label(step == OnboardingStep.allCases.last ? "시작하기" : "다음", systemImage: step == OnboardingStep.allCases.last ? "checkmark" : "chevron.right")
        }
        .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.sleepTint))
      }

      Text("밤숨은 수면 소리 변화를 살펴보는 웰니스 앱입니다. 전문적인 건강 판단을 대신하지 않습니다.")
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding(NBSpacing.large)
    .background(NBColor.surface)
  }

  private func moveBackward() {
    guard let previous = step.previous else { return }
    step = previous
  }

  private func moveForwardOrFinish() {
    guard let next = step.next else {
      appState.completeOnboarding()
      return
    }
    step = next
  }

  private func requestMicrophonePermission() {
    isRequestingPermission = true
    Task {
      _ = await appState.requestMicrophonePermission()
      isRequestingPermission = false
    }
  }
}

private enum OnboardingStep: Int, CaseIterable, Identifiable {
  case intro
  case privacy
  case noFullNightAudio
  case eventSamples
  case placement
  case microphone
  case calibration

  var id: Int { rawValue }
  var index: Int { rawValue }

  var title: String {
    switch self {
    case .intro:
      "밤숨"
    case .privacy:
      "iPhone 안에서 분석합니다"
    case .noFullNightAudio:
      "전체 밤 오디오는 저장하지 않습니다"
    case .eventSamples:
      "이벤트 오디오 샘플은 선택 사항입니다"
    case .placement:
      "iPhone 배치를 확인하세요"
    case .microphone:
      "마이크 권한이 필요합니다"
    case .calibration:
      "30초 캘리브레이션"
    }
  }

  var shortTitle: String {
    switch self {
    case .intro:
      "수면 소리 리포트"
    case .privacy:
      "개인정보"
    case .noFullNightAudio:
      "오디오 보관"
    case .eventSamples:
      "Opt-in"
    case .placement:
      "배치 가이드"
    case .microphone:
      "권한"
    case .calibration:
      "입력 확인"
    }
  }

  var subtitle: String {
    switch self {
    case .intro:
      "코골기, 이갈이 의심 소리, 기침 의심 소리, 환경 소음 같은 수면 소리 이벤트를 아침 리포트로 정리합니다."
    case .privacy:
      "분석과 저장은 로컬 중심으로 설계했습니다."
    case .noFullNightAudio:
      "밤새 녹음 파일을 남기는 앱이 아니라, 수면 소리 지표를 만드는 앱입니다."
    case .eventSamples:
      "원할 때만 짧은 이벤트 전후 샘플을 로컬에 저장할 수 있습니다."
    case .placement:
      "소리 입력이 안정적이어야 리포트도 더 참고하기 좋습니다."
    case .microphone:
      "수면 소리 입력을 받기 위해 마이크 접근 허용이 필요합니다."
    case .calibration:
      "주변 소음 baseline과 입력 상태를 짧게 확인합니다. Simulator에서는 예시 입력으로 동작합니다."
    }
  }

  var systemImage: String {
    switch self {
    case .intro:
      "moon.zzz"
    case .privacy:
      "lock.shield"
    case .noFullNightAudio:
      "externaldrive.badge.xmark"
    case .eventSamples:
      "waveform.circle"
    case .placement:
      "iphone"
    case .microphone:
      "mic"
    case .calibration:
      "waveform.badge.magnifyingglass"
    }
  }

  var illustration: NBIllustrationKind {
    switch self {
    case .intro:
      .moonBreath
    case .privacy:
      .privacyOnDevice
    case .noFullNightAudio:
      .sleepReport
    case .eventSamples:
      .breath
    case .placement:
      .devicePlacement
    case .microphone:
      .privacyOnDevice
    case .calibration:
      .breath
    }
  }

  var next: OnboardingStep? {
    OnboardingStep(rawValue: rawValue + 1)
  }

  var previous: OnboardingStep? {
    OnboardingStep(rawValue: rawValue - 1)
  }
}

private struct IntroStep: View {
  var body: some View {
    NBCard {
      VStack(alignment: .leading, spacing: NBSpacing.medium) {
        Text("밤숨은 iPhone으로 수면 중 소리 변화를 살펴보고 아침에 읽기 쉬운 리포트로 정리합니다.")
          .font(.headline)
        Text("결과는 수면 소리 점수와 이벤트 추세를 이해하기 위한 참고 정보입니다.")
          .font(.callout)
          .foregroundStyle(NBColor.secondaryText)
      }
    }
  }
}

private struct EventAudioOptInStep: View {
  @EnvironmentObject private var appState: AppState

  var body: some View {
    NBReportSection(title: "이벤트 오디오 샘플", systemImage: "waveform.circle") {
      Toggle(
        isOn: Binding(
          get: { appState.isEventAudioSampleStorageEnabled },
          set: { appState.setEventAudioSampleStorageEnabled($0) }
        )
      ) {
        VStack(alignment: .leading, spacing: 4) {
          Text("짧은 이벤트 오디오 샘플 저장")
            .font(.headline)
          Text("기본값은 꺼짐입니다. 켜면 감지 이벤트 전후의 짧은 샘플만 로컬에 저장합니다.")
            .font(.callout)
            .foregroundStyle(NBColor.secondaryText)
        }
      }

      Text("샘플은 전체 밤 오디오가 아니며, 저장 개수와 용량 제한 및 삭제 기능을 유지합니다.")
        .font(.footnote)
        .foregroundStyle(NBColor.secondaryText)
    }
  }
}

private struct PlacementStep: View {
  var body: some View {
    PrincipleList(
      rows: [
        .init(systemImage: "table.furniture", title: "침대 옆 탁자", description: "머리맡 근처의 안정적인 위치에 놓습니다."),
        .init(systemImage: "mic", title: "마이크 열어두기", description: "이불, 베개, 케이스가 마이크를 막지 않게 합니다."),
        .init(systemImage: "battery.100", title: "충전 연결", description: "밤새 측정을 위해 전원 연결을 권장합니다."),
        .init(systemImage: "shippingbox", title: "밀폐 위치 피하기", description: "서랍 안, 가방 안, 너무 먼 위치는 피합니다."),
      ]
    )
  }
}

private struct MicrophoneStep: View {
  @EnvironmentObject private var appState: AppState
  let isRequestingPermission: Bool
  let onRequestPermission: () -> Void

  var body: some View {
    NBReportSection(title: "마이크 권한", systemImage: "mic") {
      HStack {
        Text("현재 상태")
          .font(.callout.weight(.semibold))
        Spacer()
        Text(appState.microphonePermissionState.displayText)
          .font(.callout.weight(.semibold))
          .foregroundStyle(permissionTint)
      }

      Button {
        onRequestPermission()
      } label: {
        Label(isRequestingPermission ? "요청 중" : "마이크 권한 요청", systemImage: "mic.badge.plus")
      }
      .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.audioTint))
      .disabled(isRequestingPermission || appState.microphonePermissionState == .granted)

      Text("마이크 입력은 수면 소리 이벤트를 감지하기 위해 사용합니다. 서버 전송이나 전체 밤 오디오 파일 저장을 추가하지 않습니다.")
        .font(.footnote)
        .foregroundStyle(NBColor.secondaryText)
    }
  }

  private var permissionTint: Color {
    switch appState.microphonePermissionState {
    case .granted:
      NBColor.success
    case .notDetermined:
      NBColor.warning
    case .denied:
      NBColor.danger
    }
  }
}

private struct PrincipleList: View {
  let rows: [OnboardingInfoRow]

  var body: some View {
    NBCard {
      VStack(spacing: NBSpacing.medium) {
        ForEach(rows) { row in
          NBListRow(
            title: row.title,
            subtitle: row.description,
            systemImage: row.systemImage,
            tint: NBColor.sleepTint
          )
        }
      }
    }
  }
}

private struct OnboardingInfoRow: Identifiable {
  var id: String { title }
  let systemImage: String
  let title: String
  let description: String
}
