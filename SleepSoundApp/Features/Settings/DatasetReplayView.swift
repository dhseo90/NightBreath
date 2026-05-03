#if DEBUG
  import SwiftUI
  import UniformTypeIdentifiers

  struct DatasetReplayView: View {
    @StateObject private var viewModel = DatasetReplayViewModel()
    @State private var isFileImporterPresented = false

    var body: some View {
      ScrollView {
        VStack(spacing: NBSpacing.sectionVertical) {
          NBCard(background: NBColor.audioTint.opacity(0.08), stroke: NBColor.audioTint.opacity(0.18)) {
            VStack(alignment: .leading, spacing: NBSpacing.medium) {
              Label("Dataset Replay", systemImage: "play.rectangle.on.rectangle")
                .font(NBTypography.cardTitle)
                .foregroundStyle(NBColor.audioTint)
              Text(
                "실제 iPhone 마이크 없이 synthetic pattern 또는 로컬 오디오 파일을 AudioChunk stream으로 바꿔 detector와 리포트를 검증합니다."
              )
              .font(NBTypography.footnote)
              .foregroundStyle(NBColor.secondaryText)
              Text("원본 오디오는 앱에 저장하지 않으며, 공개/개인 데이터 파일은 git에 포함하지 않습니다.")
                .font(NBTypography.footnote)
                .foregroundStyle(NBColor.secondaryText)
              NBStatusBadge("DEBUG 전용", kind: .debug)
            }
          }

          NBCard {
            VStack(alignment: .leading, spacing: NBSpacing.medium) {
              Text("Synthetic Replay")
                .font(NBTypography.sectionTitle)

              Picker("Pattern", selection: $viewModel.syntheticPattern) {
                ForEach(SyntheticAudioPattern.allCases) { pattern in
                  Text(pattern.displayName).tag(pattern)
                }
              }
              .pickerStyle(.menu)

              Picker("Replay mode", selection: $viewModel.replayMode) {
                ForEach(AudioSourceReplayMode.allCases) { mode in
                  Text(mode.displayName).tag(mode)
                }
              }
              .pickerStyle(.segmented)

              HStack(spacing: NBSpacing.small) {
                Button {
                  Task {
                    await viewModel.startSyntheticReplay()
                  }
                } label: {
                  Label("Synthetic 시작", systemImage: "play.fill")
                }
                .buttonStyle(.nbPrimary)
                .disabled(viewModel.isRunning)

                Button {
                  viewModel.stopReplay()
                } label: {
                  Label("중지", systemImage: "stop.fill")
                }
                .buttonStyle(.nbSecondary)
                .disabled(!viewModel.isRunning)
              }
            }
          }

          NBCard {
            VStack(alignment: .leading, spacing: NBSpacing.medium) {
              Text("Local Audio File")
                .font(NBTypography.sectionTitle)

              Text(viewModel.selectedFileName)
                .font(NBTypography.body)
                .foregroundStyle(viewModel.selectedFileURL == nil ? NBColor.secondaryText : NBColor.primaryText)

              if viewModel.selectedFileURL == nil {
                NBEmptyStateView(
                  title: "Dataset Replay 파일 없음",
                  message: "로컬 오디오 파일을 선택하면 자동 다운로드 없이 기기 안에서 replay합니다.",
                  systemImage: "folder.badge.questionmark"
                )
              }

              HStack(spacing: NBSpacing.small) {
                Button {
                  isFileImporterPresented = true
                } label: {
                  Label("파일 선택", systemImage: "folder")
                }
                .buttonStyle(.nbSecondary)

                Button {
                  Task {
                    await viewModel.startDatasetReplay()
                  }
                } label: {
                  Label("파일 Replay", systemImage: "waveform")
                }
                .buttonStyle(.nbPrimary)
                .disabled(viewModel.selectedFileURL == nil || viewModel.isRunning)
              }

              Text("WAV/CAF/M4A 파일을 로컬에서 직접 선택합니다. 공개 데이터셋은 자동 다운로드하지 않습니다.")
                .font(NBTypography.caption)
                .foregroundStyle(NBColor.secondaryText)
            }
          }

          ReplayMetricsSection(viewModel: viewModel)

          if let report = viewModel.report {
            NBCard {
              VStack(alignment: .leading, spacing: NBSpacing.medium) {
                Text("Replay 리포트")
                  .font(NBTypography.sectionTitle)
                HStack {
                  ReplayMetricTile(
                    title: "수면 소리 점수", value: "\(report.sleepSoundScore)", systemImage: "moon.zzz")
                  ReplayMetricTile(
                    title: "이벤트", value: "\(viewModel.events.count)", systemImage: "list.bullet")
                }
                Text(report.mainDisturbanceReason)
                  .font(NBTypography.body)
                  .foregroundStyle(NBColor.secondaryText)
              }
            }
          }

          if let diagnostics = viewModel.diagnostics {
            ReplayDiagnosticsSection(diagnostics: diagnostics)
          }

          if !viewModel.events.isEmpty {
            NBCard {
              VStack(alignment: .leading, spacing: NBSpacing.medium) {
                Text("생성된 이벤트")
                  .font(NBTypography.sectionTitle)
                ForEach(viewModel.events) { event in
                  NBListRow(
                    title: event.type.timelineDisplayName,
                    subtitle:
                      "\(event.startedAt.formatted(date: .omitted, time: .standard)) · \(SleepFormatters.durationString(event.duration)) · confidence \(String(format: "%.2f", event.confidence))",
                    systemImage: symbol(for: event.type),
                    tint: event.type.tintColor
                  )
                }
              }
            }
          }
        }
        .padding(NBSpacing.screenHorizontal)
      }
      .background(NBColor.pageBackground)
      .navigationTitle("Dataset Replay")
      .fileImporter(
        isPresented: $isFileImporterPresented,
        allowedContentTypes: [.audio],
        allowsMultipleSelection: false
      ) { result in
        viewModel.handleFileImport(result)
      }
    }

    private func symbol(for eventType: SleepEventType) -> String {
      switch eventType {
      case .snore:
        "waveform"
      case .bruxismLike:
        "sparkle.magnifyingglass"
      case .breathingPauseSuspected:
        "pause.circle"
      case .gaspLike:
        "wind"
      case .coughLike:
        "burst"
      case .sleepTalkLike:
        "text.bubble"
      case .movementLike:
        "bed.double"
      case .environmentalNoise:
        "speaker.wave.3"
      case .awakeningSuspected:
        "eye"
      case .unknown:
        "questionmark.circle"
      }
    }
  }

  @MainActor
  private final class DatasetReplayViewModel: ObservableObject {
    @Published var syntheticPattern: SyntheticAudioPattern = .snoreLikeBurst
    @Published var replayMode: AudioSourceReplayMode = .fastAsPossible
    @Published var selectedFileURL: URL?
    @Published var metrics = AudioCaptureMetrics()
    @Published var events: [SleepEvent] = []
    @Published var diagnostics: DetectorDiagnostics?
    @Published var report: NightReport?
    @Published var errorMessage: String?
    @Published var isRunning = false

    private var currentSource: (any AudioSourceProtocol)?
    private let configuration = DetectorTuningProfile.balanced.configuration

    var selectedFileName: String {
      selectedFileURL?.lastPathComponent ?? "선택된 파일 없음"
    }

    func startSyntheticReplay() async {
      let source = SyntheticAudioSource(
        pattern: syntheticPattern,
        replayMode: replayMode,
        duration: syntheticPattern.defaultDuration,
        chunkDuration: syntheticPattern == .breathingPauseLikeLowActivity
          ? syntheticPattern.defaultDuration : 1
      )
      await process(source: source, label: syntheticPattern.displayName)
    }

    func startDatasetReplay() async {
      guard let selectedFileURL else {
        errorMessage = "Replay할 로컬 오디오 파일을 먼저 선택하세요."
        return
      }

      let source = DatasetReplayAudioSource(fileURL: selectedFileURL, replayMode: replayMode)
      await process(source: source, label: selectedFileURL.lastPathComponent)
    }

    func stopReplay() {
      currentSource?.stop()
      isRunning = false
    }

    func handleFileImport(_ result: Result<[URL], Error>) {
      switch result {
      case .success(let urls):
        selectedFileURL = urls.first
        errorMessage = nil
      case .failure(let error):
        errorMessage = error.localizedDescription
      }
    }

    private func process(source: any AudioSourceProtocol, label: String) async {
      guard !isRunning else { return }

      isRunning = true
      currentSource = source
      events = []
      diagnostics = nil
      report = nil
      errorMessage = nil

      let startedAt = Date()
      var session = SleepSession(startedAt: startedAt, modelVersion: "dataset-replay-rule-v1")
      let analyzer = configuration.makeSleepAnalyzer()
      let collector = DetectorDiagnosticsCollector()
      var rawOutputs: [DetectorOutput] = []
      var audioFeatures: [AudioFeatures] = []
      let stream = source.makeChunkStream()

      collector.reset(
        sessionId: session.id,
        startedAt: startedAt,
        detectorBackend: analyzer.detectorBackend.displayName,
        modelInstalled: analyzer.isModelInstalled,
        thresholdsSnapshot: analyzer.thresholdsSnapshot.merging(configuration.thresholdSnapshot) {
          current, _ in current
        },
        eventAudioSampleStorageEnabled: false
      )
      collector.addNote("Dataset Replay: \(label)")

      do {
        try await source.start()

        for try await chunk in stream {
          var workingMetrics = source.metrics
          let result = analyzer.detectOutputsWithFeatures(from: chunk, updating: &workingMetrics)
          metrics = workingMetrics
          collector.record(features: result.features, outputs: result.outputs)
          audioFeatures.append(result.features)
          rawOutputs.append(contentsOf: result.outputs)
        }

        let endedAt = Date()
        let sequenceResult = analyzer.detectSuspectedBreathingPauseSequence(
          features: audioFeatures,
          contextOutputs: rawOutputs
        )
        collector.record(sequenceResult: sequenceResult)
        rawOutputs.append(contentsOf: sequenceResult.outputs)
        let smoothingResult = analyzer.smoothWithDiagnostics(outputs: rawOutputs)
        collector.record(smoothingDiagnostics: smoothingResult.diagnostics)
        session.endedAt = endedAt
        session.measurementDuration = max(
          metrics.sessionElapsedSeconds, metrics.receivedAudioSeconds)
        session.estimatedSleepDuration = session.measurementDuration
        events = analyzer.makeEvents(session: session, outputs: smoothingResult.outputs)
        collector.record(finalEvents: events)
        metrics = source.metrics.snapshot(at: endedAt)
        diagnostics = collector.finalize(endedAt: endedAt, metrics: metrics)
        report = SleepScoreCalculator().makeReport(
          session: session,
          events: events,
          captureMetrics: metrics
        )
      } catch {
        errorMessage = (error as? AudioSourceError)?.message ?? error.localizedDescription
      }

      source.stop()
      currentSource = nil
      isRunning = false
    }
  }

  private struct ReplayMetricsSection: View {
    @ObservedObject var viewModel: DatasetReplayViewModel

    var body: some View {
      NBCard {
        VStack(alignment: .leading, spacing: NBSpacing.medium) {
          Text("Replay 상태")
            .font(NBTypography.sectionTitle)

          LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.small
          ) {
            ReplayMetricTile(
              title: "AudioChunk", value: "\(viewModel.metrics.receivedChunkCount)",
              systemImage: "square.stack.3d.up")
            ReplayMetricTile(
              title: "수신 시간",
              value: SleepFormatters.durationString(viewModel.metrics.receivedAudioSeconds),
              systemImage: "waveform")
            ReplayMetricTile(
              title: "분석 시간",
              value: SleepFormatters.durationString(viewModel.metrics.analyzedAudioSeconds),
              systemImage: "cpu")
            ReplayMetricTile(
              title: "커버리지",
              value: "\(Int((viewModel.metrics.audioCoverageRatio * 100).rounded()))%",
              systemImage: "gauge")
          }

          if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
              .font(NBTypography.footnote)
              .foregroundStyle(NBColor.danger)
          }
        }
      }
    }
  }

  private struct ReplayDiagnosticsSection: View {
    var diagnostics: DetectorDiagnostics

    var body: some View {
      NBDiagnosticCard(
        title: "DEBUG Detector 진단",
        summary: diagnostics.summaryTextForZeroEvents ?? "Replay detector diagnostics를 raw 후보부터 최종 이벤트까지 확인합니다.",
        systemImage: "waveform.and.magnifyingglass"
      ) {
        NBDiagnosticItemList(items: diagnosticItems, showsDetails: true)
        if !diagnostics.topRejectReasons.isEmpty {
          VStack(alignment: .leading, spacing: NBSpacing.xSmall) {
            Text("탈락 이유 TOP")
              .font(NBTypography.captionEmphasis)
              .foregroundStyle(NBColor.secondaryText)
            ForEach(diagnostics.topRejectReasons.prefix(5), id: \.0) { reason, count in
              NBListRow(
                title: reason.displayName,
                value: "\(count)회",
                systemImage: "xmark.circle",
                tint: NBColor.caution
              )
            }
          }
        }
      }
    }

    private var diagnosticItems: [NBDiagnosticItem] {
      [
        NBDiagnosticItem(title: "raw 후보 수", value: "\(diagnostics.rawCandidateCount)개", status: .neutral),
        NBDiagnosticItem(title: "smoothing 전/후", value: "\(diagnostics.preSmoothingCandidateCount) / \(diagnostics.postSmoothingEventCount)", status: .debug),
        NBDiagnosticItem(title: "최종 이벤트 수", value: "\(diagnostics.finalEventCountByType.values.reduce(0, +))개", status: .good),
        NBDiagnosticItem(title: "RMS / energy p90", value: "\(String(format: "%.4f", diagnostics.rmsSummary.p90)) / \(String(format: "%.4f", diagnostics.energySummary.p90))", status: .neutral),
        NBDiagnosticItem(title: "detector backend", value: diagnostics.detectorBackend, status: .debug),
        NBDiagnosticItem(title: "Core ML model", value: diagnostics.modelInstalled ? "Installed" : "Not installed", status: diagnostics.modelInstalled ? .good : .neutral),
        NBDiagnosticItem(title: "fallback count", value: "\(diagnostics.modelFallbackCount)회", status: diagnostics.modelFallbackCount > 0 ? .caution : .good),
      ]
    }
  }

  private struct ReplayMetricTile: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
      NBMetricCard(
        title: title,
        value: value,
        systemImage: systemImage,
        tint: NBColor.audioTint,
        status: .debug,
        accessibilityLabel: "\(title), \(value)"
      )
    }
  }
#endif
