//
//  QuestionEntity.swift
//  isola_test
//
//  Created by Biu on 2026/6/2.
//
import Foundation
import SwiftData

/// 題目類型的安全列舉（對應 Firebase 的 category 欄位）
enum QuestionCategory: String, Codable {
    case daily = "daily"
    case introspection = "introspection"
}

@Model
final class JournalQuestion {
    /// 唯一識別碼（對應 Firebase 的 id）
    @Attribute(.unique) var id: String
    
    /// 題目文字內容（對應 Firebase 的 text）
    var text: String
    
    /// 是否需要上傳圖片（對應 Firebase 的 requiresImage）
    var requireImage: Bool
    
    /// 類別字串（對應 Firebase 的 category）
    var categoryRawValue: String
    
    /// 紀錄這題上次被選中的時間（用於每天隨機抽題的邏輯，避免短期重複）
    var lastSelectedDate: Date?

    /// 計算屬性：讓 Swift 程式碼可以用強型別安全操作
    var category: QuestionCategory {
        get { QuestionCategory(rawValue: categoryRawValue) ?? .daily }
        set { categoryRawValue = newValue.rawValue }
    }

    // 初始化方法
    init(id: String, text: String, requireImage: Bool, category: QuestionCategory) {
        self.id = id
        self.text = text
        self.requireImage = requireImage
        self.categoryRawValue = category.rawValue
        self.lastSelectedDate = nil
    }
}
