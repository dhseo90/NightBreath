import Foundation
import ImageIO
import Testing

@Suite("App Icon Assets")
struct AppIconAssetTests {
    @Test
    func appIconSetDefinesAllRequiredSlotsWithMatchingPngDimensions() throws {
        let iconSetURL = repositoryRoot
            .appendingPathComponent("SleepSoundApp/App/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
        let contentsURL = iconSetURL.appendingPathComponent("Contents.json")
        let data = try Data(contentsOf: contentsURL)
        let contents = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let images = try #require(contents["images"] as? [[String: String]])

        #expect(images.count == 18)
        #expect(Set(images.compactMap { $0["filename"] }).contains("AppIcon-1024.png"))

        for image in images {
            let filename = try #require(image["filename"])
            let size = try #require(image["size"])
            let scale = try #require(image["scale"])
            let expectedPixels = try expectedPixelSide(size: size, scale: scale)
            let imageURL = iconSetURL.appendingPathComponent(filename)
            let pixelSize = try pngPixelSize(at: imageURL)

            #expect(pixelSize.width == expectedPixels, "\(filename) width mismatch")
            #expect(pixelSize.height == expectedPixels, "\(filename) height mismatch")
        }
    }

    @Test
    func marketingIconIsOpaqueAndGeneratedFromNightBreathArtworkScript() throws {
        let iconURL = repositoryRoot
            .appendingPathComponent("SleepSoundApp/App/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
        let imageSource = try #require(CGImageSourceCreateWithURL(iconURL as CFURL, nil))
        let image = try #require(CGImageSourceCreateImageAtIndex(imageSource, 0, nil))
        let script = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Tools/AppIcon/generate_app_icon.swift"),
            encoding: .utf8
        )

        #expect(image.width == 1024)
        #expect(image.height == 1024)
        #expect(image.alphaInfo == .noneSkipLast || image.alphaInfo == .none)
        #expect(script.contains("Crescent moon"))
        #expect(script.contains("Breathing rhythm"))
        #expect(script.contains("privacy"))
        #expect(!script.contains("diagnosis"))
    }

    @Test
    func appIconReleaseWorkflowHasValidationAndReviewSheet() throws {
        let toolReadme = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Tools/AppIcon/README.md"),
            encoding: .utf8
        )
        let validationScript = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Tools/AppIcon/validate_app_icon.swift"),
            encoding: .utf8
        )
        let reviewScript = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Tools/AppIcon/render_app_icon_review_sheet.swift"),
            encoding: .utf8
        )
        let releaseGuide = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/APP_RELEASE_GUIDE.md"),
            encoding: .utf8
        )
        let designSystem = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/DESIGN_SYSTEM.md"),
            encoding: .utf8
        )
        let reviewSheetURL = repositoryRoot.appendingPathComponent("Docs/AppIcon/app_icon_review_sheet.png")
        let reviewSheetSize = try pngPixelSize(at: reviewSheetURL)

        #expect(toolReadme.contains("validate_app_icon.swift"))
        #expect(toolReadme.contains("render_app_icon_review_sheet.swift"))
        #expect(validationScript.contains("alpha channel"))
        #expect(validationScript.contains("AppIcon-1024.png"))
        #expect(validationScript.contains("ios-marketing"))
        #expect(reviewScript.contains("Home Screen"))
        #expect(reviewScript.contains("Settings"))
        #expect(reviewScript.contains("Smallest"))
        #expect(releaseGuide.contains("validate_app_icon.swift"))
        #expect(releaseGuide.contains("app_icon_review_sheet.png"))
        #expect(designSystem.contains("generate/validate/review sheet"))
        #expect(reviewSheetSize.width == 1600)
        #expect(reviewSheetSize.height == 1200)
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }

    private func expectedPixelSide(size: String, scale: String) throws -> Int {
        let pointComponent = try #require(size.split(separator: "x").first)
        let pointSide = try #require(Double(String(pointComponent)))
        let multiplier = try #require(Double(scale.replacingOccurrences(of: "x", with: "")))
        return Int((pointSide * multiplier).rounded())
    }

    private func pngPixelSize(at url: URL) throws -> (width: Int, height: Int) {
        let imageSource = try #require(CGImageSourceCreateWithURL(url as CFURL, nil))
        let properties = try #require(CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any])
        let width = try #require(properties[kCGImagePropertyPixelWidth] as? Int)
        let height = try #require(properties[kCGImagePropertyPixelHeight] as? Int)
        return (width, height)
    }
}
