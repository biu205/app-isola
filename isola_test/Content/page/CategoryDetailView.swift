import Charts
import SwiftUI

struct CategoryDetailView: View {
    let category: HealthCategoryType
    @Environment(HealthDashboardViewModel.self) private var vm
    @AppStorage("appearanceMode") private var appearanceMode: Int = AppTheme.system.rawValue

    private var isDark: Bool {
        let theme = AppTheme(rawValue: appearanceMode) ?? .system
        return theme.colorScheme == .dark
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                scoreCard
                ForEach(category.metrics, id: \.self) { metric in
                    metricCard(metric)
                }

            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(category.backgroundColor(isDark: isDark))
        .navigationTitle(category.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Score summary card

    private var scoreCard: some View {
        let catScore = vm.categoryScores.first { $0.type == category }
        return HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(category.subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.black.opacity(0.85))

                if let score = catScore?.score {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(score.rounded()))")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.black.opacity(0.9))

                        Text("分")
                            .font(.title3)
                            .foregroundStyle(Color.black.opacity(0.85))
                    }
                } else {
                    Text("資料不足")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            ArcGaugeView(score: catScore?.score, grade: catScore?.grade)
                .frame(width: 90, height: 90)
                .foregroundStyle(Color.black.opacity(0.9))

        }
        .padding(20)
        .background(category.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Per-metric chart card

    private func metricCard(_ metric: MetricType) -> some View {
        let samples = vm.samples(for: metric)
        let current = vm.currentValue(for: metric)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(metric.displayName, systemImage: metric.icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(metric.color)
                Spacer()
                if let v = current {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(metric.formatValue(v))
                            .font(.title3.weight(.bold))
                        Text(metric.unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("—")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            if metric == .sleep {
                SleepDetailSection(sessions: vm.sleepSessions)
            } else if !samples.isEmpty {
                FullChartView(samples: samples, metric: metric)
                    .frame(height: 160)
            } else {
                Text("目前沒有資料")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
