import Foundation
import OfflineEvaluationSupport
import SleepSoundCore

@main
struct OfflineEvaluationCLI {
  static func main() {
    do {
      let options = try OfflineEvaluationOptions(
        arguments: Array(CommandLine.arguments.dropFirst()))
      let runner = OfflineEvaluationRunner()
      let result = try runner.evaluate(
        manifestURL: options.manifestURL,
        outputDirectory: options.outputDirectory,
        profiles: options.profiles
      )

      print("Offline Evaluation complete")
      if let validation = result.validation {
        print("manifest validation:")
        print("  valid segments: \(validation.validSegmentCount)/\(validation.totalSegments)")
        print("  missing files: \(validation.missingFiles.count)")
        print("  unsupported labels: \(validation.unsupportedLabels.count)")
        print("  license warnings: \(validation.licenseWarnings.count)")
        print("  missing required fields: \(validation.missingRequiredFields.count)")
        print("  invalid durations: \(validation.invalidDurations.count)")
        print("  field warnings: \(validation.fieldWarnings.count)")
      }
      print("evaluated segments: \(result.output.summary.evaluatedSegments)")
      print("evaluated records: \(result.output.summary.evaluatedRecords)")
      print("zero-event records: \(result.output.summary.zeroEventRecords)")
      print("failed records: \(result.output.summary.failedRecords)")
      print("snore candidates: \(result.output.summary.snoreCandidates)")
      print("final snore events: \(result.output.summary.finalSnoreEvents)")
      print("top reject reason: \(result.output.summary.topRejectReason ?? "none")")
      print("csv: \(result.csvURL.path)")
      print("json: \(result.jsonURL.path)")
    } catch {
      if let evaluationError = error as? OfflineEvaluationError {
        fputs("\(evaluationError.message)\n\n\(Self.usage)\n", stderr)
      } else {
        fputs("\(error.localizedDescription)\n\n\(Self.usage)\n", stderr)
      }
      exit(1)
    }
  }

  private static let usage = """
    Usage:
      swift run OfflineEvaluation --manifest Tools/OfflineEvaluation/sample_manifest.example.json --output Tools/OfflineEvaluation/output --profiles conservative,balanced,sensitive

    Notes:
      - 공개/개인 오디오 파일은 repository에 커밋하지 않습니다.
      - 공개 데이터셋은 자동 다운로드하지 않습니다.
      - 이 도구는 detector 개발용이며 의료 성능 검증 도구가 아닙니다.
    """
}

private struct OfflineEvaluationOptions {
  var manifestURL: URL
  var outputDirectory: URL
  var profiles: [DetectorTuningProfile]

  init(arguments: [String]) throws {
    var manifestPath: String?
    var outputPath = "Tools/OfflineEvaluation/output"
    var profileText = "conservative,balanced,sensitive"
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
      case "--profiles":
        index += 1
        profileText = index < arguments.count ? arguments[index] : profileText
      case "--help", "-h":
        throw OfflineEvaluationError.missingManifestPath
      default:
        break
      }
      index += 1
    }

    guard let manifestPath else {
      throw OfflineEvaluationError.missingManifestPath
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
