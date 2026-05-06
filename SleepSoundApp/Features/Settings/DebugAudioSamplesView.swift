#if DEBUG
import AVFoundation
import SwiftUI

struct DebugAudioSamplesView: View {
  @EnvironmentObject private var appState: AppState
  @StateObject private var viewModel = DebugAudioSamplesViewModel()

  var body: some View {
    List {
      Section("DEBUG 오디오 샘플") {
        NBPrivacyNoticeCard(
          title: "로컬 샘플 재생",
          messages: [
            "DEBUG 빌드에서만 보입니다.",
            "이벤트와 연결되지 않은 debug-preview 샘플도 재생할 수 있습니다.",
            "전체 밤 오디오는 저장하지 않습니다.",
            "서버로 전송하지 않습니다.",
          ],
          systemImage: "waveform.circle"
        )
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .listRowBackground(Color.clear)

        if viewModel.records.isEmpty {
          VStack(alignment: .leading, spacing: 6) {
            Label("저장된 DEBUG 오디오 샘플 없음", systemImage: "waveform.slash")
              .font(.headline)
            Text("이벤트 오디오 샘플 저장을 켠 뒤 측정을 종료하면 짧은 debug-preview 또는 이벤트 샘플이 이곳에 표시됩니다.")
              .font(.callout)
              .foregroundStyle(.secondary)
          }
          .padding(.vertical, 8)
        } else {
          ForEach(viewModel.records) { record in
            DebugAudioSampleRow(
              record: record,
              isPlaying: viewModel.playingFileName == record.fileName
            ) {
              viewModel.play(record)
            } onDelete: {
              viewModel.delete(record)
              appState.refreshEventAudioStorageStats()
            }
          }
        }

        if let message = viewModel.message {
          Text(message)
            .font(.footnote)
            .foregroundStyle(viewModel.messageIsError ? NBColor.danger : .secondary)
        }
      }

      Section("저장 상태") {
        PrivacyStorageStatRow(
          title: "저장된 샘플",
          value: "\(appState.eventAudioStorageStats.sampleCount)개 · \(appState.eventAudioStorageStats.formattedTotalSize)",
          systemImage: "internaldrive"
        )
        PrivacyStorageStatRow(
          title: "연결되지 않은 샘플",
          value: "\(appState.eventAudioStorageStats.orphanSampleCount)개 · \(appState.eventAudioStorageStats.formattedOrphanSize)",
          systemImage: "link.badge.plus"
        )
        Text("연결되지 않은 샘플은 리포트 이벤트와 매칭되지 않은 짧은 로컬 오디오입니다. DEBUG 분석용으로만 확인하세요.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
    .navigationTitle("DEBUG 오디오 샘플")
    .scrollContentBackground(.hidden)
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
    .onAppear {
      viewModel.refresh()
      appState.refreshEventAudioStorageStats()
    }
  }
}

private struct DebugAudioSampleRow: View {
  let record: EventAudioSnippetFileRecord
  let isPlaying: Bool
  let onPlay: () -> Void
  let onDelete: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: NBSpacing.small) {
      HStack(alignment: .top, spacing: NBSpacing.small) {
        Image(systemName: record.isDebugPreview ? "waveform.circle" : "waveform.badge.magnifyingglass")
          .foregroundStyle(record.isDebugPreview ? NBColor.audioTint : NBColor.sleepTint)
          .frame(width: 24)
          .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: 4) {
          Text(record.isDebugPreview ? "DEBUG 미리듣기" : "이벤트 오디오 샘플")
            .font(.subheadline.weight(.semibold))
          Text(detailText)
            .font(.caption)
            .foregroundStyle(NBColor.secondaryText)
          Text(record.fileName)
            .font(.caption2.monospaced())
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }

        Spacer()
      }

      HStack(spacing: NBSpacing.sm) {
        Button {
          onPlay()
        } label: {
          Label(isPlaying ? "다시 재생" : "재생", systemImage: "play.circle")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.nbSecondary)

        Button(role: .destructive) {
          onDelete()
        } label: {
          Label("삭제", systemImage: "trash")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(NBSecondaryButtonStyle(tint: NBColor.danger))
      }
    }
    .padding(.vertical, 6)
  }

  private var detailText: String {
    let createdAt = record.createdAt.map {
      "\(SleepFormatters.shortDate($0)) \(SleepFormatters.shortTime($0))"
    } ?? "생성 시각 없음"
    let duration = SleepFormatters.compactDurationString(record.duration)
    let size = ByteCountFormatter.string(fromByteCount: record.sizeBytes, countStyle: .file)
    return "\(createdAt) · \(duration) · \(size)"
  }
}

@MainActor
private final class DebugAudioSamplesViewModel: ObservableObject {
  @Published private(set) var records: [EventAudioSnippetFileRecord] = []
  @Published var playingFileName: String?
  @Published var message: String?
  @Published var messageIsError = false

  private let snippetStore: EventAudioSnippetStore
  private var audioPlayer: AVAudioPlayer?

  init(snippetStore: EventAudioSnippetStore = EventAudioSnippetStore()) {
    self.snippetStore = snippetStore
  }

  func refresh() {
    records = snippetStore.debugPlayableRecords()
  }

  func play(_ record: EventAudioSnippetFileRecord) {
    do {
      #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(
          .playback,
          mode: .default,
          options: [.duckOthers]
        )
        try? AVAudioSession.sharedInstance().setActive(true)
      #endif

      let player = try AVAudioPlayer(contentsOf: record.url)
      player.prepareToPlay()
      player.play()
      audioPlayer = player
      playingFileName = record.fileName
      message = "오디오 샘플을 재생합니다."
      messageIsError = false
    } catch {
      audioPlayer = nil
      playingFileName = nil
      message = "오디오 샘플을 재생하지 못했습니다."
      messageIsError = true
    }
  }

  func delete(_ record: EventAudioSnippetFileRecord) {
    if playingFileName == record.fileName {
      audioPlayer?.stop()
      playingFileName = nil
    }

    do {
      try snippetStore.deleteSnippet(fileName: record.fileName)
      refresh()
      message = "오디오 샘플을 삭제했습니다."
      messageIsError = false
    } catch {
      message = "오디오 샘플을 삭제하지 못했습니다."
      messageIsError = true
    }
  }
}
#endif
