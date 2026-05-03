#if DEBUG
import SwiftUI

struct SimulatorScenarioView: View {
  @EnvironmentObject private var appState: AppState
  @State private var selectedPreset: SimulatorQAScenarioPreset = .quietNight

  private var previewBundle: SimulatorQAScenarioBundle {
    SimulatorQAScenarioFactory.make(preset: selectedPreset)
  }

  var body: some View {
    List {
      Section {
        VStack(alignment: .leading, spacing: NBSpacing.medium) {
          Label("Simulator E2E QA", systemImage: "iphone.gen3.radiowaves.left.and.right")
            .font(NBTypography.sectionTitle)
            .foregroundStyle(NBColor.audioTint)

          Text("실제 iPhone 녹음 없이 mock 수면 세션, 이벤트, 리포트, detector 진단, 이벤트 오디오 저장소 상태를 재현합니다.")
            .font(NBTypography.callout)
            .foregroundStyle(NBColor.secondaryText)
          NBStatusBadge("DEBUG 전용", kind: .debug)
        }
        .padding(.vertical, 6)
      }

      Section("Scenario Preset") {
        Picker("Preset", selection: $selectedPreset) {
          ForEach(SimulatorQAScenarioPreset.allCases) { preset in
            Text(preset.displayName)
              .tag(preset)
          }
        }

        VStack(alignment: .leading, spacing: 6) {
          Text(selectedPreset.koreanTitle)
            .font(.headline)
          Text(selectedPreset.qaFocus)
            .font(.callout)
            .foregroundStyle(NBColor.secondaryText)
        }
        .padding(.vertical, 4)

        Button {
          appState.applySimulatorQAScenario(selectedPreset)
        } label: {
          Label("시나리오 적용", systemImage: "checkmark.circle")
        }
        .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.audioTint))

        if let activePreset = appState.activeSimulatorQAScenario {
          NBStatusBadge("현재 적용됨: \(activePreset.displayName)", kind: .good, systemImage: "checkmark.seal")

          Button {
            appState.clearSimulatorQAScenario()
          } label: {
            Label("QA 시나리오 해제", systemImage: "arrow.uturn.backward")
          }
          .buttonStyle(.nbSecondary)
        }
      }

      Section("Preview Summary") {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.md) {
          ScenarioStatRow(
            title: "수면 소리 점수",
            value: "\(previewBundle.report.sleepSoundScore)",
            unit: "점",
            systemImage: "waveform.path.ecg",
            status: .debug
          )
          ScenarioStatRow(
            title: "측정 품질",
            value: previewBundle.report.measurementQuality.displayName,
            systemImage: "checkmark.seal",
            status: .neutral
          )
          ScenarioStatRow(
            title: "앱 동작 시간",
            value: SleepFormatters.compactDurationString(previewBundle.report.measurementDuration),
            systemImage: "clock",
            status: .debug
          )
          ScenarioStatRow(
            title: "실제 오디오 수신",
            value: SleepFormatters.compactDurationString(previewBundle.report.receivedAudioDuration),
            systemImage: "waveform",
            status: .debug
          )
          ScenarioStatRow(
            title: "최종 이벤트",
            value: "\(previewBundle.events.count)",
            unit: "개",
            systemImage: "list.bullet.rectangle",
            status: .debug
          )
          ScenarioStatRow(
            title: "Detector raw 후보",
            value: "\(previewBundle.detectorDiagnostics.rawCandidateCount)",
            unit: "개",
            systemImage: "waveform.and.magnifyingglass",
            status: .debug
          )
          ScenarioStatRow(
            title: "오디오 샘플 저장",
            value: previewBundle.isEventAudioSampleStorageEnabled ? "켜짐" : "꺼짐",
            systemImage: "waveform.circle",
            status: previewBundle.isEventAudioSampleStorageEnabled ? .debug : .privacy
          )
          ScenarioStatRow(
            title: "저장소 상태",
            value:
              "\(previewBundle.eventAudioStorageStats.sampleCount)개 · \(previewBundle.eventAudioStorageStats.formattedTotalSize)",
            systemImage: "internaldrive",
            status: .privacy
          )
          ScenarioStatRow(
            title: "연결되지 않은 샘플",
            value:
              "\(previewBundle.eventAudioStorageStats.orphanSampleCount)개 · \(previewBundle.eventAudioStorageStats.formattedOrphanSize)",
            systemImage: "link.badge.plus",
            status: .caution
          )
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .listRowBackground(Color.clear)
      }

      Section("화면 확인") {
        NavigationLink {
          HomeDashboardView()
        } label: {
          Label("HomeDashboardView", systemImage: "house")
        }

        NavigationLink {
          SleepReportView(report: appState.latestReport, events: appState.latestEvents)
        } label: {
          Label("SleepReportView", systemImage: "doc.text.magnifyingglass")
        }

        NavigationLink {
          SleepTimelineView(report: appState.latestReport, events: appState.latestEvents)
        } label: {
          Label("SleepTimelineView", systemImage: "timeline.selection")
        }

        NavigationLink {
          PrivacySettingsView()
        } label: {
          Label("PrivacySettingsView", systemImage: "lock.shield")
        }

        Text("먼저 시나리오를 적용한 뒤 각 화면에서 점수, 측정 품질, 실제 오디오 수신 시간, 이벤트 수, 샘플 저장 상태, 저장 용량, detector 진단, zero-event 분석을 확인합니다.")
          .font(.footnote)
          .foregroundStyle(NBColor.secondaryText)
      }

      Section("QA 범위") {
        NBPrivacyNoticeCard(
          title: "QA 범위",
          messages: [
            "Simulator에서 리포트와 설정 UI edge case를 빠르게 확인합니다.",
            "실제 마이크, 화면 잠금 녹음, 배터리/발열은 실기기에서만 확인합니다.",
            "서버 전송, HealthKit, 전체 밤 원본 오디오 저장은 포함하지 않습니다.",
            "DEBUG 빌드에서만 노출됩니다.",
          ],
          systemImage: "checkmark.circle"
        )
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .listRowBackground(Color.clear)
      }
    }
    .navigationTitle("Simulator QA")
    .scrollContentBackground(.hidden)
    .background(NBColor.pageBackground)
  }
}

private struct ScenarioStatRow: View {
  let title: String
  let value: String
  var unit: String?
  let systemImage: String
  let status: NBStatusKind

  var body: some View {
    NBMetricCard(
      title: title,
      value: value,
      unit: unit,
      systemImage: systemImage,
      tint: status.tint,
      status: status,
      accessibilityLabel: "\(title), \(value)\(unit ?? "")"
    )
  }
}
#endif
