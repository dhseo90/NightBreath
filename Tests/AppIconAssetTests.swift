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
