import Foundation
import Testing
@testable import SleepSoundCore

@Suite("Health Navigation Access")
struct HealthNavigationAccessTests {
    @Test
    func homeDashboardProvidesDirectHealthDetailAndCalendarAccess() throws {
        let contents = try sourceContents("SleepSoundApp/Features/Dashboard/HomeDashboardView.swift")

        #expect(contents.contains("healthQuickAccessSection"))
        #expect(contents.contains("건강 기록 바로가기"))
        #expect(contents.contains("최근 건강 기록"))
        #expect(contents.contains("DailyMeasurementDetailView("))
        #expect(contents.contains("HealthCalendarView("))
        #expect(contents.contains("UnifiedHealthMetricSampleRepositoryProtocol"))
        #expect(contents.contains("loadHomeHealthSamples()"))
        #expect(contents.contains("HomeHealthDateControls"))
        #expect(contents.contains("moveHomeHealthDate(by:"))
        #expect(contents.contains("HomeHealthQuickValueChip"))
        #expect(contents.contains("latestSample(.bodyMass)"))
        #expect(contents.contains("latestSample(.systolicBloodPressure)"))
        #expect(contents.contains("Label(\"건강\", systemImage: \"heart.text.square\")"))
        #expect(contents.contains("HealthDashboardView()"))
        #expect(!contents.contains("requestReadPermission"))
    }

    @Test
    func healthDashboardTabProvidesRecentDateShortcutWithoutPermissionRequest() throws {
        let contents = try sourceContents("SleepSoundApp/Features/Dashboard/HealthDashboardView.swift")

        #expect(contents.contains("recentMeasurementShortcutSection"))
        #expect(contents.contains("최근 날짜 바로가기"))
        #expect(contents.contains("최근 날짜 자세히 보기"))
        #expect(contents.contains("DailyMeasurementDetailView("))
        #expect(contents.contains("calendarBuilder.detailData"))
        #expect(contents.contains("healthCalendarLatestDate"))
        #expect(contents.contains("가장 최신 측정일 기준"))

        let sectionStart = try #require(contents.range(of: "private var recentMeasurementShortcutSection")?.lowerBound)
        let sectionEnd = try #require(contents.range(of: "private var dataStateSection")?.lowerBound)
        let section = contents[sectionStart..<sectionEnd]
        #expect(!section.contains("requestReadPermission"))
    }

    private func sourceContents(_ relativePath: String) throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
    }
}
