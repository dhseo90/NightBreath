import SwiftUI

struct PrivacySettingsView: View {
    @EnvironmentObject private var appState: AppState

    private let policy = PrivacyPolicyModel()
    @State private var showDeleteAllConfirmation = false
    @State private var showDeleteLatestConfirmation = false
    @State private var showDeleteEventAudioConfirmation = false

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

                Button(role: .destructive) {
                    showDeleteEventAudioConfirmation = true
                } label: {
                    Label("이벤트 오디오 샘플 삭제", systemImage: "waveform.slash")
                }

                Text("저장된 수면 세션, 이벤트 요약, 리포트, 아침 컨디션, 사용자 확인 feedback, 짧은 이벤트 오디오 샘플을 삭제할 수 있습니다. 원본 전체 오디오는 저장하지 않습니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("개인정보")
        .confirmationDialog("최근 수면 데이터를 삭제할까요?", isPresented: $showDeleteLatestConfirmation, titleVisibility: .visible) {
            Button("최근 수면 데이터 삭제", role: .destructive) {
                appState.deleteLatestSession()
            }
        }
        .confirmationDialog("전체 로컬 수면 데이터를 삭제할까요?", isPresented: $showDeleteAllConfirmation, titleVisibility: .visible) {
            Button("전체 삭제", role: .destructive) {
                appState.deleteAllSleepData()
            }
        }
        .confirmationDialog("저장된 이벤트 오디오 샘플을 삭제할까요?", isPresented: $showDeleteEventAudioConfirmation, titleVisibility: .visible) {
            Button("이벤트 오디오 샘플 삭제", role: .destructive) {
                appState.deleteAllEventAudioSnippets()
            }
        } message: {
            Text("짧게 저장된 이벤트 전후 오디오만 삭제합니다. 수면 세션과 리포트 요약은 유지됩니다.")
        }
    }
}
