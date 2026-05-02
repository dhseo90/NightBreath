import SwiftUI

struct SleepRecordingView: View {
    @EnvironmentObject private var appState: AppState
    let onStopComplete: () -> Void

    init(onStopComplete: @escaping () -> Void = {}) {
        self.onStopComplete = onStopComplete
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let session = appState.activeSession {
                    recordingCard(session: session)
                } else {
                    completedCard
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func recordingCard(session: SleepSession) -> some View {
        VStack(spacing: 18) {
            Image(systemName: "record.circle")
                .font(.system(size: 54))
                .foregroundStyle(.red)

            Text("수면 기록 중")
                .font(.title.bold())

            TimelineView(.periodic(from: session.startedAt, by: 60)) { context in
                Text(SleepFormatters.durationString(context.date.timeIntervalSince(session.startedAt)))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }

            Text("감지 결과는 로컬 리포트 생성을 위한 이벤트 형태로 정리됩니다.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            audioCaptureStatus

            Button(role: .destructive) {
                appState.endSleepSession()
                onStopComplete()
            } label: {
                Label("수면 종료", systemImage: "stop.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var audioCaptureStatus: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(appState.audioCaptureState.displayText, systemImage: "mic")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Int(appState.latestAudioLevel * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: min(max(appState.latestAudioLevel, 0), 1))
                .progressViewStyle(.linear)

            Text("정리된 이벤트 후보 \(appState.detectedEventCandidateCount)개")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("수집된 오디오 청크 \(appState.capturedAudioChunkCount)개")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("마이크 권한 \(appState.microphonePermissionState.displayText)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let message = appState.audioCaptureMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(messageTint)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var messageTint: Color {
        if case .failed = appState.audioCaptureState {
            return .red
        }
        return .secondary
    }

    private var completedCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("최근 리포트가 준비되었습니다")
                .font(.title3.bold())
            Label(appState.latestReportSource.displayText, systemImage: appState.latestReportSource.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            if let message = appState.audioCaptureMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            NavigationLink {
                SleepReportView(report: appState.latestReport, events: appState.latestEvents)
            } label: {
                Label("리포트 보기", systemImage: "doc.text")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
