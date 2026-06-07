//
//  aiDiaryView.swift
//  isola_test
//
//  Created by Biu on 2026/5/27.
//
import SwiftUI

// 1. 定義單頁週報的資料結構
struct DiaryPageItem: Identifiable {
    let id = UUID()
    let dateText: String     // 例如 "5/20 Wed." 或 "五月第四周 週報"
    let imageName: String    // 圖片名稱代號
    let content: String      // 下方的詳細文字內容
    let isLastPage: Bool     // 是否為最後一頁（用來判斷要不要顯示確認按鈕）
}

struct AIDiaryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // 2. 建立四個分頁的資料（對應你的設計圖）
    let diaryPages: [DiaryPageItem] = [
        DiaryPageItem(
            dateText: "5/20 Wed.",
            imageName: "愉快度Ｑ1", // 替換成你的黃色大福圖片名稱
            content: "今天特地去現場為朋友的表演加油，看到舞台上閃閃發光的模樣，內心無比激動與驕傲，真的非常開心！",
            isLastPage: false
        ),
        DiaryPageItem(
            dateText: "5/23 Sat.",
            imageName: "非常愉快度Ｑ1", // 替換成你的橘色大福圖片名稱
            content: "今天特地去逛了新一代設計展，看到學長姐們實力驚人、作品實用又吸睛，真的好崇拜！其他展區的創意設計也讓人大開眼界，收穫滿滿。",
            isLastPage: false
        ),
        DiaryPageItem(
            dateText: "5/24 Sun.",
            imageName: "度Ｑ1",  // 替換成你的綠色大福圖片名稱
            content: "今天堆積了好多待辦事項，偏偏身體又感到格外疲憊，面對處理不完的瑣事，希望現在能立刻好好放空休息。",
            isLastPage: false
        ),
        DiaryPageItem(
            dateText: "五月第四周 週報",
            imageName: "", // 最後一頁沒有大圖片，留空即可
            content: "你在這一週的開端過得有些平淡，日子在日常上課與瑣碎的搜索中度過...（此處省略，可自行貼上圖中完整文字）",
            isLastPage: true
        )
    ]
    
    // 用於追蹤當前滑到哪一頁
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color(hex: "#151D2B") : Color(hex: "#FDFBF0"))
                .ignoresSafeArea()
            
            // 3. 核心分頁元件
            TabView(selection: $currentPage) {
                ForEach(Array(diaryPages.enumerated()), id: \.element.id) { index, page in
                    // 呼叫下方自定義的單頁 View
                    SingleDiaryPageView(page: page, onConfirm: {
                        dismiss() // 點擊確認完畢後，關閉此頁返回
                    })
                    .tag(index) // 綁定索引值，讓分頁小圓點知道目前在哪一頁
                }
            }
            // 關鍵：將 TabView 切換為「左右翻頁」風格
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .never)) // 隱藏小圓點背後的黑色半透明底
        }
        // 隱藏原生導覽列的返回按鈕，或是保留它（看你的設計視覺需求）
        .navigationBarBackButtonHidden(false)
    }
}

// 4. 單一分頁的佈局元件
struct SingleDiaryPageView: View {
    let page: DiaryPageItem
    var onConfirm: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
                .frame(height: 40)
            
            // 日期 / 標題
            Text(page.dateText)
                .font(.custom("Georgia", size: 24))
                .foregroundColor(.secondary)
                .padding(.top, 20)
            
            Spacer()
            
            // 根據是否為最後一頁，決定呈現圖片還是純長文字
            if !page.isLastPage {
                // Page 1 ~ 3: 圖片 + 短文字
                if !page.imageName.isEmpty {
                    Image(page.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 140)
                }
                
                Text(page.content)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .lineSpacing(8) // 調整行距，讓字體排版更好看
                    .multilineTextAlignment(.center) // 文字置中
                    .padding(.horizontal, 40)
                
            } else {
                // Page 4: 總結頁（長文字 + 確認按鈕）
                ScrollView(showsIndicators: false) {
                    Text(page.content)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineSpacing(8)
                        .multilineTextAlignment(.leading) // 總結頁文字靠左對齊
                        .padding(.horizontal, 40)
                }
                .frame(maxHeight: 280) // 限制長文字區域高度，避免擠壓到按鈕
                
                // 確認完畢按鈕
                Button(action: onConfirm) {
                    Text("確認完畢")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 120, height: 40)
                        .background(Color(hex: "#C69C55")) // 駝色/土黃色按鈕
                        .cornerRadius(8)
                }
                .padding(.top, 10)
            }
            
            Spacer()
                .frame(height: 80) // 留出底部空間給分頁小圓點
        }
    }
}
#Preview {
    AIDiaryView()
}

#Preview {
    HomeView()
}
