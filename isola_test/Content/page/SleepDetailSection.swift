// MARK: 睡眠資訊卡
import Charts
import SwiftUI

struct SleepDetailSection: View {
    let sessions: [SleepSession]

    private var latest: SleepSession? { sessions.last }

    var body: some View {
        VStack(spacing: 16) {
            if let s = latest {
                latestNightCard(s)
            }
            if sessions.count > 1 {
                weeklyTrendChart
            }
        }
    }

    private func latestNightCard(_ s: SleepSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("上一晚睡眠結構", systemImage: "moon.stars.fill")
                .font(.subheadline.weight(.semibold))

            stageBar(s)

            HStack(spacing: 0) {
                stagePill(color: .purple,  label: "REM",   mins: s.remMinutes)
                stagePill(color: .indigo,  label: "深眠",  mins: s.deepMinutes)
                stagePill(color: .blue,    label: "淺眠",  mins: s.lightMinutes)
                stagePill(color: .gray,    label: "清醒",  mins: s.awakeMinutes)
            }

            HStack {
                Spacer()
                Label(String(format: "睡眠效率 %.0f%%", s.efficiency), systemImage: "percent")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func stageBar(_ s: SleepSession) -> some View {
        let total = s.totalMinutes + s.awakeMinutes
        return GeometryReader { geo in
            HStack(spacing: 2) {
                bar(color: .purple, width: geo.size.width * s.remMinutes  / max(total, 1))
                bar(color: .indigo, width: geo.size.width * s.deepMinutes / max(total, 1))
                bar(color: .blue,   width: geo.size.width * s.lightMinutes / max(total, 1))
                bar(color: .gray,   width: geo.size.width * s.awakeMinutes / max(total, 1))
            }
        }
        .frame(height: 14)
    }

    private func bar(color: Color, width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color.opacity(0.8))
            .frame(width: max(width, 0))
    }

    private func stagePill(color: Color, label: String, mins: Double) -> some View {
        VStack(spacing: 2) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(String(format: "%.0f分", mins)).font(.caption.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
    }

    private var weeklyTrendChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("近 7 晚趨勢", systemImage: "chart.bar.fill")
                .font(.subheadline.weight(.semibold))
            Chart {
                ForEach(sessions.suffix(7)) { s in
                    BarMark(
                        x: .value("日期", s.date, unit: .day),
                        y: .value("小時", s.totalHours)
                    )
                    .foregroundStyle(Color(hue: 0.72, saturation: 0.6, brightness: 0.75))
                    .cornerRadius(4)
                }
                RuleMark(y: .value("建議", 8))
                    .foregroundStyle(.secondary.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks(values: .stride(by: 2)) { v in
                    AxisValueLabel { Text("\(v.as(Int.self) ?? 0)h").font(.caption2) }
                    AxisGridLine()
                }
            }
            .frame(height: 140)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
