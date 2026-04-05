import SwiftUI
import SwiftData

struct QuestionView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @State private var inputText = ""
    
    // 狀態管理：0 = 選心情, 1 = 寫日記
    @State private var currentState: Int = 0
    @State private var selectedMoodIndex: Int = 2
    
    let moodImages = ["非常不愉快度Ｑ", "不愉快度Ｑ", "度Ｑ", "愉快度Ｑ", "非常愉快度Ｑ"]
    let moodName = ["非常不愉快", "不愉快", "一般", "愉快", "非常愉快"]
    let defaultQuestion = "請放心自由自在的分享\n你今天的所有想法\n不管任何都可以！"
    
    var body: some View {
        ZStack {

            Image("paper")
                .resizable()
                .scaledToFill()
                .frame(width: 400, height: 800)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            
 
            VStack {
                HStack {
   
                    if currentState == 1 {
                        Button(action: {
                            withAnimation(.spring()) {
                                currentState = 0
                            }
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "chevron.left")
                                Text("心情")
                            }
                            .font(.system(size: 17, weight: .medium, design: .serif))
                            .foregroundColor(.brown.opacity(0.8))
                            .padding(.leading, 20)
                        }
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.95).combined(with: .opacity),
                                removal: .scale(scale: 1.05).combined(with: .opacity)   
                            )
                        )
                    }
                    
                    Spacer()
                    
                    // 右上角關閉
                    Button(action: {
                        withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
                            isPresented = false
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(20)
                    }
                }
                .padding(.top, 10) // 根據紙張位置調整
                Spacer()
            }
            .frame(width: 350, height: 550)

            // 3. 內容區域
            VStack(spacing: 25) {
                if currentState == 0 {
                    // --- 第一階段：選擇心情 ---
                    VStack(spacing: 40) {
                        Text("今天的心情如何？")
                            .font(.system(.title3, design: .serif))
                            .fontWeight(.medium)
                            .foregroundColor(.black.opacity(0.7))
                        
                        ZStack {
                            ForEach(0..<5) { index in
                                if selectedMoodIndex == index {
                                    Image(moodImages[index])
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 140, height: 140) // 稍微加大圖示
                                        .transition(.scale.combined(with: .opacity))
                                    Text(moodName[index])
                                        .font(.system(.title3, design: .serif))
                                        .fontWeight(.medium)
                                        .foregroundStyle(.black.opacity(0.7))
                                        .padding(.top,150)
                                }
                            }
                        }
                        .frame(height: 150)
                        
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
                        .scaleEffect(1.5)
                        .padding(.horizontal, 50)
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentState = 1
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }) {
                            Text("下一步")
                                .font(.system(.headline, design: .serif))
                                .padding(.horizontal, 40)
                                .padding(.vertical, 12)
                                .background(Capsule().stroke(Color.brown, lineWidth: 1.5))
                                .foregroundColor(.brown)
                        }
                    }

                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity), // 稍微從小變大進入
                            removal: .scale(scale: 1.05).combined(with: .opacity)   // 稍微變大並消失
                        )
                    )
                    
                } else {
                    // --- 第二階段：寫日記 ---
                    VStack(spacing: 15) {
                        Text(defaultQuestion)
                            .font(.system(.headline, design: .serif))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundColor(.black.opacity(0.7))
                            .padding(.top, 20)
                        
                        TextEditor(text: $inputText)
                            .font(.system(size: 18, design: .serif)) // 保持書寫感
                            .scrollContentBackground(.hidden) // 隱藏原生白色背景
                            .background(Color.clear) // 確保透明
                            .lineSpacing(8)
                            .padding(10)
                            .frame(maxWidth: 300, maxHeight: .infinity)
                            .foregroundColor(.black.opacity(0.8))
                            .foregroundStyle(.black.opacity(0.8))
                            .submitLabel(.done)
                        
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
                        .padding(.bottom, 20)
                    }

                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 1.05).combined(with: .opacity)
                        )
                    )
                }
            }
            .padding(30)
            .frame(width: 320, height: 500)
        }
    }
    
    private func saveAndClose() {
        let newEntry = DiaryEntry(
            title: defaultQuestion,
            content: inputText,
            moodIndex: selectedMoodIndex
        )
        
        modelContext.insert(newEntry)
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
            isPresented = false
        }
    }}

#Preview {
    HomeView()
}
