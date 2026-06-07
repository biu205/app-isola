import SwiftUI

struct MetricCardView: View {
    let metric: MetricType
    let value: Double?
    let samples: [HealthSample]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            headerRow
            valueRow
            Spacer(minLength: 0)
            MiniChartView(
                samples: samples,
                style: metric.chartStyle,
                color: .white.opacity(0.9)
            )
            .frame(height: 44)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var headerRow: some View {
        HStack(spacing: 6) {
            Image(systemName: metric.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
            Text(metric.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
        }
    }

    private var valueRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            if let v = value {
                Text(metric.formatValue(v))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            } else {
                Text("—")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Text(metric.unit)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.white.opacity(0.7))
                .offset(y: -2)
        }
    }

    private var cardBackground: some View {
        ZStack {
            metric.color
            LinearGradient(
                colors: [.white.opacity(0.15), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
