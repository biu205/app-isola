//
//  QuestionManager.swift
//  isola_test
//
//  Created by Biu on 2026/4/7.
//
import Foundation
import Combine // 👈 關鍵：必須引入這個庫，神經線才有用

class QuestionManager: ObservableObject {
    @Published var allQuestions: [Question] = []
    
    init() {
        loadJSON()
    }
    
    func loadJSON() {
        // 在藍色資料夾中，Bundle 依然可以透過檔名找到它
        guard let url = Bundle.main.url(forResource: "Questions", withExtension: "json") else {
            print("❌ 找不到 Questions.json，請檢查 Target Membership 是否勾選")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            self.allQuestions = try decoder.decode([Question].self, from: data)
            print("✅ 成功載入 \(allQuestions.count) 個題目")
        } catch {
            print("❌ 解析 JSON 失敗: \(error)")
        }
    }
}
