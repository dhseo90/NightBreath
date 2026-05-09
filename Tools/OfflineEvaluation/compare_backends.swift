import Foundation
import OfflineEvaluationSupport
import SleepSoundCore

@main
struct OfflineBackendCompareCLI {
  static func main() {
    do {
      let options = try OfflineBackendCompareOptions(
        arguments: Array(CommandLine.arguments.dropFirst()))
      let runner = BackendComparisonRunner()
      let result = try runner.compare(
        manifestURL: options.manifestURL,
        outputDirectory: options.outputDirectory,
        profile: options.profile
      )

      print("Offline Backend Compare complete")
      print("profile: \(result.output.detectorProfile)")
      print("evaluated segments: \(result.output.summary.evaluatedSegments)")
      print("ruleOnly cases: \(result.output.summary.ruleOnlyCases)")
      print("mlOnly cases: \(result.output.summary.mlOnlyCases)")
      print("recommendation: \(result.output.summary.recommendedBackendForNextIteration)")
      print("csv: \(result.csvURL.path)")
      print("json: \(result.jsonURL.path)")
      print("report: \(result.markdownURL.path)")
    } catch {
      if let comparisonError = error as? BackendComparisonError {
        fputs("\(comparisonError.message)\n\n\(Self.usage)\n", stderr)
      } else if let evaluationError = error as? OfflineEvaluationError {
        fputs("\(evaluationError.message)\n\n\(Self.usage)\n", stderr)
      } else {
        fputs("\(error.localizedDescription)\n\n\(Self.usage)\n", stderr)
      }
      exit(1)
    }
  }

  private static let usage = """
    Usage:
      swift run OfflineBackendCompare --manifest Tools/OfflineEvaluation/sample_manifest.example.json --output Tools/OfflineEvaluation/output --profile balanced

    Notes:
      - 비교 backend는 ruleBased, coreML, hybrid로 고정됩니다.
      - 공개 오디오 파일은 기본 workflow에서 repository에 커밋하지 않습니다.
      - 공개 dataset을 포함 배포하는 경우 upstream license와 attribution을 유지합니다.
      - 개인 오디오 파일은 repository에 커밋하지 않습니다.
      - Core ML 모델이 없어도 crash하지 않고 unavailable/fallback 결과를 리포트합니다.
      - 이 도구는 detector 개발용이며 의료 성능 검증 도구가 아닙니다.
    """
}

private struct OfflineBackendCompareOptions {
  var manifestURL: URL
  var outputDirectory: URL
  var profile: DetectorTuningProfile

  init(arguments: [String]) throws {
    var manifestPath: String?
    var outputPath = "Tools/OfflineEvaluation/output"
    var profileText = DetectorTuningProfile.balanced.rawValue
    var index = 0

    while index < arguments.count {
      let argument = arguments[index]
      switch argument {
      case "--manifest":
        index += 1
        manifestPath = index < arguments.count ? arguments[index] : nil
      case "--output":
        index += 1
        outputPath = index < arguments.count ? arguments[index] : outputPath
      case "--profile":
        index += 1
        profileText = index < arguments.count ? arguments[index] : profileText
      case "--help", "-h":
        throw BackendComparisonError.missingManifestPath
      default:
        break
      }
      index += 1
    }

    guard let manifestPath else {
      throw BackendComparisonError.missingManifestPath
    }
    guard let parsedProfile = DetectorTuningProfile(rawValue: profileText) else {
      throw OfflineEvaluationError.invalidProfile(profileText)
    }

    manifestURL = Self.url(from: manifestPath)
    outputDirectory = Self.url(from: outputPath)
    profile = parsedProfile
  }

  private static func url(from path: String) -> URL {
    let expandedPath = NSString(string: path).expandingTildeInPath
    if expandedPath.hasPrefix("/") {
      return URL(fileURLWithPath: expandedPath)
    }
    return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      .appendingPathComponent(expandedPath)
      .standardizedFileURL
  }
}
