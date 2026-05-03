import Foundation
import Testing
@testable import SleepSoundCore

@Suite("MetricTrendDataPoint")
struct MetricTrendDataPointTests {
    @Test
    func pointKeepsSourceTypeSourceNameSampleIDAndDataQuality() {
        let sampleID = UUID(uuidString: "42000000-0000-0000-0000-000000000001")!
        let sample = UnifiedHealthMetricSample(
            id: sampleID,
            metricID: .basalMetabolicRate,
            value: 1_520,
            unit: "kcal/day",
            measuredAt: referenceDate,
            sourceType: .fitdaysCSV,
            sourceName: "Fitdays CSV Import",
            createdAt: referenceDate
        )

        let point = MetricTrendDataPoint(sample: sample, dataQuality: .good)

        #expect(point.id == sampleID)
        #expect(point.date == referenceDate)
        #expect(point.value == 1_520)
        #expect(point.sourceType == .fitdaysCSV)
        #expect(point.sourceName == "Fitdays CSV Import")
        #expect(point.sampleId == sampleID)
        #expect(point.dataQuality == .good)
    }

    @Test
    func nonFinitePointValueFallsBackToZero() {
        let point = MetricTrendDataPoint(
            date: referenceDate,
            value: .infinity,
            sourceType: .manual,
            sourceName: "수동 입력",
            sampleId: UUID()
        )

        #expect(point.value == 0)
    }

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_777_680_000)
    }
}
