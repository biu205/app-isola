import SwiftUI

struct DashboardView: View {
    @Environment(HealthDashboardViewModel.self) private var vm

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    dateHeader
                    StressBannerView(
                        stressPercent: vm.stressPercent,
                        label: vm.stressLabel,
                        hasData: vm.currentHRV != nil
                    )
                    metricGrid
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("健康總覽")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarItems }
            .refreshable { await vm.fetchAllData() }
            .overlay { if vm.isLoading { loadingOverlay } }
        }
    }

    private var dateHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.title3.weight(.semibold))
                Text(Date(), format: .dateTime.year().month().day().weekday(.wide))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "heart.fill")
                .font(.title2)
                .foregroundStyle(.red.opacity(0.8))
        }
        .padding(.top, 4)
    }

    private var metricGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(MetricType.allCases) { metric in
                NavigationLink {
                    MetricDetailView(metric: metric)
                        .environment(vm)
                } label: {
                    MetricCardView(
                        metric: metric,
                        value: vm.currentValue(for: metric),
                        samples: vm.samples(for: metric)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if vm.isAuthorized {
                Button {
                    Task { await vm.fetchAllData() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            } else {
                Button("授權 HealthKit") {
                    vm.requestAuthorization()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.15).ignoresSafeArea()
            ProgressView("讀取中…")
                .padding(20)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "早安 ☀️"
        case 12..<17: return "午安 🌤"
        case 17..<21: return "晚安 🌙"
        default:      return "深夜好 🌟"
        }
    }
}
