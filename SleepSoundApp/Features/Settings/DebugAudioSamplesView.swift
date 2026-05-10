#if DEBUG
import AVFoundation
import SwiftUI

struct DebugAudioSamplesView: View {
  @EnvironmentObject private var appState: AppState
  @StateObject private var viewModel = DebugAudioSamplesViewModel()
  @State private var isDeleteAllConfirmationPresented = false

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
              isLinked: appState.isEventAudioSnippetLinked(fileName: record.fileName),
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

        Button {
          appState.cleanupOrphanEventAudioSamples()
          viewModel.refresh()
        } label: {
          Label("연결되지 않은 샘플 정리", systemImage: "link.badge.minus")
        }
        .buttonStyle(.nbSecondary)

        Button {
          appState.cleanupMissingEventAudioReferences()
          viewModel.refresh()
        } label: {
          Label("파일 없는 참조 정리", systemImage: "waveform.slash")
        }
        .buttonStyle(.nbSecondary)

        Button(role: .destructive) {
          isDeleteAllConfirmationPresented = true
        } label: {
          Label("모든 DEBUG 샘플 삭제", systemImage: "trash")
        }
        .buttonStyle(NBSecondaryButtonStyle(tint: NBColor.danger))
        .disabled(appState.eventAudioStorageStats.sampleCount == 0)

        if let message = appState.eventAudioStorageMessage {
          Text(message)
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
    }
    .navigationTitle("DEBUG 오디오 샘플")
    .scrollContentBackground(.hidden)
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
    .toolbar(.hidden, for: .tabBar)
    .onAppear {
      viewModel.refresh()
      appState.refreshEventAudioStorageStats()
    }
    .alert("모든 DEBUG 오디오 샘플 삭제", isPresented: $isDeleteAllConfirmationPresented) {
      Button("모든 샘플 삭제", role: .destructive) {
        viewModel.stopPlayback()
        appState.deleteAllEventAudioSnippets()
        viewModel.refresh()
      }
      Button("취소", role: .cancel) {}
    } message: {
      Text("리포트 이벤트에 연결된 샘플과 연결되지 않은 DEBUG 미리듣기 샘플을 모두 삭제합니다. 수면 리포트 기록은 유지됩니다.")
    }
  }
}

struct DebugAudioSamplesFixtureQAView: View {
  private let fixtures: [DebugAudioSampleFixture] = [
    DebugAudioSampleFixture(
      fileName: "event-snore_2026-05-10_2312.m4a",
      title: "이벤트 오디오 샘플",
      isLinked: true,
      duration: 6,
      sizeText: "192KB",
      createdAtText: "5월 10일 23:12"
    ),
    DebugAudioSampleFixture(
      fileName: "event-cough_2026-05-10_0418.m4a",
      title: "이벤트 오디오 샘플",
      isLinked: true,
      duration: 5,
      sizeText: "160KB",
      createdAtText: "5월 11일 04:18"
    ),
    DebugAudioSampleFixture(
      fileName: "debug-preview_2026-05-10_2330.m4a",
      title: "DEBUG 미리듣기",
      isLinked: false,
      duration: 10,
      sizeText: "320KB",
      createdAtText: "5월 10일 23:30"
    ),
    DebugAudioSampleFixture(
      fileName: "event-environment_2026-05-10_0522_orphan.m4a",
      title: "이벤트 오디오 샘플",
      isLinked: false,
      duration: 4,
      sizeText: "128KB",
      createdAtText: "5월 11일 05:22"
    ),
  ]

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        NBReportSection(title: "DEBUG 오디오 샘플 다건 상태", systemImage: "waveform.circle") {
          VStack(alignment: .leading, spacing: NBSpacing.medium) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.small) {
              NBMetricCard(
                title: "샘플",
                value: "\(fixtures.count)",
                unit: "개",
                systemImage: "waveform.circle",
                tint: NBColor.audioTint,
                status: .debug
              )
              NBMetricCard(
                title: "연결되지 않음",
                value: "\(fixtures.filter { !$0.isLinked }.count)",
                unit: "개",
                systemImage: "link.badge.plus",
                tint: NBColor.warning,
                status: .caution
              )
            }

            ForEach(fixtures) { fixture in
              DebugAudioSampleFixtureRow(fixture: fixture)
              if fixture.id != fixtures.last?.id {
                Divider().overlay(NBColor.divider)
              }
            }

            Button(role: .destructive) {
            } label: {
              Label("모든 DEBUG 샘플 삭제", systemImage: "trash")
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(NBSecondaryButtonStyle(tint: NBColor.danger))
          }
        }

        NBPrivacyNoticeCard(
          title: "QA fixture",
          messages: [
            "이 화면은 DEBUG screenshot용 예시 목록입니다.",
            "실제 오디오 파일을 만들거나 재생하지 않습니다.",
            "연결된 샘플과 연결되지 않은 샘플의 UI 상태만 확인합니다.",
            "Release 사용자에게 노출되지 않습니다.",
          ],
          systemImage: "lock.shield"
        )
      }
      .padding(.horizontal, NBSpacing.screenHorizontal)
      .padding(.vertical, NBSpacing.sectionVertical)
    }
    .background(NBColor.pageBackground)
    .navigationTitle("샘플 다건 QA")
    .toolbar(.hidden, for: .tabBar)
    .nbAvoidFloatingTabBar()
  }
}

private struct DebugAudioSampleFixture: Identifiable {
  var id: String { fileName }
  let fileName: String
  let title: String
  let isLinked: Bool
  let duration: TimeInterval
  let sizeText: String
  let createdAtText: String
}

private struct DebugAudioSampleFixtureRow: View {
  let fixture: DebugAudioSampleFixture

  var body: some View {
    VStack(alignment: .leading, spacing: NBSpacing.small) {
      HStack(alignment: .top, spacing: NBSpacing.small) {
        Image(systemName: fixture.fileName.hasPrefix("debug-preview_") ? "waveform.circle" : "waveform.badge.magnifyingglass")
          .foregroundStyle(fixture.fileName.hasPrefix("debug-preview_") ? NBColor.audioTint : NBColor.sleepTint)
          .frame(width: 24)
          .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: 4) {
          Text(fixture.title)
            .font(.subheadline.weight(.semibold))
          NBStatusBadge(
            fixture.isLinked ? "이벤트 연결됨" : "연결되지 않음",
            kind: fixture.isLinked ? .good : .caution,
            systemImage: fixture.isLinked ? "link" : "link.badge.plus"
          )
          Text("\(fixture.createdAtText) · \(SleepFormatters.compactDurationString(fixture.duration)) · \(fixture.sizeText)")
            .font(.caption)
            .foregroundStyle(NBColor.secondaryText)
          Text(fixture.fileName)
            .font(.caption2.monospaced())
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }

        Spacer()
      }

      HStack(spacing: NBSpacing.sm) {
        Button {
        } label: {
          Label("재생", systemImage: "play.circle")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.nbSecondary)

        Button(role: .destructive) {
        } label: {
          Label("삭제", systemImage: "trash")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(NBSecondaryButtonStyle(tint: NBColor.danger))
      }
    }
    .padding(.vertical, 6)
  }
}

private struct DebugAudioSampleRow: View {
  let record: EventAudioSnippetFileRecord
  let isLinked: Bool
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
          VStack(alignment: .leading, spacing: 4) {
            Text(record.isDebugPreview ? "DEBUG 미리듣기" : "이벤트 오디오 샘플")
              .font(.subheadline.weight(.semibold))
            NBStatusBadge(
              isLinked ? "이벤트 연결됨" : "연결되지 않음",
              kind: isLinked ? .good : .caution,
              systemImage: isLinked ? "link" : "link.badge.plus"
            )
          }
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
      stopPlayback()
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

  func stopPlayback() {
    audioPlayer?.stop()
    audioPlayer = nil
    playingFileName = nil
  }
}
#endif
