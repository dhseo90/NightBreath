import SwiftUI

struct SleepStartView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showLatestReport = false

    var body: some View {
        Group {
            if appState.isRecording {
                SleepRecordingView {
                    showLatestReport = true
                }
            } else {
                startContent
            }
        }
        .navigationDestination(isPresented: $showLatestReport) {
            SleepReportView(report: appState.latestReport, events: appState.latestEvents)
        }
        .onAppear {
            appState.refreshMicrophonePermissionState()
        }
    }

    private var startContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.indigo)
                    Text("수면 시작")
                        .font(.largeTitle.bold())
                    Text("iPhone을 침대 옆에 두고 밤새 감지된 소리 기반 지표를 기록합니다.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                permissionStatusCard

                VStack(spacing: 12) {
                    GuideRow(systemImage: "mic", title: "마이크 권한 확인", description: "수면 시작 시 권한을 요청하고 허용된 경우에만 오디오 캡처를 시작합니다.")
                    GuideRow(systemImage: "lock.shield", title: "온디바이스 분석", description: "V1은 서버 업로드 없이 로컬 모델과 규칙 기반 결과만 사용합니다.")
                    GuideRow(systemImage: "waveform.badge.minus", title: "원본 전체 오디오 저장 안 함", description: "리포트용 이벤트 메타데이터를 중심으로 저장합니다.")
                }

                Button {
                    appState.startSleepSession()
                } label: {
                    Label(startButtonTitle, systemImage: startButtonIcon)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(appState.isPreparingCapture)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var permissionStatusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("마이크 권한", systemImage: "mic")
                    .font(.headline)
                Spacer()
                Text(appState.microphonePermissionState.displayText)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(permissionTint.opacity(0.14))
                    .foregroundStyle(permissionTint)
                    .clipShape(Capsule())
            }

            Text(permissionDescription)
                .font(.callout)
                .foregroundStyle(.secondary)

            if appState.isPreparingCapture {
                Label(appState.audioCaptureState.displayText, systemImage: "waveform")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let message = appState.audioCaptureMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var startButtonTitle: String {
        appState.isPreparingCapture ? "캡처 준비 중" : "수면 시작"
    }

    private var startButtonIcon: String {
        appState.isPreparingCapture ? "hourglass" : "play.fill"
    }

    private var permissionDescription: String {
        switch appState.microphonePermissionState {
        case .notDetermined:
            "수면 시작을 누르면 iPhone에서 마이크 권한을 요청합니다."
        case .granted:
            "마이크 권한이 허용되어 실제 오디오 캡처 테스트를 시작할 수 있습니다."
        case .denied:
            "설정 앱에서 밤숨의 마이크 권한을 허용한 뒤 다시 시도해 주세요."
        }
    }

    private var permissionTint: Color {
        switch appState.microphonePermissionState {
        case .notDetermined:
            .orange
        case .granted:
            .green
        case .denied:
            .red
        }
    }
}

private struct GuideRow: View {
    let systemImage: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
