import SwiftUI

struct SleepStartView: View {
  @EnvironmentObject private var appState: AppState
  @State private var showLatestReport = false
  @State private var didQueuePermissionRefresh = false

  var body: some View {
    Group {
      if appState.isRecording {
        SleepRecordingView()
      } else {
        startContent
      }
    }
    .navigationDestination(isPresented: $showLatestReport) {
      SleepReportView(report: appState.latestReport, events: appState.latestEvents)
    }
    .navigationDestination(for: SleepStartDestination.self) { destination in
      switch destination {
      case .latestReport:
        SleepReportView(report: appState.latestReport, events: appState.latestEvents)
      case .latestTimeline:
        SleepTimelineView(report: appState.latestReport, events: appState.latestEvents)
      case .trend:
        TrendDashboardView()
      case .history:
        SleepSessionHistoryView()
      }
    }
    .onChange(of: appState.isFinalizingSleepSession) { wasFinalizing, isFinalizing in
      if wasFinalizing, !isFinalizing, !appState.isRecording, appState.latestReportSource == .deviceAnalysis {
        showLatestReport = true
      }
    }
    .task {
      queueDeferredMicrophonePermissionRefresh()
    }
  }

  private var startContent: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        NBCard(background: NBColor.sleep.opacity(0.10), stroke: NBColor.sleep.opacity(0.18)) {
          VStack(alignment: .leading, spacing: NBSpacing.md) {
            NBMoonBreathIcon(tint: NBColor.sleep)
              .frame(width: 54, height: 54)
              .accessibilityHidden(true)
            Text("수면 시작")
              .font(NBTypography.screenTitle)
              .foregroundStyle(NBColor.primaryText)
            Text("수면 중 소리 기반 지표를 기록합니다.")
              .font(NBTypography.body)
              .foregroundStyle(NBColor.secondaryText)
            Text("iPhone을 침대 옆에 두고, 아침에는 수면 소리 점수와 주요 이벤트를 확인할 수 있습니다.")
              .font(NBTypography.callout)
              .foregroundStyle(NBColor.secondaryText)
          }
        }

        NBPrimaryButton(title: startButtonTitle,
          systemImage: startButtonIcon,
          isDisabled: appState.isPreparingCapture,
          isBusy: appState.isPreparingCapture
        ) {
          appState.startSleepSession()
        }

        sleepStartActionFeedbackView
        permissionStatusCard
        setupSummaryCard
        latestResultSection

        NBPrivacyNoticeCard(
          title: "측정 전 개인정보 확인",
          messages: [
            "원본 전체 오디오는 저장하지 않습니다.",
            "이벤트 오디오 샘플은 사용자가 켠 경우에만 저장됩니다.",
            "분석은 iPhone 안에서 수행됩니다.",
            "서버로 전송하지 않습니다.",
          ]
        )
      }
      .padding(.horizontal, NBSpacing.screenHorizontal)
      .padding(.top, NBSpacing.sm)
      .padding(.bottom, NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
  }

  private func queueDeferredMicrophonePermissionRefresh() {
    guard !didQueuePermissionRefresh else { return }
    didQueuePermissionRefresh = true
    appState.refreshMicrophonePermissionStateAfterTabTransition()
  }

  private var latestResultSection: some View {
    NBReportSection(title: "최근 수면 결과", systemImage: "doc.text.magnifyingglass") {
      VStack(spacing: NBSpacing.md) {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.medium) {
          NBMetricCard(
            title: "수면 소리 점수",
            value: "\(appState.latestReport.sleepSoundScore)",
            unit: "점",
            subtitle: SleepFormatters.shortDate(appState.latestReport.generatedAt),
            systemImage: "waveform.path.ecg",
            tint: NBColor.sleepTint
          )

          NBMetricCard(
            title: "측정 품질",
            value: appState.latestReport.measurementQuality.displayName,
            subtitle: "커버리지 \(percentString(appState.latestReport.audioCoverageRatio))",
            systemImage: "checkmark.seal",
            tint: appState.latestReport.measurementQuality == .poor ? NBColor.danger : NBColor.success
          )
        }

        HStack(spacing: NBSpacing.md) {
          NavigationLink(value: SleepStartDestination.latestReport) {
            Label("리포트", systemImage: "doc.text.magnifyingglass")
          }
          .buttonStyle(.nbSecondary)

          NavigationLink(value: SleepStartDestination.latestTimeline) {
            Label("타임라인", systemImage: "list.bullet.rectangle")
          }
          .buttonStyle(.nbSecondary)
        }

        NavigationLink(value: SleepStartDestination.trend) {
          Label("수면 트렌드", systemImage: "chart.line.uptrend.xyaxis")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.nbSecondary)

        NavigationLink(value: SleepStartDestination.history) {
          Label("수면 기록 히스토리", systemImage: "calendar")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.nbSecondary)
      }
    }
  }

  private var permissionStatusCard: some View {
    NBCard {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        HStack {
          Label("마이크 권한", systemImage: "mic")
            .font(.headline)
          Spacer()
          NBStatusBadge(
            appState.microphonePermissionState.displayText,
            kind: permissionStatusKind,
            systemImage: permissionStatusIcon
          )
        }

        Text(permissionDescription)
          .font(.callout)
          .foregroundStyle(NBColor.secondaryText)

        if let message = appState.audioCaptureMessage {
          Text(message)
            .font(.caption)
            .foregroundStyle(NBColor.danger)
        }
      }
    }
  }

  @ViewBuilder
  private var sleepStartActionFeedbackView: some View {
    if appState.isFinalizingSleepSession {
      NBInlineStatus(
        title: "수면 기록 정리 중",
        detail: "캡처를 마무리하고 아침 리포트를 준비하고 있습니다.",
        kind: .privacy,
        systemImage: "arrow.triangle.2.circlepath",
        isLoading: true
      )
    } else {
      switch appState.audioCaptureState {
      case .requestingPermission:
        NBInlineStatus(
          title: "수면 시작 요청됨 · 권한 확인 중",
          detail: "마이크 권한 확인이 끝날 때까지 버튼은 잠시 비활성화됩니다.",
          kind: .privacy,
          systemImage: "mic.badge.plus",
          isLoading: true
        )
      case .ready:
        NBInlineStatus(
          title: "캡처 준비 완료",
          detail: "오디오 캡처 세션을 열고 수면 기록 화면으로 전환합니다.",
          kind: .good,
          systemImage: "checkmark.circle"
        )
      case .stopping:
        NBInlineStatus(
          title: "캡처 종료 요청됨",
          detail: "수면 기록을 저장 가능한 리포트로 정리하고 있습니다.",
          kind: .privacy,
          systemImage: "stop.circle",
          isLoading: true
        )
      case .failed(let message):
        NBInlineStatus(
          title: "수면 시작 완료 안 됨",
          detail: message,
          kind: .warning,
          systemImage: "exclamationmark.triangle"
        )
      case .idle, .capturing(_), .stopped:
        EmptyView()
      }
    }
  }

  private var setupSummaryCard: some View {
    NBReportSection(title: "오늘 밤 측정 준비", systemImage: "checklist") {
      VStack(spacing: NBSpacing.sm) {
        NBListRow(
          title: "기기 배치",
          value: "침대 옆",
          subtitle: "iPhone을 충전기에 연결하고 마이크가 막히지 않게 둡니다.",
          systemImage: "iphone",
          tint: NBColor.sleep
        )
        Divider().overlay(NBColor.divider)
        NBListRow(
          title: "이벤트 오디오 샘플 저장",
          value: appState.isEventAudioSampleStorageEnabled ? "켜짐" : "꺼짐",
          subtitle: "이벤트 오디오 샘플은 사용자가 켠 경우에만 저장됩니다.",
          systemImage: appState.isEventAudioSampleStorageEnabled ? "waveform.circle" : "waveform.slash",
          tint: appState.isEventAudioSampleStorageEnabled ? NBColor.audioTint : NBColor.privacy
        )
        Divider().overlay(NBColor.divider)
        NBListRow(
          title: "원본 전체 오디오",
          value: "저장 안 함",
          subtitle: "밤새 전체 원본 오디오 파일을 기본 동작으로 저장하지 않습니다.",
          systemImage: "lock.shield",
          tint: NBColor.privacy
        )
      }
    }
  }

  private var startButtonTitle: String {
    appState.isPreparingCapture ? "캡처 준비 중" : "수면 시작"
  }

  private var startButtonIcon: String {
    appState.isPreparingCapture ? "hourglass" : "play.fill"
  }

  private func percentString(_ ratio: Double) -> String {
    String(format: "%.0f%%", min(max(ratio, 0), 1) * 100)
  }

  private var permissionDescription: String {
    switch appState.microphonePermissionState {
    case .notDetermined:
      "수면 시작을 누르면 iPhone에서 마이크 권한을 요청합니다."
    case .granted:
      "마이크 권한이 허용되어 실제 오디오 캡처 테스트를 시작할 수 있습니다."
    case .denied:
      "설정 앱에서 밤숨의 마이크 권한을 허용한 뒤 다시 시도해 주세요."
    }
  }

  private var permissionStatusKind: NBStatusKind {
    switch appState.microphonePermissionState {
    case .notDetermined:
      .caution
    case .granted:
      .good
    case .denied:
      .danger
    }
  }

  private var permissionStatusIcon: String {
    switch appState.microphonePermissionState {
    case .notDetermined:
      "questionmark.circle"
    case .granted:
      "checkmark.circle"
    case .denied:
      "xmark.circle"
    }
  }
}

private enum SleepStartDestination: Hashable {
  case latestReport
  case latestTimeline
  case trend
  case history
}

private struct SleepSessionHistoryView: View {
  @EnvironmentObject private var appState: AppState
  private let calendar = Calendar.current

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        headerSection
        privacyNoticeSection

        if historyItems.isEmpty {
          NBEmptyStateView(
            title: "저장된 수면 기록이 없습니다",
            message: "수면 기록을 마치면 날짜별 리포트, 측정 품질, 아침 체크인 상태를 다시 볼 수 있습니다.",
            systemImage: "calendar.badge.exclamationmark",
            illustration: .emptyReport
          )
        } else {
          historySummarySection
          historyListSection
        }
      }
      .padding(.horizontal, NBSpacing.screenHorizontal)
      .padding(.vertical, NBSpacing.sectionVertical)
    }
    .navigationTitle("수면 기록 히스토리")
    .background(NBColor.pageBackground)
    .toolbar(.hidden, for: .tabBar)
    .nbAvoidFloatingTabBar()
  }

  private var historyItems: [SleepSessionHistoryItem] {
    appState.sleepSessionHistory(limit: 90)
  }

  private var historySections: [SleepHistoryDaySection] {
    let grouped = Dictionary(grouping: historyItems) { item in
      calendar.startOfDay(for: item.session.startedAt)
    }

    return grouped
      .map { day, items in
        SleepHistoryDaySection(
          date: day,
          items: items.sorted { lhs, rhs in lhs.session.startedAt > rhs.session.startedAt }
        )
      }
      .sorted { $0.date > $1.date }
  }

  private var headerSection: some View {
    NBCard(background: NBColor.sleep.opacity(0.08), stroke: NBColor.sleep.opacity(0.18)) {
      VStack(alignment: .leading, spacing: NBSpacing.md) {
        HStack(spacing: NBSpacing.sm) {
          Image(systemName: "calendar")
            .font(.title3.weight(.semibold))
            .foregroundStyle(NBColor.sleep)
            .frame(width: 36, height: 36)
            .background(NBColor.sleep.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
            .accessibilityHidden(true)

          VStack(alignment: .leading, spacing: NBSpacing.xxs) {
            Text("수면 기록 히스토리")
              .font(NBTypography.title)
              .foregroundStyle(NBColor.primaryText)
            Text("저장된 수면 리포트를 날짜별로 다시 보고 측정 품질과 체크인 상태를 확인합니다.")
              .font(NBTypography.caption)
              .foregroundStyle(NBColor.secondaryText)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
      }
    }
  }

  private var privacyNoticeSection: some View {
    NBPrivacyNoticeCard(
      title: "로컬 히스토리",
      messages: [
        "수면 기록은 기기 안 저장소에서만 불러옵니다.",
        "전체 밤 원본 오디오는 저장하지 않습니다.",
      ],
      systemImage: "lock.shield"
    )
  }

  private var historySummarySection: some View {
    NBReportSection(title: "최근 저장 기록", systemImage: "chart.bar.doc.horizontal") {
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.md) {
        NBMetricCard(
          title: "리포트",
          value: "\(historyItems.count)",
          unit: "개",
          subtitle: "최근 90개 기준",
          systemImage: "doc.text.magnifyingglass",
          tint: NBColor.sleepTint
        )

        NBMetricCard(
          title: "아침 체크인",
          value: "\(historyItems.filter(\.hasMorningCheckIn).count)",
          unit: "개",
          subtitle: "리포트와 연결됨",
          systemImage: "sun.max",
          tint: NBColor.dawn
        )
      }
    }
  }

  private var historyListSection: some View {
    VStack(alignment: .leading, spacing: NBSpacing.md) {
      ForEach(historySections) { section in
        NBReportSection(title: historyDateTitle(section.date), systemImage: "calendar.day.timeline.left") {
          VStack(spacing: NBSpacing.sm) {
            ForEach(section.items) { item in
              NavigationLink {
                SleepSessionDetailView(sessionId: item.id)
              } label: {
                SleepHistoryRow(item: item)
              }
              .buttonStyle(.plain)

              if item.id != section.items.last?.id {
                Divider().overlay(NBColor.divider)
              }
            }
          }
        }
      }
    }
  }

  private func historyDateTitle(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "yyyy년 M월 d일"
    return formatter.string(from: date)
  }
}

private struct SleepSessionDetailView: View {
  @EnvironmentObject private var appState: AppState

  let sessionId: UUID

  var body: some View {
    Group {
      if let item = appState.sleepSessionHistoryItem(for: sessionId) {
        detailContent(item)
      } else {
        NBEmptyStateView(
          title: "수면 기록을 찾을 수 없습니다",
          message: "로컬 저장소에서 이 세션의 리포트가 삭제되었거나 더 이상 사용할 수 없습니다.",
          systemImage: "doc.text.magnifyingglass",
          illustration: .emptyReport
        )
        .padding(NBSpacing.screenHorizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NBColor.pageBackground)
      }
    }
    .navigationTitle("세션 상세")
    .toolbar(.hidden, for: .tabBar)
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
  }

  private func detailContent(_ item: SleepSessionHistoryItem) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        detailHeader(item)
        reliabilitySection(item)
        eventSection(item)
        morningCheckInSection(item)
        actionSection(item)
      }
      .padding(.horizontal, NBSpacing.screenHorizontal)
      .padding(.vertical, NBSpacing.sectionVertical)
    }
  }

  private func detailHeader(_ item: SleepSessionHistoryItem) -> some View {
    NBCard(background: NBColor.sleep.opacity(0.08), stroke: NBColor.sleep.opacity(0.18)) {
      VStack(alignment: .leading, spacing: NBSpacing.md) {
        ViewThatFits(in: .horizontal) {
          HStack(alignment: .top, spacing: NBSpacing.sm) {
            titleBlock(item)
            Spacer()
            qualityBadge(item.report.measurementQuality)
          }
          VStack(alignment: .leading, spacing: NBSpacing.sm) {
            titleBlock(item)
            qualityBadge(item.report.measurementQuality)
          }
        }

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.md) {
          NBMetricCard(
            title: "수면 소리 점수",
            value: "\(item.report.sleepSoundScore)",
            unit: "점",
            subtitle: "웰니스 참고용",
            systemImage: "waveform.path.ecg",
            tint: scoreTint(item.report.sleepSoundScore)
          )
          NBMetricCard(
            title: "측정 시간",
            value: SleepFormatters.compactDurationString(item.report.measurementDuration),
            subtitle: "앱 동작 기준",
            systemImage: "clock",
            tint: NBColor.sleepTint
          )
        }
      }
    }
  }

  private func titleBlock(_ item: SleepSessionHistoryItem) -> some View {
    VStack(alignment: .leading, spacing: NBSpacing.xxs) {
      Text(SleepFormatters.shortDate(item.session.startedAt))
        .font(NBTypography.title)
        .foregroundStyle(NBColor.primaryText)
      Text("\(SleepFormatters.shortTime(item.session.startedAt)) 시작 · \(item.session.devicePlacement.displayName)")
        .font(NBTypography.caption)
        .foregroundStyle(NBColor.secondaryText)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private func reliabilitySection(_ item: SleepSessionHistoryItem) -> some View {
    NBReportSection(
      title: "측정 신뢰도",
      subtitle: reliabilityDetail(item.report),
      systemImage: "waveform.badge.checkmark"
    ) {
      VStack(alignment: .leading, spacing: NBSpacing.md) {
        NBInlineStatus(
          title: reliabilityTitle(item.report),
          detail: reliabilityDetail(item.report),
          kind: reliabilityStatus(item.report),
          systemImage: reliabilityIcon(item.report)
        )

        NBDiagnosticItemList(
          items: [
            NBDiagnosticItem(
              title: "녹음 커버리지",
              value: percentString(item.report.audioCoverageRatio),
              detail: "앱 동작 시간 대비 실제 오디오 수신 시간입니다.",
              status: coverageStatus(item.report)
            ),
            NBDiagnosticItem(
              title: "실제 오디오 수신",
              value: SleepFormatters.compactDurationString(item.report.receivedAudioDuration),
              detail: "분석 가능한 마이크 입력이 들어온 시간입니다.",
              status: .neutral
            ),
            NBDiagnosticItem(
              title: "실제 분석 시간",
              value: SleepFormatters.compactDurationString(item.report.analyzedAudioDuration),
              detail: "수신된 입력 중 detector가 처리한 시간입니다.",
              status: .neutral
            ),
            NBDiagnosticItem(
              title: "가장 긴 입력 공백",
              value: SleepFormatters.compactDurationString(item.report.longestAudioGapSeconds),
              detail: "중간에 오디오 입력이 끊긴 가장 긴 구간입니다.",
              status: item.report.longestAudioGapSeconds > 10 ? .caution : .good
            ),
            NBDiagnosticItem(
              title: "오디오 중단",
              value: "\(item.report.interruptionCount)회",
              detail: "시스템 interruption 또는 캡처 중단 진단에 남은 횟수입니다.",
              status: item.report.interruptionCount > 0 ? .caution : .good
            ),
          ],
          showsDetails: true
        )
      }
    }
  }

  private func eventSection(_ item: SleepSessionHistoryItem) -> some View {
    NBReportSection(title: "이벤트 요약", systemImage: "list.bullet.rectangle") {
      VStack(alignment: .leading, spacing: NBSpacing.md) {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.md) {
          NBMetricCard(
            title: "최종 이벤트",
            value: "\(item.events.count)",
            unit: "개",
            subtitle: "detector 기준 통과",
            systemImage: "waveform.and.magnifyingglass",
            tint: item.events.isEmpty ? NBColor.neutral : NBColor.audioTint
          )
          NBMetricCard(
            title: "감지 이벤트 시간",
            value: SleepFormatters.compactDurationString(item.report.detectedEventDuration),
            subtitle: "이벤트 구간 합계",
            systemImage: "timeline.selection",
            tint: NBColor.breathBlue
          )
          NBMetricCard(
            title: "코골기 시간",
            value: SleepFormatters.durationString(item.report.snoreTotalSeconds),
            systemImage: SleepEventType.snore.symbolName,
            tint: SleepEventType.snore.tintColor
          )
          NBMetricCard(
            title: "호흡정지 의심 구간",
            value: "\(item.report.suspectedBreathingPauseCount)",
            unit: "회",
            systemImage: SleepEventType.breathingPauseSuspected.symbolName,
            tint: SleepEventType.breathingPauseSuspected.tintColor
          )
        }

        Text(item.report.mainDisturbanceReason)
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private func morningCheckInSection(_ item: SleepSessionHistoryItem) -> some View {
    NBReportSection(title: "아침 체크인 연결", systemImage: "sun.max") {
      VStack(alignment: .leading, spacing: NBSpacing.md) {
        if let checkIn = item.morningCheckIn {
          NBDiagnosticItemList(
            items: [
              NBDiagnosticItem(title: "개운함", value: "\(checkIn.refreshScore)/5", status: checkIn.refreshScore >= 4 ? .good : .neutral),
              NBDiagnosticItem(title: "피로감", value: "\(checkIn.fatigueScore)/5", status: checkIn.fatigueScore >= 4 ? .caution : .neutral),
              NBDiagnosticItem(title: "기억나는 각성", value: "\(checkIn.rememberedAwakenings)회", status: checkIn.rememberedAwakenings > 0 ? .caution : .good),
            ],
            showsDetails: false
          )
        } else {
          NBInlineStatus(
            title: "아침 체크인 없음",
            detail: "이 수면 리포트에 연결된 주관적 컨디션 기록이 아직 없습니다.",
            kind: .neutral,
            systemImage: "square.and.pencil"
          )
        }

        NavigationLink {
          MorningCheckInView(sessionId: item.id)
        } label: {
          Label(item.hasMorningCheckIn ? "아침 체크인 다시 보기" : "아침 체크인 기록", systemImage: "sun.max")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.dawn))
      }
    }
  }

  private func actionSection(_ item: SleepSessionHistoryItem) -> some View {
    VStack(spacing: NBSpacing.sm) {
      NavigationLink {
        SleepReportView(report: item.report, events: item.events)
      } label: {
        Label("전체 리포트 보기", systemImage: "doc.text.magnifyingglass")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.nbSecondary)

      NavigationLink {
        SleepTimelineView(report: item.report, events: item.events)
      } label: {
        Label("타임라인 보기", systemImage: "list.bullet.rectangle")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.nbSecondary)
    }
  }

  private func qualityBadge(_ quality: MeasurementQuality) -> some View {
    NBStatusBadge(quality.displayName, kind: measurementQualityStatus(quality), systemImage: "checkmark.seal")
  }

  private func reliabilityTitle(_ report: NightReport) -> String {
    if report.measurementDuration < 4 * 60 * 60 {
      return "짧은 측정 기록"
    }
    if hasCoverageOrInterruptionIssue(report) {
      return "긴 세션의 커버리지 확인"
    }
    if report.measurementDuration >= 6 * 60 * 60 {
      return "장시간 측정 기준 충족"
    }
    return "중간 길이 측정"
  }

  private func reliabilityDetail(_ report: NightReport) -> String {
    let isShort = report.measurementDuration < 4 * 60 * 60
    let hasIssue = hasCoverageOrInterruptionIssue(report)

    if isShort && hasIssue {
      return "측정 시간이 짧고 오디오 수신도 제한적입니다. 기록된 구간의 수면 소리만 참고해 주세요."
    }
    if isShort {
      return "측정 시간이 4시간보다 짧아 전체 밤 패턴으로 보기에는 제한이 있습니다."
    }
    if hasIssue {
      return "4시간 이상 기록됐지만 실제 오디오 수신, 입력 공백, 중단 기록을 함께 확인해야 합니다."
    }
    return "수신/분석 시간과 측정 품질이 함께 확보되었습니다. 결과는 개인 패턴 참고용입니다."
  }

  private func reliabilityStatus(_ report: NightReport) -> NBStatusKind {
    if report.measurementDuration < 4 * 60 * 60 || report.measurementQuality == .poor {
      return .danger
    }
    if hasCoverageOrInterruptionIssue(report) {
      return .caution
    }
    return .good
  }

  private func reliabilityIcon(_ report: NightReport) -> String {
    if report.measurementDuration < 4 * 60 * 60 {
      return "clock.badge.exclamationmark"
    }
    if hasCoverageOrInterruptionIssue(report) {
      return "waveform.badge.exclamationmark"
    }
    return "checkmark.seal"
  }

  private func hasCoverageOrInterruptionIssue(_ report: NightReport) -> Bool {
    report.measurementQuality == .limited
      || report.measurementQuality == .poor
      || report.interruptionCount > 0
  }

  private func coverageStatus(_ report: NightReport) -> NBStatusKind {
    switch report.audioCoverageRatio {
    case 0.95...:
      return .good
    case 0.85..<0.95:
      return .neutral
    case 0.60..<0.85:
      return .caution
    default:
      return .danger
    }
  }

  private func measurementQualityStatus(_ quality: MeasurementQuality) -> NBStatusKind {
    switch quality {
    case .excellent, .good:
      return .good
    case .limited:
      return .caution
    case .poor:
      return .danger
    }
  }

  private func scoreTint(_ score: Int) -> Color {
    switch score {
    case 85...100:
      return NBColor.success
    case 70..<85:
      return NBColor.breathBlue
    case 55..<70:
      return NBColor.warning
    default:
      return NBColor.danger
    }
  }

  private func percentString(_ ratio: Double) -> String {
    String(format: "%.1f%%", min(max(ratio, 0), 1) * 100)
  }
}

private struct SleepHistoryDaySection: Identifiable {
  var id: Date { date }
  let date: Date
  let items: [SleepSessionHistoryItem]
}

private struct SleepHistoryRow: View {
  let item: SleepSessionHistoryItem

  var body: some View {
    HStack(alignment: .top, spacing: NBSpacing.md) {
      Image(systemName: item.report.isRecoveredUnfinishedRecording ? "arrow.clockwise.circle" : "moon.zzz")
        .font(.body.weight(.semibold))
        .foregroundStyle(rowTint)
        .frame(width: 34, height: 34)
        .background(rowTint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.small, style: .continuous))
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: NBSpacing.xs) {
        HStack(alignment: .firstTextBaseline, spacing: NBSpacing.sm) {
          Text("\(SleepFormatters.shortTime(item.session.startedAt)) 시작")
            .font(NBTypography.bodyEmphasis)
            .foregroundStyle(NBColor.primaryText)
          Spacer()
          Text("\(item.report.sleepSoundScore)점")
            .font(NBTypography.bodyEmphasis.monospacedDigit())
            .foregroundStyle(rowTint)
        }

        Text("측정 \(SleepFormatters.compactDurationString(item.report.measurementDuration)) · 커버리지 \(percentString(item.report.audioCoverageRatio)) · 중단 \(item.report.interruptionCount)회")
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
          .fixedSize(horizontal: false, vertical: true)

        ViewThatFits(in: .horizontal) {
          HStack(spacing: NBSpacing.xs) {
            badges
          }
          VStack(alignment: .leading, spacing: NBSpacing.xs) {
            badges
          }
        }
      }

      Image(systemName: "chevron.right")
        .font(.caption.weight(.semibold))
        .foregroundStyle(NBColor.secondaryText)
        .padding(.top, NBSpacing.xs)
        .accessibilityHidden(true)
    }
    .contentShape(Rectangle())
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder
  private var badges: some View {
    NBStatusBadge(item.report.measurementQuality.displayName, kind: measurementQualityStatus, systemImage: "checkmark.seal")
    NBStatusBadge("\(item.events.count)개 이벤트", kind: item.events.isEmpty ? .neutral : .good, systemImage: "waveform")
    NBStatusBadge(item.hasMorningCheckIn ? "체크인 있음" : "체크인 없음", kind: item.hasMorningCheckIn ? .good : .neutral, systemImage: "sun.max")
  }

  private var rowTint: Color {
    switch item.report.sleepSoundScore {
    case 85...100:
      return NBColor.success
    case 70..<85:
      return NBColor.breathBlue
    case 55..<70:
      return NBColor.warning
    default:
      return NBColor.danger
    }
  }

  private var measurementQualityStatus: NBStatusKind {
    switch item.report.measurementQuality {
    case .excellent, .good:
      return .good
    case .limited:
      return .caution
    case .poor:
      return .danger
    }
  }

  private func percentString(_ ratio: Double) -> String {
    String(format: "%.1f%%", min(max(ratio, 0), 1) * 100)
  }
}

private struct GuideRow: View {
  let systemImage: String
  let title: String
  let description: String

  var body: some View {
    NBCard(padding: NBSpacing.medium) {
      NBListRow(
        title: title,
        subtitle: description,
        systemImage: systemImage,
        tint: NBColor.breathBlue
      )
    }
  }
}
