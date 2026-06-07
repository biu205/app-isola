// MARK: 詳細圖表統計表
import Charts
import SwiftUI

struct FullChartView: View {
    let samples: [HealthSample]
    let metric: MetricType

    @State private var selectedSample: HealthSample?

    // 折線圖只顯示過去 24 小時
    private var displaySamples: [HealthSample] {
        guard metric.chartStyle == .line else { return samples }
        let cutoff = Date().addingTimeInterval(-86_400)
        let recent = samples.filter { $0.date >= cutoff }
        return recent.isEmpty ? samples : recent
    }

    private var avg: Double? {
        guard !displaySamples.isEmpty else { return nil }
        return displaySamples.map(\.value).reduce(0, +) / Double(displaySamples.count)
    }

    private var yDomain: ClosedRange<Double> {
        let values = displaySamples.map(\.value)
        guard let lo = values.min(), let hi = values.max() else { return 0...100 }
        let buffer = max((hi - lo) * 0.20, 1.0)
        return (lo - buffer)...(hi + buffer)
    }

    var body: some View {
        if metric.chartStyle == .bar {
            barChart
        } else {
            lineChart
        }
    }

    // MARK: 折線圖（含互動）
    private var lineChart: some View {
        Chart {
            ForEach(displaySamples) { s in
                AreaMark(
                    x: .value("時間", s.date),
                    y: .value("值", s.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [metric.color.opacity(0.3), .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            ForEach(displaySamples) { s in
                LineMark(
                    x: .value("時間", s.date),
                    y: .value("值", s.value)
                )
                .foregroundStyle(metric.color)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
            }
            // 選取指示器
            if let sel = selectedSample {
                RuleMark(x: .value("選取", sel.date))
                    .foregroundStyle(Color.primary.opacity(0.25))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    .annotation(
                        position: .top,
                        spacing: 6,
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                    ) {
                        selectionTooltip(sel, dateFormat: .dateTime.hour().minute())
                    }
                PointMark(
                    x: .value("時間", sel.date),
                    y: .value("值", sel.value)
                )
                .foregroundStyle(metric.color)
                .symbolSize(55)
            }
            if let a = avg {
                RuleMark(y: .value("平均", a))
                    .foregroundStyle(.secondary.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("均 \(metric.formatValue(a))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour().minute())
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                nearest(to: value.location, in: displaySamples, proxy: proxy, geo: geo)
                            }
                    )
            }
        }
    }

    private func selectionTooltip(_ sample: HealthSample, dateFormat: Date.FormatStyle) -> some View {
        VStack(spacing: 2) {
            Text(sample.date, format: dateFormat)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(metric.formatValue(sample.value)) \(metric.unit)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(metric.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
    }

    private func nearest(to location: CGPoint, in pool: [HealthSample], proxy: ChartProxy, geo: GeometryProxy) {
        let origin = geo[proxy.plotAreaFrame].origin
        let x = location.x - origin.x
        guard let date: Date = proxy.value(atX: x) else { return }
        selectedSample = pool.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }

    // MARK: 長條圖（含互動）
    private var barChart: some View {
        Chart {
            ForEach(samples) { s in
                BarMark(
                    x: .value("日期", s.date, unit: .day),
                    y: .value("值", s.value)
                )
                .foregroundStyle(
                    selectedSample?.id == s.id
                        ? metric.color
                        : metric.color.opacity(0.65)
                )
                .cornerRadius(5)
            }
            if let sel = selectedSample {
                RuleMark(x: .value("選取", sel.date, unit: .day))
                    .foregroundStyle(Color.primary.opacity(0.25))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    .annotation(
                        position: .top,
                        spacing: 6,
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                    ) {
                        selectionTooltip(sel, dateFormat: .dateTime.month().day())
                    }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                nearest(to: value.location, in: samples, proxy: proxy, geo: geo)
                            }
                    )
            }
        }
    }
}
