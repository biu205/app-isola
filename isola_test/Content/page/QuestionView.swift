import SwiftUI
import SwiftData

struct QuestionView: View {
    @StateObject var qManager = QuestionManager()
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @State private var inputText = ""
    
    // 狀態管理：0 = 選心情, 1 = 寫日記
    @State private var currentState: Int = 0
    @State private var selectedMoodIndex: Int = 2
    
    let moodImages = ["非常不愉快度Ｑ", "不愉快度Ｑ", "度Ｑ", "愉快度Ｑ", "非常愉快度Ｑ"]
    let moodName = ["非常不愉快", "不愉快", "一般", "愉快", "非常愉快"]
    
    var body: some View {
        ZStack {
            // 背景紙張
            Image("paper")
                .resizable()
                .scaledToFill()
                .frame(width: 400, height: 800)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            
            // 介面層
            VStack {
                // 頂部導覽列
                HStack {
                    if currentState == 1 {
                        Button(action: {
                            withAnimation(.spring()) { currentState = 0 }
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "chevron.left")
                            }
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.brown.opacity(0.8))
                        }
                        .padding(.leading, 30)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
                            isPresented = false
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            //.foregroundColor(.gray.opacity(0.5))
                            .foregroundColor(.brown.opacity(0.8))
                    }
                    .padding(.trailing, 27)
                }
                .padding(.top, 150) // 調整頂部按鈕位置，使其在紙張內
                .padding(.horizontal, 30)
                
                // 內容切換區
                VStack(spacing: 25) {
                    if currentState == 0 {
                        // 第一階段：選擇心情
                        moodSelectionSection
                            .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .opacity))
                    } else {
                        // 第二階段：寫日記
                        diaryInputSection
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                    }
                }
                .frame(maxHeight: .infinity) // 讓內容撐開
                .padding(.bottom, 150)
            }
        }
    }
    
    // --- 子視圖：心情選擇 ---
    private var moodSelectionSection: some View {
        VStack(spacing: 30) {
            Text("今天的心情如何？")
                .font(.system(.title3, design: .serif))
                .fontWeight(.medium)
                .foregroundColor(.black.opacity(0.7))
            
            ZStack {
                ForEach(0..<5) { index in
                    if selectedMoodIndex == index {
                        VStack {
                            Image(moodImages[index])
                                .resizable()
                                .scaledToFit()
                                .frame(width: 190, height: 190)
                                .transition(.scale.combined(with: .opacity))
                            
                            Text(moodName[index])
                                .font(.system(.title3, design: .serif))
                                .fontWeight(.medium)
                                .foregroundStyle(.black.opacity(0.7))
                        }
                    }
                }
            }
            .frame(height: 200)
            
            Slider(value: Binding(
                get: { Double(selectedMoodIndex) },
                set: { newValue in
                    let roundedValue = Int(newValue.rounded())
                    if roundedValue != selectedMoodIndex {
                        selectedMoodIndex = roundedValue
                        UISelectionFeedbackGenerator().selectionChanged()
                    }
                }
            ), in: 0...4, step: 1)
            .accentColor(.brown)
            .padding(.horizontal, 70)
            
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { currentState = 1 }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                Text("下一步")
                    .font(.system(.headline, design: .serif))
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(Capsule().stroke(Color.brown, lineWidth: 1.5))
                    .foregroundColor(.brown)
            }
        }
    }
    
    // --- 子視圖：日記輸入 ---
        private var diaryInputSection: some View {
            VStack(spacing: 15) {
                // 這裡變成了：從 JSON 抓取的動態題目
                // 如果 JSON 還沒讀到，會顯示 "載入題目中..."
                Text(qManager.allQuestions.first?.content ?? "載入題目中...")
                    .font(.system(.headline, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black.opacity(0.7))
                    .padding(.horizontal, 100)
                    .padding(.top, 20)
                
                ZStack(alignment: .topLeading) {
                    // 灰色區域提示文字：現在改成簡單的「請輸入...」
                    if inputText.isEmpty {
                        Text("請輸入")
                            .font(.system(size: 18, design: .serif))
                            .foregroundColor(.gray.opacity(0.4)) // 淡淡的灰色
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                    
                    TextEditor(text: $inputText)
                        .font(.system(size: 18, design: .serif))
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .lineSpacing(8)
                        .padding(10)
                        .frame(maxWidth: 250, maxHeight: .infinity)
                        .foregroundColor(.black.opacity(0.8))
                        
                }
                .frame(height: 250) // 固定輸入區域高度，視覺更穩定
                
                Button(action: saveAndClose) {
                    Text("封入瓶子")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(inputText.isEmpty ? Color.gray.opacity(0.5) : Color.brown)
                        )
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal, 100)
                .padding(.bottom, 30)
            }
        }
    // --- 儲存邏輯 ---
    private func saveAndClose() {
        let newEntry = DiaryEntry(
            title: qManager.allQuestions.first?.content ?? "一般日記",
            content: inputText,
            moodIndex: selectedMoodIndex
        )
        
        modelContext.insert(newEntry)
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
            isPresented = false
        }
    }
}
//MARK: - Preview區塊
#Preview {
    HomeView()
}
