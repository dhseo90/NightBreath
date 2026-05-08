import Foundation
import Testing
@testable import SleepSoundCore

@Suite("Health Navigation Access")
struct HealthNavigationAccessTests {
    @Test
    func homeDashboardKeepsHealthDetailsInHealthTabRole() throws {
        let contents = try sourceContents("SleepSoundApp/Features/Dashboard/HomeDashboardView.swift")

        #expect(contents.contains("Label(\"건강\", systemImage: \"heart.text.square\")"))
        #expect(contents.contains("Label(\"건강 탭에서 자세히\", systemImage: \"heart.text.square\")"))
        #expect(contents.contains("HealthDashboardView()"))
        #expect(!contents.contains("requestReadPermission"))
        #expect(!contents.contains("healthQuickAccessSection"))
        #expect(!contents.contains("HomeHealthDateControls"))
        #expect(!contents.contains("DailyMeasurementDetailView("))
        #expect(!contents.contains("HealthCalendarView("))
    }

    @Test
    func healthDashboardTabProvidesRecentDateShortcutWithoutPermissionRequest() throws {
        let contents = try sourceContents("SleepSoundApp/Features/Dashboard/HealthDashboardView.swift")

        #expect(contents.contains("recentMeasurementShortcutSection"))
        #expect(contents.contains("title: \"바로가기\""))
        #expect(contents.contains("최근 날짜 자세히 보기"))
        #expect(contents.contains("HealthDashboardShortcutCard"))
        #expect(contents.contains("Fitdays 붙여넣기"))
        #expect(contents.contains("DailyMeasurementDetailView("))
        #expect(contents.contains("calendarBuilder.detailData"))
        #expect(contents.contains("healthCalendarLatestDate"))
        #expect(contents.contains("가장 최신 측정일 기준"))

        let bodyShortcut = try #require(contents.range(of: "recentMeasurementShortcutSection")?.lowerBound)
        let bodyDataState = try #require(contents.range(of: "dataStateSection")?.lowerBound)
        #expect(bodyShortcut < bodyDataState)

        let sectionStart = try #require(contents.range(of: "private var recentMeasurementShortcutSection")?.lowerBound)
        let sectionEnd = try #require(contents.range(of: "private var dataStateSection")?.lowerBound)
        let section = contents[sectionStart..<sectionEnd]
        #expect(!section.contains("requestReadPermission"))
    }

    @Test
    func healthDashboardUsesPersistedEveningCheckInsForCalendarAndDetail() throws {
        let contents = try sourceContents("SleepSoundApp/Features/Dashboard/HealthDashboardView.swift")

        #expect(contents.contains("calendarEveningCheckIns"))
        #expect(contents.contains("appState.eveningCheckIns"))
        #expect(contents.contains("eveningCheckIns: calendarEveningCheckIns"))
        #expect(!contents.contains("eveningCheckIns: []"))
    }

    @Test
    func eveningCheckInViewSavesThroughAppStatePersistence() throws {
        let contents = try sourceContents("SleepSoundApp/Features/DailyRhythm/EveningCheckInView.swift")

        #expect(contents.contains("@EnvironmentObject private var appState: AppState"))
        #expect(contents.contains("appState.eveningCheckIn(for: Date())"))
        #expect(contents.contains("appState.saveEveningCheckIn(checkIn)"))
        #expect(contents.contains("기기 안 로컬 저장"))
        #expect(!contents.contains("화면 안에서만 임시로 보관"))
        #expect(!contents.contains("TODO: Wire this to a local Daily Rhythm repository"))
    }

    @Test
    func sleepTabProvidesStartAndRecentResultAccess() throws {
        let contents = try sourceContents("SleepSoundApp/Features/Sleep/SleepStartView.swift")

        #expect(contents.contains("latestResultSection"))
        #expect(contents.contains("최근 수면 결과"))
        #expect(contents.contains("SleepReportView(report: appState.latestReport"))
        #expect(contents.contains("SleepTimelineView(report: appState.latestReport"))
        #expect(contents.contains("TrendDashboardView()"))
        #expect(contents.contains("NBPrimaryButton(title: startButtonTitle"))
    }

    @Test
    func tabRoleContractIsDocumented() throws {
        let screenMap = try sourceContents("Docs/UI_SCREEN_MAP.md")
        let productDirection = try sourceContents("Docs/PRODUCT_DIRECTION.md")
        let combined = [screenMap, productDirection].joined(separator: "\n")

        #expect(screenMap.contains("Tab Role Contract"))
        #expect(combined.contains("홈 | 종합 평가"))
        #expect(combined.contains("수면 | 수면 기능 동작과 결과 확인"))
        #expect(combined.contains("건강 | Apple 건강앱 + 밤숨 수면 결과 + Fitdays"))
        #expect(combined.contains("설정 | 앱 설정"))
        #expect(productDirection.contains("홈에는 건강 데이터 상세 탐색을 깊게 넣지 않습니다"))
    }

    private func sourceContents(_ relativePath: String) throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
    }
}
