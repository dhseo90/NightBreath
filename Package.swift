// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "NightBreath",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
  ],
  products: [
    .library(name: "SleepSoundCore", targets: ["SleepSoundCore"]),
    .executable(name: "OfflineEvaluation", targets: ["OfflineEvaluation"]),
    .executable(name: "OfflineProfileCompare", targets: ["OfflineProfileCompare"]),
  ],
  targets: [
    .target(
      name: "SleepSoundCore",
      path: "SleepSoundApp/Core"
    ),
    .target(
      name: "OfflineEvaluationSupport",
      dependencies: ["SleepSoundCore"],
      path: "Tools/OfflineEvaluation/Support"
    ),
    .executableTarget(
      name: "OfflineEvaluation",
      dependencies: ["OfflineEvaluationSupport"],
      path: "Tools/OfflineEvaluation",
      exclude: [
        "README.md",
        "sample_manifest.example.json",
        "output",
        "Support",
        "compare_profiles.swift",
      ],
      sources: ["evaluate_dataset.swift"]
    ),
    .executableTarget(
      name: "OfflineProfileCompare",
      dependencies: ["OfflineEvaluationSupport"],
      path: "Tools/OfflineEvaluation",
      exclude: [
        "README.md",
        "sample_manifest.example.json",
        "output",
        "Support",
        "evaluate_dataset.swift",
      ],
      sources: ["compare_profiles.swift"]
    ),
    .testTarget(
      name: "SleepSoundCoreTests",
      dependencies: [
        "SleepSoundCore",
        "OfflineEvaluationSupport",
      ],
      path: "Tests",
      swiftSettings: [
        .unsafeFlags([
          "-F",
          "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
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
          "Testing",
        ])
      ]
    ),
  ]
)
