import Foundation
import OfflineEvaluationSupport
import SleepSoundCore

@main
struct SnoreBaselineEvaluationCLI {
  static func main() {
    do {
      let options = try SnoreBaselineOptions(arguments: Array(CommandLine.arguments.dropFirst()))
      let runner = SnoreBaselineEvaluationRunner()
      let result = try runner.evaluate(
        manifestURL: options.manifestURL,
        outputDirectory: options.outputDirectory,
        profiles: options.profiles
      )

      print("Snore baseline evaluation complete")
      print("evaluated segments: \(result.output.summary.evaluatedSegments)")
      print("evaluated records: \(result.output.summary.evaluatedRecords)")
      print("failed records: \(result.output.summary.failedRecords)")
      print("possible false-positive-like cases: \(result.output.summary.possibleFalsePositiveCount)")
      print("possible false-negative-like cases: \(result.output.summary.possibleFalseNegativeCount)")
      print("manifest missing files: \(result.output.summary.manifestValidation.missingFiles)")
      print("manifest unsupported labels: \(result.output.summary.manifestValidation.unsupportedLabels)")
      for summary in result.output.summary.profileSummaries {
        print(
          "profile \(summary.detectorProfile): finalSnore=\(summary.finalSnoreEventCount), zeroEvent=\(summary.zeroEventCount), fpLike=\(summary.possibleFalsePositiveCount), fnLike=\(summary.possibleFalseNegativeCount)"
        )
      }
      print("csv: \(result.csvURL.path)")
      print("json: \(result.jsonURL.path)")
      print("report: \(result.markdownURL.path)")
    } catch {
      if let baselineError = error as? SnoreBaselineEvaluationError {
        fputs("\(baselineError.message)\n\n\(Self.usage)\n", stderr)
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
      swift run OfflineSnoreBaseline --manifest Tools/OfflineEvaluation/sample_manifest.example.json --output Tools/OfflineEvaluation/output --profiles verySensitive,sensitive,balanced,conservative,veryConservative

    Options:
      --manifest PATH     Dataset manifest JSON path.
      --output PATH       Output directory. Default: Tools/OfflineEvaluation/output
      --profiles LIST     Comma-separated profiles: verySensitive,sensitive,balanced,conservative,veryConservative
      --profile NAME      Single profile alias for --profiles.

    No data / missing manifest:
      - 공개 데이터셋은 자동 다운로드하지 않습니다.
      - 오디오 파일은 repo 밖 또는 gitignore된 Datasets/ 아래에 직접 준비하세요.
      - synthetic 확인은 sample manifest를 복사한 뒤 localFilePath를 직접 만든 짧은 WAV/CAF 파일로 바꿔 실행하세요.
      - 이 baseline은 detector 개발용이며 의료 성능 검증이 아닙니다.
    """
}

private struct SnoreBaselineOptions {
  var manifestURL: URL
  var outputDirectory: URL
  var profiles: [DetectorTuningProfile]

  init(arguments: [String]) throws {
    var manifestPath: String?
    var outputPath = "Tools/OfflineEvaluation/output"
    var profileText = "verySensitive,sensitive,balanced,conservative,veryConservative"
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
      case "--profiles", "--profile":
        index += 1
        profileText = index < arguments.count ? arguments[index] : profileText
      case "--help", "-h":
        throw SnoreBaselineEvaluationError.missingManifestPath
      default:
        break
      }
      index += 1
    }

    guard let manifestPath else {
      throw SnoreBaselineEvaluationError.missingManifestPath
    }

    manifestURL = Self.url(from: manifestPath)
    outputDirectory = Self.url(from: outputPath)
    profiles = try OfflineEvaluationRunner.parseProfiles(profileText)
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
