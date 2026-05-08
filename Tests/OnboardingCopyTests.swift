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
    func onboardingUsesPurposeBuiltIllustrations() throws {
        let onboarding = try read("SleepSoundApp/Features/Onboarding/OnboardingView.swift")
        let illustrations = try read("SleepSoundApp/Core/Design/NBIllustration.swift")
        let guide = try read("Docs/ONBOARDING_ILLUSTRATION_GUIDE.md")

        #expect(onboarding.contains(".onboardingIntro"))
        #expect(onboarding.contains(".eventAudioSamples"))
        #expect(onboarding.contains(".microphonePermission"))
        #expect(onboarding.contains(".calibrationCheck"))
        #expect(illustrations.contains("struct NBOnboardingIntroIllustration"))
        #expect(illustrations.contains("struct NBEventAudioSamplesIllustration"))
        #expect(illustrations.contains("struct NBMicrophonePermissionIllustration"))
        #expect(illustrations.contains("struct NBCalibrationCheckIllustration"))
        #expect(illustrations.contains("struct NBEmptyReportIllustration"))
        #expect(illustrations.contains("struct NBEmptyTimelineIllustration"))
        #expect(guide.contains("NBOnboardingIntroIllustration"))
        #expect(guide.contains("NBEmptyTimelineIllustration"))
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
