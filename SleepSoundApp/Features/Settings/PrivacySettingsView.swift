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
        NBPrivacyNoticeCard(
          title: "밤숨 개인정보 원칙",
          messages: policy.principles + [
            "이벤트 오디오 샘플은 사용자가 켠 경우에만 저장됩니다.",
            "저장된 샘플은 언제든 삭제할 수 있습니다.",
          ],
          systemImage: "lock.shield"
        )
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .listRowBackground(Color.clear)
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
            Text("서버로 전송하지 않습니다.")
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
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.sm) {
          NBMetricCard(
            title: "샘플 저장",
            value: appState.isEventAudioSampleStorageEnabled ? "켜짐" : "꺼짐",
            subtitle: "기본값 OFF",
            systemImage: appState.isEventAudioSampleStorageEnabled ? "checkmark.circle" : "xmark.circle",
            tint: appState.isEventAudioSampleStorageEnabled ? NBColor.audioTint : NBColor.privacy,
            status: appState.isEventAudioSampleStorageEnabled ? .debug : .privacy
          )
          NBMetricCard(
            title: "저장된 샘플",
            value: "\(appState.eventAudioStorageStats.sampleCount)",
            unit: "개",
            systemImage: "waveform.circle",
            tint: NBColor.audioTint
          )
          NBMetricCard(
            title: "총 시간",
            value: SleepFormatters.compactDurationString(
              appState.eventAudioStorageStats.totalDurationSeconds),
            systemImage: "timer",
            tint: NBColor.sleep
          )
          NBMetricCard(
            title: "용량",
            value: appState.eventAudioStorageStats.formattedTotalSize,
            systemImage: "internaldrive",
            tint: NBColor.privacy
          )
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .listRowBackground(Color.clear)

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

        NBSecondaryButton(title: "연결되지 않은 샘플 정리", systemImage: "sparkles", isDisabled: appState.eventAudioStorageStats.orphanSampleCount == 0) {
          showCleanupOrphanConfirmation = true
        }

        NBDangerButton(title: "저장된 이벤트 오디오 샘플 전체 삭제", systemImage: "waveform.slash", isDisabled: appState.eventAudioStorageStats.sampleCount == 0) {
          showDeleteEventAudioConfirmation = true
        }

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

        NBDangerButton(title: "이벤트 피드백 삭제", systemImage: "bubble.left.and.exclamationmark.bubble.right", isDisabled: appState.eventFeedbackCount == 0) {
          showDeleteEventFeedbackConfirmation = true
        }

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
          NBDiagnosticCard(
            title: "Detector 진단 요약",
            summary: "로컬 detector가 남긴 raw 후보, smoothing 결과, fallback 정보를 표시합니다.",
            items: [
              NBDiagnosticItem(title: "현재 backend", value: diagnostics.detectorBackend, status: .debug),
              NBDiagnosticItem(title: "분석 chunk", value: "\(diagnostics.analyzedChunkCount)개", status: .neutral),
              NBDiagnosticItem(title: "Raw 후보", value: "\(diagnostics.rawCandidateCount)개", status: .neutral),
              NBDiagnosticItem(title: "Smoothing 후", value: "\(diagnostics.postSmoothingEventCount)개", status: .debug),
              NBDiagnosticItem(title: "최종 이벤트", value: "\(diagnostics.finalEventCountByType.values.reduce(0, +))개", status: .good),
              NBDiagnosticItem(title: "RMS p90", value: shortNumber(diagnostics.rmsSummary.p90), status: .neutral),
              NBDiagnosticItem(title: "Energy p90", value: shortNumber(diagnostics.energySummary.p90), status: .neutral),
              NBDiagnosticItem(title: "Core ML fallback", value: "\(diagnostics.modelFallbackCount)회", status: diagnostics.modelFallbackCount > 0 ? .caution : .good),
            ],
            showsDetails: false
          )
          .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
          .listRowBackground(Color.clear)

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
        NBDangerButton(title: "최근 수면 데이터 삭제", systemImage: "trash", isDisabled: appState.latestReportSource == .sample) {
          showDeleteLatestConfirmation = true
        }

        NBDangerButton(title: "전체 로컬 수면 데이터 삭제", systemImage: "trash.slash") {
          showDeleteAllConfirmation = true
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
