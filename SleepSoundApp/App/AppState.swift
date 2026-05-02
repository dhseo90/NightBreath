import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var activeSession: SleepSession?
    @Published var latestSession: SleepSession
    @Published var latestEvents: [SleepEvent]
    @Published var latestReport: NightReport
    @Published var morningCheckIn: MorningCheckIn

    private let repository: SleepRepository

    init(repository: SleepRepository = SleepRepository()) {
        let bundle = MockSleepDataFactory.latestBundle()
        self.repository = repository
        self.latestSession = bundle.0
        self.latestEvents = bundle.1
        self.latestReport = bundle.2
        self.morningCheckIn = bundle.3

        repository.save(session: bundle.0, events: bundle.1, report: bundle.2)
        repository.save(checkIn: bundle.3)
    }

    var isRecording: Bool {
        activeSession != nil
    }

    func startSleepSession() {
        activeSession = SleepSession(
            startedAt: Date(),
            estimatedSleepStart: nil,
            estimatedWakeTime: nil,
            measurementDuration: 0,
            estimatedSleepDuration: 0,
            devicePlacement: .bedside,
            ambientNoiseBaseline: nil,
            appVersion: "1.0",
            modelVersion: "mock-rule-v1"
        )
    }

    func endSleepSession() {
        let bundle = MockSleepDataFactory.latestBundle(now: Date())
        latestSession = bundle.0
        latestEvents = bundle.1
        latestReport = bundle.2
        morningCheckIn = MorningCheckIn(sessionId: bundle.0.id)
        activeSession = nil

        repository.save(session: bundle.0, events: bundle.1, report: bundle.2)
    }

    func saveMorningCheckIn(_ checkIn: MorningCheckIn) {
        morningCheckIn = checkIn
        repository.save(checkIn: checkIn)
    }
}
