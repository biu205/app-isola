//
//  QuestionView.swift
//  isola_test
//
//  Created by Biu on 2026/4/3.
//

import SwiftUI

struct QuestionView: View {
    // 使用 @Binding (來自父層狀態
    // 不需要給它初始值（如false）因為是「借用」別人的
    @Binding var isPresented: Bool
    @State private var inputText = ""
    
    var body: some View {
        VStack {
            ZStack {
                Image("paper")
                    .resizable()
                    .scaledToFill() // 確保圖片填滿你設定的框
                    //.frame(width: 300, height: 400) // 【關鍵】設定視窗的大小
                    .shadow(radius: 10)
                
                // 2. 疊在紙張上面的內容
                VStack(spacing: 20) {
                    Text("Q：屁眼") // 參考你的 Figma 內容
                        .font(.title3)
                        .bold()
                    
                    
                    // 這裡可以放你的 TextField
                    TextEditor(text: $inputText)
                        .frame(height: 150)
                        .padding()
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                    
                    Button("儲存並關閉") {
                        withAnimation { isPresented = false }
                    }
                    .buttonStyle(.borderedProminent)
                }
                //.frame(width: 300, height: 400) // 內容物的範圍也要對齊
            }
        }
        
    }
}
