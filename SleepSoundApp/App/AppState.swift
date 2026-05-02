import Foundation
import Combine

enum SleepReportSource: Equatable {
    case sample
    case deviceAnalysis

    var displayText: String {
        switch self {
        case .sample:
            "샘플 리포트"
        case .deviceAnalysis:
            "기기 분석 리포트"
        }
    }

    var systemImage: String {
        switch self {
        case .sample:
            "sparkles"
        case .deviceAnalysis:
            "iphone.gen3.radiowaves.left.and.right"
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var activeSession: SleepSession?
    @Published var latestSession: SleepSession
    @Published var latestEvents: [SleepEvent]
    @Published var latestReport: NightReport
    @Published var morningCheckIn: MorningCheckIn
    @Published var latestReportSource: SleepReportSource = .sample
    @Published var recentReports: [NightReport]
    @Published var audioCaptureState: AudioCaptureState = .idle
    @Published var microphonePermissionState: MicrophonePermissionState = .notDetermined
    @Published var latestAudioLevel: Double = 0
    @Published var audioCaptureMessage: String?
    @Published var detectedEventCandidateCount: Int = 0
    @Published var capturedAudioChunkCount: Int = 0

    private let repository: any SleepRepository
    private let audioSessionManager: AudioSessionManaging
    private let audioCaptureService: AudioCaptureServiceProtocol
    private let sleepAnalyzer: SleepAnalyzer
    private var recentAudioBuffer = AudioRingBuffer(maxChunkCount: 180, maxDuration: 180)
    private var currentDetectorOutputs: [DetectorOutput] = []

    init(
        repository: any SleepRepository = JSONFileSleepRepository(),
        audioSessionManager: AudioSessionManaging = AudioSessionManager(),
        audioCaptureService: AudioCaptureServiceProtocol? = nil,
        sleepAnalyzer: SleepAnalyzer = SleepAnalyzer()
    ) {
        let sampleBundle = MockSleepDataFactory.latestBundle()
        let storedReport = repository.latestReport()
        let storedSession = storedReport.flatMap { repository.session(for: $0.sessionId) }
        let hasStoredBundle = storedReport != nil && storedSession != nil
        let initialSession = storedSession ?? sampleBundle.0
        let initialEvents = hasStoredBundle ? repository.events(for: initialSession.id) : sampleBundle.1
        let initialReport = hasStoredBundle ? storedReport ?? sampleBundle.2 : sampleBundle.2
        let initialCheckIn = repository.checkIn(for: initialReport.sessionId) ?? sampleBundle.3
        let initialRecentReports = repository.recentReports(days: 7)

        self.repository = repository
        self.audioSessionManager = audioSessionManager
        self.audioCaptureService = audioCaptureService ?? AudioCaptureService(sessionManager: audioSessionManager)
        self.sleepAnalyzer = sleepAnalyzer
        self.latestSession = initialSession
        self.latestEvents = initialEvents
        self.latestReport = initialReport
        self.morningCheckIn = initialCheckIn
        self.latestReportSource = hasStoredBundle ? .deviceAnalysis : .sample
        self.recentReports = initialRecentReports
        self.microphonePermissionState = audioSessionManager.microphonePermissionState()

        self.audioCaptureService.onChunk = { [weak self] chunk in
            Task { @MainActor [weak self] in
                self?.handleAudioChunk(chunk)
            }
        }

        self.audioCaptureService.onStateChange = { [weak self] state in
            Task { @MainActor [weak self] in
                self?.handleAudioCaptureStateChange(state)
            }
        }
    }

    var isRecording: Bool {
        activeSession != nil
    }

    var isPreparingCapture: Bool {
        audioCaptureState.isPreparing
    }

    func refreshMicrophonePermissionState() {
        microphonePermissionState = audioSessionManager.microphonePermissionState()
    }

    func startSleepSession() {
        guard activeSession == nil, !audioCaptureState.isPreparing else { return }

        audioCaptureMessage = nil
        latestAudioLevel = 0
        detectedEventCandidateCount = 0
        capturedAudioChunkCount = 0
        currentDetectorOutputs.removeAll(keepingCapacity: true)
        recentAudioBuffer.removeAll()

        Task {
            await startAudioCaptureAndCreateSession()
        }
    }

    func endSleepSession() {
        guard let session = activeSession else { return }

        audioCaptureService.stopCapture()
        audioCaptureState = audioCaptureService.state

        let completedSession = makeCompletedSession(from: session, endedAt: Date())
        let smoothedOutputs = sleepAnalyzer.smooth(outputs: currentDetectorOutputs)
        let events = sleepAnalyzer.makeEvents(session: completedSession, outputs: smoothedOutputs)
        let report = SleepScoreCalculator().makeReport(session: completedSession, events: events)

        latestSession = completedSession
        latestEvents = events
        latestReport = report
        latestReportSource = .deviceAnalysis
        morningCheckIn = MorningCheckIn(sessionId: completedSession.id)
        activeSession = nil

        let chunkMessage = capturedAudioChunkCount == 0
            ? "캡처된 오디오 청크가 없어 이벤트 없는 분석 리포트를 만들었습니다."
            : "\(capturedAudioChunkCount)개 오디오 청크에서 \(events.count)개 이벤트 후보를 정리했습니다."
        audioCaptureMessage = chunkMessage

        repository.save(session: completedSession, events: events, report: report)
        refreshRecentReports()
    }

    func saveMorningCheckIn(_ checkIn: MorningCheckIn) {
        morningCheckIn = checkIn
        repository.save(checkIn: checkIn)
    }

    func deleteLatestSession() {
        guard latestReportSource != .sample else { return }
        deleteSession(id: latestSession.id)
    }

    func deleteSession(id: UUID) {
        repository.deleteSession(id: id)
        loadLatestStoredReportOrSample(message: "선택한 수면 데이터가 삭제되었습니다.")
    }

    func deleteAllSleepData() {
        repository.deleteAllSleepData()
        loadLatestStoredReportOrSample(message: "로컬 수면 데이터가 모두 삭제되었습니다.")
    }

    private func startAudioCaptureAndCreateSession() async {
        audioCaptureState = .requestingPermission

        var permissionState = audioSessionManager.microphonePermissionState()
        microphonePermissionState = permissionState
        if permissionState == .notDetermined {
            permissionState = await audioSessionManager.requestMicrophonePermission()
            microphonePermissionState = permissionState
        }

        guard permissionState == .granted else {
            audioCaptureState = .failed(message: AudioCaptureError.microphonePermissionDenied.message)
            audioCaptureMessage = AudioCaptureError.microphonePermissionDenied.message
            return
        }

        audioCaptureState = .ready

        do {
            try audioCaptureService.startCapture()
            audioCaptureState = audioCaptureService.state
            activeSession = SleepSession(
                startedAt: audioCaptureService.state.captureStartedAt ?? Date(),
                estimatedSleepStart: nil,
                estimatedWakeTime: nil,
                measurementDuration: 0,
                estimatedSleepDuration: 0,
                devicePlacement: .bedside,
                ambientNoiseBaseline: nil,
                appVersion: "1.0",
                modelVersion: "rule-placeholder-v1"
            )
        } catch let error as AudioCaptureError {
            audioCaptureState = .failed(message: error.message)
            audioCaptureMessage = error.message
        } catch let error as AudioSessionError {
            audioCaptureState = .failed(message: error.message)
            audioCaptureMessage = error.message
        } catch {
            audioCaptureState = .failed(message: error.localizedDescription)
            audioCaptureMessage = error.localizedDescription
        }
    }

    private func handleAudioChunk(_ chunk: AudioChunk) {
        recentAudioBuffer.append(chunk)
        currentDetectorOutputs.append(contentsOf: sleepAnalyzer.detectOutputs(from: chunk))
        detectedEventCandidateCount = sleepAnalyzer.smooth(outputs: currentDetectorOutputs).count
        capturedAudioChunkCount += 1
        latestAudioLevel = chunk.basicLevel
        audioCaptureState = audioCaptureService.state
    }

    private func handleAudioCaptureStateChange(_ state: AudioCaptureState) {
        audioCaptureState = state

        if case .failed(let message) = state {
            audioCaptureMessage = message
        }
    }

    private func makeCompletedSession(from session: SleepSession, endedAt: Date) -> SleepSession {
        let measurementDuration = max(endedAt.timeIntervalSince(session.startedAt), recentAudioBuffer.retainedDuration)
        let estimatedSleepStart = session.estimatedSleepStart ?? session.startedAt
        let estimatedWakeTime = session.estimatedWakeTime ?? endedAt
        let estimatedSleepDuration = max(estimatedWakeTime.timeIntervalSince(estimatedSleepStart), 0)

        return SleepSession(
            id: session.id,
            startedAt: session.startedAt,
            endedAt: endedAt,
            estimatedSleepStart: estimatedSleepStart,
            estimatedWakeTime: estimatedWakeTime,
            measurementDuration: measurementDuration,
            estimatedSleepDuration: estimatedSleepDuration,
            devicePlacement: session.devicePlacement,
            ambientNoiseBaseline: session.ambientNoiseBaseline,
            appVersion: session.appVersion,
            modelVersion: session.modelVersion
        )
    }

    private func refreshRecentReports() {
        recentReports = repository.recentReports(days: 7)
    }

    private func loadLatestStoredReportOrSample(message: String? = nil) {
        refreshRecentReports()

        if let report = repository.latestReport(),
           let session = repository.session(for: report.sessionId) {
            latestSession = session
            latestEvents = repository.events(for: report.sessionId)
            latestReport = report
            latestReportSource = .deviceAnalysis
            morningCheckIn = repository.checkIn(for: report.sessionId) ?? MorningCheckIn(sessionId: report.sessionId)
        } else {
            let bundle = MockSleepDataFactory.latestBundle()
            latestSession = bundle.0
            latestEvents = bundle.1
            latestReport = bundle.2
            latestReportSource = .sample
            morningCheckIn = bundle.3
            recentReports = []
        }

        audioCaptureMessage = message
    }
}
