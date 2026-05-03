import SwiftUI

struct DevicePlacementGuideView: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.xLarge) {
        NBReportSection(title: "권장 배치", systemImage: "iphone") {
          VStack(spacing: NBSpacing.medium) {
            PlacementRow(
              systemImage: "iphone", title: "침대 옆 협탁", description: "마이크가 가려지지 않도록 화면이 위를 보게 둡니다.")
            PlacementRow(
              systemImage: "speaker.slash", title: "소음원과 거리 두기",
              description: "가습기, 선풍기, 충전기 소음과 너무 가깝지 않게 둡니다.")
            PlacementRow(
              systemImage: "battery.100", title: "전원 연결", description: "밤새 측정할 수 있도록 충전기에 연결합니다.")
          }
        }

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
