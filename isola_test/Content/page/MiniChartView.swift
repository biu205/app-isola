import Charts
import SwiftUI

struct MiniChartView: View {
    let samples: [HealthSample]
    let style: ChartStyle
    let color: Color

    private var recent: [HealthSample] { Array(samples.suffix(7)) }

    private var yDomain: ClosedRange<Double> {
        let values = recent.map(\.value)
        guard let lo = values.min(), let hi = values.max() else { return 0...100 }
        let buffer = max((hi - lo) * 0.20, 1.0)
        return (lo - buffer)...(hi + buffer)
    }

    var body: some View {
        if recent.isEmpty {
            Text("—")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if style == .bar {
            barChart
        } else {
            lineChart
        }
    }

    private var barChart: some View {
        Chart(recent) { s in
            BarMark(
                x: .value("t", s.date, unit: .day),
                y: .value("v", s.value)
            )
            .foregroundStyle(color.opacity(0.85))
            .cornerRadius(2)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartPlotStyle { $0.background(.clear) }
    }

    private var lineChart: some View {
        Chart(recent) { s in
            LineMark(
                x: .value("t", s.date),
                y: .value("v", s.value)
            )
            .foregroundStyle(color)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .interpolationMethod(.catmullRom)
        }
        .chartYScale(domain: yDomain)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartPlotStyle { $0.background(.clear) }
    }
}
