import SwiftUI

enum DailyRhythmUI {
  static func dataQualityStatus(_ quality: DailyDataQuality) -> NBStatusKind {
    switch quality {
    case .excellent, .good:
      .good
    case .limited:
      .caution
    case .poor:
      .warning
    case .insufficient:
      .danger
    }
  }

  static func scoreTint(_ score: Int) -> Color {
    switch score {
    case 85...100:
      NBColor.success
    case 70..<85:
      NBColor.accent
    case 55..<70:
      NBColor.warning
    default:
      NBColor.danger
    }
  }

  static func insightStatus(_ severity: DailyInsightSeverity) -> NBStatusKind {
    switch severity {
    case .positive:
      .good
    case .caution:
      .caution
    case .neutral:
      .neutral
    }
  }

  static func icon(for insightType: DailyInsightType) -> String {
    switch insightType {
    case .sleep:
      "moon.zzz"
    case .recovery:
      "sunrise"
    case .activity:
      "figure.walk"
    case .bloodPressure:
      "heart"
    case .bodyComposition:
      "scalemass"
    case .lifestyle:
      "tag"
    case .dataQuality:
      "checkmark.seal"
    }
  }

  static func icon(for metricType: HealthMetricType?) -> String {
    guard let metricType else { return "sparkles" }

    return switch metricType {
    case .systolicBloodPressure, .diastolicBloodPressure:
      "heart"
    case .bodyMass:
      "scalemass"
    case .bodyFatPercentage:
      "percent"
    case .bodyMassIndex:
      "figure"
    case .leanBodyMass:
      "figure.strengthtraining.traditional"
    case .stepCount:
      "figure.walk"
    case .activeEnergy:
      "flame"
    case .heartRate, .restingHeartRate:
      "heart.fill"
    case .sleepDuration:
      "bed.double"
    case .respiratoryRate:
      "lungs"
    }
  }

  static func tint(for metricType: HealthMetricType?) -> Color {
    guard let metricType else { return NBColor.accent }

    return switch metricType {
    case .systolicBloodPressure:
      NBColor.danger
    case .diastolicBloodPressure:
      NBColor.warning
    case .bodyMass:
      NBColor.breathBlue
    case .bodyFatPercentage:
      NBColor.mistTeal
    case .bodyMassIndex:
      NBColor.lavender
    case .leanBodyMass:
      NBColor.quietIndigo
    case .stepCount:
      NBColor.mistTeal
    case .activeEnergy:
      NBColor.warning
    case .heartRate, .restingHeartRate:
      NBColor.danger
    case .sleepDuration:
      NBColor.sleepTint
    case .respiratoryRate:
      NBColor.audioTint
    }
  }

  static func measurementQualityStatus(_ quality: MeasurementQuality) -> NBStatusKind {
    switch quality {
    case .excellent, .good:
      .good
    case .limited:
      .caution
    case .poor:
      .danger
    }
  }

  static func valueString(_ value: Double, unit: String) -> String {
    switch unit {
    case "mmHg", "bpm", "kcal":
      "\(Int(value.rounded())) \(unit)"
    case "걸음":
      "\(Int(value.rounded()).formatted())걸음"
    case "BMI":
      String(format: "%.1f", value)
    case "시간":
      String(format: "%.1f시간", value)
    case "%":
      String(format: "%.1f%%", value)
    default:
      String(format: "%.1f %@", value, unit)
    }
  }
}

struct DailyRhythmScoreRing: View {
  let score: Int
  var title: String = "오늘의 리듬 점수"
  var tint: Color?

  var body: some View {
    ZStack {
      Circle()
        .stroke(NBColor.cardStroke.opacity(0.55), lineWidth: 12)
      Circle()
        .trim(from: 0, to: CGFloat(DailyRhythmScore.clampedScore(score)) / 100)
        .stroke(tint ?? DailyRhythmUI.scoreTint(score), style: StrokeStyle(lineWidth: 12, lineCap: .round))
        .rotationEffect(.degrees(-90))
      VStack(spacing: 2) {
        Text("\(DailyRhythmScore.clampedScore(score))")
          .font(.system(size: 34, weight: .bold, design: .rounded))
          .monospacedDigit()
        Text("/100")
          .font(NBTypography.caption)
          .foregroundStyle(NBColor.secondaryText)
      }
    }
    .frame(width: 116, height: 116)
    .accessibilityLabel("\(title) \(score)점")
  }
}

struct DailyRhythmDataReadinessSection: View {
  let summary: DailyRhythmDataReadinessSummary
  var title: String = "데이터 준비 상태"

  var body: some View {
    NBReportSection(title: title, systemImage: "checklist.checked") {
      VStack(alignment: .leading, spacing: NBSpacing.md) {
        VStack(alignment: .leading, spacing: NBSpacing.xs) {
          Text(summary.title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(NBColor.primaryText)
            .fixedSize(horizontal: false, vertical: true)

          Text(summary.message)
            .font(NBTypography.caption)
            .foregroundStyle(NBColor.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
        }

        ViewThatFits(in: .horizontal) {
          HStack(spacing: NBSpacing.xs) {
            readinessBadges
          }
          VStack(alignment: .leading, spacing: NBSpacing.xs) {
            readinessBadges
          }
        }

        NBListRow(
          title: "준비된 입력",
          value: "\(summary.includedSignalCount)개",
          subtitle: summary.availableText,
          systemImage: "checkmark.circle",
          tint: NBColor.success
        )
        NBListRow(
          title: "제한 항목",
          value: "\(summary.missingSignalCount)개",
          subtitle: summary.missingText,
          systemImage: "exclamationmark.circle",
          tint: summary.missingSignalCount == 0 ? NBColor.neutral : NBColor.warning
        )
      }
    }
  }

  @ViewBuilder
  private var readinessBadges: some View {
    NBStatusBadge(
      "품질 \(summary.quality.displayName)",
      kind: DailyRhythmUI.dataQualityStatus(summary.quality),
      systemImage: "checkmark.seal"
    )
    NBStatusBadge(
      "완성도 \(summary.completenessPercentText)",
      kind: .neutral,
      systemImage: "chart.pie"
    )
  }
}
