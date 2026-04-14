//
//  Clothes.swift
//  isola_test
//
//  Created by Biu on 2026/4/9.
//
import SwiftUI

struct Accessory: Identifiable {
    let id: Int
    let name: String
    let imageName: String
    let description: String
    let unlockThreshold: Int

    // 這裡我們新增兩個「計算屬性」，讓程式自動去拼湊正確的名字
    var grayImageName: String { imageName + "灰" }  // 例如：花灰
    var displayImageName: String { imageName + "小" }  // 例如：花小
}

let accessoryData = [
    Accessory(
        id: 1,
        name: "蝴蝶結",
        imageName: "蝴蝶結",
        description: "可愛萌萌的蝴蝶結。",
        unlockThreshold: 0
    ),
    Accessory(
        id: 2,
        name: "眼鏡",
        imageName: "眼鏡",
        description: "集帥氣與性感於一身的小燒包眼鏡。",
        unlockThreshold: 1
    ),
    Accessory(
        id: 3,
        name: "橘子",
        imageName: "橘子",
        description: "新鮮的橘子。",
        unlockThreshold: 3
    ),
    Accessory(
        id: 4,
        name: "花",
        imageName: "花",
        description: "既然是小島的話一定會有花的吧！",
        unlockThreshold: 4
    ),
    Accessory(
        id: 5,
        name: "醬",
        imageName: "醬",
        description: "不吃想念，吃完懷念的巧克力脆脆醬",
        unlockThreshold: 5
    ),
    Accessory(
        id: 6,
        name: "舌頭",
        imageName: "舌頭",
        description: "增加無辜感的舌頭",
        unlockThreshold: 6
    ),
]

struct Clothes: View {
    @State private var userNumber: Int = 5
    @State private var selectedAccessory: Accessory? = nil
    @Environment(\.dismiss) var dismiss
    

    var body: some View {
        VStack { // <--- 大盒子開始
    
            // 2. 主角顯示區 (ZStack)
            ZStack {
                Image("islandDry")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 280)

                if let accessory = selectedAccessory {
                    Image(accessory.displayImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 280)
                }
            }
            .padding()

            Divider()

            // 3. 配件清單區域 (ScrollView)
            ScrollView {
                
                VStack(spacing: 18) {
                    ForEach(accessoryData) { item in
                        let isUnlocked = userNumber >= item.unlockThreshold

                        AccessoryListRow(
                            accessory: item,
                            isUnlocked: isUnlocked,
                            isSelected: selectedAccessory?.id == item.id
                        ) {
                            if isUnlocked {
                                if selectedAccessory?.id == item.id {
                                    selectedAccessory = nil
                                } else {
                                    selectedAccessory = item
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }.background(Color(hex: "#EEE9D4"))
            .contentMargins(Edge.Set.all, 10)
            .contentMargins(.top, 20, for: .scrollContent)
            
        } // <--- 大盒子結束
    } // <--- body 結束
} // <--- Clothes 結束

// --- 配件格子組件 ---
struct AccessoryListRow: View {
    let accessory: Accessory
    let isUnlocked: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) { // 改用左右排隊
                // 左邊放圖
                Image(isUnlocked ? accessory.imageName : accessory.grayImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(3)

                // 右邊放文字
                VStack(alignment: .leading) {
                    Text(isUnlocked ? accessory.name : "尚未解鎖")
                        .font(.system(.title3, design: .serif,weight: .bold))
                        .foregroundColor(isUnlocked ? .black : .gray)
                    
                    if isUnlocked {
                        Text(accessory.description)
                            .font(.system(.subheadline, design: .serif))
                            .foregroundColor(Color(hex: "#010101"))
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer()
            }
            .padding(5)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color(hex: "#ffcc22") : Color(hex: "#C68F3C"), lineWidth: 3)
                    .background(isSelected ? Color(hex: "#fffae8").cornerRadius(14) : Color.white.cornerRadius(14))
//                    .background(Color.white.cornerRadius(14))
            )
        }
        .disabled(!isUnlocked)
    }
}


//MARK: - Preview區塊
#Preview {
    Clothes()
}
