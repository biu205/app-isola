// MARK: 詳細頁共用模板
import Charts
import SwiftUI

struct MetricDetailView: View {
    let metric: MetricType
    @Environment(HealthDashboardViewModel.self) private var vm

    private var samples: [HealthSample] { vm.samples(for: metric) }
    private var currentVal: Double?     { vm.currentValue(for: metric) }
    private var minVal: Double?  { samples.map(\.value).min() }
    private var maxVal: Double?  { samples.map(\.value).max() }
    private var avgVal: Double?  { samples.isEmpty ? nil : samples.map(\.value).reduce(0, +) / Double(samples.count) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                currentValueCard
                if !samples.isEmpty {
                    if metric == .sleep {
                        SleepDetailSection(sessions: vm.sleepSessions)
                    } else {
                        fullChartCard
                        statsRow
                    }
                } else {
                    noDataCard
                }
                FormulaCardView(info: metric.formulaInfo)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(metric.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var currentValueCard: some View {
        VStack(spacing: 8) {
            Image(systemName: metric.icon)
                .font(.system(size: 40))
                .foregroundStyle(metric.color)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if let v = currentVal {
                    Text(metric.formatValue(v))
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                } else {
                    Text("—")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Text(metric.unit)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .offset(y: -8)
            }
            Text(metric == .sleep ? "最近一晚" : "最新紀錄")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var fullChartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("過去紀錄", systemImage: "chart.xyaxis.line")
                .font(.subheadline.weight(.semibold))
            FullChartView(samples: samples, metric: metric)
                .frame(height: 180)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(label: "最小", value: minVal)
            Divider()
            statCell(label: "平均", value: avgVal)
            Divider()
            statCell(label: "最大", value: maxVal)
        }
        .frame(height: 70)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statCell(label: String, value: Double?) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let v = value {
                Text(metric.formatValue(v))
                    .font(.title3.weight(.semibold))
            } else {
                Text("—").font(.title3).foregroundStyle(.secondary)
            }
            Text(metric.unit)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var noDataCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("目前沒有「\(metric.displayName)」的資料")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
