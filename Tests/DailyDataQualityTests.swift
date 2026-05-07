import Foundation
import Testing
@testable import SleepSoundCore

@Suite("DailyDataQuality")
struct DailyDataQualityTests {
    @Test
    func qualityBandsUseCompletenessScore() {
        #expect(DailyDataQuality.quality(for: 0.95) == .excellent)
        #expect(DailyDataQuality.quality(for: 0.75) == .good)
        #expect(DailyDataQuality.quality(for: 0.55) == .limited)
        #expect(DailyDataQuality.quality(for: 0.3) == .poor)
        #expect(DailyDataQuality.quality(for: 0.1) == .insufficient)
    }

    @Test
    func completenessIsClampedToRatioRange() {
        #expect(DailyDataQuality.clampedCompleteness(-1) == 0)
        #expect(DailyDataQuality.clampedCompleteness(1.4) == 1)
        #expect(DailyDataQuality.clampedCompleteness(.nan) == 0)
    }

    @Test
    func casesAreCodableAndIdentifiable() throws {
        let encoded = try JSONEncoder().encode(DailyDataQuality.allCases)
        let decoded = try JSONDecoder().decode([DailyDataQuality].self, from: encoded)

        #expect(decoded == DailyDataQuality.allCases)
        #expect(DailyDataQuality.good.id == DailyDataQuality.good.rawValue)
        #expect(!DailyDataQuality.excellent.displayName.isEmpty)
    }

    @Test
    func readinessSummarySeparatesAvailableAndMissingSignals() {
        let bloodPressureSample = makeSample(
            id: UUID(uuidString: "80000000-0000-0000-0000-000000000101")!,
            metricType: .systolicBloodPressure
        )
        let bodyMassSample = makeSample(
            id: UUID(uuidString: "80000000-0000-0000-0000-000000000102")!,
            metricType: .bodyMass
        )
        let snapshot = DailyHealthSnapshot(
            date: referenceDate,
            sleepReportId: UUID(uuidString: "80000000-0000-0000-0000-000000000201")!,
            morningCheckInId: UUID(uuidString: "80000000-0000-0000-0000-000000000202")!,
            healthMetricSampleIds: [bloodPressureSample.id, bodyMassSample.id],
            dataCompletenessScore: 4.0 / 6.0
        )

        let summary = DailyRhythmDataReadinessSummary.make(
            snapshot: snapshot,
            healthMetricSamples: [bloodPressureSample, bodyMassSample]
        )
        let availableSignals = Set(summary.availableItems.map(\.signal))
        let missingSignals = Set(summary.missingItems.map(\.signal))

        #expect(summary.quality == .limited)
        #expect(summary.includedSignalCount == 4)
        #expect(summary.missingSignalCount == 2)
        #expect(availableSignals == [
            .sleepReport,
            .morningCheckIn,
            .bloodPressure,
            .bodyMetrics,
        ])
        #expect(missingSignals == [
            .eveningCheckIn,
            .activityAndRecovery,
        ])
        #expect(summary.availableText.contains("수면 리포트"))
        #expect(summary.missingText.contains("저녁 기록"))
    }

    @Test
    func readinessSummaryUsesSparseDataCopy() {
        let snapshot = DailyHealthSnapshot(
            date: referenceDate,
            dataCompletenessScore: 0.1
        )

        let summary = DailyRhythmDataReadinessSummary.make(snapshot: snapshot)

        #expect(summary.quality == .insufficient)
        #expect(summary.includedSignalCount == 0)
        #expect(summary.missingSignalCount == DailyRhythmDataReadinessSignal.allCases.count)
        #expect(summary.completenessPercentText == "10%")
        #expect(summary.title.contains("제한"))
        #expect(summary.message.contains("점수보다"))
        #expect(summary.availableText == "아직 준비된 항목 없음")
    }

    @Test
    func readinessSummaryCopyAvoidsDiagnosisAndCausalityClaims() {
        let summary = DailyRhythmDataReadinessSummary.make(
            snapshot: DailyHealthSnapshot(date: referenceDate, dataCompletenessScore: 0.35)
        )
        let combinedCopy = ([summary.title, summary.message, summary.availableText, summary.missingText] +
            summary.availableItems.flatMap { [$0.title, $0.detail] } +
            summary.missingItems.flatMap { [$0.title, $0.detail] })
            .joined(separator: " ")
        let restrictedTerms = [
            "수면" + "무호흡증",
            "질병" + "판정",
            "치료" + "필요",
            "의료" + "진단",
            "정상",
            "비정상",
            "원인",
            "유발",
        ]

        #expect(restrictedTerms.allSatisfy { !combinedCopy.contains($0) })
    }

    @Test
    func dailyRhythmViewsRenderReadinessSection() throws {
        let morningBriefSource = try sourceContents(
            "SleepSoundApp/Features/DailyRhythm/MorningBriefView.swift"
        )
        let reportSource = try sourceContents(
            "SleepSoundApp/Features/DailyRhythm/DailyRhythmReportView.swift"
        )
        let helperSource = try sourceContents(
            "SleepSoundApp/Features/DailyRhythm/DailyRhythmUIHelpers.swift"
        )

        #expect(morningBriefSource.contains("DailyRhythmDataReadinessSection"))
        #expect(reportSource.contains("DailyRhythmDataReadinessSection"))
        #expect(helperSource.contains("준비된 입력"))
        #expect(helperSource.contains("제한 항목"))
    }

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_777_680_000)
    }

    private func makeSample(
        id: UUID,
        metricType: HealthMetricType
    ) -> HealthMetricSample {
        HealthMetricSample(
            id: id,
            metricType: metricType,
            value: 1,
            unit: metricType.unitLabel,
            measuredAt: referenceDate,
            sourceName: "테스트 데이터",
            sourceBundleIdentifier: "local.test"
        )
    }

    private func sourceContents(_ relativePath: String) throws -> String {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
    }
}
