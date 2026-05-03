import Foundation
import Testing
@testable import SleepSoundCore

@Suite("DailyHealthCardTemplate")
struct DailyHealthCardTemplateTests {
    @Test
    func templatesExposeExpectedCasesAndDisplayNames() {
        #expect(DailyHealthCardTemplate.allCases == [
            .simple,
            .sleepFocused,
            .healthSummary,
            .privacyMinimal,
        ])
        #expect(DailyHealthCardTemplate.simple.displayName == "기본")
        #expect(DailyHealthCardTemplate.sleepFocused.shortDisplayName == "수면")
        #expect(DailyHealthCardTemplate.healthSummary.displayName == "건강 요약")
        #expect(DailyHealthCardTemplate.privacyMinimal.shortDisplayName == "보호")
    }

    @Test
    func privacyMinimalTemplateForcesMinimalPrivacyOnly() {
        #expect(DailyHealthCardTemplate.privacyMinimal.effectivePrivacyLevel == .minimal)
        #expect(DailyHealthCardTemplate.simple.effectivePrivacyLevel == nil)
        #expect(DailyHealthCardTemplate.sleepFocused.effectivePrivacyLevel == nil)
        #expect(DailyHealthCardTemplate.healthSummary.effectivePrivacyLevel == nil)
    }

    @Test
    func privacyLevelsControlSensitiveValuesAndSourceDetails() {
        #expect(DailyHealthCardPrivacyLevel.minimal.includesSensitiveValues == false)
        #expect(DailyHealthCardPrivacyLevel.minimal.includesSourceDetails == false)
        #expect(DailyHealthCardPrivacyLevel.standard.includesSensitiveValues)
        #expect(DailyHealthCardPrivacyLevel.standard.includesSourceDetails == false)
        #expect(DailyHealthCardPrivacyLevel.detailed.includesSensitiveValues)
        #expect(DailyHealthCardPrivacyLevel.detailed.includesSourceDetails)
    }

    @Test
    func templateAndPrivacyEnumsRoundTripThroughJSON() throws {
        let templatesData = try JSONEncoder().encode(DailyHealthCardTemplate.allCases)
        let privacyData = try JSONEncoder().encode(DailyHealthCardPrivacyLevel.allCases)

        let decodedTemplates = try JSONDecoder().decode([DailyHealthCardTemplate].self, from: templatesData)
        let decodedPrivacyLevels = try JSONDecoder().decode([DailyHealthCardPrivacyLevel].self, from: privacyData)

        #expect(decodedTemplates == DailyHealthCardTemplate.allCases)
        #expect(decodedPrivacyLevels == DailyHealthCardPrivacyLevel.allCases)
        #expect(DailyHealthCardTemplate.healthSummary.id == DailyHealthCardTemplate.healthSummary.rawValue)
        #expect(DailyHealthCardPrivacyLevel.detailed.id == DailyHealthCardPrivacyLevel.detailed.rawValue)
    }

    @Test
    func templateAndPrivacyCopyAvoidsDiagnosisAndCausalityClaims() {
        let copy = (
            DailyHealthCardTemplate.allCases.map(\.summaryText) +
            DailyHealthCardPrivacyLevel.allCases.map(\.description)
        )
        .joined(separator: " ")
        let restrictedTerms = [
            "고혈압" + "입니다",
            "비만" + "입니다",
            "수면" + "무호흡증 가능성이 " + "높습니다",
            "치료" + "가 필요합니다",
            "코골기" + " 때문에 " + "혈압",
            "건강 " + "진단 " + "점수",
            "질병 " + "예측",
            "원인",
            "유발",
            "정상",
            "비정상",
        ]

        #expect(restrictedTerms.allSatisfy { !copy.contains($0) })
    }
}
