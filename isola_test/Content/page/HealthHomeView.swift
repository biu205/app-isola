import SwiftUI

struct HealthHomeView: View {
    @Environment(HealthDashboardViewModel.self) private var vm
    @AppStorage("appearanceMode") private var appearanceMode: Int = AppTheme.system.rawValue
    @State private var showAIConsentSheet = false
    private var currentTheme: AppTheme { AppTheme(rawValue: appearanceMode) ?? .system }
    private var isDark: Bool { currentTheme.colorScheme == .dark }
    private var pageBackground: Color { isDark ? Color(hex: "#151D2B") : Color(hex: "#FDFBF0") }

// MARK: - View
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if !vm.aiHealthConsentGiven {
                        aiConsentBanner
                    }
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
        .sheet(isPresented: $showAIConsentSheet) {
            aiConsentSheet
        }
    }
// MARK: - 隱私允許
    private var aiConsentBanner: some View {
        Button {
            showAIConsentSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("啟用 AI 健康建議")
                        .font(.subheadline.bold())
                    Text("允許將健康數據傳送給 Google Gemini 以生成建議")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var aiConsentSheet: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "brain.head.profile")
                .font(.system(size: 56))
                .foregroundColor(.accentColor)
            VStack(spacing: 10) {
                Text("AI 健康建議")
                    .font(.title2.bold())
                Text("isola 會將以下資訊傳送給 Google Gemini 以生成個人化建議：\n\n• 整體健康分數\n• HRV、靜息心率、血氧\n• 睡眠時數、今日步數\n\n這些資料不會儲存於 Google 的伺服器。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Spacer()
            VStack(spacing: 12) {
                Button {
                    vm.aiHealthConsentGiven = true
                    showAIConsentSheet = false
                    Task { await vm.generateAISuggestion() }
                } label: {
                    Text("允許並啟用")
                        .font(.body.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color.accentColor))
                }
                Button("不啟用") { showAIConsentSheet = false }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }


    // MARK: - 整體評分
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
                Text(":0")
                    .font(.system(size: 80))
            }

            if let score = overall.total {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(" ")
                    Text("\(Int(score.rounded()))")
                        .font(.system(size: 44, weight: .semibold, design: .rounded))
                    Text("分")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            if vm.isGeneratingAISuggestion {
                HStack(spacing: 6) {
                    ProgressView().scaleEffect(0.75)
                    Text("分析中…")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(vm.aiSuggestion ?? overall.feedbackText)
                    .font(.system(size: 16, weight: .semibold))
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

    // MARK: - 資訊卡

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
