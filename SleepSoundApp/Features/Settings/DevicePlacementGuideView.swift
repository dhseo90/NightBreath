import SwiftUI

struct DevicePlacementGuideView: View {
    var body: some View {
        List {
            Section("권장 배치") {
                PlacementRow(systemImage: "iphone", title: "침대 옆 협탁", description: "마이크가 가려지지 않도록 화면이 위를 보게 둡니다.")
                PlacementRow(systemImage: "speaker.slash", title: "소음원과 거리 두기", description: "가습기, 선풍기, 충전기 소음과 너무 가깝지 않게 둡니다.")
                PlacementRow(systemImage: "battery.100", title: "전원 연결", description: "밤새 측정할 수 있도록 충전기에 연결합니다.")
            }

            Section("리포트 해석") {
                Text("리포트는 감지된 소리 기반 지표를 보여주는 웰니스 참고 정보입니다.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("배치 가이드")
    }
}

private struct PlacementRow: View {
    let systemImage: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.blue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
