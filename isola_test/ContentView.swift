import SwiftUI
//首頁
struct ContentView: View {
    // 在 struct 最上方定義這個開關 下方的 $isShowingQuestion 才能找到對象
    @State private var isShowingQuestion = false
    var body: some View {
        ZStack {
             
            // 動態背景
            TimelineView(.periodic(from: .now, by: 1/60)) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    
                    // 取得圖片
                    guard let seaImg = context.resolveSymbol(id: "sea"),
                          let darkImg = context.resolveSymbol(id: "dark"),
                          let lightImg = context.resolveSymbol(id: "light"),
                          let bottleImg = context.resolveSymbol(id: "bottle"),
                          let trashcanImg = context.resolveSymbol(id: "trashcan")
                    else { return }
                    
                    let imgW = seaImg.size.width
                    let centerY = size.height / 2
                    
                    // --- 繪製函數function -------
                    func drawLayer(img: GraphicsContext.ResolvedSymbol, speed: CGFloat, amplitude: CGFloat, frequency: CGFloat) {
                        // 水平位移 (原本的捲動)
                        let offset = CGFloat(time * speed).truncatingRemainder(dividingBy: imgW)
                        // 垂直位移 (S 形波浪：sin(時間 * 頻率) * 振幅)
                        let waveY = sin(time * frequency) * amplitude
                        context.draw(img, at: CGPoint(x: offset, y: centerY + waveY))
                        context.draw(img, at: CGPoint(x: offset - imgW, y: centerY + waveY))
                    }
                    
                    // 背景
                    if let backgroundImg = context.resolveSymbol(id: "background") {
                        context.draw(backgroundImg, at: CGPoint(x: size.width/2, y: centerY), anchor: .center)
                    }
                    
                    // --- B. 執行繪製 (套用 S 形效果) --
                    // amplitude: 震盪幅度(px), frequency: 震盪速度
                    drawLayer(img: seaImg, speed: 70, amplitude: 2, frequency: 1.5)
                    drawLayer(img: darkImg, speed: 60, amplitude: 8, frequency: 1.2)
                    drawLayer(img: lightImg, speed: 40, amplitude: 3, frequency: 0.8)
                    // --- 繪製函數function end-------
                    
                    // 小島
                    if let islandImg = context.resolveSymbol(id: "island") {
                        context.draw(islandImg, at: CGPoint(x: size.width/2, y: centerY), anchor: .center)
                    }
                    // 太陽
                    if let sunImg = context.resolveSymbol(id: "sun") {
                        context.draw(sunImg, at: CGPoint(x: size.width - 280, y: size.height - 660), anchor: .center)
                    }
                    
                    //bottle and trashcan
                    if let bottleImg = context.resolveSymbol(id: "bottle"),
                       let trashcanImg = context.resolveSymbol(id: "trashcan") {
                        // 1. 設定浮動的參數
                        let bottleAmplitude: CGFloat = 10   // 震盪幅度（像素），數字越大跳越高
                        let bottleFrequency: CGFloat = 1.3  // 震盪頻率（速度），數字越大晃越快
                        
                        // 2. 計算垂直位移
                        let bottleFloat = sin(time * bottleFrequency) * bottleAmplitude
                        
                        // 3. 執行繪製 (將位移加在 y 座標上)
                        context.draw(bottleImg, at: CGPoint(x: size.width - 270, y: size.height - 280 + bottleFloat), anchor: .center)
                        context.draw(trashcanImg, at: CGPoint(x: size.width - 130, y: size.height - 260 + bottleFloat), anchor: .center)
                    }
                }// canvas end、定義圖片們接後面
                symbols: {
                    Image("background").tag("background")
                    Image("sea").tag("sea")
                    Image("dark").tag("dark")
                    Image("light").tag("light")
                    Image("island").tag("island")
                    Image("sun").resizable().tag("sun").frame(width: 120, height: 120)
                    Image("bottle").resizable().tag("bottle").frame(width: 200, height: 200)
                    Image("trashcan").resizable().tag("trashcan").frame(width: 120, height: 120)
                }
          
   
            }// timelineview end
            
            .ignoresSafeArea()
            .blur(radius: isShowingQuestion ? 10 : 0) //按鈕被點 背景一起模糊
            // timeline裡面不放if
            if isShowingQuestion {
                Color.black.opacity(0.2)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation { isShowingQuestion = false }
                            }
                            // 問題視窗、呼叫另一個檔案的 View，並把狀態「綁定」進去
                            QuestionView(isPresented: $isShowingQuestion)
                                .transition(.scale.combined(with: .opacity))
                        }
            // 瓶子的隱形按鈕
                        GeometryReader { geometry in
                                Button(action: {
                                    isShowingQuestion = true // 點擊後觸發跳轉
                                    
                                }) { Color.white.opacity(0.001)// 按鈕的形狀 透明
                                }
                                .frame(width: 120, height: 180) // 設定跟瓶子差不多大的感應區
                                //  position 對齊上面 context.draw 瓶子位置
                                .position(x: geometry.size.width - 270, y: geometry.size.height - 280)
                            }
                        }// zstack end
       }// body end
    }// big view end
#Preview {
    ContentView()
}
