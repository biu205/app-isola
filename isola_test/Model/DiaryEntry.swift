//
//  DiaryEntry.swift
//  isola_test
//
//  Created by Qian Hsu on 2026/4/5.
//

import Foundation
import SwiftData

// 加上 @Model，這段普通的 class 就會瞬間變成高效能的本地資料庫結構




// MARK: - DiaryMedia 模型：存儲照片/視頻縮圖
@Model
final class DiaryMedia {
   var id: UUID
   var mediaType: String  // "photo" 或 "video"
   var imageData: Data?   // 照片或視頻縮圖
   var timestamp: Date
   
   var entry: DiaryEntry?
   
   init(mediaType: String, imageData: Data? = nil) {
       self.id = UUID()
       self.mediaType = mediaType
       self.imageData = imageData
       self.timestamp = Date()
   }
}

// MARK: - DiaryEntry 修改版本：支持多媒體
@Model
final class DiaryEntry {
   var id: UUID
   var date: Date
   var title: String          // 日記的題目（瓶子預設問題）
   var content: String        // 用戶寫下的內容
   var moodIndex: Int?        // 可選：浮標時為 nil
   var type: String           // "daily" / "introspection" / "freeNote"
   
   @Relationship(deleteRule: .cascade, inverse: \DiaryMedia.entry)
   var mediaItems: [DiaryMedia] = []  // 支持多個媒體（照片/視頻）
   
   init(
       title: String,
       content: String,
       moodIndex: Int? = nil,
       type: String,
       mediaItems: [DiaryMedia] = []
   ) {
       self.id = UUID()
       self.date = Date()
       self.title = title
       self.content = content
       self.moodIndex = moodIndex
       self.type = type
       self.mediaItems = mediaItems
   }
}


