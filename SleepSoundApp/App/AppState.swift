import Foundation
import Combine
#if os(iOS)
import AVFoundation
import UIKit
#endif

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
    @Published var latestDetectedEventText: String = "아직 없음"
    @Published var latestDetectedEventAt: Date?
    @Published var audioCaptureMetrics = AudioCaptureMetrics()
    @Published var debugLifecycleLog: [String] = []

    private let repository: any SleepRepository
    private let audioSessionManager: AudioSessionManaging
    private let audioCaptureService: AudioCaptureServiceProtocol
    private let sleepAnalyzer: SleepAnalyzer
    private let eventAudioSnippetStore: EventAudioSnippetStore
    private var recentAudioBuffer = AudioRingBuffer(maxChunkCount: 180, maxDuration: 180)
    private var currentDetectorOutputs: [DetectorOutput] = []
    private var eventAudioSnippetTasks: [Task<Void, Never>] = []
    private var savedAudioSnippets: [EventAudioSnippet] = []
    private var scheduledSnippetKeys = Set<String>()
    private var latestSnippetStartedAtByType: [SleepEventType: Date] = [:]
    private var lifecycleObservers: [NSObjectProtocol] = []

    init(
        repository: any SleepRepository = JSONFileSleepRepository(),
        audioSessionManager: AudioSessionManaging = AudioSessionManager(),
        audioCaptureService: AudioCaptureServiceProtocol? = nil,
        sleepAnalyzer: SleepAnalyzer = SleepAnalyzer(),
        eventAudioSnippetStore: EventAudioSnippetStore = EventAudioSnippetStore()
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
        self.eventAudioSnippetStore = eventAudioSnippetStore
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

        installLifecycleObservers()
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
        latestDetectedEventText = "아직 없음"
        latestDetectedEventAt = nil
        audioCaptureMetrics = AudioCaptureMetrics()
        currentDetectorOutputs.removeAll(keepingCapacity: true)
        eventAudioSnippetTasks.forEach { $0.cancel() }
        eventAudioSnippetTasks.removeAll(keepingCapacity: true)
        savedAudioSnippets.removeAll(keepingCapacity: true)
        scheduledSnippetKeys.removeAll(keepingCapacity: true)
        latestSnippetStartedAtByType.removeAll(keepingCapacity: true)
        recentAudioBuffer.removeAll()
        try? eventAudioSnippetStore.pruneExpiredSnippets()

        Task {
            await startAudioCaptureAndCreateSession()
        }
    }

    func endSleepSession() {
        guard let session = activeSession else { return }

        audioCaptureService.stopCapture()
        recordDebugLifecycleEvent("audio capture stopped")
        audioCaptureState = audioCaptureService.state

        let endedAt = Date()
        audioCaptureMetrics.stop(at: endedAt)
        let completedSession = makeCompletedSession(from: session, endedAt: endedAt)
        let smoothedOutputs = sleepAnalyzer.smooth(outputs: currentDetectorOutputs)
        saveMissingEventAudioSnippets(sessionId: completedSession.id, outputs: smoothedOutputs)
        eventAudioSnippetTasks.forEach { $0.cancel() }
        eventAudioSnippetTasks.removeAll(keepingCapacity: true)
        let events = attachAudioSnippets(
            to: sleepAnalyzer.makeEvents(session: completedSession, outputs: smoothedOutputs)
        )
        let report = SleepScoreCalculator().makeReport(
            session: completedSession,
            events: events,
            captureMetrics: audioCaptureMetrics
        )

        latestSession = completedSession
        latestEvents = events
        latestReport = report
        latestReportSource = .deviceAnalysis
        morningCheckIn = MorningCheckIn(sessionId: completedSession.id)
        activeSession = nil

        let chunkMessage = capturedAudioChunkCount == 0
            ? "캡처된 오디오 청크가 없어 이벤트 없는 분석 리포트를 만들었습니다."
            : "\(capturedAudioChunkCount)개 오디오 청크에서 \(events.count)개 이벤트 후보와 \(events.filter { $0.audioSnippetFileName != nil }.count)개 짧은 오디오 샘플을 정리했습니다."
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
        let events = repository.events(for: id)
        let eventIds = events.map(\.id)
        for fileName in events.compactMap(\.audioSnippetFileName) {
            try? eventAudioSnippetStore.deleteSnippet(fileName: fileName)
        }
        try? SleepEventFeedbackStore().deleteFeedback(for: eventIds)
        repository.deleteSession(id: id)
        loadLatestStoredReportOrSample(message: "선택한 수면 데이터가 삭제되었습니다.")
    }

    func deleteAllSleepData() {
        repository.deleteAllSleepData()
        try? SleepEventFeedbackStore().deleteAllFeedback()
        try? eventAudioSnippetStore.deleteAllSnippets()
        loadLatestStoredReportOrSample(message: "로컬 수면 데이터가 모두 삭제되었습니다.")
    }

    func deleteAllEventAudioSnippets() {
        try? eventAudioSnippetStore.deleteAllSnippets()
        latestEvents = latestEvents.map { event in
            var updatedEvent = event
            updatedEvent.audioSnippetFileName = nil
            updatedEvent.audioSnippetDuration = nil
            return updatedEvent
        }
        latestReport.savedAudioDuration = 0
        if latestReportSource == .deviceAnalysis {
            repository.save(session: latestSession, events: latestEvents, report: latestReport)
            refreshRecentReports()
        }
        audioCaptureMessage = "저장된 이벤트 오디오 샘플을 삭제했습니다."
    }

    func deleteEventAudioSnippet(for eventId: UUID) {
        guard let eventIndex = latestEvents.firstIndex(where: { $0.id == eventId }) else { return }
        guard let fileName = latestEvents[eventIndex].audioSnippetFileName else { return }

        try? eventAudioSnippetStore.deleteSnippet(fileName: fileName)
        latestEvents[eventIndex].audioSnippetFileName = nil
        latestEvents[eventIndex].audioSnippetDuration = nil
        latestReport.savedAudioDuration = latestEvents.reduce(0) { partialResult, event in
            partialResult + max(0, event.audioSnippetDuration ?? 0)
        }

        if latestReportSource == .deviceAnalysis {
            repository.save(session: latestSession, events: latestEvents, report: latestReport)
            refreshRecentReports()
        }
        audioCaptureMessage = "선택한 이벤트 오디오 샘플을 삭제했습니다."
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
            audioCaptureMetrics.recordCaptureError()
            audioCaptureState = .failed(message: AudioCaptureError.microphonePermissionDenied.message)
            audioCaptureMessage = AudioCaptureError.microphonePermissionDenied.message
            return
        }

        audioCaptureState = .ready

        do {
            try audioCaptureService.startCapture()
            audioCaptureState = audioCaptureService.state
            let startedAt = audioCaptureService.state.captureStartedAt ?? Date()
            audioCaptureMetrics.start(at: startedAt)
            recordDebugLifecycleEvent("audio capture started")
            activeSession = SleepSession(
                startedAt: startedAt,
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
            audioCaptureMetrics.recordCaptureError()
            recordDebugLifecycleEvent("capture error: \(error.message)")
            audioCaptureState = .failed(message: error.message)
            audioCaptureMessage = error.message
        } catch let error as AudioSessionError {
            audioCaptureMetrics.recordCaptureError()
            recordDebugLifecycleEvent("capture error: \(error.message)")
            audioCaptureState = .failed(message: error.message)
            audioCaptureMessage = error.message
        } catch {
            audioCaptureMetrics.recordCaptureError()
            recordDebugLifecycleEvent("capture error: \(error.localizedDescription)")
            audioCaptureState = .failed(message: error.localizedDescription)
            audioCaptureMessage = error.localizedDescription
        }
    }

    private func handleAudioChunk(_ chunk: AudioChunk) {
        recentAudioBuffer.append(chunk)
        audioCaptureMetrics.recordReceived(chunk: chunk)
        let outputs = sleepAnalyzer.detectOutputs(from: chunk, updating: &audioCaptureMetrics)
        currentDetectorOutputs.append(contentsOf: outputs)
        for output in outputs {
            scheduleEventAudioSnippetCapture(sessionId: activeSession?.id, output: output)
        }
        detectedEventCandidateCount = sleepAnalyzer.smooth(outputs: currentDetectorOutputs).count
        capturedAudioChunkCount += 1
        latestAudioLevel = chunk.basicLevel
        if let output = outputs.max(by: { $0.confidence < $1.confidence }) {
            latestDetectedEventText = "\(output.eventType.displayName) \(Int(output.confidence * 100))%"
            latestDetectedEventAt = Date()
        }
        audioCaptureState = audioCaptureService.state
    }

    private func handleAudioCaptureStateChange(_ state: AudioCaptureState) {
        audioCaptureState = state

        if case .failed(let message) = state {
            if message == AudioCaptureError.captureInterrupted.message {
                audioCaptureMetrics.recordInterruption()
                recordDebugLifecycleEvent("audio interruption began")
            }
            audioCaptureMetrics.recordCaptureError()
            recordDebugLifecycleEvent("capture error: \(message)")
            audioCaptureMessage = message
        }
    }

    func recordDebugLifecycleEvent(_ message: String) {
        #if DEBUG
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "HH:mm:ss"
        debugLifecycleLog.append("\(formatter.string(from: Date())) \(message)")
        if debugLifecycleLog.count > 40 {
            debugLifecycleLog.removeFirst(debugLifecycleLog.count - 40)
        }
        #endif
    }

    private func installLifecycleObservers() {
        #if DEBUG && os(iOS)
        let notificationCenter = NotificationCenter.default
        let notifications: [(Notification.Name, String)] = [
            (UIApplication.didBecomeActiveNotification, "app became active"),
            (UIApplication.willResignActiveNotification, "app will resign active"),
            (UIApplication.didEnterBackgroundNotification, "app entered background"),
            (UIApplication.willTerminateNotification, "app will terminate")
        ]

        lifecycleObservers = notifications.map { name, message in
            notificationCenter.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.recordDebugLifecycleEvent(message)
                }
            }
        }

        let audioInterruptionObserver = notificationCenter.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let interruptionMessage: String

            if let rawType,
               let type = AVAudioSession.InterruptionType(rawValue: rawType),
               type == .began {
                interruptionMessage = "audio interruption began"
            } else if let rawType,
                      let type = AVAudioSession.InterruptionType(rawValue: rawType),
                      type == .ended {
                interruptionMessage = "audio interruption ended"
            } else {
                interruptionMessage = "audio interruption changed"
            }

            Task { @MainActor [weak self] in
                self?.recordDebugLifecycleEvent(interruptionMessage)
            }
        }
        lifecycleObservers.append(audioInterruptionObserver)
        #endif
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

    private func scheduleEventAudioSnippetCapture(sessionId: UUID?, output: DetectorOutput) {
        guard let sessionId,
              output.eventType != .unknown,
              output.duration > 0,
              output.confidence >= 0.35 else {
            return
        }

        if let latest = latestSnippetStartedAtByType[output.eventType],
           output.startedAt.timeIntervalSince(latest) < 4 {
            return
        }

        let key = snippetKey(for: output)
        guard !scheduledSnippetKeys.contains(key) else { return }
        guard savedAudioSnippets.count + eventAudioSnippetTasks.count < EventAudioSnippetPolicy.default.maxSnippetsPerSession else {
            return
        }

        scheduledSnippetKeys.insert(key)
        latestSnippetStartedAtByType[output.eventType] = output.startedAt

        let delaySeconds = max(0, output.endedAt.addingTimeInterval(EventAudioSnippetPolicy.default.postEventSeconds).timeIntervalSinceNow)
        let task = Task { [weak self] in
            let nanoseconds = UInt64(delaySeconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            await MainActor.run { [weak self] in
                self?.saveEventAudioSnippet(sessionId: sessionId, output: output)
            }
        }
        eventAudioSnippetTasks.append(task)
    }

    private func saveMissingEventAudioSnippets(sessionId: UUID, outputs: [DetectorOutput]) {
        for output in outputs where output.eventType != .unknown && output.duration > 0 {
            guard savedAudioSnippets.count < EventAudioSnippetPolicy.default.maxSnippetsPerSession else { return }
            guard !savedAudioSnippets.contains(where: { snippetMatches($0, output: output) }) else { continue }
            saveEventAudioSnippet(sessionId: sessionId, output: output)
        }
    }

    private func saveEventAudioSnippet(sessionId: UUID, output: DetectorOutput) {
        guard output.eventType != .unknown else { return }

        do {
            let snippet = try eventAudioSnippetStore.saveSnippet(
                sessionId: sessionId,
                output: output,
                chunks: recentAudioBuffer.snapshot()
            )
            if !savedAudioSnippets.contains(where: { $0.fileName == snippet.fileName }) {
                savedAudioSnippets.append(snippet)
            }
        } catch {
            recordDebugLifecycleEvent("event audio snippet skipped: \(error.localizedDescription)")
        }
    }

    private func attachAudioSnippets(to events: [SleepEvent]) -> [SleepEvent] {
        var unmatchedSnippets = savedAudioSnippets.sorted { $0.eventStartedAt < $1.eventStartedAt }
        var matchedFileNames = Set<String>()

        let eventsWithSnippets = events.map { event in
            var updatedEvent = event
            guard let index = unmatchedSnippets.firstIndex(where: { snippetMatches($0, event: event) }) else {
                return updatedEvent
            }

            let snippet = unmatchedSnippets.remove(at: index)
            updatedEvent.audioSnippetFileName = snippet.fileName
            updatedEvent.audioSnippetDuration = snippet.duration
            matchedFileNames.insert(snippet.fileName)
            return updatedEvent
        }

        for snippet in savedAudioSnippets where !matchedFileNames.contains(snippet.fileName) {
            try? eventAudioSnippetStore.deleteSnippet(fileName: snippet.fileName)
        }
        savedAudioSnippets.removeAll { !matchedFileNames.contains($0.fileName) }

        return eventsWithSnippets
    }

    private func snippetMatches(_ snippet: EventAudioSnippet, event: SleepEvent) -> Bool {
        guard snippet.eventType == event.type else { return false }
        let tolerance: TimeInterval = 2
        return snippet.eventStartedAt <= event.endedAt.addingTimeInterval(tolerance) &&
            event.startedAt <= snippet.eventEndedAt.addingTimeInterval(tolerance)
    }

    private func snippetMatches(_ snippet: EventAudioSnippet, output: DetectorOutput) -> Bool {
        guard snippet.eventType == output.eventType else { return false }
        let tolerance: TimeInterval = 2
        return snippet.eventStartedAt <= output.endedAt.addingTimeInterval(tolerance) &&
            output.startedAt <= snippet.eventEndedAt.addingTimeInterval(tolerance)
    }

    private func snippetKey(for output: DetectorOutput) -> String {
        let timeBucket = Int(output.startedAt.timeIntervalSinceReferenceDate)
        return "\(output.eventType.rawValue)-\(timeBucket)"
    }
}
