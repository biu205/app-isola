//
//  SettingView.swift
//  isola_test
//
//  Created by Biu on 2026/4/14.
//

import SwiftUI

struct SettingView: View {
    // 使用 AppStorage 確保重啟 App 後資料還在
    @AppStorage("userName") var userName: String = "請填寫～"
    @AppStorage("appearanceMode") var appearanceMode: Int = 0  // 0: 白天, 1: 夜晚, 2: 系統
    @Environment(UIManager.self) private var uiManager  //控制島臉列開關
    // 用於控制 TextField 的焦點
    @FocusState private var isNameFocused: Bool

    var body: some View {
        ZStack {

            Spacer()
            Text("設定")
                .font(.headline)
            Spacer()
            // 背景顏色
            Color(hex: "FDFBF0").ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. 自定義導覽列

                ScrollView {
                    VStack(spacing: 20) {
                        // 2. 頭像區域
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 240, height: 240)

                                Image("islandDry")  // 替換為你的圖片名稱
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 170)
                            }

                            // 這裡會隨著下方輸入即時改變
                            Text(userName)
                                .font(.system(size: 28, weight: .medium))
                                .padding(.top, 10)
                        }
                        .padding(.vertical, 30)

                        // 3. 設定列表
                        VStack(spacing: 0) {
                            Divider()

                            // --- 用戶名稱欄位 ---
                            HStack {
                                Text("用戶名稱")
                                Spacer()
                                TextField("輸入名稱", text: $userName)
                                    .multilineTextAlignment(.trailing)
                                    .focused($isNameFocused)
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)

                                Image(systemName: "square.and.pencil")
                                    .onTapGesture {
                                        isNameFocused = true
                                    }
                            }
                            .padding()
                            .frame(height: 60)

                            // --- 模式切換欄位 ---
                            Divider()
                            HStack {
                                Text("模式")
                                Spacer()
                                Picker("模式選擇", selection: $appearanceMode) {
                                    Text("白天").tag(0)
                                    Text("夜晚").tag(1)
                                    Text("系統").tag(2)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(width: 180)
                            }
                            .padding(.horizontal)
                            .frame(height: 60)

                            // 其他靜態欄位
                            StaticRow(title: "系統管理")
                            StaticRow(title: "通知設定")
                            StaticRow(title: "App鎖")
                        }
                        .padding(.horizontal)
                    }
                }

            }
        }
        //模式
        .onChange(of: appearanceMode) { oldValue, newValue in
            updateTheme(newValue)
        }
        //navbar開關～～～～
        .onAppear {
            withAnimation {
                print("SettingView 進入了，準備關閉 Navbar")
                uiManager.isTabBarVisible = false  // 進入設定頁時，把 Navbar 藏起來
            }
        }
        .onDisappear {
            withAnimation {
                print("SettingViewＮＯＯＯＯ，")
                uiManager.isTabBarVisible = true  // 離開設定頁時，把 Navbar 變回來
            }
        }
    }

}

// 切換深淺色模式的邏輯
func updateTheme(_ mode: Int) {
    let style: UIUserInterfaceStyle
    switch mode {
    case 0: style = .light
    case 1: style = .dark
    default: style = .unspecified
    }
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?.windows.first?.overrideUserInterfaceStyle = style
}

// 靜態行組件
struct StaticRow: View {
    var title: String
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Text(title)
                Spacer()
                //Text("Detail").foregroundColor(.gray)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(height: 60)
        }
    }
}
