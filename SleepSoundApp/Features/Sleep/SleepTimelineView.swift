import AVFoundation
import SwiftUI

struct SleepTimelineView: View {
  @EnvironmentObject private var appState: AppState

  let report: NightReport
  let events: [SleepEvent]
  @StateObject private var feedbackViewModel = SleepEventFeedbackViewModel()

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.xLarge) {
        NBCard {
          VStack(alignment: .leading, spacing: NBSpacing.small) {
            Text("이벤트 타임라인")
              .font(.title2.bold())
            Text("감지된 수면 중 소리 이벤트를 시간 순서로 확인합니다.")
              .font(.callout)
              .foregroundStyle(.secondary)
          }
        }

        NBCard {
          EventTimelineBand(events: events)
            .frame(height: 130)
        }

        if events.isEmpty {
          NBPrivacyNoticeCard(
            title: "감지된 이벤트 없음",
            message: "오디오 입력이 정상이어도 detector 기준을 통과한 이벤트가 없을 수 있습니다.",
            systemImage: "waveform.slash"
          )
        } else {
          VStack(alignment: .leading, spacing: NBSpacing.medium) {
            ForEach(events) { event in
              EventRow(
                event: event,
                feedback: feedbackViewModel.feedback(for: event.id),
                hasSnippet: feedbackViewModel.hasSnippet(for: event),
                snippetDuration: event.audioSnippetDuration,
                isEventAudioSampleStorageEnabled: appState.isEventAudioSampleStorageEnabled
              ) { selection in
                feedbackViewModel.saveFeedback(for: event, selection: selection)
              } onPlaySnippet: {
                feedbackViewModel.playSnippet(for: event)
              } onDeleteSnippet: {
                appState.deleteEventAudioSnippet(for: event.id)
                feedbackViewModel.markSnippetDeleted(for: event)
              }
            }
          }
        }
      }
      .padding(NBSpacing.large)
    }
    .navigationTitle("타임라인")
    .background(NBColor.pageBackground)
  }
}

struct EventTimelineBand: View {
  let events: [SleepEvent]

  var body: some View {
    GeometryReader { proxy in
      if let start = events.map(\.startedAt).min(),
        let end = events.map(\.endedAt).max()
      {
        let total = max(end.timeIntervalSince(start), 1)

        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 4)
            .fill(NBColor.cardStroke.opacity(0.65))
            .frame(height: 6)
            .position(x: proxy.size.width / 2, y: proxy.size.height - 24)

          ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
            let x = proxy.size.width * CGFloat(event.startedAt.timeIntervalSince(start) / total)
            let width = max(CGFloat(4), proxy.size.width * CGFloat(event.duration / total))
            Capsule()
              .fill(event.type.tintColor.opacity(0.82))
              .frame(width: min(width, proxy.size.width), height: 10)
              .position(
                x: min(proxy.size.width - width / 2, max(width / 2, x + width / 2)),
                y: yPosition(for: index))
          }

          Text(SleepFormatters.shortTime(start))
            .font(.caption2)
            .foregroundStyle(.secondary)
            .position(x: 24, y: proxy.size.height - 4)

          Text(SleepFormatters.shortTime(end))
            .font(.caption2)
            .foregroundStyle(.secondary)
            .position(x: proxy.size.width - 24, y: proxy.size.height - 4)
        }
      } else {
        ContentUnavailableView("감지된 이벤트 없음", systemImage: "waveform.slash")
      }
    }
  }

  private func yPosition(for index: Int) -> CGFloat {
    CGFloat(18 + (index % 6) * 15)
  }
}

private struct EventRow: View {
  let event: SleepEvent
  let feedback: SleepEventFeedback?
  let hasSnippet: Bool
  let snippetDuration: TimeInterval?
  let isEventAudioSampleStorageEnabled: Bool
  let onFeedback: (SleepEventFeedbackSelection) -> Void
  let onPlaySnippet: () -> Void
  let onDeleteSnippet: () -> Void

  @State private var showDeleteSnippetConfirmation = false

  var body: some View {
    NBTimelineRow(
      title: event.type.displayName,
      subtitle:
        "\(SleepFormatters.shortTime(event.startedAt)) · \(SleepFormatters.compactDurationString(event.duration)) · 신뢰도 \(Int(event.confidence * 100))%",
      detail: event.type == .bruxismLike ? "사용자 확인이 도움이 되는 항목입니다." : nil,
      systemImage: event.type.symbolName,
      tint: event.type.tintColor
    ) {
      if event.type == .bruxismLike {
        bruxismFeedbackSection
      }

      if hasSnippet {
        audioSnippetSection
      } else if !isEventAudioSampleStorageEnabled {
        audioSnippetDisabledSection
      }
    }
    .confirmationDialog(
      "이 이벤트 오디오 샘플을 삭제할까요?", isPresented: $showDeleteSnippetConfirmation, titleVisibility: .visible
    ) {
      Button("이벤트 오디오 샘플 삭제", role: .destructive) {
        onDeleteSnippet()
      }
    } message: {
      Text("짧게 저장된 이벤트 전후 오디오만 삭제합니다.")
    }
  }

  private var bruxismFeedbackSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("사용자 확인 필요")
        .font(.caption.weight(.semibold))
        .foregroundStyle(NBColor.warning)
      Text("침구 마찰음이나 주변 소음과 구분이 어려울 수 있습니다. 정확한 진단은 전문가 상담이 필요합니다.")
        .font(.caption)
        .foregroundStyle(.secondary)

      HStack(spacing: 8) {
        ForEach(SleepEventFeedbackSelection.allCases) { selection in
          Button {
            onFeedback(selection)
          } label: {
            Text(selection.displayName)
              .font(.caption.weight(.semibold))
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.bordered)
          .tint(feedback?.selectedFeedback == selection ? NBColor.warning : .secondary)
        }
      }
    }
  }

  private var audioSnippetSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Label("짧은 이벤트 오디오", systemImage: "waveform.circle")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)

        if let snippetDuration {
          Text(SleepFormatters.compactDurationString(snippetDuration))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Text("이벤트 판단 시점 전후의 짧은 샘플만 로컬에 저장됩니다. 전체 밤 오디오는 저장하지 않습니다.")
        .font(.caption)
        .foregroundStyle(.secondary)

      HStack(spacing: 8) {
        Button {
          onPlaySnippet()
        } label: {
          Label("재생", systemImage: "play.circle")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)

        Button(role: .destructive) {
          showDeleteSnippetConfirmation = true
        } label: {
          Label("삭제", systemImage: "trash")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
      }
    }
    .padding(12)
    .background(NBColor.elevatedSurface)
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }

  private var audioSnippetDisabledSection: some View {
    Label("오디오 샘플 저장이 꺼져 있어 이 이벤트의 음성은 저장되지 않았습니다.", systemImage: "waveform.slash")
      .font(.caption)
      .foregroundStyle(.secondary)
      .padding(12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(NBColor.elevatedSurface)
      .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}

@MainActor
private final class SleepEventFeedbackViewModel: ObservableObject {
  @Published private var feedbackByEventID: [UUID: SleepEventFeedback] = [:]
  @Published private var deletedSnippetFileNames: Set<String> = []

  private let store: SleepEventFeedbackStore
  private let snippetStore: EventAudioSnippetStore
  private var audioPlayer: AVAudioPlayer?

  init(
    store: SleepEventFeedbackStore = SleepEventFeedbackStore(),
    snippetStore: EventAudioSnippetStore = EventAudioSnippetStore()
  ) {
    self.store = store
    self.snippetStore = snippetStore
    self.feedbackByEventID = Dictionary(
      uniqueKeysWithValues: store.fetchAll().map { feedback in
        (feedback.eventId, feedback)
      }
    )
  }

  func feedback(for eventId: UUID) -> SleepEventFeedback? {
    feedbackByEventID[eventId]
  }

  func saveFeedback(for event: SleepEvent, selection: SleepEventFeedbackSelection) {
    let feedback = SleepEventFeedback(
      eventId: event.id,
      selectedFeedback: selection,
      note: event.type == .bruxismLike ? "bruxismLike timeline feedback" : nil
    )

    feedbackByEventID[event.id] = feedback
    try? store.save(feedback)
  }

  func hasSnippet(for event: SleepEvent) -> Bool {
    guard let fileName = event.audioSnippetFileName,
      !deletedSnippetFileNames.contains(fileName)
    else {
      return false
    }

    return snippetStore.snippetExists(fileName: fileName)
  }

  func playSnippet(for event: SleepEvent) {
    guard hasSnippet(for: event),
      let fileName = event.audioSnippetFileName
    else {
      return
    }

    do {
      #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(
          .playback, mode: .default, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
      #endif
      let player = try AVAudioPlayer(contentsOf: snippetStore.url(for: fileName))
      player.prepareToPlay()
      player.play()
      audioPlayer = player
    } catch {
      audioPlayer = nil
    }
  }

  func markSnippetDeleted(for event: SleepEvent) {
    guard let fileName = event.audioSnippetFileName else { return }

    audioPlayer?.stop()
    deletedSnippetFileNames.insert(fileName)
  }
}
