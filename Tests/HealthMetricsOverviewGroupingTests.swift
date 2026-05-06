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
            .recovery,
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

    @Test
    func recoveryGroupContainsReadOnlyRecoveryMetricsButExcludesFitdaysExtendedOnes() throws {
        let groups = UnifiedHealthMetricOverviewGrouping().groups()
        let recoveryGroup = try #require(groups.first { $0.id == .recovery })

        #expect(recoveryGroup.metricIDs == [
            .restingHeartRate,
            .heartRate,
            .respiratoryRate,
        ])
        #expect(!recoveryGroup.metricIDs.contains(.basalMetabolicRate))
    }

    @Test
    func overviewGroupsCoverEveryCatalogMetricExactlyOnce() {
        let groups = UnifiedHealthMetricOverviewGrouping().groups()
        let groupedMetricIDs = groups.flatMap(\.metricIDs)

        #expect(groupedMetricIDs.count == Set(groupedMetricIDs).count)
        #expect(Set(groupedMetricIDs) == Set(MetricCatalog.default.allMetrics().map(\.metricID)))
    }

    @Test
    func localOnlyMetricsStayIsolatedToFitdaysExtendedGroup() throws {
        let groups = UnifiedHealthMetricOverviewGrouping().groups()
        let fitdaysGroup = try #require(groups.first { $0.id == .fitdaysExtended })
        let nonFitdaysGroups = groups.filter { $0.id != .fitdaysExtended }
        let fitdaysExtendedMetricIDs = Set(UnifiedHealthMetricOverviewGrouping.fitdaysExtendedMetricIDs)

        #expect(Set(fitdaysGroup.metricIDs) == fitdaysExtendedMetricIDs)

        for group in nonFitdaysGroups {
            #expect(
                Set(group.metricIDs).isDisjoint(with: fitdaysExtendedMetricIDs),
                "\(group.id.rawValue) should not contain Fitdays extended metrics."
            )
        }

        let sleepAndAppGroup = try #require(groups.first { $0.id == .sleepAndApp })
        #expect(sleepAndAppGroup.metricIDs.contains(.sleepSoundScore))
        #expect(sleepAndAppGroup.metricIDs.contains(.dailyRhythmScore))
    }
}
