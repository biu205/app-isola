//
//  DailyQuestionManager.swift
//  isola_test
//
//  Created by Biu on 2026/6/2.
//
import Foundation
import FirebaseFirestore
import SwiftData
import Observation

@Observable
final class DailyQuestionManager {
    var todayDailyQuestion: JournalQuestion?
    var todayIntrospectionQuestion: JournalQuestion?
    
    var isSyncing = false
    
    private let db = Firestore.firestore()
    private let localVersionKey = "isola_LocalQuestionVersion"
    private let lastRefreshDateKey = "isola_LastRefreshDate"
    private let dailyQuestionIdKey = "isola_TodayDailyId"
    private let introspectionQuestionIdKey = "isola_TodayIntrospectionId"
    
    // MARK: - 啟動同步與選題
    @MainActor
    func initializeDailyQuestions(modelContext: ModelContext) async {
        let all = (try? modelContext.fetch(FetchDescriptor<JournalQuestion>())) ?? []
        print("SwiftData 現有題目數量 = \(all.count)")
        print("開始初始化")

        await syncFromFirebaseIfNeeded(modelContext: modelContext)
        loadOrRefreshDailyQuestions(modelContext: modelContext)
    }
    
    // MARK: - Firebase 省流量同步
    @MainActor
    private func syncFromFirebaseIfNeeded(modelContext: ModelContext) async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            // A. 讀取遠端 app_config 的最新版號
            let configDoc = try await db.collection("app_config").document("questions_info").getDocument()
            guard let remoteVersion = configDoc.data()?["questionVersion"] as? Int else {
                print("[isola Config] 找不到遠端版號設定，跳過同步。")
                return
            }
            
            // B. 檢查本地版號，如果本地已經是最新的，直接 return
            let localVersion = UserDefaults.standard.integer(forKey: localVersionKey)
            if localVersion >= remoteVersion {
                print("[isola Config] 題目庫已是最新版本 (v\(localVersion))，跳過下載")
                return
            }
            
            print(" [isola Sync] 偵測到新題目版本 (遠端: v\(remoteVersion))，開始全量同步...")
            
            // C. 下載架構 A 的 questions 
            let snapshot = try await db.collection("Question_data").getDocuments()
            print("Firebase 抓到 \(snapshot.documents.count) 筆文件")
            
            var successCount = 0
            for document in snapshot.documents {
                let data = document.data()
                let id = document.documentID
                print("文件 id=\(id), data=\(data)")
                
                guard let text = data["text"] as? String,
                      let categoryStr = data["category"] as? String else {
                    print("文件 \(id) 缺少必要字段 (text 或 category)，跳過")
                    continue
                }
                
                let requireImageValue = data["requireImage"]
                let requireImage: Bool
                if let boolValue = requireImageValue as? Bool {
                    requireImage = boolValue
                } else if let numberValue = requireImageValue as? NSNumber {
                    requireImage = numberValue.boolValue  // 0 → false, 1 → true
                } else {
                    requireImage = false  // 預設為 false
                }
                
                let category = QuestionCategory(rawValue: categoryStr) ?? .daily
                
                let descriptor = FetchDescriptor<JournalQuestion>(predicate: #Predicate { $0.id == id })
                if let existing = try? modelContext.fetch(descriptor).first {
                    existing.text = text
                    existing.requireImage = requireImage
                    existing.categoryRawValue = category.rawValue
                } else {
                    let newQuestion = JournalQuestion(id: id, text: text, requireImage: requireImage, category: category)
                    modelContext.insert(newQuestion)
                }
                successCount += 1
            }
            
            try modelContext.save()
            UserDefaults.standard.set(remoteVersion, forKey: localVersionKey)
            print("[isola Sync] SwiftData 資料庫更新成功，已存入 \(successCount) 筆題目，已升級至 v\(remoteVersion)")
        } catch {
            print("[isola Sync] Firebase 同步發生錯誤: \(error.localizedDescription)")
        }
    }
    
    // MARK: -12 點自動刷新與加載
    @MainActor
    private func loadOrRefreshDailyQuestions(modelContext: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        
        if let lastRefreshDate = UserDefaults.standard.object(forKey: lastRefreshDateKey) as? Date {
            if calendar.isDate(lastRefreshDate, inSameDayAs: now) {
                let dailyId = UserDefaults.standard.string(forKey: dailyQuestionIdKey) ?? ""
                let introId = UserDefaults.standard.string(forKey: introspectionQuestionIdKey) ?? ""
                
                print("[緩存] dailyId = '\(dailyId)', introId = '\(introId)'")
                
                let dailyDesc = FetchDescriptor<JournalQuestion>(predicate: #Predicate { $0.id == dailyId })
                let introDesc = FetchDescriptor<JournalQuestion>(predicate: #Predicate { $0.id == introId })
                
                self.todayDailyQuestion = try? modelContext.fetch(dailyDesc).first
                self.todayIntrospectionQuestion = try? modelContext.fetch(introDesc).first
                
                print("[緩存] todayDailyQuestion = \(String(describing: todayDailyQuestion))")
                
                if todayDailyQuestion != nil && todayIntrospectionQuestion != nil {
                    print("[isola Time] 處於同一天內，繼續鎖定今日固定題目。")
                    return
                }
            }
        }
        
        print("[isola Time] 跨越午夜 12 點！觸發全自動刷新機制。")
        executeNewRandomSelection(modelContext: modelContext, todayDate: now)
    }
    
    @MainActor
    private func executeNewRandomSelection(modelContext: ModelContext, todayDate: Date) {
        let dailyRaw = QuestionCategory.daily.rawValue
        let introRaw = QuestionCategory.introspection.rawValue
        
        let dailyDesc = FetchDescriptor<JournalQuestion>(predicate: #Predicate { $0.categoryRawValue == dailyRaw })
        let introDesc = FetchDescriptor<JournalQuestion>(predicate: #Predicate { $0.categoryRawValue == introRaw })
        
        let allDaily = (try? modelContext.fetch(dailyDesc)) ?? []
        let allIntro = (try? modelContext.fetch(introDesc)) ?? []
        print("allDaily 數量 = \(allDaily.count), allIntro 數量 = \(allIntro.count)")
        
        
        // 使用智選演算法抽取
        let selectedDaily = pickSmartRandom(from: allDaily)
        let selectedIntro = pickSmartRandom(from: allIntro)
        
       
        self.todayDailyQuestion = selectedDaily
        self.todayIntrospectionQuestion = selectedIntro
        
        // 紀錄最後抽中時間
        selectedDaily?.lastSelectedDate = todayDate
        selectedIntro?.lastSelectedDate = todayDate
        
        // 寫入 UserDefaults 緩存
        UserDefaults.standard.set(todayDate, forKey: lastRefreshDateKey)
        UserDefaults.standard.set(selectedDaily?.id ?? "", forKey: dailyQuestionIdKey)
        UserDefaults.standard.set(selectedIntro?.id ?? "", forKey: introspectionQuestionIdKey)
        
        try? modelContext.save()
    }
    
    /// 智慧權重隨機
    private func pickSmartRandom(from questions: [JournalQuestion]) -> JournalQuestion? {
        guard !questions.isEmpty else { return nil }
        // 依據時間升序排序（最久沒出現的排前面）
        let sorted = questions.sorted {
            ($0.lastSelectedDate ?? Date.distantPast) < ($1.lastSelectedDate ?? Date.distantPast)
        }
        // 至少保留 2 題候選，避免只有 1 題時永遠固定
        let poolSize = max(2, Int(Double(sorted.count) * 0.4))
        return Array(sorted.prefix(poolSize)).randomElement()
    }

    /// 跨日時呼叫（例如首頁 Timer 偵測到新的一天）
    @MainActor
    func refreshQuestionsForNewDay(modelContext: ModelContext) {
        loadOrRefreshDailyQuestions(modelContext: modelContext)
    }
}
