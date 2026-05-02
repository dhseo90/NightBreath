// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NightBreath",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "SleepSoundCore", targets: ["SleepSoundCore"])
    ],
    targets: [
        .target(
            name: "SleepSoundCore",
            path: "SleepSoundApp/Core"
        ),
        .testTarget(
            name: "SleepSoundCoreTests",
            dependencies: ["SleepSoundCore"],
            path: "Tests",
            swiftSettings: [
                .unsafeFlags([
                    "-F",
                    "/Library/Developer/CommandLineTools/Library/Developer/Frameworks"
                ])
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-F",
                    "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                    "-Xlinker",
                    "-rpath",
                    "-Xlinker",
                    "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                    "-Xlinker",
                    "-rpath",
                    "-Xlinker",
                    "/Library/Developer/CommandLineTools/Library/Developer/usr/lib",
                    "-framework",
                    "Testing"
                ])
            ]
        )
    ]
)
