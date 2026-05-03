import Foundation
import OfflineEvaluationSupport

@main
struct OfflineProfileCompareCLI {
  static func main() {
    do {
      let options = try OfflineProfileCompareOptions(
        arguments: Array(CommandLine.arguments.dropFirst()))
      let runner = OfflineProfileComparisonRunner()
      let result = try runner.compare(
        evaluationJSONURLs: options.inputURLs,
        outputDirectory: options.outputDirectory
      )

      print("Offline Profile Compare complete")
      print("profiles: \(result.comparison.profileSummaries.map(\.tuningProfile).joined(separator: ","))")
      print("label findings: \(result.comparison.labelFindings.count)")
      print("suggested changes: \(result.comparison.suggestedChanges.changes.count)")
      print("auto applied: \(result.comparison.suggestedChanges.autoApplied)")
      print("report: \(result.reportURL.path)")
      print("suggested changes json: \(result.suggestedChangesURL.path)")
    } catch {
      if let comparisonError = error as? OfflineProfileComparisonError {
        fputs("\(comparisonError.message)\n\n\(Self.usage)\n", stderr)
      } else {
        fputs("\(error.localizedDescription)\n\n\(Self.usage)\n", stderr)
      }
      exit(1)
    }
  }

  private static let usage = """
    Usage:
      swift run OfflineProfileCompare --input Tools/OfflineEvaluation/output/offline_evaluation_YYYYMMDD_HHMMSS.json --output Tools/OfflineEvaluation/output
      swift run OfflineProfileCompare --inputs file1.json,file2.json --output Tools/OfflineEvaluation/output

    Notes:
      - threshold는 자동으로 변경하지 않습니다.
      - suggested_changes.json은 수동 검토용입니다.
      - 공개/개인 오디오 파일은 repository에 커밋하지 않습니다.
      - 이 도구는 detector 개발용이며 의료 성능 검증 도구가 아닙니다.
    """
}

private struct OfflineProfileCompareOptions {
  var inputURLs: [URL]
  var outputDirectory: URL

  init(arguments: [String]) throws {
    var inputPaths: [String] = []
    var outputPath = "Tools/OfflineEvaluation/output"
    var index = 0

    while index < arguments.count {
      let argument = arguments[index]
      switch argument {
      case "--input":
        index += 1
        if index < arguments.count {
          inputPaths.append(arguments[index])
        }
      case "--inputs":
        index += 1
        if index < arguments.count {
          inputPaths.append(contentsOf: arguments[index].split(separator: ",").map(String.init))
        }
      case "--output":
        index += 1
        outputPath = index < arguments.count ? arguments[index] : outputPath
      case "--help", "-h":
        throw OfflineProfileComparisonError.missingInput
      default:
        break
      }
      index += 1
    }

    let cleanedInputPaths = inputPaths
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
    guard !cleanedInputPaths.isEmpty else {
      throw OfflineProfileComparisonError.missingInput
    }

    inputURLs = cleanedInputPaths.map(Self.url)
    outputDirectory = Self.url(from: outputPath)
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
