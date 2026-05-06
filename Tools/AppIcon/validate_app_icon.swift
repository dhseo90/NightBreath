import Foundation
import ImageIO

struct IconSlot: Hashable {
    let idiom: String
    let size: String
    let scale: String
    let filename: String
    let pixels: Int
}

enum AppIconValidationError: Error, CustomStringConvertible {
    case contentsMissing(URL)
    case contentsInvalid(String)
    case slotMissing(IconSlot)
    case fileMissing(String)
    case dimensionMismatch(filename: String, expected: Int, actualWidth: Int, actualHeight: Int)
    case alphaChannelPresent(String)
    case fileTooSmall(String)

    var description: String {
        switch self {
        case .contentsMissing(let url):
            return "Missing Contents.json at \(url.path)"
        case .contentsInvalid(let message):
            return "Invalid Contents.json: \(message)"
        case .slotMissing(let slot):
            return "Missing app icon slot \(slot.idiom) \(slot.size) \(slot.scale) -> \(slot.filename)"
        case .fileMissing(let filename):
            return "Missing app icon PNG: \(filename)"
        case let .dimensionMismatch(filename, expected, actualWidth, actualHeight):
            return "\(filename) should be \(expected)x\(expected), got \(actualWidth)x\(actualHeight)"
        case .alphaChannelPresent(let filename):
            return "\(filename) should be opaque and must not include an alpha channel"
        case .fileTooSmall(let filename):
            return "\(filename) is unexpectedly small; regenerate from the 1024px source artwork"
        }
    }
}

let expectedSlots: [IconSlot] = [
    IconSlot(idiom: "iphone", size: "20x20", scale: "2x", filename: "AppIcon-20@2x.png", pixels: 40),
    IconSlot(idiom: "iphone", size: "20x20", scale: "3x", filename: "AppIcon-20@3x.png", pixels: 60),
    IconSlot(idiom: "iphone", size: "29x29", scale: "2x", filename: "AppIcon-29@2x.png", pixels: 58),
    IconSlot(idiom: "iphone", size: "29x29", scale: "3x", filename: "AppIcon-29@3x.png", pixels: 87),
    IconSlot(idiom: "iphone", size: "40x40", scale: "2x", filename: "AppIcon-40@2x.png", pixels: 80),
    IconSlot(idiom: "iphone", size: "40x40", scale: "3x", filename: "AppIcon-40@3x.png", pixels: 120),
    IconSlot(idiom: "iphone", size: "60x60", scale: "2x", filename: "AppIcon-60@2x.png", pixels: 120),
    IconSlot(idiom: "iphone", size: "60x60", scale: "3x", filename: "AppIcon-60@3x.png", pixels: 180),
    IconSlot(idiom: "ipad", size: "20x20", scale: "1x", filename: "AppIcon-iPad-20.png", pixels: 20),
    IconSlot(idiom: "ipad", size: "20x20", scale: "2x", filename: "AppIcon-iPad-20@2x.png", pixels: 40),
    IconSlot(idiom: "ipad", size: "29x29", scale: "1x", filename: "AppIcon-iPad-29.png", pixels: 29),
    IconSlot(idiom: "ipad", size: "29x29", scale: "2x", filename: "AppIcon-iPad-29@2x.png", pixels: 58),
    IconSlot(idiom: "ipad", size: "40x40", scale: "1x", filename: "AppIcon-iPad-40.png", pixels: 40),
    IconSlot(idiom: "ipad", size: "40x40", scale: "2x", filename: "AppIcon-iPad-40@2x.png", pixels: 80),
    IconSlot(idiom: "ipad", size: "76x76", scale: "1x", filename: "AppIcon-iPad-76.png", pixels: 76),
    IconSlot(idiom: "ipad", size: "76x76", scale: "2x", filename: "AppIcon-iPad-76@2x.png", pixels: 152),
    IconSlot(idiom: "ipad", size: "83.5x83.5", scale: "2x", filename: "AppIcon-iPad-83.5@2x.png", pixels: 167),
    IconSlot(idiom: "ios-marketing", size: "1024x1024", scale: "1x", filename: "AppIcon-1024.png", pixels: 1024),
]

let arguments = CommandLine.arguments
let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconSetURL: URL
if arguments.count > 1 {
    iconSetURL = URL(fileURLWithPath: arguments[1], relativeTo: repositoryRoot).standardizedFileURL
} else {
    iconSetURL = repositoryRoot
        .appendingPathComponent("SleepSoundApp/App/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
}

func loadContents() throws -> [[String: String]] {
    let contentsURL = iconSetURL.appendingPathComponent("Contents.json")
    guard FileManager.default.fileExists(atPath: contentsURL.path) else {
        throw AppIconValidationError.contentsMissing(contentsURL)
    }

    let data = try Data(contentsOf: contentsURL)
    guard
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
        let images = object["images"] as? [[String: String]]
    else {
        throw AppIconValidationError.contentsInvalid("Expected an images array.")
    }

    return images
}

func pngProperties(for filename: String) throws -> (width: Int, height: Int, hasAlpha: Bool, byteCount: Int) {
    let url = iconSetURL.appendingPathComponent(filename)
    guard FileManager.default.fileExists(atPath: url.path) else {
        throw AppIconValidationError.fileMissing(filename)
    }

    let data = try Data(contentsOf: url)
    guard
        let source = CGImageSourceCreateWithURL(url as CFURL, nil),
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
        let width = properties[kCGImagePropertyPixelWidth] as? Int,
        let height = properties[kCGImagePropertyPixelHeight] as? Int,
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
        throw AppIconValidationError.contentsInvalid("Could not read PNG metadata for \(filename).")
    }

    let alphaInfo = image.alphaInfo
    let hasAlpha = alphaInfo == .first
        || alphaInfo == .last
        || alphaInfo == .premultipliedFirst
        || alphaInfo == .premultipliedLast

    return (width, height, hasAlpha, data.count)
}

do {
    let images = try loadContents()
    let contentsSlots = Set(images.map {
        IconSlot(
            idiom: $0["idiom"] ?? "",
            size: $0["size"] ?? "",
            scale: $0["scale"] ?? "",
            filename: $0["filename"] ?? "",
            pixels: 0
        )
    })

    for expected in expectedSlots {
        let expectedWithoutPixels = IconSlot(
            idiom: expected.idiom,
            size: expected.size,
            scale: expected.scale,
            filename: expected.filename,
            pixels: 0
        )
        guard contentsSlots.contains(expectedWithoutPixels) else {
            throw AppIconValidationError.slotMissing(expected)
        }

        let properties = try pngProperties(for: expected.filename)
        guard properties.width == expected.pixels, properties.height == expected.pixels else {
            throw AppIconValidationError.dimensionMismatch(
                filename: expected.filename,
                expected: expected.pixels,
                actualWidth: properties.width,
                actualHeight: properties.height
            )
        }
        guard !properties.hasAlpha else {
            throw AppIconValidationError.alphaChannelPresent(expected.filename)
        }
        if expected.pixels >= 120, properties.byteCount < 8_000 {
            throw AppIconValidationError.fileTooSmall(expected.filename)
        }
    }

    print("Validated \(expectedSlots.count) NightBreath app icon slots at \(iconSetURL.path)")
} catch {
    FileHandle.standardError.write(Data("App icon validation failed: \(error)\n".utf8))
    exit(1)
}
