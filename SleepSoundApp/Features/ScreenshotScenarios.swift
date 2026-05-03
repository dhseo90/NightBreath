import Foundation

#if DEBUG
enum ScreenshotScenario: String, CaseIterable, Identifiable, Sendable {
  case homeDashboard
  case sleepStart
  case sleepRecording
  case sleepReport
  case eventTimeline
  case morningBrief
  case dailyRhythmReport
  case dailyHealthCard
  case privacySettings
  case healthDashboard
  case fitdaysImport
  case fitdaysImportResult
  case healthMetricsOverview
  case healthCalendar
  case dailyMeasurementDetail
  case metricDetail
  case importError
  case localOnlyMetric
  case zeroEventReport
  case lowCoverageReport
  case eventAudioStorageOff
  case debugTools

  var id: String { rawValue }

  static func launchArgumentScenario(processInfo: ProcessInfo = .processInfo) -> ScreenshotScenario? {
    let arguments = processInfo.arguments
    let environment = processInfo.environment

    if let value = environment["NIGHTBREATH_SCREENSHOT_SCENARIO"],
       let scenario = ScreenshotScenario(value: value) {
      return scenario
    }

    for (index, argument) in arguments.enumerated() {
      if argument == "--nightbreath-screenshot-scenario",
         arguments.indices.contains(index + 1),
         let scenario = ScreenshotScenario(value: arguments[index + 1]) {
        return scenario
      }

      if argument.hasPrefix("--nightbreath-screenshot-scenario=") {
        let value = String(argument.dropFirst("--nightbreath-screenshot-scenario=".count))
        if let scenario = ScreenshotScenario(value: value) {
          return scenario
        }
      }
    }

    return nil
  }

  private init?(value: String) {
    let normalized = value
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: "-", with: "")
      .replacingOccurrences(of: "_", with: "")
      .lowercased()

    if let scenario = Self.allCases.first(where: {
      $0.rawValue.lowercased() == normalized || $0.displayName.lowercased() == normalized
    }) {
      self = scenario
      return
    }

    return nil
  }

  var displayName: String {
    switch self {
    case .homeDashboard:
      "ScreenshotHomeScenario"
    case .sleepStart:
      "ScreenshotSleepStartScenario"
    case .sleepRecording:
      "ScreenshotRecordingScenario"
    case .sleepReport:
      "ScreenshotSleepReportScenario"
    case .eventTimeline:
      "ScreenshotTimelineScenario"
    case .morningBrief:
      "ScreenshotMorningBriefScenario"
    case .dailyRhythmReport:
      "ScreenshotDailyRhythmScenario"
    case .dailyHealthCard:
      "ScreenshotDailyHealthCardScenario"
    case .privacySettings:
      "ScreenshotPrivacyScenario"
    case .healthDashboard:
      "ScreenshotHealthDashboardScenario"
    case .fitdaysImport:
      "ScreenshotFitdaysImportScenario"
    case .fitdaysImportResult:
      "ScreenshotFitdaysImportResultScenario"
    case .healthMetricsOverview:
      "ScreenshotHealthMetricsOverviewScenario"
    case .healthCalendar:
      "ScreenshotHealthCalendarScenario"
    case .dailyMeasurementDetail:
      "ScreenshotDailyMeasurementDetailScenario"
    case .metricDetail:
      "ScreenshotMetricDetailScenario"
    case .importError:
      "ScreenshotImportErrorScenario"
    case .localOnlyMetric:
      "ScreenshotLocalOnlyMetricScenario"
    case .zeroEventReport:
      "ScreenshotZeroEventScenario"
    case .lowCoverageReport:
      "ScreenshotLowCoverageScenario"
    case .eventAudioStorageOff:
      "ScreenshotEventAudioStorageOffScenario"
    case .debugTools:
      "ScreenshotDebugScenario"
    }
  }

  var headlineCopy: String {
    switch self {
    case .homeDashboard:
      "수면 중 소리 기반 지표를 한눈에"
    case .sleepStart:
      "잠들기 전 준비를 차분하게"
    case .sleepRecording:
      "iPhone 안에서 조용히 분석"
    case .sleepReport:
      "아침에 읽기 쉬운 수면 소리 리포트"
    case .eventTimeline:
      "코골기와 환경 소음 흐름 확인"
    case .morningBrief:
      "아침에 시작하는 하루 건강 리듬"
    case .dailyRhythmReport:
      "오늘의 리듬 점수를 참고용으로"
    case .dailyHealthCard:
      "하루 리듬을 카드 한 장으로"
    case .privacySettings:
      "전체 밤 오디오는 저장하지 않습니다"
    case .healthDashboard:
      "혈압/체성분 대시보드 준비"
    case .fitdaysImport:
      "Fitdays CSV를 로컬에서 가져오기"
    case .fitdaysImportResult:
      "Fitdays CSV import 결과 확인"
    case .healthMetricsOverview:
      "모든 건강 지표를 source와 함께"
    case .healthCalendar:
      "월별로 보는 수면과 건강 기록"
    case .dailyMeasurementDetail:
      "하루의 기록을 category별로"
    case .metricDetail:
      "지표 하나의 흐름을 자세히"
    case .importError:
      "가져오기 오류도 차분하게 안내"
    case .localOnlyMetric:
      "Fitdays local-only 지표 구분"
    case .zeroEventReport:
      "이벤트가 적은 밤도 측정 맥락과 함께"
    case .lowCoverageReport:
      "측정 품질이 낮은 날은 제한적으로"
    case .eventAudioStorageOff:
      "이벤트 샘플 저장은 사용자가 선택"
    case .debugTools:
      "DEBUG에서만 확인하는 검증 화면"
    }
  }

  var captureNote: String {
    switch self {
    case .homeDashboard:
      "최근 리포트, 수면 소리 점수, 측정 품질, 온디바이스 안내가 보이게 캡처합니다."
    case .sleepStart:
      "수면 시작 CTA, 마이크 권한, 기기 배치, 이벤트 오디오 샘플 저장 상태가 보이게 캡처합니다."
    case .sleepRecording:
      "녹음 중 상태, 실제 오디오 수신 시간, 커버리지, 수면 종료 버튼이 보이게 캡처합니다."
    case .sleepReport:
      "점수, 주요 이벤트, detector diagnostics 요약, 진단 목적 아님 안내가 보이게 캡처합니다."
    case .eventTimeline:
      "이벤트 시간, 타입, duration, 오디오 샘플 상태가 보이게 캡처합니다."
    case .morningBrief:
      "수면 요약, 아침 컨디션, 예시 혈압/체성분, 데이터 품질이 보이게 캡처합니다."
    case .dailyRhythmReport:
      "오늘의 리듬 점수, component score, Daily Insight, 인과관계 아님 안내가 보이게 캡처합니다."
    case .dailyHealthCard:
      "카드 template, privacy level, 오늘의 리듬 카드 preview가 보이게 캡처합니다."
    case .privacySettings:
      "이벤트 샘플 opt-in, 저장 용량, 삭제 가능성, 서버 전송 없음 안내가 보이게 캡처합니다."
    case .healthDashboard:
      "HealthKit read-only 방향과 혈압/체성분/CrossMetric 진입이 보이게 캡처합니다."
    case .fitdaysImport:
      "파일 선택 CTA, 로컬 import 원칙, HealthKit write 없음 안내가 보이게 캡처합니다."
    case .fitdaysImportResult:
      "synthetic import 결과, 생성 샘플 수, 알 수 없는 column, 미리보기 목록이 보이게 캡처합니다."
    case .healthMetricsOverview:
      "HealthKit-backed 지표와 Fitdays local-only 지표, 기간 선택, category row가 보이게 캡처합니다."
    case .healthCalendar:
      "월 이동, 데이터 있는 날짜 dot, source/data quality 안내가 보이게 캡처합니다."
    case .dailyMeasurementDetail:
      "선택 날짜의 수면, 체크인, 혈압, 체성분, Fitdays 확장 지표 section이 보이게 캡처합니다."
    case .metricDetail:
      "체수분률 상세 화면의 기간 선택, source filter, 그래프, sample list가 보이게 캡처합니다."
    case .importError:
      "invalid CSV와 unknown column을 안내하는 import edge state를 캡처합니다."
    case .localOnlyMetric:
      "기초대사량 같은 Fitdays local-only 지표 설명과 sample list가 보이게 캡처합니다."
    case .zeroEventReport:
      "이벤트 0개 상태, zero-event 분석, 측정 품질 안내가 보이게 캡처합니다."
    case .lowCoverageReport:
      "낮은 오디오 커버리지, 제한 안내, 측정 품질 배지가 보이게 캡처합니다."
    case .eventAudioStorageOff:
      "이벤트 오디오 샘플 저장 꺼짐, 원본 전체 오디오 미저장 안내가 보이게 캡처합니다."
    case .debugTools:
      "Dataset Replay 또는 Detector Tuning 같은 DEBUG 전용 검증 화면임이 보이게 캡처합니다."
    }
  }

  var simulatorPreset: SimulatorQAScenarioPreset {
    switch self {
    case .homeDashboard, .sleepStart, .sleepReport, .eventTimeline, .morningBrief, .dailyRhythmReport, .dailyHealthCard,
         .healthMetricsOverview, .healthCalendar, .dailyMeasurementDetail, .metricDetail, .localOnlyMetric:
      .snoreHeavyNight
    case .sleepRecording, .privacySettings:
      .eventAudioStorageOnWithSamples
    case .healthDashboard, .fitdaysImport, .fitdaysImportResult, .importError:
      .quietNight
    case .zeroEventReport:
      .zeroEventButGoodAudioCoverage
    case .lowCoverageReport:
      .lowAudioCoverageNight
    case .eventAudioStorageOff:
      .eventAudioStorageOff
    case .debugTools:
      .zeroEventButGoodAudioCoverage
    }
  }

  var suggestedScreenshotPath: String {
    switch self {
    case .homeDashboard:
      "Docs/Screenshots/README/home_dashboard_light.png"
    case .sleepStart:
      "Docs/Screenshots/README/sleep_start_light.png"
    case .sleepRecording:
      "Docs/Screenshots/README/sleep_recording_dark.png"
    case .sleepReport:
      "Docs/Screenshots/README/sleep_report_light.png"
    case .eventTimeline:
      "Docs/Screenshots/README/sleep_timeline_light.png"
    case .morningBrief:
      "Docs/Screenshots/README/morning_brief_light.png"
    case .dailyRhythmReport:
      "Docs/Screenshots/README/daily_rhythm_report_light.png"
    case .dailyHealthCard:
      "Docs/Screenshots/README/daily_health_card_light.png"
    case .privacySettings:
      "Docs/Screenshots/README/privacy_settings_light.png"
    case .healthDashboard:
      "Docs/Screenshots/README/health_dashboard_light.png"
    case .fitdaysImport:
      "Docs/Screenshots/Health/fitdays_import_light.png"
    case .fitdaysImportResult:
      "Docs/Screenshots/Health/fitdays_import_result_light.png"
    case .healthMetricsOverview:
      "Docs/Screenshots/Health/health_metrics_overview_light.png"
    case .healthCalendar:
      "Docs/Screenshots/Health/health_calendar_light.png"
    case .dailyMeasurementDetail:
      "Docs/Screenshots/Health/daily_measurement_detail_light.png"
    case .metricDetail:
      "Docs/Screenshots/Health/metric_detail_body_water_light.png"
    case .importError:
      "Docs/Screenshots/Health/fitdays_import_error_light.png"
    case .localOnlyMetric:
      "Docs/Screenshots/Health/metric_detail_basal_metabolic_rate_light.png"
    case .zeroEventReport:
      "Docs/Screenshots/EdgeStates/zero_event_report_light.png"
    case .lowCoverageReport:
      "Docs/Screenshots/EdgeStates/low_coverage_report_light.png"
    case .eventAudioStorageOff:
      "Docs/Screenshots/EdgeStates/event_audio_storage_off_light.png"
    case .debugTools:
      "Docs/Screenshots/Debug/detector_tuning_light.png"
    }
  }
}

@MainActor
enum ScreenshotScenarioFactory {
  static func makeAppState(for scenario: ScreenshotScenario) -> AppState {
    let settings = ScreenshotUserSettings()
    settings.hasCompletedOnboarding = true
    settings.isEventAudioSampleStorageEnabled = scenario == .privacySettings || scenario == .sleepRecording

    let state = AppState(
      repository: InMemorySleepRepository(),
      audioSessionManager: PreviewAudioSessionManager(),
      audioCaptureService: MockAudioCaptureService(),
      userSettings: settings
    )

    state.applySimulatorQAScenario(scenario.simulatorPreset)
    state.microphonePermissionState = .granted
    state.morningCheckIn = makeScreenshotMorningCheckIn(sessionId: state.latestSession.id)

    if scenario == .sleepRecording {
      applyRecordingState(to: state)
    }

    return state
  }

  static func makeScreenshotMorningCheckIn(sessionId: UUID) -> MorningCheckIn {
    MorningCheckIn(
      sessionId: sessionId,
      refreshScore: 4,
      fatigueScore: 2,
      headache: false,
      dryMouth: true,
      soreThroat: false,
      rememberedAwakenings: 1,
      memo: "Simulator 예시 기록"
    )
  }

  static func makeScreenshotEveningCheckIn(referenceDate: Date = Date()) -> EveningCheckIn {
    EveningCheckIn(
      date: referenceDate,
      fatigueScore: 3,
      stressScore: 2,
      moodScore: 4,
      caffeine: true,
      lateMeal: false,
      exercise: true,
      nap: false,
      memo: "Simulator 예시 기록"
    )
  }

  static func makeScreenshotHealthSamples(referenceDate: Date = Date()) -> [UnifiedHealthMetricSample] {
    let calendar = Calendar.current
    let dayStart = calendar.startOfDay(for: referenceDate)
    let mockHealthSamples = MockHealthDataService.makeDefaultSamples(referenceDate: dayStart)
      .map { $0.unifiedSample(sourceType: .mock) }
    let batchId = "screenshot-fitdays-batch"

    let fitdaysSamples: [UnifiedHealthMetricSample] = [
      UnifiedHealthMetricSample(
        metricID: .bodyWaterPercentage,
        value: 56.8,
        unit: "%",
        measuredAt: dayStart.addingTimeInterval(7 * 60 * 60 + 40 * 60),
        sourceType: .fitdaysCSV,
        sourceName: "Fitdays CSV Import",
        importBatchId: batchId,
        notes: "Synthetic screenshot sample"
      ),
      UnifiedHealthMetricSample(
        metricID: .visceralFatPercentage,
        value: 9.2,
        unit: "%",
        measuredAt: dayStart.addingTimeInterval(7 * 60 * 60 + 40 * 60),
        sourceType: .fitdaysCSV,
        sourceName: "Fitdays CSV Import",
        importBatchId: batchId
      ),
      UnifiedHealthMetricSample(
        metricID: .skeletalMuscleMass,
        value: 31.2,
        unit: "kg",
        measuredAt: dayStart.addingTimeInterval(7 * 60 * 60 + 40 * 60),
        sourceType: .fitdaysCSV,
        sourceName: "Fitdays CSV Import",
        importBatchId: batchId
      ),
      UnifiedHealthMetricSample(
        metricID: .mineralMass,
        value: 3.1,
        unit: "kg",
        measuredAt: dayStart.addingTimeInterval(7 * 60 * 60 + 40 * 60),
        sourceType: .fitdaysCSV,
        sourceName: "Fitdays CSV Import",
        importBatchId: batchId
      ),
      UnifiedHealthMetricSample(
        metricID: .basalMetabolicRate,
        value: 1_520,
        unit: "kcal/day",
        measuredAt: dayStart.addingTimeInterval(7 * 60 * 60 + 40 * 60),
        sourceType: .fitdaysCSV,
        sourceName: "Fitdays CSV Import",
        importBatchId: batchId
      ),
      UnifiedHealthMetricSample(
        metricID: .proteinPercentage,
        value: 18.4,
        unit: "%",
        measuredAt: dayStart.addingTimeInterval(7 * 60 * 60 + 40 * 60),
        sourceType: .fitdaysCSV,
        sourceName: "Fitdays CSV Import",
        importBatchId: batchId
      ),
      UnifiedHealthMetricSample(
        metricID: .sleepSoundScore,
        value: 82,
        unit: "점",
        measuredAt: dayStart.addingTimeInterval(8 * 60 * 60),
        sourceType: .appComputed,
        sourceName: "밤숨 앱"
      ),
      UnifiedHealthMetricSample(
        metricID: .dailyRhythmScore,
        value: 78,
        unit: "점",
        measuredAt: dayStart.addingTimeInterval(20 * 60 * 60),
        sourceType: .appComputed,
        sourceName: "밤숨 앱"
      ),
      UnifiedHealthMetricSample(
        metricID: .audioCoverageRatio,
        value: 96,
        unit: "%",
        measuredAt: dayStart.addingTimeInterval(8 * 60 * 60),
        sourceType: .appComputed,
        sourceName: "밤숨 앱"
      ),
    ]

    return mockHealthSamples + fitdaysSamples
  }

  static func makeScreenshotFitdaysImportResult(referenceDate: Date = Date()) -> FitdaysImportResult {
    let fitdaysSamples = makeScreenshotHealthSamples(referenceDate: referenceDate)
      .filter { $0.sourceType == .fitdaysCSV }
    let batch = ImportBatch(
      sourceName: "Fitdays CSV Import",
      sourceType: .fitdaysCSV,
      importedAt: referenceDate,
      fileName: "synthetic_fitdays_preview.csv",
      rowCount: 4,
      sampleCount: fitdaysSamples.count,
      skippedRowCount: 1,
      errorCount: 1,
      notes: "Screenshot scenario synthetic import result"
    )

    return FitdaysImportResult(
      batch: batch,
      samples: fitdaysSamples,
      unknownColumns: ["Device Nickname"],
      rowErrors: [
        FitdaysImportRowError(rowNumber: 5, message: "측정시간 값을 해석하지 못했습니다."),
      ]
    )
  }

  static func makeScreenshotDailyMeasurementDetailData(
    appState: AppState,
    samples: [UnifiedHealthMetricSample]
  ) -> DailyMeasurementDetailData {
    HealthCalendarBuilder().detailData(
      for: appState.latestReport.generatedAt,
      samples: samples,
      sleepReports: [appState.latestReport],
      morningCheckIns: [appState.morningCheckIn],
      eveningCheckIns: [makeScreenshotEveningCheckIn(referenceDate: appState.latestReport.generatedAt)]
    )
  }

  private static func applyRecordingState(to state: AppState) {
    var session = state.latestSession
    session.endedAt = nil
    session.measurementDuration = 2 * 60 * 60 + 18 * 60

    let now = session.startedAt.addingTimeInterval(session.measurementDuration)
    let receivedAudioSeconds = session.measurementDuration * 0.97
    let analyzedAudioSeconds = session.measurementDuration * 0.965

    state.activeSession = session
    state.audioCaptureState = .capturing(startedAt: session.startedAt)
    state.audioCaptureMetrics = AudioCaptureMetrics(
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
    state.latestAudioLevel = 0.08
    state.capturedAudioChunkCount = 128
    state.detectedEventCandidateCount = 6
    state.latestDetectedEventText = "코골기 후보"
    state.latestDetectedEventAt = now.addingTimeInterval(-12 * 60)
    state.audioCaptureMessage = "Screenshot preset입니다. 실제 오디오 파일은 생성하지 않습니다."
  }
}

private final class ScreenshotUserSettings: UserSettingsProviding {
  var isEventAudioSampleStorageEnabled = false
  var hasCompletedOnboarding = true
}
#endif
