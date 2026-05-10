#if DEBUG
import SwiftUI

struct SimulatorScenarioView: View {
  @EnvironmentObject private var appState: AppState
  @State private var selectedPreset: SimulatorQAScenarioPreset = .quietNight
  @State private var selectedScreenshotScenario: ScreenshotScenario = .homeDashboard
  @State private var selectedScreenshotSurface: ScreenshotSurface = .documentation

  private var previewBundle: SimulatorQAScenarioBundle {
    SimulatorQAScenarioFactory.make(preset: selectedPreset)
  }

  private var ehmReferenceDate: Date {
    appState.latestReport.generatedAt
  }

  private var ehmPreviewSamples: [UnifiedHealthMetricSample] {
    ScreenshotScenarioFactory.makeScreenshotHealthSamples(referenceDate: ehmReferenceDate)
  }

  private var ehmPartialHealthKitSamples: [UnifiedHealthMetricSample] {
    let allowedMetrics: Set<HealthMetricType> = [
      .systolicBloodPressure,
      .diastolicBloodPressure,
      .stepCount,
      .activeEnergy,
    ]

    return MockHealthDataService.makeDefaultSamples(referenceDate: ehmReferenceDate)
      .filter { allowedMetrics.contains($0.metricType) }
      .map { $0.unifiedSample(sourceType: .healthKit) }
  }

  private var ehmFitdaysLocalOnlySamples: [UnifiedHealthMetricSample] {
    ehmPreviewSamples.filter { $0.sourceType == .fitdaysCSV }
  }

  private var ehmMixedSourceSamples: [UnifiedHealthMetricSample] {
    (
      ehmPartialHealthKitSamples
        + ehmFitdaysLocalOnlySamples
        + ehmPreviewSamples.filter { $0.sourceType == .appComputed }
    )
    .sortedByMeasuredAtAscending()
  }

  private var ehmDetailData: DailyMeasurementDetailData {
    ScreenshotScenarioFactory.makeScreenshotDailyMeasurementDetailData(
      appState: appState,
      samples: ehmMixedSourceSamples
    )
  }

  var body: some View {
    List {
      Section {
        VStack(alignment: .leading, spacing: NBSpacing.medium) {
          Label("Simulator E2E QA", systemImage: "iphone.gen3.radiowaves.left.and.right")
            .font(NBTypography.sectionTitle)
            .foregroundStyle(NBColor.audioTint)

          Text("실제 iPhone 녹음 없이 mock 수면 세션, 이벤트, 리포트, detector 분석, 이벤트 오디오 저장소 상태를 재현합니다.")
            .font(NBTypography.callout)
            .foregroundStyle(NBColor.secondaryText)
          NBStatusBadge("DEBUG 전용", kind: .debug)
        }
        .padding(.vertical, 6)
      }

      Section("Scenario Preset") {
        Picker("Preset", selection: $selectedPreset) {
          ForEach(SimulatorQAScenarioPreset.allCases) { preset in
            Text(preset.displayName)
              .tag(preset)
          }
        }

        VStack(alignment: .leading, spacing: 6) {
          Text(selectedPreset.koreanTitle)
            .font(.headline)
          Text(selectedPreset.qaFocus)
            .font(.callout)
            .foregroundStyle(NBColor.secondaryText)
        }
        .padding(.vertical, 4)

        Button {
          appState.applySimulatorQAScenario(selectedPreset)
        } label: {
          Label("시나리오 적용", systemImage: "checkmark.circle")
        }
        .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.audioTint))

        if let activePreset = appState.activeSimulatorQAScenario {
          NBStatusBadge("현재 적용됨: \(activePreset.displayName)", kind: .good, systemImage: "checkmark.seal")

          Button {
            appState.clearSimulatorQAScenario()
          } label: {
            Label("QA 시나리오 해제", systemImage: "arrow.uturn.backward")
          }
          .buttonStyle(.nbSecondary)
        }
      }

      Section("Screenshot Preset") {
        Picker("Screenshot", selection: $selectedScreenshotScenario) {
          ForEach(ScreenshotScenario.allCases) { scenario in
            Text(scenario.displayName)
              .tag(scenario)
          }
        }

        Picker("Surface", selection: $selectedScreenshotSurface) {
          ForEach(ScreenshotSurface.allCases) { surface in
            Text(surface.rawValue)
              .tag(surface)
          }
        }

        VStack(alignment: .leading, spacing: 6) {
          Text(selectedScreenshotScenario.headlineCopy)
            .font(.headline)
          Text(selectedScreenshotScenario.captureNote)
            .font(.callout)
            .foregroundStyle(NBColor.secondaryText)
          Text("권장 경로: \(selectedScreenshotScenario.suggestedScreenshotPath)")
            .font(.caption.monospaced())
            .foregroundStyle(NBColor.tertiaryText)
        }
        .padding(.vertical, 4)

        Button {
          appState.applyScreenshotScenario(selectedScreenshotScenario, surface: selectedScreenshotSurface)
        } label: {
          Label("스크린샷 프리셋 적용", systemImage: "camera.viewfinder")
        }
        .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.privacyTint))

        if let activeScenario = appState.activeScreenshotScenario {
          NBStatusBadge("현재 screenshot preset: \(activeScenario.displayName)", kind: .debug, systemImage: "camera")
        }

        NavigationLink {
          ScreenshotScenarioDestinationView(
            scenario: selectedScreenshotScenario,
            surface: selectedScreenshotSurface
          )
        } label: {
          Label("선택 화면 열기", systemImage: "rectangle.inset.filled")
        }

        Text("먼저 preset을 적용한 뒤 선택 화면을 열어 캡처합니다. 모든 상태는 예시 데이터 또는 simulator scenario 기반이며 실제 건강 데이터나 실제 오디오 파일을 사용하지 않습니다.")
          .font(.footnote)
          .foregroundStyle(NBColor.secondaryText)
      }

      Section("Privacy Snapshot") {
        NavigationLink {
          PrivacySnapshotCoverQAView()
        } label: {
          Label("앱 전환 보호 화면", systemImage: "lock.shield")
        }

        Text("앱이 inactive/background로 넘어갈 때 표시되는 보호 화면을 simulator에서 직접 확인합니다.")
          .font(.footnote)
          .foregroundStyle(NBColor.secondaryText)
      }

      Section("EHM 화면 상태") {
        NavigationLink {
          HealthDashboardView(
            service: DisabledHealthKitService(),
            unifiedSampleRepository: InMemoryUnifiedHealthMetricSampleRepository()
          )
        } label: {
          Label("HealthKit 사용 불가", systemImage: "exclamationmark.triangle")
        }

        NavigationLink {
          HealthMetricsOverviewView(
            samples: ehmFitdaysLocalOnlySamples,
            permissionState: .denied,
            isPreviewData: false
          )
        } label: {
          Label("권한 없음 + Fitdays 로컬 전용", systemImage: "lock.slash")
        }

        NavigationLink {
          HealthMetricsOverviewView(
            samples: ehmPartialHealthKitSamples,
            permissionState: .readRequestCompleted,
            isPreviewData: false
          )
        } label: {
          Label("일부 권한 허용", systemImage: "checkmark.seal")
        }

        NavigationLink {
          HealthMetricsOverviewView(
            samples: [],
            permissionState: .readRequestCompleted,
            isPreviewData: false
          )
        } label: {
          Label("데이터 없음", systemImage: "tray")
        }

        NavigationLink {
          HealthMetricsOverviewView(
            samples: ehmMixedSourceSamples,
            permissionState: .readRequestCompleted,
            isPreviewData: false
          )
        } label: {
          Label("출처 혼합", systemImage: "square.stack.3d.up")
        }

        NavigationLink {
          BloodPressureDashboardView(
            samples: ScreenshotScenarioFactory.makeScreenshotStandardHealthSamples(referenceDate: ehmReferenceDate),
            permissionState: .mockDataOnly,
            isPreviewData: true
          )
        } label: {
          Label("BloodPressure dashboard", systemImage: "heart")
        }

        NavigationLink {
          BodyCompositionDashboardView(
            samples: ScreenshotScenarioFactory.makeScreenshotStandardHealthSamples(referenceDate: ehmReferenceDate),
            permissionState: .mockDataOnly,
            isPreviewData: true
          )
        } label: {
          Label("BodyComposition dashboard", systemImage: "scalemass")
        }

        NavigationLink {
          CrossMetricDashboardView(
            reports: ScreenshotScenarioFactory.makeScreenshotCrossMetricReports(referenceDate: ehmReferenceDate),
            samples: ScreenshotScenarioFactory.makeScreenshotStandardHealthSamples(referenceDate: ehmReferenceDate),
            permissionState: .mockDataOnly,
            isPreviewData: true
          )
        } label: {
          Label("CrossMetric dashboard", systemImage: "chart.dots.scatter")
        }

        NavigationLink {
          HealthCalendarView(
            samples: ehmMixedSourceSamples,
            sleepReports: [appState.latestReport],
            morningCheckIns: [appState.morningCheckIn],
            eveningCheckIns: [ScreenshotScenarioFactory.makeScreenshotEveningCheckIn(referenceDate: ehmReferenceDate)],
            permissionState: .readRequestCompleted,
            isPreviewData: false,
            initialMonth: ehmReferenceDate
          )
        } label: {
          Label("HealthCalendar 출처 혼합", systemImage: "calendar")
        }

        NavigationLink {
          HealthCalendarView(
            samples: [],
            sleepReports: [],
            morningCheckIns: [],
            eveningCheckIns: [],
            permissionState: .readRequestCompleted,
            isPreviewData: false,
            initialMonth: ehmReferenceDate
          )
        } label: {
          Label("HealthCalendar 빈 날짜", systemImage: "calendar.badge.exclamationmark")
        }

        NavigationLink {
          DailyMeasurementDetailView(
            detailData: ehmDetailData,
            allSamples: ehmMixedSourceSamples
          )
        } label: {
          Label("DailyMeasurementDetail", systemImage: "calendar.badge.clock")
        }

        NavigationLink {
          MetricDetailView(
            metricID: .systolicBloodPressure,
            samples: ehmMixedSourceSamples,
            selectedPeriod: .all
          )
        } label: {
          Label("MetricDetail HealthKit 기반", systemImage: "heart.text.square")
        }

        NavigationLink {
          MetricDetailView(
            metricID: .bodyWaterPercentage,
            samples: ehmMixedSourceSamples,
            selectedPeriod: .all
          )
        } label: {
          Label("MetricDetail 로컬 전용", systemImage: "chart.xyaxis.line")
        }

        NavigationLink {
          HealthMetricsOverviewView(
            samples: [],
            permissionState: .denied,
            isPreviewData: false
          )
        } label: {
          Label("Health permission empty", systemImage: "lock.slash")
        }

        NavigationLink {
          MetricDetailView(
            metricID: .bodyWaterPercentage,
            samples: [],
            selectedPeriod: .thirtyDays
          )
        } label: {
          Label("MetricDetail empty", systemImage: "tray")
        }

        NavigationLink {
          CrossMetricDashboardView(
            reports: Array(ScreenshotScenarioFactory.makeScreenshotCrossMetricReports(referenceDate: ehmReferenceDate).prefix(2)),
            samples: ScreenshotScenarioFactory.makeScreenshotStandardHealthSamples(referenceDate: ehmReferenceDate),
            permissionState: .mockDataOnly,
            isPreviewData: true
          )
        } label: {
          Label("CrossMetric insufficient", systemImage: "chart.dots.scatter")
        }

        Text("이 섹션은 DEBUG 전용이며 mock HealthKit 상태, synthetic Fitdays CSV 결과, 앱 계산 샘플만 사용합니다. Release 사용자에게 노출되지 않습니다.")
          .font(.footnote)
          .foregroundStyle(NBColor.secondaryText)
      }

      Section("Preview Summary") {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.md) {
          ScenarioStatRow(
            title: "수면 소리 점수",
            value: "\(previewBundle.report.sleepSoundScore)",
            unit: "점",
            systemImage: "waveform.path.ecg",
            status: .debug
          )
          ScenarioStatRow(
            title: "측정 품질",
            value: previewBundle.report.measurementQuality.displayName,
            systemImage: "checkmark.seal",
            status: .neutral
          )
          ScenarioStatRow(
            title: "앱 동작 시간",
            value: SleepFormatters.compactDurationString(previewBundle.report.measurementDuration),
            systemImage: "clock",
            status: .debug
          )
          ScenarioStatRow(
            title: "실제 오디오 수신",
            value: SleepFormatters.compactDurationString(previewBundle.report.receivedAudioDuration),
            systemImage: "waveform",
            status: .debug
          )
          ScenarioStatRow(
            title: "최종 이벤트",
            value: "\(previewBundle.events.count)",
            unit: "개",
            systemImage: "list.bullet.rectangle",
            status: .debug
          )
          ScenarioStatRow(
            title: "Detector raw 후보",
            value: "\(previewBundle.detectorDiagnostics.rawCandidateCount)",
            unit: "개",
            systemImage: "waveform.and.magnifyingglass",
            status: .debug
          )
          ScenarioStatRow(
            title: "오디오 샘플 저장",
            value: previewBundle.isEventAudioSampleStorageEnabled ? "켜짐" : "꺼짐",
            systemImage: "waveform.circle",
            status: previewBundle.isEventAudioSampleStorageEnabled ? .debug : .privacy
          )
          ScenarioStatRow(
            title: "저장소 상태",
            value:
              "\(previewBundle.eventAudioStorageStats.sampleCount)개 · \(previewBundle.eventAudioStorageStats.formattedTotalSize)",
            systemImage: "internaldrive",
            status: .privacy
          )
          ScenarioStatRow(
            title: "연결되지 않은 샘플",
            value:
              "\(previewBundle.eventAudioStorageStats.orphanSampleCount)개 · \(previewBundle.eventAudioStorageStats.formattedOrphanSize)",
            systemImage: "link.badge.plus",
            status: .caution
          )
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .listRowBackground(Color.clear)
      }

      Section("화면 확인") {
        NavigationLink {
          HomeDashboardView()
        } label: {
          Label("HomeDashboardView", systemImage: "house")
        }

        NavigationLink {
          SleepReportView(report: appState.latestReport, events: appState.latestEvents)
        } label: {
          Label("SleepReportView", systemImage: "doc.text.magnifyingglass")
        }

        NavigationLink {
          SleepTimelineView(report: appState.latestReport, events: appState.latestEvents)
        } label: {
          Label("SleepTimelineView", systemImage: "timeline.selection")
        }

        NavigationLink {
          PrivacySettingsView()
        } label: {
          Label("PrivacySettingsView", systemImage: "lock.shield")
        }

        Text("먼저 시나리오를 적용한 뒤 각 화면에서 점수, 측정 품질, 실제 오디오 수신 시간, 이벤트 수, 샘플 저장 상태, 저장 용량, detector 분석, zero-event 분석을 확인합니다.")
          .font(.footnote)
          .foregroundStyle(NBColor.secondaryText)
      }

      Section("QA 범위") {
        NBPrivacyNoticeCard(
          title: "QA 범위",
          messages: [
            "Simulator에서 리포트와 설정 UI edge case를 빠르게 확인합니다.",
            "실제 마이크, 화면 잠금 녹음, 배터리/발열은 실기기에서만 확인합니다.",
            "서버 전송, HealthKit, 전체 밤 원본 오디오 저장은 포함하지 않습니다.",
            "DEBUG 빌드에서만 노출됩니다.",
          ],
          systemImage: "checkmark.circle"
        )
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .listRowBackground(Color.clear)
      }
    }
    .navigationTitle("Simulator QA")
    .scrollContentBackground(.hidden)
    .background(NBColor.pageBackground)
    .toolbar(.hidden, for: .tabBar)
  }
}

struct ScreenshotScenarioDestinationView: View {
  @EnvironmentObject private var appState: AppState
  let scenario: ScreenshotScenario
  var surface: ScreenshotSurface = .documentation

  var body: some View {
    destination
  }

  private var dailyHealthCardProfile: MockDailyRhythmData.DailyHealthCardDisplayProfile {
    surface.isAppStoreMarketing ? .appStoreMarketing : .readmeRepresentative
  }

  private var dailyHealthCardBundle: DailyRhythmMockBundle {
    DailyRhythmMockFactory.makeDailyHealthCardDisplayBundle(
      profile: dailyHealthCardProfile,
      referenceDate: appState.latestReport.generatedAt,
      nightReport: appState.latestReport,
      morningCheckIn: appState.morningCheckIn
    )
  }

  private var unifiedHealthSamples: [UnifiedHealthMetricSample] {
    if surface.isAppStoreMarketing {
      return ScreenshotScenarioFactory.makeAppStoreScreenshotHealthSamples(
        referenceDate: appState.latestReport.generatedAt
      )
    }

    return ScreenshotScenarioFactory.makeScreenshotHealthSamples(
      referenceDate: appState.latestReport.generatedAt
    )
  }

  private var healthPermissionState: HealthMetricPermissionState {
    surface.isAppStoreMarketing ? .readRequestCompleted : .mockDataOnly
  }

  private var isHealthPreviewData: Bool {
    !surface.isAppStoreMarketing
  }

  @ViewBuilder
  private var destination: some View {
    switch scenario {
    case .homeDashboard:
      HomeDashboardView()
    case .trendDashboard:
      TrendDashboardView()
    case .sleepStart:
      SleepStartView()
    case .sleepRecording:
      SleepRecordingView()
        .navigationTitle("수면 기록 중")
    case .onboarding:
      OnboardingView()
    case .devicePlacement:
      DevicePlacementGuideView()
    case .calibration:
      CalibrationView()
    case .sleepReport, .zeroEventReport, .lowCoverageReport:
      SleepReportView(report: appState.latestReport, events: appState.latestEvents)
    case .eventTimeline:
      SleepTimelineView(report: appState.latestReport, events: appState.latestEvents)
    case .morningCheckIn:
      MorningCheckInView(sessionId: appState.latestSession.id)
    case .morningBrief:
      MorningBriefView(
        nightReport: appState.latestReport,
        morningCheckIn: appState.morningCheckIn,
        referenceDate: appState.latestReport.generatedAt
      )
    case .dailyRhythmReport:
      DailyRhythmReportView(
        nightReport: appState.latestReport,
        morningCheckIn: appState.morningCheckIn,
        referenceDate: appState.latestReport.generatedAt
      )
    case .eveningCheckIn:
      EveningCheckInView()
    case .dailyHealthCard:
      if surface.isAppStoreMarketing {
        DailyHealthCardView(content: dailyHealthCardBundle.cardContent)
      } else {
        DailyHealthCardPreviewView(bundle: dailyHealthCardBundle)
      }
    case .dailyHealthCardExport:
      DailyHealthCardPreviewView(
        bundle: dailyHealthCardBundle,
        initialExportPreview: true
      )
    case .healthDashboard:
      HealthDashboardView()
    case .bloodPressureDashboard:
      BloodPressureDashboardView(
        samples: ScreenshotScenarioFactory.makeScreenshotStandardHealthSamples(referenceDate: appState.latestReport.generatedAt),
        permissionState: .mockDataOnly,
        isPreviewData: true
      )
    case .bodyCompositionDashboard:
      BodyCompositionDashboardView(
        samples: ScreenshotScenarioFactory.makeScreenshotStandardHealthSamples(referenceDate: appState.latestReport.generatedAt),
        permissionState: .mockDataOnly,
        isPreviewData: true
      )
    case .crossMetricDashboard:
      CrossMetricDashboardView(
        reports: ScreenshotScenarioFactory.makeScreenshotCrossMetricReports(referenceDate: appState.latestReport.generatedAt),
        samples: ScreenshotScenarioFactory.makeScreenshotStandardHealthSamples(referenceDate: appState.latestReport.generatedAt),
        permissionState: .mockDataOnly,
        isPreviewData: true
      )
    case .fitdaysImport:
      FitdaysImportView(repository: InMemoryUnifiedHealthMetricSampleRepository())
    case .fitdaysImportResult:
      FitdaysImportView(
        repository: InMemoryUnifiedHealthMetricSampleRepository(),
        initialImportResult: ScreenshotScenarioFactory.makeScreenshotFitdaysImportResult(referenceDate: appState.latestReport.generatedAt),
        initialStatusMessage: "저장 전 미리보기를 만들었습니다.",
        prioritizesInitialImportResult: true
      )
    case .importError:
      FitdaysImportView(
        repository: InMemoryUnifiedHealthMetricSampleRepository(),
        initialErrorMessage: "CSV의 측정일 열을 확인할 수 없습니다."
      )
    case .healthMetricsOverview:
      HealthMetricsOverviewView(
        samples: unifiedHealthSamples,
        permissionState: healthPermissionState,
        isPreviewData: isHealthPreviewData
      )
    case .healthCalendar:
      HealthCalendarView(
        samples: unifiedHealthSamples,
        sleepReports: [appState.latestReport],
        morningCheckIns: [appState.morningCheckIn],
        eveningCheckIns: [ScreenshotScenarioFactory.makeScreenshotEveningCheckIn(referenceDate: appState.latestReport.generatedAt)],
        permissionState: healthPermissionState,
        isPreviewData: isHealthPreviewData,
        initialMonth: appState.latestReport.generatedAt
      )
    case .dailyMeasurementDetail:
      let samples = unifiedHealthSamples
      DailyMeasurementDetailView(
        detailData: ScreenshotScenarioFactory.makeScreenshotDailyMeasurementDetailData(
          appState: appState,
          samples: samples
        ),
        allSamples: samples
      )
    case .metricDetail:
      MetricDetailView(
        metricID: .bodyWaterPercentage,
        samples: unifiedHealthSamples,
        selectedPeriod: .all
      )
    case .localOnlyMetric:
      MetricDetailView(
        metricID: .basalMetabolicRate,
        samples: unifiedHealthSamples,
        selectedPeriod: .all
      )
    case .healthPermissionEmpty:
      HealthMetricsOverviewView(
        samples: [],
        permissionState: .denied,
        isPreviewData: false
      )
    case .metricDetailEmpty:
      MetricDetailView(
        metricID: .bodyWaterPercentage,
        samples: [],
        selectedPeriod: .thirtyDays
      )
    case .crossMetricInsufficient:
      CrossMetricDashboardView(
        reports: Array(ScreenshotScenarioFactory.makeScreenshotCrossMetricReports(referenceDate: appState.latestReport.generatedAt).prefix(2)),
        samples: ScreenshotScenarioFactory.makeScreenshotStandardHealthSamples(referenceDate: appState.latestReport.generatedAt),
        permissionState: .mockDataOnly,
        isPreviewData: true
      )
    case .privacySettings:
      PrivacySettingsView()
    case .eventAudioStorageOff:
      ScreenshotEventAudioStorageOffView()
    case .reportEmpty:
      ScreenshotReportEmptyStateView()
    case .debugTools:
      DetectorTuningView()
    case .simulatorScenario:
      SimulatorScenarioView()
    case .audioDebug:
      AudioDebugView()
    case .sampleCapture:
      SampleCaptureView()
    case .datasetReplay:
      DatasetReplayView()
    }
  }
}

private struct ScreenshotReportEmptyStateView: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        NBCard {
          NBEmptyStateView(
            title: "아직 수면 리포트가 없습니다",
            message: "오늘 밤 수면을 기록하면 아침에 수면 소리 리포트와 측정 품질을 확인할 수 있습니다.",
            systemImage: "doc.text.magnifyingglass",
            illustration: .emptyReport
          )
        }

        NBPrivacyNoticeCard(
          title: "리포트 생성 전 안내",
          messages: [
            "수면 시작 전에는 실제 개인 오디오나 건강 데이터를 표시하지 않습니다.",
            "전체 밤 원본 오디오를 기본 저장하지 않습니다.",
            "수면 중 소리 기반 지표는 개인 참고용 보기입니다.",
          ],
          systemImage: "lock.shield"
        )
      }
      .padding(.horizontal, NBSpacing.screenHorizontal)
      .padding(.vertical, NBSpacing.sectionVertical)
    }
    .background(NBColor.pageBackground)
    .navigationTitle("수면 리포트")
  }
}

private struct ScreenshotEventAudioStorageOffView: View {
  @EnvironmentObject private var appState: AppState

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        NBReportSection(title: "이벤트 오디오 샘플 저장 꺼짐", systemImage: "waveform.slash") {
          VStack(alignment: .leading, spacing: NBSpacing.medium) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.small) {
              NBMetricCard(
                title: "샘플 저장",
                value: appState.isEventAudioSampleStorageEnabled ? "켜짐" : "꺼짐",
                subtitle: "기본값 OFF",
                systemImage: appState.isEventAudioSampleStorageEnabled ? "checkmark.circle" : "xmark.circle",
                tint: appState.isEventAudioSampleStorageEnabled ? NBColor.audioTint : NBColor.privacy,
                status: appState.isEventAudioSampleStorageEnabled ? .debug : .privacy
              )
              NBMetricCard(
                title: "저장된 샘플",
                value: "\(appState.eventAudioStorageStats.sampleCount)",
                unit: "개",
                systemImage: "waveform.circle",
                tint: NBColor.audioTint
              )
              NBMetricCard(
                title: "총 시간",
                value: SleepFormatters.compactDurationString(appState.eventAudioStorageStats.totalDurationSeconds),
                systemImage: "timer",
                tint: NBColor.sleep
              )
              NBMetricCard(
                title: "저장 용량",
                value: appState.eventAudioStorageStats.formattedTotalSize,
                systemImage: "internaldrive",
                tint: NBColor.privacy
              )
            }

            Text("꺼져 있으면 앞으로 감지되는 이벤트의 짧은 오디오 샘플도 저장하지 않습니다. 기존 저장 샘플은 자동 삭제하지 않고, 개인정보 설정에서 사용자가 직접 지울 수 있습니다.")
              .font(NBTypography.callout)
              .foregroundStyle(NBColor.secondaryText)
              .fixedSize(horizontal: false, vertical: true)
          }
        }

        NBPrivacyNoticeCard(
          title: "로컬 보관 원칙",
          messages: [
            "전체 밤 원본 오디오는 기본 저장하지 않습니다.",
            "이벤트 전후의 짧은 샘플은 사용자가 켠 경우에만 로컬 저장합니다.",
            "서버 전송, 클라우드 처리, 말소리 텍스트 변환을 하지 않습니다.",
          ],
          systemImage: "lock.shield"
        )

        NBReportSection(title: "샘플 제한", systemImage: "checklist") {
          VStack(alignment: .leading, spacing: NBSpacing.small) {
            PrivacyStorageStatRow(title: "이벤트 전후 범위", value: "이벤트 전 2초 · 후 3초", systemImage: "waveform.path")
            PrivacyStorageStatRow(title: "샘플 최대 길이", value: "10초", systemImage: "timer")
            PrivacyStorageStatRow(title: "세션당 최대 개수", value: "100개", systemImage: "number")
            PrivacyStorageStatRow(title: "폴더 용량 제한", value: "200MB", systemImage: "internaldrive")
          }
        }
      }
      .padding(.horizontal, NBSpacing.screenHorizontal)
      .padding(.vertical, NBSpacing.sectionVertical)
    }
    .background(NBColor.pageBackground)
    .navigationTitle("샘플 저장 꺼짐")
    .onAppear {
      appState.refreshEventAudioStorageStats()
    }
  }
}

private struct ScenarioStatRow: View {
  let title: String
  let value: String
  var unit: String?
  let systemImage: String
  let status: NBStatusKind

  var body: some View {
    NBMetricCard(
      title: title,
      value: value,
      unit: unit,
      systemImage: systemImage,
      tint: status.tint,
      status: status,
      accessibilityLabel: "\(title), \(value)\(unit ?? "")"
    )
  }
}
#endif
