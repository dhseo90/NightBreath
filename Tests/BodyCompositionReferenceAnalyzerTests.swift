import Foundation
import Testing
@testable import SleepSoundCore

@Suite("Body Composition Reference Analyzer")
struct BodyCompositionReferenceAnalyzerTests {
    private let analyzer = BodyCompositionReferenceAnalyzer()
    private let referenceDate = Date(timeIntervalSince1970: 1_777_680_000)
    private let day: TimeInterval = 24 * 60 * 60

    @Test
    func koreanBMICategoriesUseAdultReferenceBandsWithoutDefinitiveCopy() throws {
        #expect(KoreanBMIReferenceCategory.category(for: 18.4) == .belowReference)
        #expect(KoreanBMIReferenceCategory.category(for: 18.5) == .reference)
        #expect(KoreanBMIReferenceCategory.category(for: 22.9) == .reference)
        #expect(KoreanBMIReferenceCategory.category(for: 23.0) == .preObesity)
        #expect(KoreanBMIReferenceCategory.category(for: 25.0) == .obesityStage1)
        #expect(KoreanBMIReferenceCategory.category(for: 30.0) == .obesityStage2)
        #expect(KoreanBMIReferenceCategory.category(for: 35.0) == .obesityStage3)
        #expect(KoreanBMIReferenceCategory.category(for: 0) == nil)

        let copy = KoreanBMIReferenceCategory.allCases.map(\.displayName).joined(separator: " ")
        for restricted in ["정상", "비정상", "판정", "치료 필요", "의료 진단"] {
            #expect(!copy.contains(restricted))
        }
    }

    @Test
    func summaryClassifiesBMIWithoutDerivingHeightFromWeightAndBMI() throws {
        let samples = [
            sample(.bodyMass, 72.0, daysAgo: 0),
            sample(.bodyMassIndex, 25.0, daysAgo: 0),
            sample(.bodyFatPercentage, 22.5, daysAgo: 0),
        ]

        let summary = analyzer.summary(samples: samples, endingAt: referenceDate)

        #expect(summary.bmiCategory == .obesityStage1)
        #expect(summary.latestWeightKg == 72.0)
    }

    @Test
    func referenceBoundaryRequiresExplicitHeightAndUsesUpperBoundary() throws {
        let boundary = try #require(analyzer.referenceBoundary(
            weightKg: 72.0,
            heightMeters: 1.7,
            bmiCategory: .obesityStage1
        ))

        #expect(boundary.kind == .upperReference)
        #expect(abs(boundary.bmiBoundary - 23.0) < 0.0001)
        #expect(abs(boundary.boundaryWeightKg - (23.0 * 1.7 * 1.7)) < 0.05)
        #expect(abs(boundary.deltaKg - (72.0 - 23.0 * 1.7 * 1.7)) < 0.05)
        #expect(analyzer.referenceBoundary(weightKg: 72.0, heightMeters: nil, bmiCategory: .obesityStage1) == nil)
    }

    @Test
    func belowReferenceBMIUsesLowerReferenceBoundaryWhenHeightIsProvided() throws {
        let heightMeters = 1.7
        let bmi = 17.5
        let weight = bmi * heightMeters * heightMeters
        let samples = [
            sample(.bodyMass, weight, daysAgo: 0),
            sample(.bodyMassIndex, bmi, daysAgo: 0),
        ]

        let summary = analyzer.summary(samples: samples, endingAt: referenceDate)
        let boundary = try #require(analyzer.referenceBoundary(
            weightKg: summary.latestWeightKg,
            heightMeters: heightMeters,
            bmiCategory: summary.bmiCategory
        ))

        #expect(summary.bmiCategory == .belowReference)
        #expect(boundary.kind == .lowerReference)
        #expect(abs(boundary.bmiBoundary - 18.5) < 0.0001)
        #expect(abs(boundary.boundaryWeightKg - (18.5 * heightMeters * heightMeters)) < 0.05)
        #expect(boundary.deltaKg < 0)
    }

    @Test
    func recentMuscleDecreaseCreatesTrendNoticeWithoutMedicalClaim() throws {
        let samples = [
            sample(.skeletalMuscleMass, 32.2, daysAgo: 55),
            sample(.skeletalMuscleMass, 32.0, daysAgo: 42),
            sample(.skeletalMuscleMass, 31.1, daysAgo: 20),
            sample(.skeletalMuscleMass, 30.8, daysAgo: 8),
        ]

        let notices = analyzer.trendNotices(samples: samples, endingAt: referenceDate)

        #expect(notices.contains { $0.kind == .muscleDecrease })
        #expect(notices.first { $0.kind == .muscleDecrease }?.changeValue.map { $0 < -0.5 } == true)

        let copy = notices.flatMap { [$0.title, $0.message] }.joined(separator: " ")
        for restricted in ["질병", "치료", "의료 진단", "판정", "정상", "비정상"] {
            #expect(!copy.contains(restricted))
        }
    }

    @Test
    func combinedWeightAndMuscleDecreaseIsPrioritizedWhenBothMoveTogether() throws {
        let samples = [
            sample(.bodyMass, 72.4, daysAgo: 55),
            sample(.bodyMass, 72.0, daysAgo: 42),
            sample(.skeletalMuscleMass, 32.2, daysAgo: 55),
            sample(.skeletalMuscleMass, 32.0, daysAgo: 42),
            sample(.bodyMass, 70.8, daysAgo: 20),
            sample(.bodyMass, 70.6, daysAgo: 8),
            sample(.skeletalMuscleMass, 31.1, daysAgo: 20),
            sample(.skeletalMuscleMass, 30.9, daysAgo: 8),
        ]

        let notices = analyzer.trendNotices(samples: samples, endingAt: referenceDate)

        #expect(notices.first?.kind == .weightAndMuscleDecrease)
        #expect(notices.first?.title.contains("함께 내려가는 흐름") == true)
    }

    private func sample(
        _ metricID: UnifiedHealthMetricID,
        _ value: Double,
        daysAgo: Int
    ) -> UnifiedHealthMetricSample {
        UnifiedHealthMetricSample(
            metricID: metricID,
            value: value,
            unit: MetricCatalog.default.metadata(for: metricID)?.unit ?? "",
            measuredAt: referenceDate.addingTimeInterval(-Double(daysAgo) * day),
            sourceType: .fitdaysCSV,
            sourceName: "Fitdays CSV Import",
            createdAt: referenceDate
        )
    }
}
