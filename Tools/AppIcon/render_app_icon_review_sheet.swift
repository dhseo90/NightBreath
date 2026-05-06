import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ReviewSheetError: Error, CustomStringConvertible {
    case imageLoadFailed(URL)
    case contextCreateFailed
    case encodeFailed(URL)

    var description: String {
        switch self {
        case .imageLoadFailed(let url):
            return "Could not load app icon at \(url.path)"
        case .contextCreateFailed:
            return "Could not create review sheet bitmap context"
        case .encodeFailed(let url):
            return "Could not write review sheet PNG to \(url.path)"
        }
    }
}

struct PreviewTile {
    let title: String
    let subtitle: String
    let iconSide: CGFloat
    let background: CGColor
    let textColor: CGColor
    let subtitleColor: CGColor
}

let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let arguments = CommandLine.arguments
let sourceIconURL = arguments.count > 1
    ? URL(fileURLWithPath: arguments[1], relativeTo: repositoryRoot).standardizedFileURL
    : repositoryRoot.appendingPathComponent("SleepSoundApp/App/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
let outputURL = arguments.count > 2
    ? URL(fileURLWithPath: arguments[2], relativeTo: repositoryRoot).standardizedFileURL
    : repositoryRoot.appendingPathComponent("Docs/AppIcon/app_icon_review_sheet.png")

func rgba(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func loadIcon() throws -> CGImage {
    guard
        let source = CGImageSourceCreateWithURL(sourceIconURL as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
        throw ReviewSheetError.imageLoadFailed(sourceIconURL)
    }

    return image
}

func fillRoundedRect(_ context: CGContext, rect: CGRect, radius: CGFloat, color: CGColor) {
    context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.setFillColor(color)
    context.fillPath()
}

func drawIcon(_ image: CGImage, in rect: CGRect, context: CGContext) {
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: 14), blur: 24, color: rgba(0, 0, 0, 0.22))
    context.addPath(CGPath(roundedRect: rect, cornerWidth: rect.width * 0.2237, cornerHeight: rect.height * 0.2237, transform: nil))
    context.clip()
    context.draw(image, in: rect)
    context.restoreGState()
}

func drawText(
    _ text: String,
    x: CGFloat,
    y: CGFloat,
    size: CGFloat,
    color: CGColor,
    context: CGContext,
    weight: CGFloat = 0
) {
    let font = CTFontCreateWithName("Helvetica Neue" as CFString, size, nil)
    let descriptor = CTFontCopyFontDescriptor(font)
    let traits = [kCTFontWeightTrait: weight] as CFDictionary
    let attributes = [kCTFontTraitsAttribute: traits] as CFDictionary
    let boldDescriptor = CTFontDescriptorCreateCopyWithAttributes(descriptor, attributes)
    let weightedFont = CTFontCreateWithFontDescriptor(boldDescriptor, size, nil)
    let attributed = CFAttributedStringCreate(nil, text as CFString, [
        kCTFontAttributeName: weightedFont,
        kCTForegroundColorAttributeName: color,
    ] as CFDictionary)!
    let line = CTLineCreateWithAttributedString(attributed)
    context.textPosition = CGPoint(x: x, y: y)
    CTLineDraw(line, context)
}

let icon = try loadIcon()
let width = 1600
let height = 1200
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: nil,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: width * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else {
    throw ReviewSheetError.contextCreateFailed
}

context.setShouldAntialias(true)
context.setAllowsAntialiasing(true)
context.interpolationQuality = .high
context.setFillColor(rgba(247, 250, 252))
context.fill(CGRect(x: 0, y: 0, width: width, height: height))

let titleColor = rgba(17, 24, 39)
let mutedColor = rgba(75, 85, 99)
drawText("NightBreath App Icon Review", x: 72, y: 1118, size: 38, color: titleColor, context: context, weight: 0.4)
drawText("Final candidate check: App Store, Home Screen, Settings, and small-size recognition.", x: 72, y: 1072, size: 22, color: mutedColor, context: context)

let tiles: [PreviewTile] = [
    PreviewTile(title: "App Store", subtitle: "1024 source, review at 256", iconSide: 256, background: rgba(255, 255, 255), textColor: titleColor, subtitleColor: mutedColor),
    PreviewTile(title: "Home Screen", subtitle: "180 px iPhone @3x", iconSide: 180, background: rgba(25, 37, 62), textColor: rgba(255, 255, 255), subtitleColor: rgba(209, 213, 219)),
    PreviewTile(title: "Home Screen", subtitle: "120 px iPhone @2x", iconSide: 120, background: rgba(238, 242, 247), textColor: titleColor, subtitleColor: mutedColor),
    PreviewTile(title: "Settings", subtitle: "87 px small list", iconSide: 87, background: rgba(255, 255, 255), textColor: titleColor, subtitleColor: mutedColor),
    PreviewTile(title: "Search", subtitle: "60 px result", iconSide: 60, background: rgba(17, 24, 39), textColor: rgba(255, 255, 255), subtitleColor: rgba(209, 213, 219)),
    PreviewTile(title: "Smallest", subtitle: "40/29/20 px check", iconSide: 40, background: rgba(255, 255, 255), textColor: titleColor, subtitleColor: mutedColor),
]

let tileWidth: CGFloat = 458
let tileHeight: CGFloat = 330
let startX: CGFloat = 72
let startY: CGFloat = 676
let gap: CGFloat = 40

for (index, tile) in tiles.enumerated() {
    let row = index / 3
    let column = index % 3
    let tileX = startX + CGFloat(column) * (tileWidth + gap)
    let tileY = startY - CGFloat(row) * (tileHeight + gap)
    let tileRect = CGRect(x: tileX, y: tileY, width: tileWidth, height: tileHeight)

    fillRoundedRect(context, rect: tileRect, radius: 34, color: tile.background)
    context.setStrokeColor(rgba(203, 213, 225, 0.72))
    context.setLineWidth(1)
    context.addPath(CGPath(roundedRect: tileRect, cornerWidth: 34, cornerHeight: 34, transform: nil))
    context.strokePath()

    let iconRect = CGRect(
        x: tileX + (tileWidth - tile.iconSide) / 2,
        y: tileY + 116,
        width: tile.iconSide,
        height: tile.iconSide
    )
    drawIcon(icon, in: iconRect, context: context)

    if index == 5 {
        let smallSides: [CGFloat] = [40, 29, 20]
        var smallX = tileX + 146
        for side in smallSides {
            let rect = CGRect(x: smallX, y: tileY + 146, width: side, height: side)
            drawIcon(icon, in: rect, context: context)
            smallX += side + 34
        }
    }

    drawText(tile.title, x: tileX + 32, y: tileY + 72, size: 25, color: tile.textColor, context: context, weight: 0.3)
    drawText(tile.subtitle, x: tileX + 32, y: tileY + 40, size: 17, color: tile.subtitleColor, context: context)
}

drawText("Review gates: no alpha channel, full AppIcon slots, no medical-device visual language, no third-party asset.", x: 72, y: 74, size: 19, color: mutedColor, context: context)

try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)

guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil),
      let rendered = context.makeImage()
else {
    throw ReviewSheetError.encodeFailed(outputURL)
}

CGImageDestinationAddImage(destination, rendered, nil)
guard CGImageDestinationFinalize(destination) else {
    throw ReviewSheetError.encodeFailed(outputURL)
}

print("Rendered NightBreath app icon review sheet to \(outputURL.path)")
