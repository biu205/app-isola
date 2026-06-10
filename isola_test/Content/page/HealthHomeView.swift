import SwiftUI

struct HealthHomeView: View {
    @Environment(HealthDashboardViewModel.self) private var vm
    @AppStorage("appearanceMode") private var appearanceMode: Int = AppTheme.system.rawValue
    private var currentTheme: AppTheme { AppTheme(rawValue: appearanceMode) ?? .system }
    private var isDark: Bool { currentTheme.colorScheme == .dark }
    private var pageBackground: Color { isDark ? Color(hex: "#151D2B") : Color(hex: "#FDFBF0") }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    overallSection
                    categorySection
                }
                .padding(.horizontal, 18)
                .padding(.top, 35)
                .padding(.bottom, 32)
            }
            .background(pageBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
            .refreshable { await vm.fetchAllData() }
            .overlay { if vm.isLoading { loadingOverlay } }
        }
        .background(pageBackground.ignoresSafeArea())
        .preferredColorScheme(currentTheme.colorScheme)
    }


    // MARK: - Overall section
    private var overallSection: some View {
        let overall = vm.overallScore
        return VStack(spacing: 6) {
            Spacer()
            
            if let imageName = overall.grade?.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 230, height: 180)
                    // .background(Color.black.opacity(0.9))
            } else {
                Text("🫀")
                    .font(.system(size: 80))
            }

            if let score = overall.total {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(" ")
                    Text("\(Int(score.rounded()))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text("分")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            if vm.isGeneratingAISuggestion {
                HStack(spacing: 6) {
                    ProgressView().scaleEffect(0.75)
                    Text("分析中…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(vm.aiSuggestion ?? overall.feedbackText)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .transition(.opacity)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 250)
        .background(pageBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Category cards

    private var categorySection: some View {
        VStack(spacing: 14) {
            ForEach(vm.categoryScores, id: \.type) { catScore in
                NavigationLink {
                    CategoryDetailView(category: catScore.type)
                        .environment(vm)
                } label: {
                    CategoryCardView(categoryScore: catScore)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Toolbar

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
}
