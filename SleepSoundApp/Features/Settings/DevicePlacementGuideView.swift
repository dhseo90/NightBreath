import SwiftUI

struct DevicePlacementGuideView: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        headerCard

        NBReportSection(title: "권장 배치", systemImage: "iphone") {
          VStack(spacing: NBSpacing.medium) {
            PlacementRow(
              systemImage: "table.furniture",
              title: "침대 옆 탁자 또는 머리맡 근처",
              description: "수면 중 나는 소리를 받을 수 있도록 머리맡에서 너무 멀지 않은 안정적인 위치에 둡니다."
            )
            PlacementRow(
              systemImage: "mic",
              title: "마이크가 막히지 않게 하기",
              description: "이불, 베개, 케이스, 책이 마이크를 덮지 않게 하고 화면이 위를 보게 둡니다."
            )
            PlacementRow(
              systemImage: "battery.100",
              title: "충전 연결 권장",
              description: "밤새 측정이 끊기지 않도록 충전기에 연결해 둡니다."
            )
            PlacementRow(
              systemImage: "battery.25",
              title: "저전력 모드 확인",
              description: "측정 전 배터리와 저전력 모드 상태를 확인하면 백그라운드 측정 흐름을 더 안정적으로 유지하는 데 도움이 됩니다."
            )
            PlacementRow(
              systemImage: "shippingbox",
              title: "멀거나 밀폐된 위치 피하기",
              description: "서랍, 가방, 두꺼운 책 아래, 방 반대편처럼 소리가 막히거나 너무 먼 위치는 피합니다."
            )
            PlacementRow(
              systemImage: "speaker.slash",
              title: "지속 소음원과 거리 두기",
              description: "선풍기, 가습기, 충전기 소음과 너무 가깝지 않게 둡니다."
            )
          }
        }

        NavigationLink {
          CalibrationView()
        } label: {
          Label("30초 캘리브레이션 실행", systemImage: "waveform.badge.magnifyingglass")
        }
        .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.audioTint))

        NBPrivacyNoticeCard(
          title: "배치와 개인정보",
          messages: [
            "정확한 측정을 위해 권장 배치를 안내합니다.",
            "분석은 iPhone 안에서 수행됩니다.",
            "원본 전체 오디오는 저장하지 않습니다.",
            "서버로 전송하지 않습니다.",
          ],
          systemImage: "info.circle"
        )
      }
      .padding(.horizontal, NBSpacing.screenHorizontal)
      .padding(.vertical, NBSpacing.sectionVertical)
    }
    .navigationTitle("배치 가이드")
    .background(NBColor.pageBackground)
    .toolbar(.hidden, for: .tabBar)
  }

  private var headerCard: some View {
    NBCard(background: NBColor.sleep.opacity(0.08), stroke: NBColor.sleep.opacity(0.18)) {
      HStack(alignment: .center, spacing: NBSpacing.lg) {
        NBIllustration(kind: .devicePlacement)
          .frame(width: 132, height: 86)
          .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: NBSpacing.sm) {
          HStack(spacing: NBSpacing.xs) {
            NBStatusBadge("권장 배치", kind: .neutral, systemImage: "iphone")
            NBStatusBadge("충전 권장", kind: .privacy, systemImage: "battery.100")
          }

          Text("iPhone을 머리맡 가까이에 두세요")
            .font(NBTypography.title)
            .foregroundStyle(NBColor.primaryText)
            .fixedSize(horizontal: false, vertical: true)

          Text("수면 중 소리 기반 지표를 안정적으로 기록하기 위한 배치 안내입니다.")
            .font(NBTypography.body)
            .foregroundStyle(NBColor.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("배치 가이드, iPhone을 머리맡 가까이에 두기")
  }
}

private struct PlacementRow: View {
  let systemImage: String
  let title: String
  let description: String

  var body: some View {
    NBListRow(
      title: title,
      subtitle: description,
      systemImage: systemImage,
      tint: NBColor.sleepTint
    )
  }
}
