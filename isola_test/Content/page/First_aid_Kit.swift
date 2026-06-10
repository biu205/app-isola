//
//  First_aid_Kit.swift
//  isola_test
//
//  Created by Qian Hsu on 2026/4/5.
//

import SwiftUI

struct MoodReportView: View {
    @AppStorage("appearanceMode") private var appearanceMode: Int = AppTheme.system.rawValue
    private var currentTheme: AppTheme { AppTheme(rawValue: appearanceMode) ?? .system }
    private var isDark: Bool { currentTheme.colorScheme == .dark }
    private var pageBackground: Color { isDark ? Color(hex: "#151D2B") : Color(hex: "#FDFBF0") }

    var body: some View {
        NavigationStack {
            ZStack {
                pageBackground.ignoresSafeArea()
                VStack(spacing: 8) {
                    Text("心情週報")
                        .font(.system(size: 28, weight: .bold))

                    Text("在這一週裡，共同回答了七個問題")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)

                    Spacer()

                    NavigationLink {
                        AIDiaryView()
                    } label: {
                        Text("點擊查看日誌")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(.systemBackground))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.primary)
                            .cornerRadius(25)
                            .padding(.horizontal, 40)
                    }

                    Spacer()
                }
                .padding(.top, 60)
            }
        }
        .preferredColorScheme(currentTheme.colorScheme)
    }
}

// 3. 這是你要導入的新頁面 『aiDiary』


#Preview {
    MoodReportView()
}
