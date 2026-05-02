import SwiftUI

struct SleepStartView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.isRecording {
                SleepRecordingView()
            } else {
                startContent
            }
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

                VStack(spacing: 12) {
                    GuideRow(systemImage: "mic", title: "마이크 권한 확인", description: "수면 시작 전에 권한 상태를 확인하는 흐름을 둡니다.")
                    GuideRow(systemImage: "lock.shield", title: "온디바이스 분석", description: "V1은 서버 업로드 없이 로컬 모델과 규칙 기반 결과만 사용합니다.")
                    GuideRow(systemImage: "waveform.badge.minus", title: "원본 전체 오디오 저장 안 함", description: "리포트용 이벤트 메타데이터를 중심으로 저장합니다.")
                }

                Button {
                    appState.startSleepSession()
                } label: {
                    Label("수면 시작", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
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
