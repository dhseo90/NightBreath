import Foundation
import Testing
@testable import SleepSoundCore

@Suite("MetricDetailViewModel")
struct MetricDetailViewModelTests {
    @Test
    func periodFilterLimitsSamplesToSelectedWindow() {
        let samples = [
            sample(.bodyMass, 71.6, daysAgo: 1, sourceType: .healthKit),
            sample(.bodyMass, 72.2, daysAgo: 40, sourceType: .healthKit),
            sample(.bodyWaterPercentage, 56.8, daysAgo: 1, sourceType: .fitdaysCSV),
        ]

        let sevenDays = MetricDetailViewModel(
            metricID: .bodyMass,
            samples: samples,
            period: .sevenDays,
            endDate: referenceDate
        )
        let all = MetricDetailViewModel(
            metricID: .bodyMass,
            samples: samples,
            period: .all,
            endDate: referenceDate
        )

        #expect(sevenDays.filteredSamples.map(\.value) == [71.6])
        #expect(sevenDays.summary.sampleCount == 1)
        #expect(all.filteredSamples.map(\.value) == [72.2, 71.6])
        #expect(all.summary.sampleCount == 2)
    }

    @Test
    func sourceFilterKeepsOnlySelectedSourceType() {
        let samples = [
            sample(.bodyMass, 71.6, daysAgo: 1, sourceType: .healthKit, sourceName: "Apple 건강앱"),
            sample(.bodyMass, 71.8, daysAgo: 2, sourceType: .fitdaysCSV, sourceName: "Fitdays CSV Import"),
            sample(.bodyMass, 71.7, daysAgo: 3, sourceType: .manual, sourceName: "수동 입력"),
        ]

        let viewModel = MetricDetailViewModel(
            metricID: .bodyMass,
            samples: samples,
            period: .thirtyDays,
            sourceFilter: .fitdaysCSV,
            endDate: referenceDate
        )

        #expect(viewModel.filteredSamples.map(\.sourceType) == [.fitdaysCSV])
        #expect(viewModel.sourceBreakdown.map(\.sourceType) == [.fitdaysCSV])
        #expect(viewModel.summary.latestValue == 71.8)
    }

    @Test
    func rawSampleListIsNewestFirstAndKeepsSourceMetadata() {
        let samples = [
            sample(.bodyWaterPercentage, 56.8, daysAgo: 3, sourceType: .fitdaysCSV, sourceName: "Fitdays CSV Import"),
            sample(.bodyWaterPercentage, 57.2, daysAgo: 1, sourceType: .fitdaysCSV, sourceName: "Fitdays CSV Import"),
            sample(.bodyWaterPercentage, 57.0, daysAgo: 2, sourceType: .manual, sourceName: "수동 입력"),
            sample(.bodyMass, 71.6, daysAgo: 1, sourceType: .healthKit, sourceName: "Apple 건강앱"),
        ]

        let viewModel = MetricDetailViewModel(
            metricID: .bodyWaterPercentage,
            samples: samples,
            period: .thirtyDays,
            endDate: referenceDate
        )

        #expect(viewModel.rawSampleList.map(\.value) == [57.2, 57.0, 56.8])
        #expect(viewModel.rawSampleList.map(\.sourceType) == [.fitdaysCSV, .manual, .fitdaysCSV])
        #expect(viewModel.rawSampleList.map(\.sourceName) == ["Fitdays CSV Import", "수동 입력", "Fitdays CSV Import"])
    }

    @Test
    func emptyDataStatesSeparateMissingMetricSourceAndPeriod() {
        let oldHealthKitSample = sample(.bodyMass, 72.2, daysAgo: 40, sourceType: .healthKit)

        let noMetric = MetricDetailViewModel(
            metricID: .bodyWaterPercentage,
            samples: [oldHealthKitSample],
            period: .thirtyDays,
            endDate: referenceDate
        )
        let noSource = MetricDetailViewModel(
            metricID: .bodyMass,
            samples: [oldHealthKitSample],
            period: .all,
            sourceFilter: .fitdaysCSV,
            endDate: referenceDate
        )
        let noPeriod = MetricDetailViewModel(
            metricID: .bodyMass,
            samples: [oldHealthKitSample],
            period: .sevenDays,
            endDate: referenceDate
        )

        #expect(noMetric.emptyStateReason == .noMetricSamples)
        #expect(noSource.emptyStateReason == .noSamplesForSource)
        #expect(noPeriod.emptyStateReason == .noSamplesForPeriod)
    }

    @Test
    func extendedLocalOnlyMetadataExplainsFitdaysImportAndLocalHandling() throws {
        let metadata = try #require(MetricCatalog.default.metadata(for: .bodyWaterPercentage))
        let explanation = MetricDetailExplanation.make(for: metadata)

        #expect(metadata.isExtendedLocalOnly)
        #expect(!metadata.isHealthKitBacked)
        #expect(explanation.messages.joined(separator: " ").contains("Fitdays CSV import"))
        #expect(explanation.messages.joined(separator: " ").contains("local-only"))
        #expect(explanation.messages.joined(separator: " ").contains("import/manual"))
    }

    @Test
    func healthKitBackedMetadataExplainsReadOnlyPolicy() throws {
        let metadata = try #require(MetricCatalog.default.metadata(for: .systolicBloodPressure))
        let explanation = MetricDetailExplanation.make(for: metadata)
        let copy = explanation.messages.joined(separator: " ")

        #expect(metadata.isHealthKitBacked)
        #expect(copy.contains("read-only"))
        #expect(copy.contains("HealthKit에 데이터를 쓰지 않습니다"))
    }

    @Test
    func detailCopyAvoidsRestrictedWording() {
        let allCopy = MetricDetailPeriod.allCases.map(\.displayName)
            + MetricDetailSourceFilter.allCases.map(\.displayName)
            + MetricCatalog.default.allMetrics().flatMap { MetricDetailExplanation.make(for: $0).messages }
            + MetricDetailEmptyStateReason.noMetricSamples.titleAndMessage
            + MetricDetailEmptyStateReason.noSamplesForSource.titleAndMessage
            + MetricDetailEmptyStateReason.noSamplesForPeriod.titleAndMessage

        let restricted = [
            "고혈압" + "입니다",
            "비만" + "입니다",
            "치" + "료" + " 필요",
            "질" + "병" + " 가능성",
            "건강 " + "진" + "단 " + "점수",
            "코골기 때문에 " + "혈압이 올랐습니다",
            "정" + "상",
            "비정" + "상",
            "위" + "험",
        ]

        for copy in allCopy {
            for word in restricted {
                #expect(!copy.contains(word))
            }
        }
    }

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_777_680_000)
    }

    private var day: TimeInterval {
        24 * 60 * 60
    }

    private func sample(
        _ metricID: UnifiedHealthMetricID,
        _ value: Double,
        daysAgo: Int,
        sourceType: HealthMetricSourceType,
        sourceName: String = "Test Source"
    ) -> UnifiedHealthMetricSample {
        UnifiedHealthMetricSample(
            metricID: metricID,
            value: value,
            unit: MetricCatalog.default.metadata(for: metricID)?.unit ?? "",
            measuredAt: referenceDate.addingTimeInterval(-Double(daysAgo) * day),
            sourceType: sourceType,
            sourceName: sourceName,
            createdAt: referenceDate
        )
    }
}

private extension MetricDetailEmptyStateReason {
    var titleAndMessage: [String] {
        [title, message]
    }
}
