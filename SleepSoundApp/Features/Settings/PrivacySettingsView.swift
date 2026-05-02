import SwiftUI

struct PrivacySettingsView: View {
    private let policy = PrivacyPolicyModel()

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
        }
        .navigationTitle("개인정보")
    }
}
