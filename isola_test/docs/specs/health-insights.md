# 身心整合洞察功能規格

## 基本資訊
- **功能名稱**：身心整合洞察（Mind-Body Integration Insights）
- **版本**：v1.1
- **狀態**：實作中
- **優先度**：高
- **建立日期**：2026-05-31

## 目的
透過自動採集使用者的生理數據（睡眠、心跳變異數、心情指數等），並與日記內容關聯，幫助使用者發現個人的「情緒-生理模式」，提供更全面的自我認知與個性化洞察。

## 範圍

### In-Scope（包含）
- Apple HealthKit 數據自動採集
- 生理觀測頁面展示
- 日記內容與生理數據關聯
- 模式識別演算法
- 個性化洞察生成
- 追蹤目標設定

### Out-of-Scope（不包含）
- 其他穿戴裝置整合（階段二）
- 醫療級診斷（不在範圍內）
- 第三方穿戴設備支援（階段二）

## 使用者故事

### 故事 1：發現自己的模式
**As a** 想了解自己身心關係的使用者  
**I want to** 看到我的睡眠、心跳和情緒之間的關聯  
**So that** 我能理解什麼因素影響我的情緒

### 故事 2：獲得個性化建議
**As a** 需要改善身體狀況的使用者  
**I want to** 系統根據我的數據給出可實行的建議  
**So that** 我知道該從何著手改善

### 故事 3：追蹤進度
**As a** 目標導向的使用者  
**I want to** 能設定睡眠或運動目標，並追蹤達成情況  
**So that** 我能看到自己的進步

## 功能流程

```
1. 使用者首次進入「身心洞察」頁面
2. 系統請求 HealthKit 授權（睡眠、心率、心情指數）
3. 使用者授權後，系統開始背景自動採集
4. 每日自動讀取過去 24 小時的生理數據
5. 與該日期的日記內容進行關聯匹配
6. 識別模式（例：睡眠不足 → 焦慮上升）
7. 顯示於「生理觀測」頁面
8. 使用者可查看趨勢圖表
9. 使用者可設定追蹤目標
10. 目標進度實時更新
```

## 驗收標準

- [ ] App 首次啟動時正確請求 HealthKit 授權
- [ ] 授權後能成功讀取睡眠數據
- [ ] 授權後能成功讀取心率變異數
- [ ] 授權後能成功讀取心情指數
- [ ] 生理觀測頁面正確顯示過去 7 天數據
- [ ] 數據圖表清晰易讀（趨勢線、數據點）
- [ ] 日記與生理數據正確關聯顯示
- [ ] 模式識別演算法能檢測出主要相關性
- [ ] 使用者能設定並修改追蹤目標
- [ ] 目標進度視覺化顯示（進度條/百分比）
- [ ] 無 HealthKit 授權時有友善的引導提示

## 技術實現

### 支援的生理指標

| 指標 | 來源 | 更新頻率 | 單位 |
|------|------|--------|------|
| 睡眠時數 | HealthKit | 每日 | 小時 |
| 心跳變異數 (HRV) | HealthKit | 每日 | ms |
| 心情指數 | HealthKit (Mood) | 每日 | 1-5 |
| 步數 | HealthKit | 每日 | 步 |
| 運動時間 | HealthKit | 每日 | 分鐘 |
| 心率 (靜息) | HealthKit | 每日 | bpm |

### 資料結構
```swift
struct HealthSnapshot {
    let id: UUID
    let date: Date
    let sleepHours: Double?
    let hrv: Double? // Heart Rate Variability
    let moodIndex: Int? // 1-5
    let stepCount: Int?
    let exerciseMinutes: Double?
    let restingHeartRate: Double?
}

struct PatternInsight {
    let id: UUID
    let pattern: String // e.g., "sleep_mood_correlation"
    let description: String
    let confidence: Double // 0.0-1.0
    let relatedMetrics: [String]
    let generatedAt: Date
}

struct TrackingGoal {
    let id: UUID
    let metric: String // "sleep", "exercise", etc.
    let targetValue: Double
    let timeframe: String // "weekly", "monthly"
    let createdAt: Date
    var progress: Double
}
```

### HealthKit 授權流程
```swift
// 請求授權的健康類別
let healthTypes: Set<HKSampleType> = [
    HKSampleType.categoryType(forIdentifier: .sleepAnalysis)!,
    HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
    HKCategoryType.categoryType(forIdentifier: .mindfulSession)!,
    HKQuantityType.quantityType(forIdentifier: .stepCount)!,
    HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!,
    HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
]

healthStore.requestAuthorization(toShare: nil, read: healthTypes) { success, error in
    if success {
        // 開始定期採集
    }
}
```

### 模式識別演算法
- 使用皮爾遜相關係數計算指標間的相關性
- 偵測 >= 0.6 相關係數的模式
- 需要至少 7 天的數據才能生成洞察
- 每週重新計算一次

## 測試要點

### 單元測試
- [ ] HealthKit 數據正確解析
- [ ] 相關係數計算正確
- [ ] 模式識別邏輯正確識別相關性
- [ ] 目標進度計算正確

### UI 測試
- [ ] 授權對話正確顯示
- [ ] 生理觀測頁面所有圖表正確呈現
- [ ] 圖表資料標籤清晰
- [ ] 目標頁面 UI 直觀
- [ ] 進度條視覺化準確

### 集成測試
- [ ] HealthKit 授權流程正常
- [ ] 數據正確存儲至 SwiftData
- [ ] 模式識別結果正確關聯日記
- [ ] 背景更新不影響 App 效能

## 非功能需求

- **效能**：
  - 圖表加載 < 1 秒
  - 模式計算 < 5 秒（後台進行）
  - 每日後台更新 < 30 秒
  
- **隱私**：
  - 所有健康數據本地存儲
  - 上傳至雲端前加密
  - 使用者可隨時撤銷授權

- **準確性**：
  - HRV 數據需來自 Apple Watch 或相容設備
  - 心情指數由 iOS 內建情緒追蹤
  - 模式信心度需 >= 0.6

## 隱私合規

- 明確告知使用者將存取哪些健康數據
- 提供隱私政策連結
- 使用者可在「設定」中隨時撤銷授權
- 健康數據永不與第三方共享

## 生理觀測頁面布局

```
┌─────────────────────┐
│   生理觀測 (Insights) │
├─────────────────────┤
│                     │
│  📊 過去 7 天趨勢    │
│  [睡眠 | 心率 | 步數]│
│                     │
│  💡 今週洞察        │
│  • 睡眠不足時焦慮感 │
│    明顯上升 (相關度 │
│    0.72)           │
│                     │
│  🎯 追蹤目標        │
│  • 每日 7h 睡眠     │
│    進度: ████░░ 67% │
│                     │
└─────────────────────┘
```

## 相依項

- HealthKit 框架支援（iOS 17+）
- Apple Watch 或支援設備（可選，提升數據精度）
- 背景更新權限
- 最小存儲空間 ≥ 50MB

## 相關文件

- [AI 週報規格](weekly-report.md)
- [情緒日曆規格](emotion-calendar.md)
- [成就系統規格](achievement-system.md)
