//
//  Island.swift
//  isola_test
//
//  Created by Qian Hsu on 2026/4/5.
//

import SwiftUI

// MARK: - ContentView
struct HomeView: View {
    @State private var isShowingQuestion = false
    @State private var isShowingSetting = false
    @State private var isHidingTopButtons = false
    @AppStorage("appearanceMode") private var appearanceMode: Int = AppTheme.system.rawValue
    // 讀取換裝頁儲存的 ID
    @AppStorage("selectedAccessoryID") private var selectedAccessoryID: Int = -1

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
                    isBlurred: isShowingQuestion,
                    theme: currentTheme,
                    onBottleTap: {
                        triggerHaptic(style: .medium)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isHidingTopButtons = true
                        }
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isShowingQuestion = true
                        }
                    },
                    onTrashTap: {
                        triggerHaptic(style: .light)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isHidingTopButtons = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isHidingTopButtons = false
                            }
                        }
                    }
                )
                
                // --- 新增：配件顯示圖層 ---
                // 這裡使用 GeometryReader 是為了獲取跟 Canvas 一樣的螢幕中心點
                if let accessory = selectedAccessory {
                    GeometryReader { proxy in
                        let centerX = proxy.size.width / 2
                        let centerY = proxy.size.height / 2
                        
                        Image("island方")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 295) // 這邊是改大小跟配件位置
                            .position(x: centerX, y: centerY)
                            // 利用 offset 微調配件在島嶼上的位置（例如往上移一點點掛在頭上）
                            .offset(x: 50, y: -19)
                            .blur(radius: isShowingQuestion ? 15 : 0)
                            .allowsHitTesting(false) // 讓配件不會擋住點擊事件
                        
                        Image(accessory.displayImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 295) // 這邊是改大小跟配件位置
                            .position(x: centerX, y: centerY)
                            // 利用 offset 微調配件在島嶼上的位置（例如往上移一點點掛在頭上）
                            .offset(x: 50, y: -19)
                            .blur(radius: isShowingQuestion ? 15 : 0)
                            .allowsHitTesting(false) // 讓配件不會擋住點擊事件
                    }
                }

                // 2. 中層：遮罩層
                if isShowingQuestion {
                    Color.black.opacity(0.15)
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismissKeyboard()
                        }
                    // ... (QuestionView 保持不變)
                    QuestionView(isPresented: $isShowingQuestion)
                        .transition(.asymmetric(insertion: .scale(scale: 0.9).combined(with: .opacity), removal: .opacity.combined(with: .scale(scale: 1.1))))
                        .zIndex(1)
                }

                // 上排按鈕們：點擊瓶子/垃圾罐時先隱藏
                Group {
                    if !isHidingTopButtons {
                        HStack(spacing: 16) {
                            NavigationLink(destination: Clothes()) {
                                Image("clothes").resizable().frame(width: 45, height: 45)
                            }
                            Button { isShowingSetting = true } label: {
                                Image("setting").resizable().frame(width: 45, height: 45).accentColor(.black)
                            }.accentColor(.black)
                        }
                        .transition(.opacity)
                    }
                }
                .padding(.top, 50)
                .padding(.trailing, 20)
            }
            .fullScreenCover(isPresented: $isShowingSetting) {
                SettingView()
            }
            .onChange(of: isShowingQuestion) { _, newValue in
                if !newValue {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHidingTopButtons = false
                    }
                }
            }
        }
    }
}
    // 觸覺反饋函數
    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }



// MARK: - 海洋動畫
struct SeaSceneView: View {
    let isBlurred: Bool
    let theme: AppTheme
    let onBottleTap: () -> Void
    let onTrashTap: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1 / 60)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let nightOpacity = theme.homeNightOverlayOpacity(at: timeline.date)

                // 1. 資源解析 (確保所有 Symbol 都已定義)
                guard let dayBackground = context.resolveSymbol(id: "bg-day"),
                    let nightBackground = context.resolveSymbol(id: "bg-night"),
                    let island = context.resolveSymbol(id: "island"),
                    let bottle = context.resolveSymbol(id: "bottle"),
                    let trashcan = context.resolveSymbol(id: "trashcan")
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
                drawWaveLayer(
                    context: context,
                    size: size,
                    time: time,
                    id: "sea",
                    speed: 70,
                    amp: 2,
                    freq: 1.5
                )
                drawWaveLayer(
                    context: context,
                    size: size,
                    time: time,
                    id: "dark",
                    speed: 60,
                    amp: 8,
                    freq: 1.2
                )
                drawWaveLayer(
                    context: context,
                    size: size,
                    time: time,
                    id: "light",
                    speed: 40,
                    amp: 3,
                    freq: 0.8
                )

                // --- 小島、瓶子、垃圾罐 ---

                // 小島
               // context.draw(island, at: CGPoint(x: centerX, y: midY))

                // 瓶子
                let bottleY = midY + 150 + sin(time * 1.3) * 10
                context.draw(
                    bottle,
                    at: CGPoint(x: centerX + 80, y: bottleY + 70)
                )

                // 垃圾桶
                let trashcanY = midY + 120 + sin(time * 1.1) * 10
                context.draw(
                    trashcan,
                    at: CGPoint(x: centerX - 100, y: trashcanY)
                )

            } symbols: {
                Image("background").tag("bg-day")
                Image("background-night").tag("bg-night")
                Image("sea").tag("sea")
                Image("dark").tag("dark")
                Image("light").tag("light")
                Image("island").tag("island")
                Image("bottle").resizable().frame(width: 180, height: 180).tag(
                    "bottle"
                )
                Image("trashcan").resizable().frame(width: 120, height: 120)
                    .tag("trashcan")
                Image("islandDry").tag("island")
            }
            .blur(radius: isBlurred ? 15 : 0)
            .ignoresSafeArea()
            .overlay {
                GeometryReader { proxy in
                    let cx = proxy.size.width / 2
                    let cy = proxy.size.height / 2

                    // 瓶子按鈕
                    Button(action: onBottleTap) { Color.black.opacity(0.001) }
                        .frame(width: 80, height: 95)
                        .position(x: cx + 80, y: cy + 205)

                    // 垃圾桶按鈕
                    Button(action: onTrashTap) { Color.black.opacity(0.001) }
                        .frame(width: 100, height: 70)
                        .position(x: cx - 100, y: cy + 120)

                }
            }
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
