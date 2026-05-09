import Foundation
import Testing

@Suite("Accessibility Regression")
struct AccessibilityRegressionTests {
    @Test
    func sharedRowsAndBadgesHideDecorativeIconsAndExposeCombinedLabels() throws {
        let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let listRow = try String(
            contentsOf: repositoryRoot.appendingPathComponent("SleepSoundApp/Core/Design/NBListRow.swift"),
            encoding: .utf8
        )
        let statusBadge = try String(
            contentsOf: repositoryRoot.appendingPathComponent("SleepSoundApp/Core/Design/NBBadge.swift"),
            encoding: .utf8
        )
        let metricCard = try String(
            contentsOf: repositoryRoot.appendingPathComponent("SleepSoundApp/Core/Design/NBMetricCard.swift"),
            encoding: .utf8
        )

        #expect(listRow.contains(".accessibilityElement(children: .ignore)"))
        #expect(listRow.contains(".accessibilityLabel(accessibilityLabelText ?? defaultAccessibilityLabel)"))
        #expect(listRow.contains(".accessibilityHidden(true)"))
        #expect(statusBadge.contains("struct NBInlineStatus"))
        #expect(statusBadge.contains(".accessibilityElement(children: .combine)"))
        #expect(statusBadge.contains(".accessibilityHidden(true)"))
        #expect(metricCard.contains(".accessibilityElement(children: .ignore)"))
        #expect(metricCard.contains(".accessibilityLabel(accessibilityLabelText ?? defaultAccessibilityLabel)"))
        #expect(metricCard.contains(".accessibilityHidden(true)"))
    }

    @Test
    func fitdaysFallbackAndDebugAudioRowsAvoidRepeatedIconAnnouncements() throws {
        let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let fitdaysView = try String(
            contentsOf: repositoryRoot.appendingPathComponent("SleepSoundApp/Features/Dashboard/FitdaysImportView.swift"),
            encoding: .utf8
        )
        let debugSamples = try String(
            contentsOf: repositoryRoot.appendingPathComponent("SleepSoundApp/Features/Settings/DebugAudioSamplesView.swift"),
            encoding: .utf8
        )
        let sleepReport = try String(
            contentsOf: repositoryRoot.appendingPathComponent("SleepSoundApp/Features/Sleep/SleepReportView.swift"),
            encoding: .utf8
        )

        #expect(fitdaysView.contains("exportUnavailableSection"))
        #expect(fitdaysView.contains("FitdaysImportFallbackGuidance.exportUnavailableSteps"))
        #expect(fitdaysView.contains(".fixedSize(horizontal: false, vertical: true)"))
        #expect(fitdaysView.contains(".accessibilityHidden(true)"))
        #expect(debugSamples.contains(".accessibilityHidden(true)"))
        #expect(sleepReport.contains("최근 오디오 미리듣기"))
        #expect(sleepReport.contains(".accessibilityHidden(true)"))
    }

    @Test
    func designSystemDocumentsDynamicTypeAndDecorativeIconRules() throws {
        let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let designSystem = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/DESIGN_SYSTEM.md"),
            encoding: .utf8
        )

        #expect(designSystem.contains("44pt"))
        #expect(designSystem.contains("fixedSize(horizontal: false, vertical: true)"))
        #expect(designSystem.contains("아이콘 전용 버튼은 VoiceOver label"))
        #expect(designSystem.contains("accessibilityHidden(true)"))
        #expect(designSystem.contains("부모 row/card가 의미 있는 label"))
    }
}
