import SwiftUI

struct PrivacySettingsView: View {
  @EnvironmentObject private var appState: AppState

  private let policy = PrivacyPolicyModel()
  @State private var showDeleteAllConfirmation = false
  @State private var showDeleteLatestConfirmation = false
  @State private var showDeleteEventAudioConfirmation = false
  @State private var showDeleteEventFeedbackConfirmation = false
  @State private var showCleanupOrphanConfirmation = false

  var body: some View {
    List {
      Section(policy.title) {
        ForEach(policy.principles, id: \.self) { principle in
          Label(principle, systemImage: "checkmark.shield")
        }
      }

      Section("오디오 보관 정책") {
        ForEach(AudioRetentionPolicy.allCases) { retentionPolicy in
          VStack(alignment: .leading, spacing: 4) {
            Text(retentionPolicy.displayName)
              .font(.headline)
            Text(retentionPolicy.description)
              .font(.callout)
              .foregroundStyle(.secondary)
          }
          .padding(.vertical, 4)
        }
      }

      Section("이벤트 오디오 샘플") {
        Toggle(
          isOn: Binding(
            get: { appState.isEventAudioSampleStorageEnabled },
            set: { appState.setEventAudioSampleStorageEnabled($0) }
          )
        ) {
          VStack(alignment: .leading, spacing: 4) {
            Text("이벤트 오디오 샘플 저장")
              .font(.headline)
            Text("감지된 이벤트 전후의 짧은 오디오만 저장합니다.")
              .font(.callout)
              .foregroundStyle(.secondary)
            Text("전체 밤 오디오는 저장하지 않습니다.")
              .font(.caption)
              .foregroundStyle(.secondary)
            Text("끄면 앞으로 새 이벤트의 오디오 샘플은 저장되지 않습니다.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .padding(.vertical, 4)
        }

        Text("기본값은 꺼짐입니다. 기존 저장 샘플은 자동 삭제되지 않으며, 아래 삭제 버튼으로 별도 삭제할 수 있습니다.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }

      Section("이벤트 오디오 샘플 관리") {
        PrivacyStorageStatRow(
          title: "이벤트 오디오 샘플 저장",
          value: appState.isEventAudioSampleStorageEnabled ? "켜짐" : "꺼짐",
          systemImage: appState.isEventAudioSampleStorageEnabled
            ? "checkmark.circle" : "xmark.circle"
        )
        PrivacyStorageStatRow(
          title: "저장된 샘플 수",
          value: "\(appState.eventAudioStorageStats.sampleCount)개",
          systemImage: "waveform.circle"
        )
        PrivacyStorageStatRow(
          title: "저장된 오디오 시간",
          value: SleepFormatters.compactDurationString(
            appState.eventAudioStorageStats.totalDurationSeconds),
          systemImage: "timer"
        )
        PrivacyStorageStatRow(
          title: "저장된 오디오 용량",
          value: appState.eventAudioStorageStats.formattedTotalSize,
          systemImage: "internaldrive"
        )
        PrivacyStorageStatRow(
          title: "연결된 샘플",
          value:
            "\(appState.eventAudioStorageStats.linkedSampleCount)개 · \(appState.eventAudioStorageStats.formattedLinkedSize)",
          systemImage: "link"
        )
        PrivacyStorageStatRow(
          title: "연결되지 않은 샘플",
          value:
            "\(appState.eventAudioStorageStats.orphanSampleCount)개 · \(appState.eventAudioStorageStats.formattedOrphanSize)",
          systemImage: "link.badge.plus"
        )

        if let latestSampleCreatedAt = appState.eventAudioStorageStats.latestSampleCreatedAt {
          PrivacyStorageStatRow(
            title: "최근 샘플",
            value:
              "\(SleepFormatters.shortDate(latestSampleCreatedAt)) \(SleepFormatters.shortTime(latestSampleCreatedAt))",
            systemImage: "calendar"
          )
        }

        if let message = appState.eventAudioStorageMessage {
          Text(message)
            .font(.footnote)
            .foregroundStyle(.secondary)
        }

        Button {
          showCleanupOrphanConfirmation = true
        } label: {
          Label("연결되지 않은 샘플 정리", systemImage: "sparkles")
        }
        .disabled(appState.eventAudioStorageStats.orphanSampleCount == 0)

        Button(role: .destructive) {
          showDeleteEventAudioConfirmation = true
        } label: {
          Label("저장된 이벤트 오디오 샘플 전체 삭제", systemImage: "waveform.slash")
        }
        .disabled(appState.eventAudioStorageStats.sampleCount == 0)

        Text("연결되지 않은 샘플은 저장소에는 남아 있지만 최종 수면 이벤트와 연결되지 않은 짧은 오디오 파일입니다. 전체 밤 오디오는 저장하지 않습니다.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }

      Section("이벤트 피드백 관리") {
        PrivacyStorageStatRow(
          title: "저장된 피드백",
          value: "\(appState.eventFeedbackCount)개",
          systemImage: "checkmark.bubble"
        )

        if let message = appState.eventFeedbackMessage {
          Text(message)
            .font(.footnote)
            .foregroundStyle(.secondary)
        }

        Button(role: .destructive) {
          showDeleteEventFeedbackConfirmation = true
        } label: {
          Label("이벤트 피드백 삭제", systemImage: "bubble.left.and.exclamationmark.bubble.right")
        }
        .disabled(appState.eventFeedbackCount == 0)

        Text("피드백은 이벤트별 맞음/아님/모르겠음 선택과 수정 label만 로컬 metadata로 저장합니다. 이벤트 오디오 샘플 삭제와 별도로 관리됩니다.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }

      Section("Apple 건강앱 데이터") {
        PrivacyStorageStatRow(
          title: "연동 방식",
          value: "읽기 전용",
          systemImage: "heart.text.square"
        )
        PrivacyStorageStatRow(
          title: "권한 요청 시점",
          value: "건강 데이터 연결 선택 시",
          systemImage: "hand.tap"
        )
        Text("건강 데이터 대시보드를 켤 때만 Apple 건강앱 읽기 권한을 요청합니다. 밤숨은 HealthKit에 데이터를 쓰지 않고, 서버로 전송하지 않습니다.")
          .font(.footnote)
          .foregroundStyle(.secondary)
        Text("권한은 iOS 설정 또는 Apple 건강앱에서 언제든지 관리할 수 있습니다.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }

      Section("Detector 진단 요약") {
        if let diagnostics = appState.latestDetectorDiagnostics {
          PrivacyStorageStatRow(
            title: "현재 backend",
            value: diagnostics.detectorBackend,
            systemImage: "slider.horizontal.3"
          )
          PrivacyStorageStatRow(
            title: "분석 chunk",
            value: "\(diagnostics.analyzedChunkCount)개",
            systemImage: "square.stack.3d.up"
          )
          PrivacyStorageStatRow(
            title: "Raw 후보",
            value: "\(diagnostics.rawCandidateCount)개",
            systemImage: "waveform"
          )
          PrivacyStorageStatRow(
            title: "Smoothing 후",
            value: "\(diagnostics.postSmoothingEventCount)개",
            systemImage: "line.3.horizontal.decrease"
          )
          PrivacyStorageStatRow(
            title: "최종 이벤트",
            value: "\(diagnostics.finalEventCountByType.values.reduce(0, +))개",
            systemImage: "checkmark.circle"
          )
          PrivacyStorageStatRow(
            title: "RMS p90",
            value: shortNumber(diagnostics.rmsSummary.p90),
            systemImage: "speaker.wave.2"
          )
          PrivacyStorageStatRow(
            title: "Energy p90",
            value: shortNumber(diagnostics.energySummary.p90),
            systemImage: "bolt"
          )
          PrivacyStorageStatRow(
            title: "Core ML fallback",
            value: "\(diagnostics.modelFallbackCount)회",
            systemImage: "arrow.triangle.2.circlepath"
          )

          Text("주요 탈락 이유: \(topRejectReasonText(diagnostics))")
            .font(.footnote)
            .foregroundStyle(.secondary)

          if let zeroEventText = diagnostics.summaryTextForZeroEvents {
            Text(zeroEventText)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }

          if let zeroEventAnalysis = ZeroEventAnalysis.make(
            diagnostics: diagnostics,
            configuration: appState.detectorThresholdConfiguration
          ) {
            Text("이벤트 0개 분석: \(zeroEventAnalysis.probableReason.displayName)")
              .font(.footnote.weight(.semibold))
            Text(zeroEventAnalysis.recommendedDebugAction)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        } else {
          Text(
            "아직 저장된 detector 진단 요약이 없습니다. 수면 측정을 종료하면 raw 후보 수, smoothing 결과, 주요 탈락 이유가 로컬에 저장됩니다."
          )
          .font(.footnote)
          .foregroundStyle(.secondary)
        }
      }

      Section("로컬 데이터 관리") {
        Button(role: .destructive) {
          showDeleteLatestConfirmation = true
        } label: {
          Label("최근 수면 데이터 삭제", systemImage: "trash")
        }
        .disabled(appState.latestReportSource == .sample)

        Button(role: .destructive) {
          showDeleteAllConfirmation = true
        } label: {
          Label("전체 로컬 수면 데이터 삭제", systemImage: "trash.slash")
        }

        Text(
          "저장된 수면 세션, 이벤트 요약, 리포트, 아침 컨디션, 사용자 확인 feedback을 삭제할 수 있습니다. 이벤트 오디오 샘플은 위 관리 섹션에서 따로 확인하고 삭제할 수 있습니다."
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
      }
    }
    .navigationTitle("개인정보")
    .scrollContentBackground(.hidden)
    .background(NBColor.pageBackground)
    .onAppear {
      appState.refreshEventAudioStorageStats()
      appState.refreshEventFeedbackCount()
    }
    .confirmationDialog(
      "최근 수면 데이터를 삭제할까요?", isPresented: $showDeleteLatestConfirmation, titleVisibility: .visible
    ) {
      Button("최근 수면 데이터 삭제", role: .destructive) {
        appState.deleteLatestSession()
      }
    }
    .confirmationDialog(
      "전체 로컬 수면 데이터를 삭제할까요?", isPresented: $showDeleteAllConfirmation, titleVisibility: .visible
    ) {
      Button("전체 삭제", role: .destructive) {
        appState.deleteAllSleepData()
      }
    }
    .confirmationDialog(
      "저장된 이벤트 오디오 샘플을 삭제할까요?", isPresented: $showDeleteEventAudioConfirmation,
      titleVisibility: .visible
    ) {
      Button("이벤트 오디오 샘플 삭제", role: .destructive) {
        appState.deleteAllEventAudioSnippets()
      }
    } message: {
      Text("짧게 저장된 이벤트 전후 오디오만 삭제합니다. 수면 세션과 리포트 요약은 유지됩니다.")
    }
    .confirmationDialog(
      "저장된 이벤트 피드백을 삭제할까요?", isPresented: $showDeleteEventFeedbackConfirmation,
      titleVisibility: .visible
    ) {
      Button("이벤트 피드백 삭제", role: .destructive) {
        appState.deleteAllEventFeedback()
      }
    } message: {
      Text("이벤트별 맞음/아님/모르겠음 metadata만 삭제합니다. 이벤트 오디오 샘플과 수면 리포트는 유지됩니다.")
    }
    .confirmationDialog(
      "연결되지 않은 샘플을 정리할까요?", isPresented: $showCleanupOrphanConfirmation, titleVisibility: .visible
    ) {
      Button("연결되지 않은 샘플 정리", role: .destructive) {
        appState.cleanupOrphanEventAudioSamples()
      }
    } message: {
      Text("최종 수면 이벤트와 연결되지 않은 짧은 오디오 샘플만 삭제합니다. 연결된 이벤트 샘플과 리포트 요약은 유지됩니다.")
    }
  }

  private func shortNumber(_ value: Double) -> String {
    if abs(value) >= 10 {
      return String(format: "%.1f", value)
    }
    return String(format: "%.4f", value)
  }

  private func topRejectReasonText(_ diagnostics: DetectorDiagnostics) -> String {
    let reasons = diagnostics.topRejectReasons.prefix(3).map { reason, count in
      "\(reason.displayName) \(count)회"
    }
    return reasons.isEmpty ? "없음" : reasons.joined(separator: ", ")
  }
}

private struct PrivacyStorageStatRow: View {
  let title: String
  let value: String
  let systemImage: String

  var body: some View {
    NBListRow(
      title: title,
      value: value,
      systemImage: systemImage,
      tint: NBColor.privacyTint
    )
  }
}
