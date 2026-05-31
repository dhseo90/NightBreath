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
    func periodBoundaryIncludesStartAndEndSamplesButExcludesOutside() {
        let start = referenceDate.addingTimeInterval(-7 * day)
        let samples = [
            sample(.bodyMass, 70.1, measuredAt: start.addingTimeInterval(-1), sourceType: .healthKit),
            sample(.bodyMass, 70.2, measuredAt: start, sourceType: .healthKit),
            sample(.bodyMass, 70.3, measuredAt: referenceDate, sourceType: .healthKit),
            sample(.bodyMass, 70.4, measuredAt: referenceDate.addingTimeInterval(1), sourceType: .healthKit),
            sample(.bodyWaterPercentage, 56.8, measuredAt: referenceDate, sourceType: .fitdaysCSV),
        ]

        let viewModel = MetricDetailViewModel(
            metricID: .bodyMass,
            samples: samples,
            period: .sevenDays,
            endDate: referenceDate
        )

        #expect(viewModel.filteredSamples.map(\.value) == [70.2, 70.3])
        #expect(viewModel.points.map(\.value) == [70.2, 70.3])
        #expect(viewModel.summary.sampleCount == 2)
        #expect(viewModel.summary.firstMeasuredAt == start)
        #expect(viewModel.summary.latestMeasuredAt == referenceDate)
        #expect(viewModel.latestSample?.value == 70.3)
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
    func allPeriodDateRangeUsesOnlySelectedSourceSamples() {
        let samples = [
            sample(.bodyMass, 71.6, daysAgo: 1, sourceType: .healthKit, sourceName: "Apple 건강앱"),
            sample(.bodyMass, 71.8, daysAgo: 90, sourceType: .fitdaysCSV, sourceName: "Fitdays CSV Import"),
            sample(.bodyMass, 71.7, daysAgo: 80, sourceType: .fitdaysCSV, sourceName: "Fitdays CSV Import"),
            sample(.bodyWaterPercentage, 56.8, daysAgo: 1, sourceType: .fitdaysCSV, sourceName: "Fitdays CSV Import"),
        ]

        let viewModel = MetricDetailViewModel(
            metricID: .bodyMass,
            samples: samples,
            period: .all,
            sourceFilter: .fitdaysCSV,
            endDate: referenceDate
        )

        #expect(viewModel.filteredSamples.map(\.value) == [71.8, 71.7])
        #expect(viewModel.rawSampleList.map(\.value) == [71.7, 71.8])
        #expect(viewModel.latestSample?.sourceType == .fitdaysCSV)
        #expect(viewModel.summary.sampleCount == 2)
        #expect(viewModel.emptyStateReason == nil)
    }

    @Test
    func allPeriodRangeDoesNotBorrowDatesFromOtherMetricsOrSources() {
        let selectedFitdaysSample = sample(
            .bodyMass,
            71.8,
            daysAgo: 14,
            sourceType: .fitdaysCSV,
            sourceName: "Fitdays CSV Import"
        )
        let samples = [
            sample(.bodyMass, 70.9, daysAgo: 250, sourceType: .healthKit, sourceName: "Apple 건강앱"),
            selectedFitdaysSample,
            sample(.bodyWaterPercentage, 56.8, daysAgo: 200, sourceType: .fitdaysCSV, sourceName: "Fitdays CSV Import"),
            sample(.bodyMassIndex, 22.8, daysAgo: 1, sourceType: .manual, sourceName: "수동 입력"),
        ]

        let viewModel = MetricDetailViewModel(
            metricID: .bodyMass,
            samples: samples,
            period: .all,
            sourceFilter: .fitdaysCSV,
            endDate: referenceDate
        )

        #expect(viewModel.dateRange.start == selectedFitdaysSample.measuredAt)
        #expect(viewModel.dateRange.end == referenceDate)
        #expect(viewModel.filteredSamples == [selectedFitdaysSample])
        #expect(viewModel.summary.sampleCount == 1)
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
    func emptyStateReasonPrioritizesSelectedSourceBeforeSelectedPeriod() {
        let oldHealthKitSample = sample(.bodyMass, 72.2, daysAgo: 400, sourceType: .healthKit)

        let sourceFiltered = MetricDetailViewModel(
            metricID: .bodyMass,
            samples: [oldHealthKitSample],
            period: .sevenDays,
            sourceFilter: .fitdaysCSV,
            endDate: referenceDate
        )
        let periodFiltered = MetricDetailViewModel(
            metricID: .bodyMass,
            samples: [oldHealthKitSample],
            period: .sevenDays,
            sourceFilter: .healthKit,
            endDate: referenceDate
        )

        #expect(sourceFiltered.emptyStateReason == .noSamplesForSource)
        #expect(periodFiltered.emptyStateReason == .noSamplesForPeriod)
    }

    @Test
    func healthKitBackedMetricImportedFromFitdaysKeepsFitdaysSourceInDetail() throws {
        let metadata = try #require(MetricCatalog.default.metadata(for: .bodyMass))
        let samples = [
            sample(.bodyMass, 71.6, daysAgo: 1, sourceType: .healthKit, sourceName: "Apple 건강앱"),
            sample(.bodyMass, 71.8, daysAgo: 2, sourceType: .fitdaysCSV, sourceName: "Fitdays CSV Import"),
        ]

        let viewModel = MetricDetailViewModel(
            metricID: .bodyMass,
            samples: samples,
            period: .thirtyDays,
            sourceFilter: .fitdaysCSV,
            endDate: referenceDate
        )

        #expect(metadata.isHealthKitBacked)
        #expect(!metadata.isExtendedLocalOnly)
        #expect(viewModel.filteredSamples.map(\.sourceType) == [.fitdaysCSV])
        #expect(viewModel.sourceBreakdown.map(\.sourceType) == [.fitdaysCSV])
        #expect(viewModel.latestSample?.sourceName == "Fitdays CSV Import")
    }

    @Test
    func sourceSummarySeparatesFitdaysImportFromHealthKitBackedMetrics() throws {
        let bodyMass = try #require(MetricCatalog.default.metadata(for: .bodyMass))
        let bodyWater = try #require(MetricCatalog.default.metadata(for: .bodyWaterPercentage))

        let standardSummary = MetricDetailSourceSummary.make(
            for: bodyMass,
            sourceTypes: [.healthKit, .fitdaysCSV]
        )
        let localOnlySummary = MetricDetailSourceSummary.make(
            for: bodyWater,
            sourceTypes: [.fitdaysCSV]
        )

        #expect(standardSummary.messages.joined(separator: " ").contains("로컬 import 출처"))
        #expect(standardSummary.messages.joined(separator: " ").contains("HealthKit 값으로 바꾸지 않고"))
        #expect(standardSummary.messages.joined(separator: " ").contains("HealthKit에 데이터를 쓰지 않습니다"))
        #expect(localOnlySummary.messages.joined(separator: " ").contains("로컬 전용 지표"))
        #expect(localOnlySummary.messages.joined(separator: " ").contains("Fitdays CSV 또는 수동 입력"))
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
        #expect(explanation.messages.joined(separator: " ").contains("로컬 전용"))
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
    func metricDetailViewsExposeBadgeFiltersGraphStatisticsAndRawList() throws {
        let contents = try sourceContents("SleepSoundApp/Features/Dashboard/HealthMetricsOverviewView.swift")
        let healthMetricChart = try sourceContents("SleepSoundApp/Features/Dashboard/HealthMetricChartView.swift")

        #expect(contents.contains("MetricRangeNavigator"))
        #expect(contents.contains("MetricAggregationIntervalPicker"))
        #expect(contents.contains("horizontalPagingGesture"))
        #expect(contents.contains("value.startLocation.x > 44"))
        #expect(contents.contains(".gesture(horizontalPagingGesture)"))
        #expect(!contents.contains(".simultaneousGesture(horizontalPagingGesture)"))
        #expect(contents.contains("MetricDetailSourceFilterMenu"))
        #expect(contents.contains("sourceDetailsSection"))
        #expect(contents.contains("DisclosureGroup(isExpanded: $isSourceDetailsExpanded)"))
        #expect(contents.contains("MetricChartView"))
        #expect(contents.contains("MetricReferenceRange"))
        #expect(contents.contains("@State private var selectedPointID"))
        #expect(contents.contains(".chartOverlay"))
        #expect(contents.contains("SpatialTapGesture"))
        #expect(contents.contains("selectNearestPoint"))
        #expect(contents.contains("nearestPoint(to:"))
        #expect(contents.contains("MetricChartOverlayLabel"))
        #expect(contents.contains("averageOverlayPosition"))
        #expect(contents.contains("averageOverlayFixedX"))
        #expect(contents.contains("selectedOverlayPosition"))
        #expect(contents.contains("selectedOverlayCandidateCenters"))
        #expect(contents.contains("clampedLabelCenter"))
        #expect(contents.contains("labelRect(center:"))
        #expect(!contents.contains("shouldPlaceOnLeft"))
        #expect(!contents.contains("MetricChartSelectedPointAnnotation"))
        #expect(!contents.contains(".annotation(position: .top"))
        #expect(contents.contains("RuleMark(y: .value(\"참고 범위 하단\""))
        #expect(contents.contains("RuleMark(y: .value(\"참고 범위 상단\""))
        #expect(contents.contains("RuleMark(x: .value(\"선택 구간\""))
        #expect(contents.contains("referenceRangeLegend"))
        #expect(contents.contains("referenceValuesForYDomain"))
        #expect(contents.contains("nearbyReferenceBoundaryLimit"))
        #expect(contents.contains("가까운 기준선만 표시"))
        #expect(contents.contains("그래프 축 밖"))
        #expect(contents.contains("RuleMark(y: .value(\"평균선\""))
        #expect(contents.contains("구간 평균"))
        #expect(contents.contains("chartSummaryStrip"))
        #expect(contents.contains("MetricChartSummaryPill"))
        #expect(!contents.contains("chartForegroundStyleScale(domain: uniqueSourceLabels, range: uniqueSourceColors)"))
        #expect(!contents.contains("sourceLegend"))
        #expect(contents.contains("MetricSummaryCard"))
        #expect(contents.contains("MetricSourceBadgeStrip"))
        #expect(contents.contains("MetricDetailSourceSummaryLine"))
        #expect(contents.contains("Fitdays CSV · 로컬"))
        #expect(contents.contains("HealthKit 기반"))
        #expect(contents.contains("로컬 전용"))
        #expect(contents.contains(".nbAvoidFloatingTabBar()"))
        #expect(healthMetricChart.contains("RuleMark(y: .value(\"평균선\""))
        #expect(healthMetricChart.contains("chartSummaryStrip(points: chartPoints)"))
        #expect(healthMetricChart.contains("HealthChartSummaryPill"))
        #expect(!contents.contains("Import batch:"))

        let bodyComposition = try sourceContents("SleepSoundApp/Features/Dashboard/BodyCompositionDashboardView.swift")
        #expect(bodyComposition.contains("referenceRange: graphReferenceRange"))
        #expect(bodyComposition.contains("label: \"BMI 참고 범위\""))
        #expect(bodyComposition.contains("label: \"입력 키 기준 체중 참고 범위\""))
        #expect(bodyComposition.contains("키 입력"))
        #expect(bodyComposition.contains("@AppStorage(\"nightbreath.bodyComposition.referenceHeightCentimeters\")"))
        #expect(bodyComposition.contains("@FocusState private var isHeightInputFocused"))
        #expect(bodyComposition.contains(".focused($isHeightInputFocused)"))
        #expect(bodyComposition.contains("isHeightInputFocused = false"))
        #expect(bodyComposition.contains("HealthKit 키 값을 읽지 않으므로"))
        #expect(bodyComposition.contains("사용자가 입력한 키가 있을 때만 계산합니다."))

        let bodyStart = try #require(contents.range(of: "var body: some View")?.lowerBound)
        let bodyEnd = try #require(contents.range(of: "private var metric: MetricDisplayMetadata")?.lowerBound)
        let body = contents[bodyStart..<bodyEnd]
        let controls = try #require(body.range(of: "controls")?.lowerBound)
        let graph = try #require(body.range(of: "MetricChartView(")?.lowerBound)
        let summary = try #require(body.range(of: "MetricSummaryCard(")?.lowerBound)
        #expect(controls < graph)
        #expect(graph < summary)
    }

    @Test
    func metricDetailGraphEmptyAndEdgeCopyStaysActionableAndSafe() throws {
        let contents = try sourceContents("SleepSoundApp/Features/Dashboard/HealthMetricsOverviewView.swift")
        let noMetric = MetricDetailEmptyStateReason.noMetricSamples
        let noSource = MetricDetailEmptyStateReason.noSamplesForSource
        let noPeriod = MetricDetailEmptyStateReason.noSamplesForPeriod

        #expect(contents.contains("선택한 구간에 표시할 데이터가 없습니다"))
        #expect(contents.contains("그래프 단위를 바꾸거나 HealthKit 연결과 Fitdays CSV 가져오기 상태를 확인하세요."))
        #expect(contents.contains("MetricChartView("))
        #expect(contents.contains("NBEmptyStateView("))
        #expect(noMetric.message.contains("HealthKit read-only"))
        #expect(noMetric.message.contains("Fitdays CSV"))
        #expect(noSource.message.contains("출처 필터"))
        #expect(noPeriod.message.contains("기간을 넓히거나 전체 기간"))

        let edgeCopy = [
            noMetric.title,
            noMetric.message,
            noSource.title,
            noSource.message,
            noPeriod.title,
            noPeriod.message,
        ].joined(separator: " ")
        #expect(!edgeCopy.contains("정상"))
        #expect(!edgeCopy.contains("비정상"))
        #expect(!edgeCopy.contains("질병"))
        #expect(!edgeCopy.contains("치료"))
    }

    @Test
    func detailCopyAvoidsRestrictedWording() {
        let allCopy = MetricDetailPeriod.allCases.map(\.displayName)
            + MetricDetailSourceFilter.allCases.map(\.displayName)
            + MetricCatalog.default.allMetrics().flatMap { MetricDetailExplanation.make(for: $0).messages }
            + MetricCatalog.default.allMetrics().flatMap {
                MetricDetailSourceSummary.make(for: $0, sourceTypes: [.healthKit, .fitdaysCSV, .manual, .appComputed]).messages
            }
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

    private func sample(
        _ metricID: UnifiedHealthMetricID,
        _ value: Double,
        measuredAt: Date,
        sourceType: HealthMetricSourceType,
        sourceName: String = "Test Source"
    ) -> UnifiedHealthMetricSample {
        UnifiedHealthMetricSample(
            metricID: metricID,
            value: value,
            unit: MetricCatalog.default.metadata(for: metricID)?.unit ?? "",
            measuredAt: measuredAt,
            sourceType: sourceType,
            sourceName: sourceName,
            createdAt: referenceDate
        )
    }

    private func sourceContents(_ relativePath: String) throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
    }
}

private extension MetricDetailEmptyStateReason {
    var titleAndMessage: [String] {
        [title, message]
    }
}
