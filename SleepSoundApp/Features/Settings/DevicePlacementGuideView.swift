import SwiftUI

struct DevicePlacementGuideView: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.xLarge) {
        NBIllustration(kind: .devicePlacement)
          .frame(height: 170)
          .accessibilityLabel("침대 옆 iPhone 배치 안내 일러스트")

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
          title: "리포트 해석",
          message: "리포트는 감지된 소리 기반 지표를 보여주는 웰니스 참고 정보입니다.",
          systemImage: "info.circle"
        )
      }
      .padding(NBSpacing.large)
    }
    .navigationTitle("배치 가이드")
    .background(NBColor.pageBackground)
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
