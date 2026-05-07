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
        #expect(!contents.contains("requestReadPermission"))
    }

    private func sourceContents(_ relativePath: String) throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
    }
}
