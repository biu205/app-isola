# AI 週報功能規格

## 基本資訊
- **功能名稱**：AI 週報與智慧洞察（Weekly AI Report）
- **版本**：v1.1
- **狀態**：實作中
- **優先度**：高
- **建立日期**：2026-05-31

## 目的
每週自動分析使用者的日記內容與生理數據，生成溫暖、貼心的個性化週報，提供可達成的改善建議，增強使用者的黏著度與自我認知。

## 範圍

### In-Scope（包含）
- 每週自動生成週報
- 日記內容 + 生理數據的綜合分析
- AI 驅動的個性化建議
- 視覺化週報呈現
- 進度追蹤展示
- 週報歷史存檔

### Out-of-Scope（不包含）
- 多語言支援（階段二）
- 週報分享（階段二）
- 人工編輯週報（不在範圍內）

## 使用者故事

### 故事 1：週度回顧
**As a** 想了解自己這週狀況的使用者  
**I want to** 收到一份溫暖貼心的週報，總結我的情緒與生活  
**So that** 我能反思這一週的經驗與成長

### 故事 2：獲得建議
**As a** 面臨困擾的使用者  
**I want to** AI 根據我的情緒模式給出可執行的建議  
**So that** 我知道下週可以如何改進

### 故事 3：追蹤進度
**As a** 有改善目標的使用者  
**I want to** 看到我對設定目標的達成情況  
**So that** 我感受到自己在進步

## 功能流程

```
1. 系統每週一早上 7:00 自動觸發週報生成
2. 收集過去 7 天的數據：
   - 日記內容（所有類型）
   - 生理觀測數據
   - 追蹤目標進度
3. 呼叫 Gemini API 進行分析與摘要
4. API 返回結構化週報內容
5. 系統儲存週報至 Firestore 與 SwiftData
6. 推送通知提醒使用者（可選）
7. 使用者打開 App 看到週報入口
8. 點擊進入詳細週報頁面
9. 可查看建議、目標進度、洞察摘要
```

## 驗收標準

- [ ] 每週一自動生成週報
- [ ] 週報內容包含情緒摘要、生理洞察、建議
- [ ] 使用者能查看本週與過往週報
- [ ] 週報頁面美觀易讀
- [ ] 建議具體可行（非模糊泛泛）
- [ ] 生理數據正確納入分析
- [ ] 追蹤目標進度正確顯示
- [ ] 推送通知能正確發送（若啟用）
- [ ] 週報可收藏或標記
- [ ] API 失敗時有優雅的降級方案

## 技術實現

### 資料結構
```swift
struct WeeklyReport {
    let id: UUID
    let weekStartDate: Date
    let weekEndDate: Date
    
    // 內容部分
    let emotionalSummary: String
    let healthInsights: [String]
    let achievements: [String]
    let suggestions: [Suggestion]
    let goalProgress: [GoalProgressItem]
    
    // 元數據
    let generatedAt: Date
    let isSynced: Bool
}

struct Suggestion {
    let title: String
    let description: String
    let actionItems: [String] // 可執行的步驟
    let priority: Priority // high, medium, low
}

struct GoalProgressItem {
    let goalName: String
    let targetValue: Double
    let achievedValue: Double
    let progress: Double // 0.0-1.0
}

enum Priority {
    case high, medium, low
}
```

### AI 提示詞設計
```
你是一位溫暖、貼心的心理陪伴 AI。基於使用者過去一週的日記和生理數據，
請生成一份個性化的週報。

要求：
1. 用友善、鼓勵的語氣
2. 指出這週的情緒亮點（正面事件）
3. 識別出主要的情緒挑戰
4. 基於生理數據提出可達成的改善建議（3-5 條）
5. 總結這週的成就與進步
6. 鼓勵使用者下週繼續堅持

日記內容：[...]
生理數據：[...]
追蹤目標：[...]

請以 JSON 格式返回，包含以下欄位：
{
  "emotional_summary": "...",
  "health_insights": ["..."],
  "achievements": ["..."],
  "suggestions": [
    {
      "title": "...",
      "description": "...",
      "action_items": ["...", "..."],
      "priority": "high|medium|low"
    }
  ]
}
```

### 週報生成流程

```swift
func generateWeeklyReport(for weekStartDate: Date) {
    // 1. 收集數據
    let diaries = fetchDiaries(from: weekStartDate, to: weekStartDate + 7days)
    let healthData = fetchHealthData(from: weekStartDate, to: weekStartDate + 7days)
    let goals = fetchActiveGoals()
    
    // 2. 準備提示詞
    let prompt = buildPrompt(diaries: diaries, health: healthData, goals: goals)
    
    // 3. 呼叫 Gemini API
    let response = try await callGeminiAPI(prompt: prompt)
    
    // 4. 解析回應
    let report = try parseWeeklyReport(from: response)
    
    // 5. 儲存
    save(report: report)
    
    // 6. 通知使用者（可選）
    sendNotification(title: "你的週報已準備好", body: "來看看這週的成長吧！")
}
```

## 週報頁面設計

```
┌──────────────────────────┐
│      這週的你            │
│   (2026年5月25-31日)      │
├──────────────────────────┤
│                          │
│ 💭 情緒亮點              │
│ 這週有 5 個充實的日子，  │
│ 特別是在 5/28 因為完成  │
│ 專案感到很滿足。        │
│                          │
│ 💪 這週成就              │
│ ✓ 運動 4 次              │
│ ✓ 完成 6 篇日記          │
│ ✓ 平均睡眠 7.2h          │
│                          │
│ 🎯 目標進度              │
│ 每日 7h 睡眠             │
│ ████████░░ 80%           │
│                          │
│ 💡 下週建議              │
│ 1. 保持運動習慣          │
│    → 繼續每周 4 次運動  │
│                          │
│ 2. 提早 30 分鐘睡眠      │
│    → 試試晚上 10:30 上床 │
│                          │
│ 3. 增加户外時間          │
│    → 周末安排戶外活動   │
│                          │
└──────────────────────────┘
```

## 測試要點

### 單元測試
- [ ] 日記與生理數據正確聚合
- [ ] 提示詞正確格式化
- [ ] API 回應正確解析
- [ ] 週報物件正確序列化

### UI 測試
- [ ] 週報頁面美觀清晰
- [ ] 各分區內容正確顯示
- [ ] 進度條視覺化準確
- [ ] 建議項目易讀

### 集成測試
- [ ] 定時器正確觸發週報生成
- [ ] API 呼叫成功與失敗都被正確處理
- [ ] 週報正確存儲至資料庫
- [ ] 推送通知正確發送

## 非功能需求

- **效能**：
  - API 回應時間 < 10 秒
  - 週報頁面加載 < 1 秒
  
- **可靠性**：
  - API 失敗時保留上週報告作為備份
  - 若無足夠數據，顯示「本週數據不足」提示
  
- **準確性**：
  - 分析需基於完整的 7 天數據
  - 建議具體且可行

## API 失敗處理

| 情況 | 處理方式 |
|------|--------|
| API 超時 | 顯示「正在生成，請稍候」，延後重試 |
| 配額超限 | 顯示「今日分析次數已滿」，明天重試 |
| 網路錯誤 | 顯示「網路連接有問題」，允許手動重試 |
| 無足夠數據 | 顯示「需要至少 3 天的記錄才能生成週報」 |

## 推送通知

- **時間**：每週一早上 7:00
- **內容**：「你的週報已準備好！來看看這週的成長吧😊」
- **操作**：輕點進入週報詳情
- **可配置**：使用者可在設定中關閉通知

## 相依項

- Gemini API 配額充足
- 至少 3-7 天的日記數據
- 生理數據完整性 ≥ 50%
- 網路連接穩定

## 相關文件

- [身心整合洞察規格](health-insights.md)
- [AI 聊天日記規格](ai-chat-diary.md)
- [情緒日曆規格](emotion-calendar.md)
