import SwiftUI

struct MorningCheckInView: View {
    @EnvironmentObject private var appState: AppState

    let sessionId: UUID

    @State private var refreshScore = 3
    @State private var fatigueScore = 3
    @State private var headache = false
    @State private var dryMouth = false
    @State private var soreThroat = false
    @State private var rememberedAwakenings = 0
    @State private var memo = ""
    @State private var didLoadExisting = false
    @State private var saved = false

    var body: some View {
        Form {
            Section("아침 컨디션") {
                Stepper("개운함 \(refreshScore)/5", value: $refreshScore, in: 1...5)
                Stepper("피로감 \(fatigueScore)/5", value: $fatigueScore, in: 1...5)
                Stepper("기억나는 각성 \(rememberedAwakenings)회", value: $rememberedAwakenings, in: 0...20)
            }

            Section("느껴진 증상") {
                Toggle("두통", isOn: $headache)
                Toggle("입 마름", isOn: $dryMouth)
                Toggle("목 불편감", isOn: $soreThroat)
            }

            Section("메모") {
                TextEditor(text: $memo)
                    .frame(minHeight: 120)
            }

            Section {
                Button {
                    save()
                } label: {
                    Label(saved ? "저장됨" : "체크인 저장", systemImage: saved ? "checkmark.circle.fill" : "tray.and.arrow.down")
                }
            }
        }
        .navigationTitle("아침 체크인")
        .onAppear(perform: loadExistingIfNeeded)
    }

    private func loadExistingIfNeeded() {
        guard !didLoadExisting else { return }
        didLoadExisting = true

        guard appState.morningCheckIn.sessionId == sessionId else { return }
        refreshScore = appState.morningCheckIn.refreshScore
        fatigueScore = appState.morningCheckIn.fatigueScore
        headache = appState.morningCheckIn.headache
        dryMouth = appState.morningCheckIn.dryMouth
        soreThroat = appState.morningCheckIn.soreThroat
        rememberedAwakenings = appState.morningCheckIn.rememberedAwakenings
        memo = appState.morningCheckIn.memo
    }

    private func save() {
        let checkIn = MorningCheckIn(
            sessionId: sessionId,
            refreshScore: refreshScore,
            fatigueScore: fatigueScore,
            headache: headache,
            dryMouth: dryMouth,
            soreThroat: soreThroat,
            rememberedAwakenings: rememberedAwakenings,
            memo: memo
        )
        appState.saveMorningCheckIn(checkIn)
        saved = true
    }
}
