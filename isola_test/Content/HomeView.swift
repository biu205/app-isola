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

    var body: some View {
        ZStack {
            // 1. 最底層的海洋
            SeaSceneView(isBlurred: isShowingQuestion) {
                // 瓶子點擊後的動作
                triggerHaptic(style: .medium)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isShowingQuestion = true
                }
            }
            
            // 2. 中層：遮罩層 (僅在視窗顯示時出現)
            if isShowingQuestion {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissKeyboard()
                    }
                
                // 3. 上層：問題視窗 (情緒入口)
                QuestionView(isPresented: $isShowingQuestion)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .opacity.combined(with: .scale(scale: 1.1))
                    ))
                    .zIndex(1)
            }
        }
    }
    
    // 觸覺反饋函數
    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
}

// MARK: - 海洋動畫
struct SeaSceneView: View {
    let isBlurred: Bool
    let onBottleTap: () -> Void
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1/60)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                // 1. 資源解析 (確保所有 Symbol 都已定義)
                guard let background = context.resolveSymbol(id: "bg"),
                      let island = context.resolveSymbol(id: "island"),
                      let bottle = context.resolveSymbol(id: "bottle"),
                      let trashcan = context.resolveSymbol(id: "trashcan")
                else { return }
                
                let midY = size.height / 2
                let centerX = size.width / 2
                
                // --- 海 ---
                context.draw(background, at: CGPoint(x: centerX, y: midY))
                
                // --- 波浪 ---
                drawWaveLayer(context: context, size: size, time: time, id: "sea", speed: 70, amp: 2, freq: 1.5)
                drawWaveLayer(context: context, size: size, time: time, id: "dark", speed: 60, amp: 8, freq: 1.2)
                drawWaveLayer(context: context, size: size, time: time, id: "light", speed: 40, amp: 3, freq: 0.8)
                
                // --- 小島、瓶子、垃圾罐 ---
                
                // 小島
                context.draw(island, at: CGPoint(x: centerX, y: midY))
                
                // 瓶子
                let bottleY = midY + 150 + sin(time * 1.3) * 10
                context.draw(bottle, at: CGPoint(x: centerX + 80, y: bottleY + 70))
                
                // 垃圾桶
                let trashcanY = midY + 120 + sin(time * 1.1) * 10
                context.draw(trashcan, at: CGPoint(x: centerX - 100, y: trashcanY))
                
            } symbols: {
                Image("background").tag("bg")
                Image("sea").tag("sea")
                Image("dark").tag("dark")
                Image("light").tag("light")
                Image("island").tag("island")
                Image("bottle").resizable().frame(width: 180, height: 180).tag("bottle")
                Image("trashcan").resizable().frame(width: 120, height: 120).tag("trashcan")
            }
            .blur(radius: isBlurred ? 15 : 0)
            .ignoresSafeArea()
            .overlay {
                GeometryReader { proxy in
                    let cx = proxy.size.width / 2
                    let cy = proxy.size.height / 2
                    
                    // 瓶子按鈕
                    Button(action: onBottleTap ) { Color.black.opacity(0.001) }
                        .frame(width: 80, height: 95)
                        .position(x: cx + 80, y: cy + 205)
                        
                    // 垃圾桶按鈕
                    Button(action: { print("垃圾桶被點擊")}) { Color.black.opacity(0.001) }
                        .frame(width: 100, height: 70)
                        .position(x: cx - 100, y: cy + 120)
                }
            }
        }
    }
    
    //海浪用函數
    private func drawWaveLayer(context: GraphicsContext, size: CGSize, time: Double, id: String, speed: CGFloat, amp: CGFloat, freq: CGFloat) {
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
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                    to: nil,
                                    from: nil,
                                    for: nil)
}
//MARK: - Preview區塊
#Preview {
    HomeView()
}
