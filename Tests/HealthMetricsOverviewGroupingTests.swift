import Testing
@testable import SleepSoundCore

@Suite("HealthMetricsOverviewGrouping")
struct HealthMetricsOverviewGroupingTests {
    @Test
    func groupsExposeRequestedOverviewCategories() throws {
        let groups = UnifiedHealthMetricOverviewGrouping().groups()

        #expect(groups.map(\.id) == [
            .bloodPressure,
            .bodyComposition,
            .activity,
            .sleepAndApp,
            .fitdaysExtended,
        ])
    }

    @Test
    func fitdaysExtendedGroupContainsLocalOnlyExtendedMetrics() throws {
        let groups = UnifiedHealthMetricOverviewGrouping().groups()
        let fitdaysGroup = try #require(groups.first { $0.id == .fitdaysExtended })

        #expect(fitdaysGroup.metricIDs.contains(.bodyWaterPercentage))
        #expect(fitdaysGroup.metricIDs.contains(.visceralFatLevel))
        #expect(fitdaysGroup.metricIDs.contains(.skeletalMuscleMass))
        #expect(fitdaysGroup.metricIDs.contains(.mineralMass))
        #expect(fitdaysGroup.metricIDs.contains(.basalMetabolicRate))
        #expect(!fitdaysGroup.metricIDs.contains(.bodyMass))
        #expect(!fitdaysGroup.metricIDs.contains(.dailyRhythmScore))
    }

    @Test
    func standardBodyCompositionGroupExcludesFitdaysExtendedMetrics() throws {
        let groups = UnifiedHealthMetricOverviewGrouping().groups()
        let bodyCompositionGroup = try #require(groups.first { $0.id == .bodyComposition })

        #expect(bodyCompositionGroup.metricIDs == [
            .bodyMass,
            .bodyFatPercentage,
            .bodyMassIndex,
            .leanBodyMass,
        ])
    }
}
