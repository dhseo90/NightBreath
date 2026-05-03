import Foundation
import Testing

@Suite("Onboarding Copy")
struct OnboardingCopyTests {
    @Test
    func audioSampleOptInCopyExists() throws {
        let contents = try read("SleepSoundApp/Features/Onboarding/OnboardingView.swift")

        #expect(contents.contains("기본값은 꺼짐"))
        #expect(contents.contains("짧은 이벤트 오디오 샘플"))
        #expect(contents.contains("전체 밤 오디오가 아니며"))
    }

    @Test
    func onboardingCopyAvoidsRestrictedClinicalTerms() throws {
        let paths = [
            "SleepSoundApp/Features/Onboarding/OnboardingView.swift",
            "SleepSoundApp/Features/Onboarding/CalibrationView.swift",
            "SleepSoundApp/Features/Settings/DevicePlacementGuideView.swift",
            "Docs/ONBOARDING_AND_CALIBRATION.md",
        ]
        let forbiddenTerms = [
            "수면무호흡증 " + "진단",
            "A" + "HI",
            "이갈이 " + "확진",
            "질병 " + "판정",
            "치료 " + "필요",
            "의료 " + "진단",
        ]

        for path in paths {
            let contents = try read(path)
            for term in forbiddenTerms {
                #expect(!contents.contains(term))
            }
        }
    }

    private func read(_ path: String) throws -> String {
        let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(path)
        return try String(contentsOf: url, encoding: .utf8)
    }
}
