import SwiftUI

struct StressBannerView: View {
    let stressPercent: Double
    let label: String
    let hasData: Bool

    private var bannerColor: Color {
        switch stressPercent {
        case ..<30:  return Color(hue: 0.38, saturation: 0.6, brightness: 0.75)
        case ..<60:  return Color(hue: 0.13, saturation: 0.7, brightness: 0.85)
        case ..<80:  return Color(hue: 0.06, saturation: 0.8, brightness: 0.9)
        default:     return Color(hue: 0.00, saturation: 0.75, brightness: 0.85)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("今日壓力狀態", systemImage: "brain.head.profile")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                if hasData {
                    Text(label)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                }
            }

            if hasData {
                progressBar
                HStack {
                    Text("放鬆").font(.caption2).foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text(String(format: "%.0f%%", stressPercent))
                        .font(.caption.weight(.semibold)).foregroundStyle(.white)
                    Spacer()
                    Text("高壓").font(.caption2).foregroundStyle(.white.opacity(0.7))
                }
            } else {
                Text("尚無 HRV 資料，無法計算壓力指數")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(16)
        .background(bannerBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .animation(.easeInOut(duration: 0.6), value: stressPercent)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.25))
                Capsule()
                    .fill(.white.opacity(0.9))
                    .frame(width: max(8, geo.size.width * stressPercent / 100))
                    .animation(.easeInOut(duration: 0.8), value: stressPercent)
            }
        }
        .frame(height: 8)
    }

    private var bannerBackground: some View {
        ZStack {
            bannerColor
            LinearGradient(
                colors: [.white.opacity(0.12), .clear],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }
}
