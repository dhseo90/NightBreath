import Foundation
import Combine
#if os(iOS)
import AVFoundation
import UIKit
#endif

enum SleepReportSource: Equatable {
    case sample
    case deviceAnalysis
    case simulatorQA

    var displayText: String {
        switch self {
        case .sample:
            "샘플 리포트"
        case .deviceAnalysis:
            "기기 분석 리포트"
        case .simulatorQA:
            "검증용 예시"
        }
    }

    var systemImage: String {
        switch self {
        case .sample:
            "sparkles"
        case .deviceAnalysis:
            "iphone.gen3.radiowaves.left.and.right"
        case .simulatorQA:
            "iphone.and.arrow.forward"
        }
    }
}

enum SleepRecordingPhase: Equatable {
    case recording
    case stoppingCapture
    case captureStoppedFinalizing
    case reportReady

    var title: String {
        switch self {
        case .recording:
            "수면 기록 중"
        case .stoppingCapture:
            "녹음 중단 처리 중"
        case .captureStoppedFinalizing:
            "수면 리포트 정리 중"
        case .reportReady:
            "리포트 준비 완료"
        }
    }

    var message: String {
        switch self {
        case .recording:
            "감지 결과는 로컬 리포트 생성을 위한 이벤트 형태로 정리됩니다."
        case .stoppingCapture:
            "녹음 중단 요청을 처리하고 있습니다."
        case .captureStoppedFinalizing:
            "녹음은 중단되었습니다. iPhone 안에서 리포트를 정리하고 있습니다."
        case .reportReady:
            "리포트 정리가 끝났습니다."
        }
    }

    var isStopButtonDisabled: Bool {
        self != .recording
    }
}

struct PendingFitdaysImportFile: Identifiable {
    let id = UUID()
    var url: URL
    var statusMessage: String
}

@MainActor
final class AppState: ObservableObject {
    @Published var activeSession: SleepSession?
    @Published var latestSession: SleepSession
    @Published var latestEvents: [SleepEvent]
    @Published var latestReport: NightReport
    @Published var morningCheckIn: MorningCheckIn
    @Published private(set) var eveningCheckIns: [EveningCheckIn]
    @Published var latestReportSource: SleepReportSource = .sample
    @Published var recentReports: [NightReport]
    @Published var audioCaptureState: AudioCaptureState = .idle
    @Published var microphonePermissionState: MicrophonePermissionState = .notDetermined
    @Published var latestAudioLevel: Double = 0
    @Published var audioCaptureMessage: String?
    @Published var isFinalizingSleepSession = false
    @Published var sleepRecordingPhase: SleepRecordingPhase = .reportReady
    @Published var detectedEventCandidateCount: Int = 0
    @Published var capturedAudioChunkCount: Int = 0
    @Published var latestDetectedEventText: String = "아직 없음"
    @Published var latestDetectedEventAt: Date?
    @Published var audioCaptureMetrics = AudioCaptureMetrics()
    @Published var debugLifecycleLog: [String] = []
    @Published private(set) var isEventAudioSampleStorageEnabled: Bool
    @Published private(set) var hasCompletedOnboarding: Bool
    @Published private(set) var eventAudioStorageStats = EventAudioStorageStats.empty
    @Published var eventAudioStorageMessage: String?
    @Published private(set) var eventFeedbackCount = 0
    @Published var eventFeedbackMessage: String?
    @Published var latestDetectorDiagnostics: DetectorDiagnostics?
    @Published private(set) var detectorTuningProfile: DetectorTuningProfile
    @Published var pendingFitdaysImportFile: PendingFitdaysImportFile?
    @Published var fitdaysOpenInMessage: String?
    #if DEBUG
    @Published var activeSimulatorQAScenario: SimulatorQAScenarioPreset?
    @Published var activeScreenshotScenario: ScreenshotScenario?
    #endif

    private let repository: any SleepRepository
    private let eveningCheckInRepository: any EveningCheckInRepositoryProtocol
    private let audioSessionManager: AudioSessionManaging
    private let audioCaptureService: AudioCaptureServiceProtocol
    private var sleepAnalyzer: SleepAnalyzer
    private let eventAudioSnippetStore: EventAudioSnippetStore
    private let eventFeedbackStore: SleepEventFeedbackStore
    private let userSettings: UserSettingsProviding
    private var recentAudioBuffer = AudioRingBuffer(maxChunkCount: 180, maxDuration: 180)
    private var eventAudioSnippetTasks: [Task<Void, Never>] = []
    private var audioProcessingPipeline: SleepAudioProcessingPipeline?
    private var audioProcessingTask: Task<Void, Never>?
    private var audioProcessingGeneration: UInt64 = 0
    private var lastAudioProcessingUIUpdateAt: Date?
    private let audioProcessingUIRefreshInterval: TimeInterval = 1.0
    private var sleepFinalizationTask: Task<Void, Never>?
    private var captureStopSafetyTask: Task<Void, Never>?
    private var savedAudioSnippets: [EventAudioSnippet] = []
    private var scheduledSnippetKeys = Set<String>()
    private var latestSnippetStartedAtByType: [SleepEventType: Date] = [:]
    private var lifecycleObservers: [NSObjectProtocol] = []
    #if DEBUG
    private var simulatorQAStorageStatsOverride: EventAudioStorageStats?
    #endif

    init(
        repository: any SleepRepository = JSONFileSleepRepository(),
        eveningCheckInRepository: any EveningCheckInRepositoryProtocol = JSONEveningCheckInRepository(),
        audioSessionManager: AudioSessionManaging = AudioSessionManager(),
        audioCaptureService: AudioCaptureServiceProtocol? = nil,
        sleepAnalyzer: SleepAnalyzer? = nil,
        eventAudioSnippetStore: EventAudioSnippetStore = EventAudioSnippetStore(),
        eventFeedbackStore: SleepEventFeedbackStore = SleepEventFeedbackStore(),
        userSettings: UserSettingsProviding = UserSettings(),
        detectorTuningProfile: DetectorTuningProfile? = nil
    ) {
        let initialDetectorTuningProfile = detectorTuningProfile ?? userSettings.detectorTuningProfile
        let sampleBundle = MockSleepDataFactory.latestBundle()
        let storedReport = repository.latestReport()
        let storedSession = storedReport.flatMap { repository.session(for: $0.sessionId) }
        let hasStoredBundle = storedReport != nil && storedSession != nil
        let initialSession = storedSession ?? sampleBundle.0
        let initialEvents = hasStoredBundle ? repository.events(for: initialSession.id) : sampleBundle.1
        let initialReport = hasStoredBundle ? storedReport ?? sampleBundle.2 : sampleBundle.2
        let initialCheckIn = repository.checkIn(for: initialReport.sessionId) ?? sampleBundle.3
        let initialRecentReports = repository.recentReports(days: 7)
        let initialEveningCheckIns = eveningCheckInRepository.all()

        self.repository = repository
        self.eveningCheckInRepository = eveningCheckInRepository
        self.audioSessionManager = audioSessionManager
        self.audioCaptureService = audioCaptureService ?? AudioCaptureService(sessionManager: audioSessionManager)
        self.sleepAnalyzer = sleepAnalyzer ?? initialDetectorTuningProfile.configuration.makeSleepAnalyzer()
        self.eventAudioSnippetStore = eventAudioSnippetStore
        self.eventFeedbackStore = eventFeedbackStore
        self.userSettings = userSettings
        self.detectorTuningProfile = initialDetectorTuningProfile
        self.latestSession = initialSession
        self.latestEvents = initialEvents
        self.latestReport = initialReport
        self.morningCheckIn = initialCheckIn
        self.eveningCheckIns = initialEveningCheckIns
        self.latestReportSource = hasStoredBundle ? .deviceAnalysis : .sample
        self.recentReports = initialRecentReports
        self.microphonePermissionState = audioSessionManager.microphonePermissionState()
        self.isEventAudioSampleStorageEnabled = userSettings.isEventAudioSampleStorageEnabled
        self.hasCompletedOnboarding = userSettings.hasCompletedOnboarding
        self.latestDetectorDiagnostics = initialReport.detectorDiagnostics
        self.eventFeedbackCount = eventFeedbackStore.feedbackCount()
        refreshEventAudioStorageStats()

        self.audioCaptureService.onChunk = { [weak self] chunk in
            Task { @MainActor [weak self] in
                self?.enqueueAudioChunk(chunk)
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
        audioCaptureState.isPreparing || isFinalizingSleepSession
    }

    var detectorThresholdConfiguration: DetectorThresholdConfiguration {
        detectorTuningProfile.configuration
    }

    func trendReports(days: Int) -> [NightReport] {
        let dayCount = max(days, 1)
        let cutoff = Date().addingTimeInterval(-TimeInterval(dayCount) * 24 * 60 * 60)
        var reports = repository.recentReports(days: dayCount)

        if latestReport.generatedAt >= cutoff,
           !reports.contains(where: { $0.sessionId == latestReport.sessionId }) {
            reports.append(latestReport)
        }

        let uniqueReports = reports.reduce(into: [UUID: NightReport]()) { result, report in
            guard report.generatedAt >= cutoff else { return }

            if let existing = result[report.sessionId], existing.generatedAt > report.generatedAt {
                return
            }

            result[report.sessionId] = report
        }

        return uniqueReports.values.sorted { lhs, rhs in
            if lhs.generatedAt == rhs.generatedAt {
                return lhs.sessionId.uuidString < rhs.sessionId.uuidString
            }
            return lhs.generatedAt < rhs.generatedAt
        }
    }

    func checkIn(for sessionId: UUID) -> MorningCheckIn? {
        if morningCheckIn.sessionId == sessionId {
            return morningCheckIn
        }
        return repository.checkIn(for: sessionId)
    }

    func eveningCheckIn(for date: Date, calendar: Calendar = .current) -> EveningCheckIn? {
        if let cached = eveningCheckIns
            .filter({ calendar.isDate($0.date, inSameDayAs: date) })
            .sorted(by: { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.id.uuidString < rhs.id.uuidString
                }
                return lhs.updatedAt > rhs.updatedAt
            })
            .first {
            return cached
        }

        return eveningCheckInRepository.latest(on: date, calendar: calendar)
    }

    var currentDetectorBackend: SleepDetectionBackend {
        sleepAnalyzer.detectorBackend
    }

    var isCurrentDetectorModelInstalled: Bool {
        sleepAnalyzer.isModelInstalled
    }

    var currentDetectorThresholdSnapshot: [String: Double] {
        var snapshot = sleepAnalyzer.thresholdsSnapshot
        snapshot.merge(detectorThresholdConfiguration.thresholdSnapshot) { _, new in new }
        return snapshot
    }

    func refreshMicrophonePermissionState() {
        microphonePermissionState = audioSessionManager.microphonePermissionState()
    }

    var canResetOnboarding: Bool {
        hasCompletedOnboarding
    }

    func requestMicrophonePermission() async -> MicrophonePermissionState {
        audioCaptureState = .requestingPermission
        var permissionState = audioSessionManager.microphonePermissionState()
        if permissionState == .notDetermined {
            permissionState = await audioSessionManager.requestMicrophonePermission()
        }
        microphonePermissionState = permissionState
        audioCaptureState = permissionState == .granted ? .ready : .failed(message: AudioCaptureError.microphonePermissionDenied.message)
        return permissionState
    }

    func completeOnboarding() {
        userSettings.hasCompletedOnboarding = true
        hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        userSettings.hasCompletedOnboarding = false
        hasCompletedOnboarding = false
    }

    func setEventAudioSampleStorageEnabled(_ isEnabled: Bool) {
        userSettings.isEventAudioSampleStorageEnabled = isEnabled
        isEventAudioSampleStorageEnabled = isEnabled

        if !isEnabled {
            cancelPendingEventAudioSnippetTasks()
        }
    }

    func setDetectorTuningProfile(_ profile: DetectorTuningProfile) {
        guard !isRecording else {
            audioCaptureMessage = "측정 중에는 detector profile을 바꾸지 않습니다. 다음 세션 전에 변경하세요."
            return
        }

        detectorTuningProfile = profile
        userSettings.detectorTuningProfile = profile
        sleepAnalyzer = profile.configuration.makeSleepAnalyzer()
        audioCaptureMessage = "다음 측정부터 detector 민감도 ‘\(profile.displayName)’를 사용합니다."
    }

    func handleOpenURL(_ url: URL) {
        guard FitdaysImportFilePolicy.isSupportedFileName(url.lastPathComponent) else {
            fitdaysOpenInMessage = "CSV 또는 text 기반 Fitdays export 파일만 가져올 수 있습니다."
            return
        }

        pendingFitdaysImportFile = PendingFitdaysImportFile(
            url: url,
            statusMessage: "Fitdays export 파일 미리보기를 만들었습니다."
        )
    }

    #if DEBUG
    func applySimulatorQAScenario(_ preset: SimulatorQAScenarioPreset) {
        if activeSession != nil {
            audioCaptureService.stopCapture()
        }

        cancelPendingEventAudioSnippetTasks()
        recentAudioBuffer.removeAll()
        audioProcessingTask?.cancel()
        audioProcessingTask = nil
        audioProcessingPipeline = nil
        audioProcessingGeneration &+= 1
        lastAudioProcessingUIUpdateAt = nil
        savedAudioSnippets.removeAll(keepingCapacity: true)
        scheduledSnippetKeys.removeAll(keepingCapacity: true)
        latestSnippetStartedAtByType.removeAll(keepingCapacity: true)

        let bundle = SimulatorQAScenarioFactory.make(preset: preset)
        latestSession = bundle.session
        latestEvents = bundle.events
        latestReport = bundle.report
        latestDetectorDiagnostics = bundle.detectorDiagnostics
        latestReportSource = .simulatorQA
        morningCheckIn = MorningCheckIn(sessionId: bundle.session.id)
        recentReports = bundle.recentReports
        isEventAudioSampleStorageEnabled = bundle.isEventAudioSampleStorageEnabled
        simulatorQAStorageStatsOverride = bundle.eventAudioStorageStats
        eventAudioStorageStats = bundle.eventAudioStorageStats
        activeSimulatorQAScenario = preset
        activeScreenshotScenario = nil
        activeSession = nil
        sleepRecordingPhase = .reportReady

        audioCaptureMetrics = AudioCaptureMetrics(
            captureStartedAt: bundle.session.startedAt,
            captureStoppedAt: bundle.session.endedAt,
            sessionElapsedSeconds: bundle.report.measurementDuration,
            captureActiveSeconds: bundle.report.measurementDuration,
            receivedAudioSeconds: bundle.report.receivedAudioDuration,
            analyzedAudioSeconds: bundle.report.analyzedAudioDuration,
            receivedChunkCount: bundle.detectorDiagnostics.analyzedChunkCount,
            analyzedChunkCount: bundle.detectorDiagnostics.analyzedChunkCount,
            totalReceivedFrameCount: Int64(bundle.report.receivedAudioDuration * 16_000),
            totalAnalyzedFrameCount: Int64(bundle.report.analyzedAudioDuration * 16_000),
            sampleRate: 16_000,
            lastChunkReceivedAt: bundle.report.receivedAudioDuration > 0
                ? bundle.session.startedAt.addingTimeInterval(bundle.report.receivedAudioDuration)
                : nil,
            lastChunkAnalyzedAt: bundle.report.analyzedAudioDuration > 0
                ? bundle.session.startedAt.addingTimeInterval(bundle.report.analyzedAudioDuration)
                : nil,
            interruptionCount: bundle.report.interruptionCount,
            longestChunkGapSeconds: bundle.report.longestAudioGapSeconds,
            currentChunkGapSeconds: max(0, bundle.report.measurementDuration - bundle.report.receivedAudioDuration),
            audioCoverageRatio: bundle.report.audioCoverageRatio
        )
        audioCaptureState = .idle
        latestAudioLevel = bundle.detectorDiagnostics.rmsSummary.p90
        capturedAudioChunkCount = bundle.detectorDiagnostics.analyzedChunkCount
        detectedEventCandidateCount = bundle.detectorDiagnostics.postSmoothingEventCount
        latestDetectedEventText = bundle.events.last.map { "\($0.type.displayName) \(Int($0.confidence * 100))%" } ?? "감지 이벤트 없음"
        latestDetectedEventAt = bundle.events.last?.startedAt
        audioCaptureMessage = "Simulator QA 시나리오 ‘\(preset.koreanTitle)’를 적용했습니다. 실제 오디오 파일은 생성하지 않았습니다."
        eventAudioStorageMessage = "Simulator QA 예시 저장소 상태입니다. 실제 파일은 생성하지 않습니다."
        recordDebugLifecycleEvent("simulator QA scenario applied: \(preset.displayName)")
    }

    func applyScreenshotScenario(
        _ scenario: ScreenshotScenario,
        surface: ScreenshotSurface = .documentation
    ) {
        applySimulatorQAScenario(scenario.simulatorPreset)
        activeScreenshotScenario = scenario
        latestReportSource = surface.isAppStoreMarketing ? .deviceAnalysis : .sample
        microphonePermissionState = .granted
        morningCheckIn = ScreenshotScenarioFactory.makeScreenshotMorningCheckIn(sessionId: latestSession.id)

        if scenario == .sleepRecording {
            applyScreenshotRecordingState()
        }

        audioCaptureMessage = surface.isAppStoreMarketing
            ? "App Store 스크린샷 표면 ‘\(scenario.displayName)’를 적용했습니다. 실제 오디오 파일은 생성하지 않습니다."
            : "스크린샷 프리셋 ‘\(scenario.displayName)’를 적용했습니다. 예시 데이터만 사용하며 실제 오디오 파일은 생성하지 않습니다."
        eventAudioStorageMessage = surface.isAppStoreMarketing
            ? "App Store 스크린샷 저장소 상태입니다. 실제 파일은 생성하지 않습니다."
            : "스크린샷 프리셋 예시 저장소 상태입니다. 실제 파일은 생성하지 않습니다."
        recordDebugLifecycleEvent("screenshot scenario applied: \(scenario.displayName)")
    }

    func clearSimulatorQAScenario() {
        activeSimulatorQAScenario = nil
        activeScreenshotScenario = nil
        simulatorQAStorageStatsOverride = nil
        isEventAudioSampleStorageEnabled = userSettings.isEventAudioSampleStorageEnabled
        loadLatestStoredReportOrSample(message: "Simulator QA 시나리오를 해제했습니다.")
        refreshEventAudioStorageStats()
    }
    #endif

    func startSleepSession() {
        guard activeSession == nil, !audioCaptureState.isPreparing, !isFinalizingSleepSession else { return }

        #if DEBUG
        activeSimulatorQAScenario = nil
        activeScreenshotScenario = nil
        simulatorQAStorageStatsOverride = nil
        isEventAudioSampleStorageEnabled = userSettings.isEventAudioSampleStorageEnabled
        #endif

        audioCaptureMessage = nil
        isFinalizingSleepSession = false
        sleepRecordingPhase = .recording
        latestAudioLevel = 0
        detectedEventCandidateCount = 0
        capturedAudioChunkCount = 0
        latestDetectedEventText = "아직 없음"
        latestDetectedEventAt = nil
        audioCaptureMetrics = AudioCaptureMetrics()
        latestDetectorDiagnostics = nil
        audioProcessingTask?.cancel()
        audioProcessingTask = nil
        audioProcessingPipeline = nil
        audioProcessingGeneration &+= 1
        lastAudioProcessingUIUpdateAt = nil
        eventAudioSnippetTasks.forEach { $0.cancel() }
        eventAudioSnippetTasks.removeAll(keepingCapacity: true)
        savedAudioSnippets.removeAll(keepingCapacity: true)
        scheduledSnippetKeys.removeAll(keepingCapacity: true)
        latestSnippetStartedAtByType.removeAll(keepingCapacity: true)
        recentAudioBuffer.removeAll()
        captureStopSafetyTask?.cancel()
        captureStopSafetyTask = nil

        Task {
            await startAudioCaptureAndCreateSession()
        }
    }

    func endSleepSession() {
        let stopTappedAt = Date()
        audioCaptureMetrics.recordStopButtonTapped(at: stopTappedAt)
        recordDebugLifecycleEvent("stop button tapped")

        guard let session = activeSession else {
            if audioCaptureService.isCapturing || audioCaptureService.state == .stopping {
                audioCaptureService.forceStopCapture(reason: "stop requested with no active session")
            } else {
                audioCaptureService.stopCapture()
            }
            audioCaptureMetrics.mergeStopDiagnostics(from: audioCaptureService.metrics)
            audioCaptureState = audioCaptureService.state
            return
        }

        guard !isFinalizingSleepSession else {
            if audioCaptureService.isCapturing || audioCaptureService.state == .stopping {
                audioCaptureService.forceStopCapture(reason: "duplicate stop request while finalizing")
            } else {
                audioCaptureService.stopCapture()
            }
            audioCaptureMetrics.mergeStopDiagnostics(from: audioCaptureService.metrics)
            audioCaptureState = audioCaptureService.state
            recordDebugLifecycleEvent("duplicate stop request ignored")
            return
        }

        isFinalizingSleepSession = true
        sleepRecordingPhase = .stoppingCapture
        audioCaptureMessage = "녹음 중단 요청을 처리하고 있습니다."
        audioCaptureMetrics.recordStopRequested(at: stopTappedAt)
        audioCaptureService.stopCapture()
        audioCaptureMetrics.mergeStopDiagnostics(from: audioCaptureService.metrics)
        recordDebugLifecycleEvent("audio capture stop requested")
        audioCaptureState = audioCaptureService.state
        sleepRecordingPhase = audioCaptureState == .stopped ? .captureStoppedFinalizing : .stoppingCapture
        audioCaptureMessage = "녹음은 중단되었습니다. 리포트를 정리하는 중입니다."
        if audioCaptureState == .stopped {
            recordDebugLifecycleEvent("audio capture stopped before report finalization")
        }
        scheduleCaptureStopSafetyCheck(sessionId: session.id)

        let endedAt = Date()
        audioCaptureMetrics.stop(at: endedAt)
        let completedSession = makeCompletedSession(from: session, endedAt: endedAt)
        let processor = audioProcessingPipeline
        let pendingProcessingTask = audioProcessingTask
        let replayAnalyzer = sleepAnalyzer
        let replayThresholds = currentDetectorThresholdSnapshot
        let recentChunksForReplay = recentAudioBuffer.snapshot()

        cancelPendingEventAudioSnippetTasks()
        audioCaptureMetrics.recordAnalyzerFinalizeStarted(at: Date())
        let stopMetrics = audioCaptureMetrics

        #if DEBUG
        let debugPreview = saveDebugAudioPreviewIfAllowed(sessionId: completedSession.id)
        #else
        let debugPreview: EventAudioSnippet? = nil
        #endif

        sleepFinalizationTask?.cancel()
        sleepFinalizationTask = Task { [weak self] in
            await pendingProcessingTask?.value
            let recentReplaySummary = recentChunksForReplay.isEmpty
                ? nil
                : replayAnalyzer.makeReplayDetectionSummary(
                    label: "recent-audio-debug-preview",
                    chunks: recentChunksForReplay,
                    thresholdsSnapshot: replayThresholds
                )

            let result: SleepAudioProcessingFinalizationResult
            if let processor {
                result = await processor.finalize(
                    endedAt: endedAt,
                    stopMetrics: stopMetrics
                )
            } else {
                let smoothingDiagnostics = DetectionSmoothingDiagnostics()
                result = SleepAudioProcessingFinalizationResult(
                    metrics: stopMetrics,
                    allOutputs: [],
                    smoothedOutputs: [],
                    smoothingDiagnostics: smoothingDiagnostics,
                    sequenceResult: SuspectedBreathingPauseSequenceResult()
                )
            }

            await self?.completeSleepSessionFinalization(
                completedSession: completedSession,
                finalizationResult: result,
                processor: processor,
                recentReplaySummary: recentReplaySummary,
                debugPreview: debugPreview
            )
        }
    }

    private func completeSleepSessionFinalization(
        completedSession: SleepSession,
        finalizationResult: SleepAudioProcessingFinalizationResult,
        processor: SleepAudioProcessingPipeline?,
        recentReplaySummary: ReplayDetectionSummary?,
        debugPreview: EventAudioSnippet?
    ) async {
        guard activeSession?.id == completedSession.id else {
            isFinalizingSleepSession = false
            sleepRecordingPhase = .reportReady
            return
        }

        captureStopSafetyTask?.cancel()
        captureStopSafetyTask = nil
        audioCaptureMetrics = finalizationResult.metrics
        audioCaptureMetrics.mergeStopDiagnostics(from: audioCaptureService.metrics)
        saveMissingEventAudioSnippets(sessionId: completedSession.id, outputs: finalizationResult.smoothedOutputs)
        let events = attachAudioSnippets(
            to: DetectorOutputMapper.makeEvents(
                from: finalizationResult.smoothedOutputs,
                sessionId: completedSession.id
            )
        )
        audioCaptureMetrics.recordReportGenerationStarted(at: Date())
        var report = SleepScoreCalculator().makeReport(
            session: completedSession,
            events: events,
            captureMetrics: audioCaptureMetrics
        )
        audioCaptureMetrics.recordReportGenerationFinished(at: Date())
        var diagnostics = await processor?.finalizeDiagnostics(
            endedAt: completedSession.endedAt ?? Date(),
            finalEvents: events,
            finalMetrics: audioCaptureMetrics
        )
        attachRecentReplaySummary(
            recentReplaySummary,
            to: &diagnostics,
            finalEventCount: events.count
        )
        report.detectorDiagnostics = diagnostics

        latestSession = completedSession
        latestEvents = events
        latestReport = report
        latestDetectorDiagnostics = diagnostics
        latestReportSource = .deviceAnalysis
        morningCheckIn = MorningCheckIn(sessionId: completedSession.id)
        activeSession = nil
        isFinalizingSleepSession = false
        sleepRecordingPhase = .reportReady
        audioProcessingPipeline = nil
        audioProcessingTask = nil

        let chunkMessage = capturedAudioChunkCount == 0
            ? "캡처된 오디오 청크가 없어 이벤트 없는 분석 리포트를 만들었습니다."
            : "\(capturedAudioChunkCount)개 오디오 청크에서 \(events.count)개 이벤트 후보와 \(events.filter { $0.audioSnippetFileName != nil }.count)개 짧은 오디오 샘플을 정리했습니다."
        let debugPreviewMessage = debugPreview.map {
            " DEBUG 미리듣기 샘플 \(SleepFormatters.compactDurationString($0.duration))을 저장했습니다."
        } ?? ""
        audioCaptureMessage = chunkMessage + debugPreviewMessage

        repository.save(session: completedSession, events: events, report: report)
        refreshRecentReports()
        refreshEventAudioStorageStats()
        recordDebugLifecycleEvent("sleep report finalized")
    }

    private func attachRecentReplaySummary(
        _ replaySummary: ReplayDetectionSummary?,
        to diagnostics: inout DetectorDiagnostics?,
        finalEventCount: Int
    ) {
        guard let replaySummary else { return }
        diagnostics?.recentAudioReplaySummary = replaySummary
        diagnostics?.notes.append("Recent audio replay summary: \(replaySummary.briefText)")

        if replaySummary.finalEventCount > 0, finalEventCount == 0 {
            diagnostics?.notes.append("Recent audio replay produced final events while the full session report had zero events; check live pipeline, smoothing window, and report aggregation.")
        } else if replaySummary.rawCandidateCount == 0, replaySummary.chunkCount > 0 {
            diagnostics?.notes.append("Recent audio replay produced no raw candidates; check input level, feature scale, and raw detector gates.")
        } else if replaySummary.rawCandidateCount > 0, replaySummary.finalEventCount == 0 {
            diagnostics?.notes.append("Recent audio replay produced raw candidates but no final events; check smoothing and confidence gates.")
        }
    }

    func saveMorningCheckIn(_ checkIn: MorningCheckIn) {
        morningCheckIn = checkIn
        repository.save(checkIn: checkIn)
    }

    func saveEveningCheckIn(_ checkIn: EveningCheckIn) {
        eveningCheckInRepository.save(checkIn)
        eveningCheckIns = eveningCheckInRepository.all()
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
        try? eventFeedbackStore.deleteFeedback(for: eventIds)
        repository.deleteSession(id: id)
        loadLatestStoredReportOrSample(message: "선택한 수면 데이터가 삭제되었습니다.")
        refreshEventFeedbackCount()
        refreshEventAudioStorageStats()
    }

    func deleteAllSleepData() {
        repository.deleteAllSleepData()
        try? eventFeedbackStore.deleteAllFeedback()
        try? eventAudioSnippetStore.deleteAllSnippets()
        loadLatestStoredReportOrSample(message: "로컬 수면 데이터가 모두 삭제되었습니다.")
        refreshEventFeedbackCount()
        refreshEventAudioStorageStats()
    }

    func deleteAllEventFeedback() {
        try? eventFeedbackStore.deleteAllFeedback()
        refreshEventFeedbackCount()
        eventFeedbackMessage = "이벤트 피드백을 모두 삭제했습니다. 수면 리포트와 이벤트 오디오 샘플은 유지됩니다."
    }

    func deleteAllEventAudioSnippets() {
        #if DEBUG
        if simulatorQAStorageStatsOverride != nil {
            simulatorQAStorageStatsOverride = .empty
            eventAudioStorageStats = .empty
        }
        #endif

        try? eventAudioSnippetStore.deleteAllSnippets()
        latestEvents = latestEvents.map { event in
            var updatedEvent = event
            updatedEvent.audioSnippetFileName = nil
            updatedEvent.audioSnippetDuration = nil
            return updatedEvent
        }
        latestReport.savedAudioDuration = 0
        latestReport.detectorDiagnostics = latestDetectorDiagnostics
        if latestReportSource == .deviceAnalysis {
            repository.save(session: latestSession, events: latestEvents, report: latestReport)
            refreshRecentReports()
        }
        audioCaptureMessage = "저장된 이벤트 오디오 샘플을 삭제했습니다."
        eventAudioStorageMessage = "저장된 이벤트 오디오 샘플을 모두 삭제했습니다."
        refreshEventAudioStorageStats()
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
        latestReport.detectorDiagnostics = latestDetectorDiagnostics

        if latestReportSource == .deviceAnalysis {
            repository.save(session: latestSession, events: latestEvents, report: latestReport)
            refreshRecentReports()
        }
        audioCaptureMessage = "선택한 이벤트 오디오 샘플을 삭제했습니다."
        eventAudioStorageMessage = "선택한 이벤트 오디오 샘플을 삭제했습니다."
        refreshEventAudioStorageStats()
    }

    func refreshEventAudioStorageStats() {
        #if DEBUG
        if let simulatorQAStorageStatsOverride {
            eventAudioStorageStats = simulatorQAStorageStatsOverride
            return
        }
        #endif
        eventAudioStorageStats = eventAudioSnippetStore.storageStats(linkedFileNames: linkedAudioSnippetFileNames())
    }

    func refreshEventFeedbackCount() {
        eventFeedbackCount = eventFeedbackStore.feedbackCount()
    }

    func cleanupOrphanEventAudioSamples() {
        #if DEBUG
        if var overrideStats = simulatorQAStorageStatsOverride {
            let deletedFileCount = overrideStats.orphanSampleCount
            let deletedBytes = overrideStats.orphanBytes
            overrideStats.sampleCount = max(0, overrideStats.sampleCount - overrideStats.orphanSampleCount)
            overrideStats.totalBytes = max(0, overrideStats.totalBytes - overrideStats.orphanBytes)
            overrideStats.totalDurationSeconds = max(0, overrideStats.totalDurationSeconds - overrideStats.orphanDurationSeconds)
            overrideStats.orphanSampleCount = 0
            overrideStats.orphanBytes = 0
            overrideStats.orphanDurationSeconds = 0
            simulatorQAStorageStatsOverride = overrideStats
            eventAudioStorageStats = overrideStats
            eventAudioStorageMessage = deletedFileCount > 0
                ? "Simulator QA: 연결되지 않은 샘플 \(deletedFileCount)개(\(EventAudioStorageStats.formatBytes(deletedBytes)))를 정리한 상태로 표시합니다."
                : "Simulator QA: 정리할 연결되지 않은 샘플이 없습니다."
            return
        }
        #endif

        let result = eventAudioSnippetStore.cleanupOrphanSnippets(linkedFileNames: linkedAudioSnippetFileNames())
        refreshEventAudioStorageStats()

        if result.failedFileCount > 0 {
            eventAudioStorageMessage = "연결되지 않은 샘플 \(result.deletedFileCount)개(\(result.formattedDeletedSize))를 정리했고, \(result.failedFileCount)개는 삭제하지 못했습니다."
        } else if result.deletedFileCount > 0 {
            eventAudioStorageMessage = "연결되지 않은 샘플 \(result.deletedFileCount)개(\(result.formattedDeletedSize))를 정리했습니다."
        } else {
            eventAudioStorageMessage = "정리할 연결되지 않은 이벤트 오디오 샘플이 없습니다."
        }
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
            let detectorModelVersion = sleepAnalyzer.isModelInstalled
                ? "\(CoreMLDetectorConfiguration.default.modelVersion) hybrid"
                : "\(CoreMLDetectorConfiguration.default.modelVersion) unavailable, rule fallback"
            let session = SleepSession(
                startedAt: startedAt,
                estimatedSleepStart: nil,
                estimatedWakeTime: nil,
                measurementDuration: 0,
                estimatedSleepDuration: 0,
                devicePlacement: .bedside,
                ambientNoiseBaseline: nil,
                appVersion: "1.0",
                modelVersion: detectorModelVersion
            )
            activeSession = session
            audioProcessingPipeline = SleepAudioProcessingPipeline(
                sessionId: session.id,
                startedAt: startedAt,
                analyzer: sleepAnalyzer,
                detectorBackend: sleepAnalyzer.detectorBackend.displayName,
                modelInstalled: sleepAnalyzer.isModelInstalled,
                thresholdsSnapshot: currentDetectorThresholdSnapshot,
                tuningProfile: detectorTuningProfile.displayName,
                eventAudioSampleStorageEnabled: isEventAudioSampleStorageEnabled
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

    private func enqueueAudioChunk(_ chunk: AudioChunk) {
        if isFinalizingSleepSession || audioCaptureMetrics.stopRequestedAt != nil {
            audioCaptureMetrics.recordReceivedAfterStopRequest(chunk: chunk)
            audioCaptureService.forceStopCapture(reason: "audio chunk delivered to app after stop request")
            audioCaptureMetrics.mergeStopDiagnostics(from: audioCaptureService.metrics)
            audioCaptureState = audioCaptureService.state
            recordDebugLifecycleEvent("post-stop audio chunk ignored")
            return
        }

        recentAudioBuffer.append(chunk)

        guard let processor = audioProcessingPipeline else { return }

        let generation = audioProcessingGeneration
        let previousTask = audioProcessingTask
        audioProcessingTask = Task.detached(priority: .utility) { [weak self] in
            await previousTask?.value
            guard !Task.isCancelled else { return }

            let snapshot = await processor.process(chunk: chunk)
            await MainActor.run { [weak self] in
                self?.applyAudioProcessingSnapshot(snapshot, generation: generation)
            }
        }
    }

    private func applyAudioProcessingSnapshot(
        _ snapshot: SleepAudioProcessingSnapshot,
        generation: UInt64
    ) {
        guard generation == audioProcessingGeneration,
              activeSession != nil,
              !isFinalizingSleepSession else {
            return
        }

        for output in snapshot.outputsForSnippetCapture {
            scheduleEventAudioSnippetCapture(sessionId: activeSession?.id, output: output)
        }

        let now = Date()
        let shouldRefreshUI = lastAudioProcessingUIUpdateAt == nil ||
            now.timeIntervalSince(lastAudioProcessingUIUpdateAt ?? now) >= audioProcessingUIRefreshInterval
        guard shouldRefreshUI else { return }

        audioCaptureMetrics = snapshot.metrics
        capturedAudioChunkCount = snapshot.capturedAudioChunkCount
        detectedEventCandidateCount = snapshot.detectedEventCandidateCount
        latestAudioLevel = snapshot.latestAudioLevel
        if let latestDetectedEventText = snapshot.latestDetectedEventText {
            self.latestDetectedEventText = latestDetectedEventText
            latestDetectedEventAt = snapshot.latestDetectedEventAt
        }
        audioCaptureState = audioCaptureService.state
        lastAudioProcessingUIUpdateAt = now
    }

    private func scheduleCaptureStopSafetyCheck(sessionId: UUID) {
        captureStopSafetyTask?.cancel()
        captureStopSafetyTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run { [weak self] in
                guard let self else { return }
                guard self.activeSession?.id == sessionId || self.latestSession.id == sessionId else { return }

                self.audioCaptureMetrics.mergeStopDiagnostics(from: self.audioCaptureService.metrics)
                let needsForceStop = self.audioCaptureService.state != .stopped
                    || self.audioCaptureService.isCapturing
                    || self.audioCaptureMetrics.chunksReceivedAfterStopRequest > 0

                guard needsForceStop else { return }

                self.audioCaptureService.forceStopCapture(reason: "app stop timeout safety check")
                self.audioCaptureMetrics.mergeStopDiagnostics(from: self.audioCaptureService.metrics)
                self.audioCaptureState = self.audioCaptureService.state
                self.recordDebugLifecycleEvent("capture force stop safety check")
            }
        }
    }

    private func handleAudioCaptureStateChange(_ state: AudioCaptureState) {
        audioCaptureState = state

        if isFinalizingSleepSession, state == .stopped {
            sleepRecordingPhase = .captureStoppedFinalizing
        }

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

    #if DEBUG
    private func applyScreenshotRecordingState() {
        var session = latestSession
        session.endedAt = nil
        session.measurementDuration = 2 * 60 * 60 + 18 * 60

        let now = session.startedAt.addingTimeInterval(session.measurementDuration)
        let receivedAudioSeconds = session.measurementDuration * 0.97
        let analyzedAudioSeconds = session.measurementDuration * 0.965

        activeSession = session
        latestSession = session
        audioCaptureState = .capturing(startedAt: session.startedAt)
        audioCaptureMetrics = AudioCaptureMetrics(
            captureStartedAt: session.startedAt,
            sessionElapsedSeconds: session.measurementDuration,
            captureActiveSeconds: session.measurementDuration,
            receivedAudioSeconds: receivedAudioSeconds,
            analyzedAudioSeconds: analyzedAudioSeconds,
            receivedChunkCount: Int(receivedAudioSeconds),
            analyzedChunkCount: Int(analyzedAudioSeconds),
            totalReceivedFrameCount: Int64(receivedAudioSeconds * 16_000),
            totalAnalyzedFrameCount: Int64(analyzedAudioSeconds * 16_000),
            sampleRate: 16_000,
            lastChunkReceivedAt: now.addingTimeInterval(-4),
            lastChunkAnalyzedAt: now.addingTimeInterval(-6),
            interruptionCount: 0,
            longestChunkGapSeconds: 4,
            currentChunkGapSeconds: 4,
            audioCoverageRatio: 0.97
        )
        latestAudioLevel = 0.08
        capturedAudioChunkCount = 128
        detectedEventCandidateCount = 6
        latestDetectedEventText = "코골기 후보"
        latestDetectedEventAt = now.addingTimeInterval(-12 * 60)
    }
    #endif

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

    private func linkedAudioSnippetFileNames() -> Set<String> {
        var fileNames = Set<String>()

        for event in latestEvents {
            if let fileName = event.audioSnippetFileName, !fileName.isEmpty {
                fileNames.insert(fileName)
            }
        }

        for session in repository.sessions() {
            for event in repository.events(for: session.id) {
                if let fileName = event.audioSnippetFileName, !fileName.isEmpty {
                    fileNames.insert(fileName)
                }
            }
        }

        return fileNames
    }

    private func cancelPendingEventAudioSnippetTasks() {
        eventAudioSnippetTasks.forEach { $0.cancel() }
        eventAudioSnippetTasks.removeAll(keepingCapacity: true)
        scheduledSnippetKeys.removeAll(keepingCapacity: true)
        latestSnippetStartedAtByType.removeAll(keepingCapacity: true)
    }

    private func loadLatestStoredReportOrSample(message: String? = nil) {
        refreshRecentReports()

        if let report = repository.latestReport(),
           let session = repository.session(for: report.sessionId) {
            latestSession = session
            latestEvents = repository.events(for: report.sessionId)
            latestReport = report
            latestDetectorDiagnostics = report.detectorDiagnostics
            latestReportSource = .deviceAnalysis
            morningCheckIn = repository.checkIn(for: report.sessionId) ?? MorningCheckIn(sessionId: report.sessionId)
        } else {
            let bundle = MockSleepDataFactory.latestBundle()
            latestSession = bundle.0
            latestEvents = bundle.1
            latestReport = bundle.2
            latestDetectorDiagnostics = bundle.2.detectorDiagnostics
            latestReportSource = .sample
            morningCheckIn = bundle.3
            recentReports = []
        }

        audioCaptureMessage = message
    }

    private func scheduleEventAudioSnippetCapture(sessionId: UUID?, output: DetectorOutput) {
        guard let sessionId,
              EventAudioSampleStorageRules.shouldAttemptStorage(
                isEnabled: isEventAudioSampleStorageEnabled,
                eventType: output.eventType,
                duration: output.duration,
                confidence: output.confidence
              ) else {
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
                guard let self, self.isEventAudioSampleStorageEnabled else { return }
                self.saveEventAudioSnippet(sessionId: sessionId, output: output)
            }
        }
        eventAudioSnippetTasks.append(task)
    }

    private func saveMissingEventAudioSnippets(sessionId: UUID, outputs: [DetectorOutput]) {
        guard isEventAudioSampleStorageEnabled else { return }

        for output in outputs where output.eventType != .unknown && output.duration > 0 {
            guard savedAudioSnippets.count < EventAudioSnippetPolicy.default.maxSnippetsPerSession else { return }
            guard !savedAudioSnippets.contains(where: { snippetMatches($0, output: output) }) else { continue }
            saveEventAudioSnippet(sessionId: sessionId, output: output)
        }
    }

    private func saveEventAudioSnippet(sessionId: UUID, output: DetectorOutput) {
        guard isEventAudioSampleStorageEnabled else { return }
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

    #if DEBUG
    private func saveDebugAudioPreviewIfAllowed(sessionId: UUID) -> EventAudioSnippet? {
        guard isEventAudioSampleStorageEnabled else {
            recordDebugLifecycleEvent("debug audio preview skipped: sample storage disabled")
            return nil
        }

        do {
            let preview = try eventAudioSnippetStore.saveDebugPreview(
                sessionId: sessionId,
                chunks: recentAudioBuffer.snapshot()
            )
            recordDebugLifecycleEvent("debug audio preview saved: \(preview.fileName)")
            return preview
        } catch {
            recordDebugLifecycleEvent("debug audio preview skipped: \(error.localizedDescription)")
            return nil
        }
    }
    #endif

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
