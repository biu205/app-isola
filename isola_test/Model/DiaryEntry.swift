//
//  DiaryEntry.swift
//  isola_test
//
//  Created by Qian Hsu on 2026/4/5.
//

import Foundation
import SwiftData

// 加上 @Model，這段普通的 class 就會瞬間變成高效能的本地資料庫結構
@Model
class DiaryEntry {
    var id: UUID
    var date: Date
    var title: String   // 日記的題目（瓶子預設問題）
    var content: String // 用戶寫下的內容
    var moodIndex: Int
    
    init(title: String, content: String, moodIndex: Int = 2) {
        self.id = UUID()
        self.date = Date()
        self.title = title
        self.content = content
        self.moodIndex = moodIndex
    }
}
