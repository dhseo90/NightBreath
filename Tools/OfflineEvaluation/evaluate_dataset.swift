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
        profiles: options.profiles,
        backends: options.backends,
        checkpointEvery: options.checkpointEvery
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
      print("backends: \(options.backends.map(\.rawValue).joined(separator: ","))")
      print("zero-event records: \(result.output.summary.zeroEventRecords)")
      print("failed records: \(result.output.summary.failedRecords)")
      print("snore candidates: \(result.output.summary.snoreCandidates)")
      print("final snore events: \(result.output.summary.finalSnoreEvents)")
      print("top reject reason: \(result.output.summary.topRejectReason ?? "none")")
      if let checkpointEvery = options.checkpointEvery {
        print("checkpoint every: \(checkpointEvery) records")
        print("checkpoint csv: \(result.checkpointCSVURL?.path ?? "none")")
        print("checkpoint json: \(result.checkpointJSONURL?.path ?? "none")")
      }
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
      swift run OfflineEvaluation --manifest Tools/OfflineEvaluation/sample_manifest.example.json --output Tools/OfflineEvaluation/output --profiles verySensitive,sensitive,balanced,conservative,veryConservative --backends ruleBased,coreML,hybrid --checkpoint-every 50

    Notes:
      - 공개 오디오 파일은 기본 workflow에서 repository에 커밋하지 않습니다.
      - 공개 dataset을 포함 배포하는 경우 upstream license와 attribution을 유지합니다.
      - 개인 오디오 파일은 repository에 커밋하지 않습니다.
      - 공개 데이터셋은 자동 다운로드하지 않습니다.
      - 이 도구는 detector 개발용이며 의료 성능 검증 도구가 아닙니다.
    """
}

private struct OfflineEvaluationOptions {
  var manifestURL: URL
  var outputDirectory: URL
  var profiles: [DetectorTuningProfile]
  var backends: [SleepDetectionBackend]
  var checkpointEvery: Int?

  init(arguments: [String]) throws {
    var manifestPath: String?
    var outputPath = "Tools/OfflineEvaluation/output"
    var profileText = "verySensitive,sensitive,balanced,conservative,veryConservative"
    var backendText = "hybrid"
    var checkpointEvery: Int?
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
      case "--backends":
        index += 1
        backendText = index < arguments.count ? arguments[index] : backendText
      case "--checkpoint-every":
        index += 1
        if index < arguments.count,
           let parsedInterval = Int(arguments[index]),
           parsedInterval > 0 {
          checkpointEvery = parsedInterval
        }
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
    backends = try OfflineEvaluationRunner.parseBackends(backendText)
    self.checkpointEvery = checkpointEvery
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
