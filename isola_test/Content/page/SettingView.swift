//
//  SettingView.swift
//  isola_test
//
//  Created by Biu on 2026/4/14.
//

import SwiftUI

struct SettingView: View {
    @AppStorage("userName") var userName: String = "請填寫～"
    @AppStorage("appearanceMode") var appearanceMode: Int = 0
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool

    private var isDark: Bool {
        switch AppTheme(rawValue: appearanceMode) ?? .system {
        case .light: return false
        case .dark: return true
        case .system:
            let hour = Calendar.current.component(.hour, from: Date())
            return hour >= 19
        }
    }

    private var textColor: Color {
        isDark ? .white : .black
    }

    private var backgroundColor: Color {
        isDark ? Color(hex: "#151D2B") : Color(hex: "#FDFBF0")
    }

    private var circleColor: Color {
        isDark ? Color(hex: "#2C2C2E") : .white
    }

    var body: some View {
        ZStack {
            Spacer()
            Text("設定")
                .font(.headline)
                .foregroundColor(textColor)
            Spacer()
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // 頭像區域
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(circleColor)
                                    .frame(width: 240, height: 240)

                                Image("islandDry")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 170)
                            }

                            Text(userName)
                                .font(.system(size: 28, weight: .medium))
                                .padding(.top, 10)
                                .foregroundColor(textColor)
                        }
                        .padding(.vertical, 30)

                        // 設定列表
                        VStack(spacing: 0) {
                            Divider()

                            // --- 用戶名稱欄位 ---
                            HStack {
                                Text("用戶名稱")
                                    .foregroundColor(textColor)

                                Spacer()
                                TextField("輸入名稱", text: $userName)
                                    .multilineTextAlignment(.trailing)
                                    .focused($isNameFocused)
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)

                                Image(systemName: "square.and.pencil")
                                    .foregroundColor(textColor)
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
                                    .foregroundColor(textColor)
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

                            // 隱私設定（開啟 iOS 系統設定 → 此 App 的權限頁）
                            VStack(spacing: 0) {
                                Divider()
                                Button {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack {
                                        Text("系統設定")
                                            .foregroundColor(textColor)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .frame(height: 60)
                                }
                            }
                            // --- 通知設定 ---
                            VStack(spacing: 0) {
                                Divider()
                                NavigationLink(destination: NotificationSettingView()) {
                                    HStack {
                                        Text("通知設定")
                                            .foregroundColor(textColor)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .frame(height: 60)
                                }
                            }

                            // App鎖 (NavigationLink)
                            VStack(spacing: 0) {
                                Divider()
                                NavigationLink(destination: AppLockSettingView()) {
                                    HStack {
                                        Text("App 鎖")
                                            .foregroundColor(textColor)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .frame(height: 60)
                                }
                            }

                            // MARK: - DEBUG ONLY 測試用，正式上線前移除
                            #if DEBUG
                            VStack(spacing: 0) {
                                Divider()
                                Button {
                                    UserDefaults.standard.removeObject(forKey: "hasSeenHomeOnboarding")
                                    UserDefaults.standard.removeObject(forKey: "hasSeenBackpackOnboarding")
                                } label: {
                                    HStack {
                                        Text("重置教學（測試用）")
                                            .foregroundColor(.orange)
                                        Spacer()
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                    .padding()
                                    .frame(height: 60)
                                }
                            }
                            #endif
                            // MARK: - END DEBUG
                        }
                        .padding(.horizontal)
                    }
                }
                .scrollDismissesKeyboard(.immediately)
            }
        }
        .onTapGesture {
            isNameFocused = false
        }
        .onAppear {
            if AppTheme(rawValue: appearanceMode) == nil {
                appearanceMode = AppTheme.system.rawValue
            }
        }
    }
}


