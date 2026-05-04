import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct IconSlot {
    let idiom: String
    let size: String
    let scale: String
    let filename: String
    let pixels: Int
}

let slots: [IconSlot] = [
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

let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconSetURL = repositoryRoot
    .appendingPathComponent("SleepSoundApp/App/Assets.xcassets/AppIcon.appiconset", isDirectory: true)

try FileManager.default.createDirectory(at: iconSetURL, withIntermediateDirectories: true)

func rgba(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func point(_ x: CGFloat, _ y: CGFloat, scale: CGFloat) -> CGPoint {
    CGPoint(x: x * scale, y: y * scale)
}

func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, scale: CGFloat) -> CGRect {
    CGRect(x: x * scale, y: y * scale, width: width * scale, height: height * scale)
}

func drawEllipse(_ context: CGContext, _ rect: CGRect, color: CGColor) {
    context.setFillColor(color)
    context.fillEllipse(in: rect)
}

func strokePath(_ context: CGContext, path: CGPath, color: CGColor, lineWidth: CGFloat) {
    context.addPath(path)
    context.setStrokeColor(color)
    context.setLineWidth(lineWidth)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.strokePath()
}

func renderIcon(pixels: Int) throws -> CGImage {
    let side = CGFloat(pixels)
    let scale = side / 1024
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: pixels,
        height: pixels,
        bitsPerComponent: 8,
        bytesPerRow: pixels * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else {
        throw NSError(domain: "NightBreathAppIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create bitmap context"])
    }

    context.setShouldAntialias(true)
    context.setAllowsAntialiasing(true)
    context.interpolationQuality = .high

    let background = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            rgba(18, 51, 98),
            rgba(26, 106, 140),
            rgba(48, 167, 160),
            rgba(17, 68, 118),
        ] as CFArray,
        locations: [0.0, 0.42, 0.72, 1.0]
    )!
    context.drawLinearGradient(
        background,
        start: CGPoint(x: 0, y: side),
        end: CGPoint(x: side, y: 0),
        options: []
    )

    let tealGlow = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            rgba(130, 255, 237, 0.68),
            rgba(68, 211, 205, 0.0),
        ] as CFArray,
        locations: [0.0, 1.0]
    )!
    context.drawRadialGradient(
        tealGlow,
        startCenter: point(635, 345, scale: scale),
        startRadius: 22 * scale,
        endCenter: point(635, 345, scale: scale),
        endRadius: 420 * scale,
        options: [.drawsAfterEndLocation]
    )

    let moonGlow = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            rgba(255, 244, 197, 0.45),
            rgba(255, 231, 174, 0.0),
        ] as CFArray,
        locations: [0.0, 1.0]
    )!
    context.drawRadialGradient(
        moonGlow,
        startCenter: point(319, 705, scale: scale),
        startRadius: 18 * scale,
        endCenter: point(319, 705, scale: scale),
        endRadius: 250 * scale,
        options: [.drawsAfterEndLocation]
    )

    // Subtle shield silhouette: privacy without looking like a medical mark.
    let shield = CGMutablePath()
    shield.move(to: point(512, 205, scale: scale))
    shield.addCurve(
        to: point(724, 403, scale: scale),
        control1: point(650, 250, scale: scale),
        control2: point(724, 318, scale: scale)
    )
    shield.addCurve(
        to: point(512, 776, scale: scale),
        control1: point(721, 568, scale: scale),
        control2: point(623, 700, scale: scale)
    )
    shield.addCurve(
        to: point(300, 403, scale: scale),
        control1: point(401, 700, scale: scale),
        control2: point(303, 568, scale: scale)
    )
    shield.addCurve(
        to: point(512, 205, scale: scale),
        control1: point(300, 318, scale: scale),
        control2: point(374, 250, scale: scale)
    )
    shield.closeSubpath()
    context.addPath(shield)
    context.setFillColor(rgba(12, 41, 86, 0.24))
    context.fillPath()
    strokePath(context, path: shield, color: rgba(177, 255, 243, 0.34), lineWidth: 18 * scale)

    // Crescent moon.
    drawEllipse(context, rect(206, 575, 286, 286, scale: scale), color: rgba(255, 245, 202))
    drawEllipse(context, rect(314, 615, 275, 275, scale: scale), color: rgba(23, 83, 136))
    drawEllipse(context, rect(238, 625, 34, 34, scale: scale), color: rgba(255, 252, 224, 0.9))
    drawEllipse(context, rect(200, 526, 16, 16, scale: scale), color: rgba(210, 255, 248, 0.9))
    drawEllipse(context, rect(686, 740, 18, 18, scale: scale), color: rgba(255, 239, 191, 0.92))
    drawEllipse(context, rect(764, 612, 12, 12, scale: scale), color: rgba(212, 255, 248, 0.8))
    drawEllipse(context, rect(614, 830, 10, 10, scale: scale), color: rgba(255, 255, 255, 0.72))

    // Breathing rhythm: two calm sound waves, no clinical ECG sharpness.
    let shadowWave = CGMutablePath()
    shadowWave.move(to: point(204, 423, scale: scale))
    shadowWave.addCurve(
        to: point(410, 424, scale: scale),
        control1: point(284, 520, scale: scale),
        control2: point(327, 326, scale: scale)
    )
    shadowWave.addCurve(
        to: point(612, 424, scale: scale),
        control1: point(493, 522, scale: scale),
        control2: point(533, 326, scale: scale)
    )
    shadowWave.addCurve(
        to: point(820, 423, scale: scale),
        control1: point(689, 520, scale: scale),
        control2: point(740, 327, scale: scale)
    )
    strokePath(context, path: shadowWave, color: rgba(8, 29, 66, 0.42), lineWidth: 72 * scale)

    let mainWave = CGMutablePath()
    mainWave.move(to: point(204, 434, scale: scale))
    mainWave.addCurve(
        to: point(410, 435, scale: scale),
        control1: point(284, 526, scale: scale),
        control2: point(327, 342, scale: scale)
    )
    mainWave.addCurve(
        to: point(612, 435, scale: scale),
        control1: point(493, 526, scale: scale),
        control2: point(533, 342, scale: scale)
    )
    mainWave.addCurve(
        to: point(820, 434, scale: scale),
        control1: point(689, 526, scale: scale),
        control2: point(740, 342, scale: scale)
    )
    strokePath(context, path: mainWave, color: rgba(217, 255, 247), lineWidth: 52 * scale)

    let highlightWave = CGMutablePath()
    highlightWave.move(to: point(238, 479, scale: scale))
    highlightWave.addCurve(
        to: point(391, 479, scale: scale),
        control1: point(295, 538, scale: scale),
        control2: point(333, 420, scale: scale)
    )
    highlightWave.addCurve(
        to: point(543, 479, scale: scale),
        control1: point(450, 538, scale: scale),
        control2: point(488, 421, scale: scale)
    )
    strokePath(context, path: highlightWave, color: rgba(255, 226, 170, 0.86), lineWidth: 18 * scale)

    // Warm dawn dot: a small "morning report" cue.
    drawEllipse(context, rect(694, 280, 112, 112, scale: scale), color: rgba(255, 169, 119))
    drawEllipse(context, rect(722, 308, 56, 56, scale: scale), color: rgba(255, 232, 185, 0.9))

    // Fine vignette improves home-screen contrast after iOS corner masking.
    let vignette = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            rgba(0, 0, 0, 0.0),
            rgba(0, 0, 0, 0.16),
        ] as CFArray,
        locations: [0.62, 1.0]
    )!
    context.drawRadialGradient(
        vignette,
        startCenter: point(512, 512, scale: scale),
        startRadius: 260 * scale,
        endCenter: point(512, 512, scale: scale),
        endRadius: 720 * scale,
        options: [.drawsAfterEndLocation]
    )

    guard let image = context.makeImage() else {
        throw NSError(domain: "NightBreathAppIcon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to create CGImage"])
    }
    return image
}

func writePNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw NSError(domain: "NightBreathAppIcon", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to create PNG destination"])
    }

    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw NSError(domain: "NightBreathAppIcon", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unable to encode PNG"])
    }
}

for slot in slots {
    let image = try renderIcon(pixels: slot.pixels)
    try writePNG(image, to: iconSetURL.appendingPathComponent(slot.filename))
}

let imagesJSON = slots.map { slot -> [String: String] in
    [
        "filename": slot.filename,
        "idiom": slot.idiom,
        "scale": slot.scale,
        "size": slot.size,
    ]
}

let contents: [String: Any] = [
    "images": imagesJSON,
    "info": [
        "author": "xcode",
        "version": 1,
    ],
]

let jsonData = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
let jsonWithTrailingNewline = jsonData + Data("\n".utf8)
try jsonWithTrailingNewline.write(to: iconSetURL.appendingPathComponent("Contents.json"), options: [.atomic])

print("Generated \(slots.count) NightBreath app icon images in \(iconSetURL.path)")
