//
//  First_aid_Kit.swift
//  isola_test
//
//  Created by Qian Hsu on 2026/4/5.
//

import SwiftUI

struct MoodReportView: View {
    var body: some View {
        // 1. 使用 NavigationStack 包裹整個畫面，才能啟用頁面導覽功能
        NavigationStack {
            VStack(spacing: 8) {
                Text("心情週報")
                    .font(.system(size: 28, weight: .bold))
                
                Text("在這一週裡，共同回答了七個問題")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                Spacer()
                
                // 2. 加入「點擊查看日誌」按鈕
                NavigationLink {
                    // 這裡目的地指向你的新頁面
                    AIDiaryView()
                } label: {
                    Text("點擊查看日誌")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.black) // 可以自行更換喜歡的品牌顏色
                        .cornerRadius(25)
                        .padding(.horizontal, 40)
                }
                
                Spacer() // 讓按鈕稍微置中偏下，你可以根據版面調整或刪除這個 Spacer
            }
            .padding(.top, 60)
        }
    }
}

// 3. 這是你要導入的新頁面 『aiDiary』


#Preview {
    MoodReportView()
}

#Preview {
    HomeView()
}
