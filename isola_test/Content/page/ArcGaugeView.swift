import SwiftUI

struct ArcGaugeView: View {
    let score: Double?
    let grade: GradeLevel?

    private let startAngle: Double = 150
    private let endAngle: Double   = 30      // clockwise past 360 → 390
    private let totalArc: Double   = 240     // degrees

    var body: some View {
     
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let lineWidth = size * 0.13

            ZStack {
                // Background track
                Circle()
                    .trim(from: 0, to: CGFloat(totalArc / 360))
                    .stroke(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(startAngle))

                // Filled arc
                if let s = score {
                    let fraction = CGFloat(s / 100) * CGFloat(totalArc / 360)
                    Circle()
                        .trim(from: 0, to: fraction)
                        .stroke(
                            grade?.color ?? .gray,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(startAngle))
                }

                // Labels
                VStack(spacing: 2) {
                    if let g = grade {
                        Text(g.label)
                            .font(.system(size: size * 0.18, weight: .semibold))
                            .foregroundStyle(g.color)
                    } else {
                        Text("—")
                            .font(.system(size: size * 0.18, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    if let s = score {
                        Text("\(Int(s.rounded()))")
                            .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary.opacity(0.75))
                    }
                }

            }
        }
    }
}
