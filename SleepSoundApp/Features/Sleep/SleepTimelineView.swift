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
              .foregroundStyle(NBColor.primaryText)
            Text("감지된 수면 중 소리 이벤트를 시간 순서로 확인합니다.")
              .font(.callout)
              .foregroundStyle(NBColor.secondaryText)
          }
        }

        NBCard {
          VStack(alignment: .leading, spacing: NBSpacing.medium) {
            EventTimelineBand(events: events)
              .frame(height: 130)

            if !events.isEmpty {
              Text("색상은 이벤트 유형을 나타냅니다.")
                .font(NBTypography.caption)
                .foregroundStyle(NBColor.secondaryText)

              timelineLegend
            }
          }
        }

        if events.isEmpty {
          NBEmptyStateView(
            title: "감지된 이벤트가 없습니다",
            message: "오디오 입력은 수신되었지만 detector 기준을 통과한 이벤트가 없었습니다. 조용한 밤이었거나 감지 기준이 보수적으로 동작했을 수 있습니다.",
            systemImage: "waveform.slash",
            illustration: .emptyTimeline
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
              ) { selection, correctedLabel in
                feedbackViewModel.saveFeedback(
                  for: event,
                  selection: selection,
                  correctedLabel: correctedLabel
                )
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
    .nbAvoidFloatingTabBar()
  }

  private var timelineLegend: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: NBSpacing.small) {
        ForEach(timelineLegendTypes, id: \.rawValue) { type in
          TimelineLegendChip(type: type)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private var timelineLegendTypes: [SleepEventType] {
    let preferred: [SleepEventType] = [
      .environmentalNoise,
      .awakeningSuspected,
      .snore,
      .movementLike,
      .coughLike,
    ]

    var types = preferred.filter { preferredType in
      events.contains { $0.type == preferredType }
    }

    for event in events where !types.contains(event.type) {
      types.append(event.type)
      if types.count >= 5 {
        break
      }
    }

    return types
  }
}

private struct TimelineLegendChip: View {
  let type: SleepEventType

  var body: some View {
    HStack(spacing: NBSpacing.xs) {
      Circle()
        .fill(type.tintColor)
        .frame(width: 8, height: 8)

      Text(type.timelineDisplayName)
        .font(NBTypography.captionEmphasis)
        .foregroundStyle(NBColor.secondaryText)
        .lineLimit(1)
    }
    .padding(.horizontal, NBSpacing.sm)
    .padding(.vertical, NBSpacing.xs)
    .background(type.tintColor.opacity(0.10))
    .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
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
        NBEmptyStateView(
          title: "감지된 이벤트 없음",
          message: "타임라인에 표시할 이벤트 구간이 없습니다.",
          systemImage: "waveform.slash",
          illustration: .emptyTimeline
        )
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
  let onFeedback: (SleepEventFeedbackSelection, EventFeedbackCorrectedLabel?) -> Void
  let onPlaySnippet: () -> Void
  let onDeleteSnippet: () -> Void

  @State private var showDeleteSnippetConfirmation = false

  var body: some View {
    NBTimelineRow(
      title: event.type.timelineDisplayName,
      subtitle:
        "\(SleepFormatters.shortTime(event.startedAt)) · \(SleepFormatters.compactDurationString(event.duration)) · 신뢰도 \(Int(event.confidence * 100))%",
      detail: event.type == .bruxismLike ? "사용자 확인이 도움이 되는 항목입니다." : nil,
      systemImage: event.type.symbolName,
      tint: event.type.tintColor
    ) {
      feedbackSection

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

  private var feedbackSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("이벤트 피드백")
        .font(.caption.weight(.semibold))
        .foregroundStyle(event.type.tintColor)
      Text("이 소리 이벤트가 맞았는지 로컬에만 기록합니다. 오디오 샘플이 없어도 피드백을 남길 수 있습니다.")
        .font(.caption)
        .foregroundStyle(NBColor.secondaryText)

      HStack(spacing: 8) {
        ForEach(SleepEventFeedbackSelection.allCases) { selection in
          Button {
            onFeedback(selection, selection == .incorrect ? feedback?.correctedLabel : nil)
          } label: {
            Text(selection.displayName)
              .font(.caption.weight(.semibold))
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.bordered)
          .tint(feedback?.selectedFeedback == selection ? event.type.tintColor : .secondary)
        }
      }

      Menu {
        ForEach(EventFeedbackCorrectedLabel.allCases) { correctedLabel in
          Button(correctedLabel.displayName) {
            onFeedback(.incorrect, correctedLabel)
          }
        }
      } label: {
        Label(
          feedbackCorrectionTitle,
          systemImage: "tag"
        )
        .font(.caption.weight(.semibold))
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .buttonStyle(.bordered)
      .tint(feedback?.correctedLabel == nil ? .secondary : event.type.tintColor)
    }
    .padding(12)
    .background(NBColor.elevatedSurface)
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }

  private var feedbackCorrectionTitle: String {
    if let correctedLabel = feedback?.correctedLabel {
      return "다른 이벤트로 수정: \(correctedLabel.displayName)"
    }
    return "다른 이벤트로 수정"
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
            .foregroundStyle(NBColor.secondaryText)
        }
      }

      Text("이벤트 판단 시점 전후의 짧은 샘플만 로컬에 저장됩니다. 전체 밤 오디오는 저장하지 않습니다.")
        .font(.caption)
        .foregroundStyle(NBColor.secondaryText)

      HStack(spacing: 8) {
        Button {
          onPlaySnippet()
        } label: {
          Label("재생", systemImage: "play.circle")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.nbSecondary)

        Button(role: .destructive) {
          showDeleteSnippetConfirmation = true
        } label: {
          Label("삭제", systemImage: "trash")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(NBSecondaryButtonStyle(tint: NBColor.danger))
      }
    }
    .padding(12)
    .background(NBColor.elevatedSurface)
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }

  private var audioSnippetDisabledSection: some View {
    HStack {
      NBStatusBadge("샘플 저장 꺼짐", kind: .privacy, systemImage: "waveform.slash")
      Text("오디오 샘플 저장이 꺼져 있어 이 이벤트의 오디오는 저장되지 않았습니다.")
        .font(.caption)
        .foregroundStyle(NBColor.secondaryText)
    }
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

  func saveFeedback(
    for event: SleepEvent,
    selection: SleepEventFeedbackSelection,
    correctedLabel: EventFeedbackCorrectedLabel? = nil
  ) {
    let existingFeedback = feedbackByEventID[event.id]
    let audioSampleId = event.audioSnippetFileName
    let feedback = SleepEventFeedback(
      id: existingFeedback?.id ?? UUID(),
      eventId: event.id,
      sessionId: event.sessionId,
      eventType: event.type,
      selectedFeedback: selection,
      correctedLabel: selection == .incorrect ? correctedLabel : nil,
      note: "timeline event feedback",
      hasAudioSample: audioSampleId.map { snippetStore.snippetExists(fileName: $0) } ?? false,
      audioSampleId: audioSampleId
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
