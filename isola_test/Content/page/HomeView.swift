//
//  Island.swift
//  isola_test
//
//  Created by Qian Hsu on 2026/4/5.
//
import SwiftUI


// MARK: - 活躍頁面狀態枚舉
enum ActiveSheet {
    case question      // bottle2 - 日常問答
    case introspection // bottle - 內省問答
    case freeNote      // 浮標 - 隨手日記
}


// MARK: - ContentView / HomeView
struct HomeView: View {
    @State private var activeSheet: ActiveSheet? = nil
    @State private var isHidingTopButtons = false
    @AppStorage("appearanceMode") private var appearanceMode: Int = AppTheme.system.rawValue
    // 讀取換裝頁儲存的 ID
    @AppStorage("selectedAccessoryID") private var selectedAccessoryID: Int = -1
    
    // 讀入問題庫
    @State private var questionManager = DailyQuestionManager()
    @Environment(\.modelContext) private var modelContext
    @State private var selectedQuestion: JournalQuestion?
    @State private var selectedIntrospectionQuestion: JournalQuestion?

    private var currentTheme: AppTheme {
        AppTheme(rawValue: appearanceMode) ?? .system
    }
    
    // 取得選中的配件資料
    private var selectedAccessory: Accessory? {
        accessoryData.first { $0.id == selectedAccessoryID }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                // 1. 最底層的海洋
                SeaSceneView(
                    isBlurred: activeSheet != nil,
                    theme: currentTheme
                )
                
                GeometryReader { proxy in
                    let cx = proxy.size.width / 2
                    let cy = proxy.size.height / 2

                    // 瓶子按鈕(日常問答) - bottle2
                    Button(action: {
                        triggerHaptic(style: .medium)
                        print("🟡 瓶子被點擊")
                        print("🟡 todayDailyQuestion = \(String(describing: questionManager.todayDailyQuestion))")
                        if let question = questionManager.todayDailyQuestion {
                            print("🟢 有題目，準備顯示")
                            self.selectedQuestion = question
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                self.activeSheet = .question
                            }
                            withAnimation(.easeInOut(duration: 0.2)) {
                                self.isHidingTopButtons = true
                            }
                        }
                        else{
                            print("🔴 沒有題目")
                        }
                    }) {
                        Color.black.opacity(0.0001)
                    }
                    .frame(width: 100, height: 105)
                    .position(x: cx + 110, y: cy + 240)

                    // 垃圾桶按鈕 - bottle（內省問答）
                    Button(action: {
                        triggerHaptic(style: .light)
                        print("🟡 垃圾桶被點擊")
                        print("🟡 todayIntrospectionQuestion = \(String(describing: questionManager.todayIntrospectionQuestion))")
                        if let question = questionManager.todayIntrospectionQuestion {
                            print("🟢 有題目，準備顯示")
                            self.selectedIntrospectionQuestion = question
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                self.activeSheet = .introspection
                            }
                            withAnimation(.easeInOut(duration: 0.2)) {
                                self.isHidingTopButtons = true
                            }
                        }
                        else{
                            print("🔴 沒有題目")
                        }
                    }) {
                        Color.black.opacity(0.0001)
                    }
                    .frame(width: 100, height: 100)
                    .position(x: cx - 50, y: cy + 210)
                    
                    // 浮標按鈕 - 隨手日記（不需要題目）
                    Button(action: {
                        triggerHaptic(style: .light)
                        print("🟡 浮標被點擊")
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            self.activeSheet = .freeNote
                        }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.isHidingTopButtons = true
                        }
                    }) {
                        Color.black.opacity(0.0001)
                    }
                    .frame(width: 70, height: 90)
                    .position(x: cx - 130, y: cy + 80)
                    
                }
                .ignoresSafeArea()
                
                
                
                // --- 新增：配件顯示圖層 ---
                // 這裡使用 GeometryReader 是為了獲取跟 Canvas 一樣的螢幕中心點
                // 1. 讓島嶼的圖片（度Ｑ）永遠顯示
                GeometryReader { proxy in
                    let centerX = proxy.size.width / 2
                    let centerY = proxy.size.height / 2
                    
                    Image("island方")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 295)
                        .position(x: centerX, y: centerY)
                        .offset(x: 50, y: -19)
                        .blur(radius: activeSheet != nil ? 15 : 0)
                        .allowsHitTesting(false)
                }
                .ignoresSafeArea(.keyboard)

                // 2. 只在有選擇配件時，才顯示配件圖層
                if let accessory = selectedAccessory {
                    GeometryReader { proxy in
                        let centerX = proxy.size.width / 2
                        let centerY = proxy.size.height / 2
                        
                        Image(accessory.displayImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 295)
                            .position(x: centerX, y: centerY)
                            .offset(x: 50, y: -19)
                            .blur(radius: activeSheet != nil ? 15 : 0)
                            .allowsHitTesting(false)
                    }
                    .ignoresSafeArea(.keyboard)
                }

                // 2. 中層：遮罩層 + 頁面顯示
                if let activeSheetType = activeSheet {
                    Color.black.opacity(0.15)
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismissKeyboard()
                        }
                    
                    // 根據 activeSheet 類型顯示不同的視圖
                    switch activeSheetType {
                    case .question:
                        if let question = selectedQuestion {
                            QuestionView(
                                activeSheet: $activeSheet,
                                question: question
                            )
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.9).combined(with: .opacity),
                                removal: .scale(scale: 1.1).combined(with: .opacity)
                            ))
                            .zIndex(1)
                        }
                    case .introspection:
                        if let question = selectedIntrospectionQuestion {
                            IntrospectionView(
                                activeSheet: $activeSheet,
                                question: question
                            )
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.9).combined(with: .opacity),
                                removal: .scale(scale: 1.1).combined(with: .opacity)
                            ))
                            .zIndex(1)
                        }
                    case .freeNote:
                        FreeNoteView(
                            activeSheet: $activeSheet
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                            removal: .scale(scale: 1.1).combined(with: .opacity)
                        ))
                        .zIndex(1)
                    }
                }

                // 上排按鈕們：點擊瓶子/垃圾罐時先隱藏
                Group {
                    if !isHidingTopButtons {
                        HStack(spacing: 8) {
                            NavigationLink(destination: Clothes()) {
                                Image("clothes").resizable().frame(width: 50, height: 50)
                            }
                            NavigationLink(destination: SettingView()) {
                                Image("setting").resizable().frame(width: 50, height: 50)
                            }
                        }
                        .transition(.opacity)
                    }
                }
                .padding(.top, 30)
                .padding(.trailing, 20)
                
                
            }
            .task {
                    await questionManager.initializeDailyQuestions(modelContext: modelContext)
                print("🔵 初始化完成")
                print("   todayDailyQuestion = \(String(describing: questionManager.todayDailyQuestion))")
                print("   todayIntrospectionQuestion = \(String(describing: questionManager.todayIntrospectionQuestion))")
                }
                }
            .onChange(of: activeSheet) { _, newValue in
                if newValue == nil {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHidingTopButtons = false
                    }
                }
            }
        }
    }


    // 觸覺反饋函數
    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }



// MARK: - 海洋動畫
struct SeaSceneView: View {
    let isBlurred: Bool
    let theme: AppTheme

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1 / 60)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let nightOpacity = theme.homeNightOverlayOpacity(at: timeline.date)

                // 1. 資源解析 (確保所有 Symbol 都已定義)
                guard let dayBackground = context.resolveSymbol(id: "bg-day"),
                    let nightBackground = context.resolveSymbol(id: "bg-night"),
                    let island = context.resolveSymbol(id: "island"),
                    let bottle2 = context.resolveSymbol(id: "bottle2"),
                    let bottle = context.resolveSymbol(id: "bottle")
                        
                else { return }

                let midY = size.height / 2
                let centerX = size.width / 2

                // --- 海 ---
                context.opacity = 1.0 - nightOpacity
                context.draw(dayBackground, at: CGPoint(x: centerX, y: midY))
                context.opacity = nightOpacity
                context.draw(nightBackground, at: CGPoint(x: centerX, y: midY))
                context.opacity = 1.0

                // --- 波浪 ---
                drawWaveLayer(context: context, size: size, time: time, id: "sea", speed: 70, amp: 2, freq: 1.5)
                drawWaveLayer(context: context, size: size, time: time, id: "dark", speed: 60, amp: 8, freq: 1.2)
                drawWaveLayer(context: context, size: size, time: time, id: "light", speed: 40, amp: 3, freq: 0.8)

                // --- 小島、瓶子、垃圾罐 ---

                // 瓶子 - bottle2
                let bottle2Y = midY + 150 + sin(time * 1.45) * 10
                context.draw(
                    bottle2,
                    at: CGPoint(x: centerX + 110, y: bottle2Y + 80)
                )

                // 垃圾桶 - bottle
                let bottleY = midY + 120 + sin(time * 1.3) * 10
                context.draw(
                    bottle,
                    at: CGPoint(x: centerX - 50, y: bottleY + 90)
                )
                
                // 浮標 - buoy
                let buoyY = midY + 120 + sin(time * 1.15) * 10
                if let buoy = context.resolveSymbol(id: "buoy") {
                    context.draw(
                        buoy,
                        at: CGPoint(x: centerX - 130, y: buoyY - 40)
                    )
                }

            } symbols: {
                Image("background").tag("bg-day")
                Image("background-night").tag("bg-night")
                Image("sea").tag("sea")
                Image("dark").tag("dark")
                Image("light").tag("light")
                Image("island").tag("island")
                Image("bottle2").resizable().frame(width: 120, height: 120).tag(
                    "bottle2"
                )
                Image("bottle").resizable().frame(width: 180, height: 180)
                    .tag("bottle")
                Image("浮標").resizable().frame(width: 120, height: 120).tag("buoy")
                Image("islandDry").tag("islandDry")
            }
            .blur(radius: isBlurred ? 15 : 0)
            .ignoresSafeArea()
        }
    }

    //海浪用函數
    private func drawWaveLayer(
        context: GraphicsContext,
        size: CGSize,
        time: Double,
        id: String,
        speed: CGFloat,
        amp: CGFloat,
        freq: CGFloat
    ) {
        guard let img = context.resolveSymbol(id: id) else { return }
        let imgW = img.size.width
        let offset = CGFloat(time * speed).truncatingRemainder(dividingBy: imgW)
        let waveY = sin(time * freq) * amp
        let yPos = (size.height / 2) + waveY

        context.draw(img, at: CGPoint(x: offset, y: yPos))
        context.draw(img, at: CGPoint(x: offset - imgW, y: yPos))
    }
}

//MARK: - 取消鍵盤函數
private func dismissKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )
}

//MARK: - Preview區塊
#Preview {
    HomeView()
}
