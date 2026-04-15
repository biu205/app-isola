//
//  ThemePicker.swift
//  isola_test
//
//  Created by Qian Hsu on 2026/4/15.
//

import SwiftUI

// 💡 競賽亮點：定義清晰的列舉，支援「跟隨系統」
enum AppTheme: Int {
    
    case light = 0
    case dark = 1
    case system = 2
    // 轉換成 SwiftUI 原生的 ColorScheme
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .light
        case .system:
            return .light // nil 代表跟隨 iOS 系統目前的設定
        }
    }
}

extension AppTheme {
    /// 首頁背景夜晚圖層透明度 (0 = 白天圖，1 = 夜晚圖)
    func homeNightOverlayOpacity(at date: Date, calendar: Calendar = .current) -> Double {
        switch self {
        case .light:
            return 0
        case .dark:
            return 1
        case .system:
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            let timeInHours = Double(hour) + (Double(minute) / 60.0)

            if timeInHours < 19.0 { return 0 }
            if timeInHours >= 19.0 { return 1 }
            return timeInHours - 18.0
        }
    }
}
