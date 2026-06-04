# 度Q成就系統功能規格

## 基本資訊
- **功能名稱**：度Q成就系統（DuQ Achievement System）
- **版本**：v1.1
- **狀態**：實作中
- **優先度**：中
- **建立日期**：2026-05-31

## 目的
透過遊戲化的成就解鎖機制，將使用者的日記記錄行為具象化為虛擬角色的成長與裝飾，激發「想要完成記錄」的動力，建立長期使用習慣。

## 範圍

### In-Scope（包含）
- 度Q 角色展示
- 配件解鎖系統（基於記錄次數）
- 成就徽章系統
- 裝飾應用與展示
- 里程碑慶祝
- 成就歷史查看

### Out-of-Scope（不包含）
- 自訂角色外觀（階段二）
- 角色進階形態（階段二）
- 社交展示（階段二）

## 使用者故事

### 故事 1：虛擬角色成長
**As a** 喜歡看到進度視覺化的使用者  
**I want to** 我的日記記錄能在虛擬角色上體現，看到它逐漸變得漂亮  
**So that** 我每次記錄都有成就感

### 故事 2：解鎖新配件
**As a** 喜歡收集的使用者  
**I want to** 透過記錄日記來解鎖新的衣服、配件、擺飾  
**So that** 我有明確的小目標推動我每天記錄

### 故事 3：展示進度
**As a** 自豪於堅持的使用者  
**I want to** 看到我已經記錄了多少篇日記，達成了什麼成就  
**So that** 我能為自己的堅持感到驕傲

## 功能流程

```
1. 使用者首次進入 App
2. 系統生成個人的「度Q」角色（虛擬圖片化身）
3. 每當使用者完成日記記錄：
   - 系統紀錄記錄次數 +1
   - 檢查是否達成解鎖條件
4. 達成條件時：
   - 觸發「配件解鎖」動畫
   - 顯示「恭喜！解鎖新配件」對話
   - 配件自動應用至角色
5. 使用者可進入「我的成就」查看：
   - 度Q 當前裝扮
   - 已解鎖的所有配件
   - 里程碑（10 篇、50 篇、100 篇等）
   - 解鎖時間線
6. 配件可選擇應用或卸下
```

## 驗收標準

- [ ] 首次打開 App 時生成度Q 角色
- [ ] 角色展示頁面清晰美觀
- [ ] 記錄日記後配件解鎖條件正確檢查
- [ ] 達成條件時顯示解鎖動畫與通知
- [ ] 解鎖的配件正確存儲
- [ ] 已應用的配件正確顯示在角色上
- [ ] 成就頁面展示所有已解鎖與未解鎖的配件
- [ ] 里程碑正確標記（10、50、100、365 篇等）
- [ ] 配件可卸下與重新應用
- [ ] 帳戶切換時成就資料正確同步

## 技術實現

### 資料結構
```swift
struct DuQCharacter {
    let userId: String
    var outfit: CharacterOutfit
    var accessories: [Accessory]
    var unlockedAchievements: [Achievement]
    var totalDiaryCount: Int
    var createdAt: Date
}

struct CharacterOutfit {
    let id: UUID
    let baseColor: Color
    let expressions: [Expression]
    var appliedAccessories: [UUID] // 配件 ID
}

struct Accessory {
    let id: UUID
    let name: String
    let description: String
    let category: AccessoryCategory // hat, shirt, shoes, etc.
    let unlockedAt: Date? // nil if not yet unlocked
    var isApplied: Bool
}

enum AccessoryCategory {
    case hat, shirt, pants, shoes, hand, back, face, ground
}

struct Achievement {
    let id: UUID
    let title: String
    let description: String
    let unlockedAt: Date
    let milestone: Int // 記錄篇數里程碑
}

enum Expression {
    case happy, excited, content, peaceful
}
```

### 配件解鎖規則

| 里程碑 | 配件 | 描述 |
|--------|------|------|
| 1篇 | 基礎服飾 | 簡單的日常服裝 |
| 5篇 | 小帽子 | 可愛的貝雷帽 |
| 10篇 | 新上衣 | 彩色T恤 |
| 15篇 | 配件組 | 項鍊或手鍊 |
| 20篇 | 特殊褲子 | 牛仔褲或運動褲 |
| 30篇 | 鞋子 | 運動鞋或靴子 |
| 50篇 | 配飾帽 | 特殊主題帽子 |
| 100篇 | 背包 | 個性背包 |
| 365篇 | 專屬皮膚 | 週年紀念獨特皮膚 |

### 解鎖檢查邏輯
```swift
func checkAndUnlockAchievements() {
    let currentCount = calculateTotalDiaryCount()
    
    let unlockRules = [
        (milestone: 1, accessoryId: "basic_outfit"),
        (milestone: 5, accessoryId: "cute_hat"),
        (milestone: 10, accessoryId: "colorful_shirt"),
        // ... 更多規則
    ]
    
    for rule in unlockRules {
        if currentCount >= rule.milestone && 
           !isAccessoryUnlocked(rule.accessoryId) {
            unlockAccessory(rule.accessoryId)
            showUnlockAnimation()
            sendNotification()
        }
    }
}
```

### 動畫與視覺效果
- 解鎖動畫：粒子效果 + 角色旋轉 + 配件飛入
- 應用配件時：角色上的配件平滑變化
- 里程碑達成：全屏慶祝動畫 + 音效

## 角色展示頁面布局

```
┌─────────────────────────┐
│        我的度Q           │
├─────────────────────────┤
│                         │
│         [角色圖片]      │
│      (穿著已應用配件)   │
│                         │
│  📊 記錄統計            │
│  總記錄數: 47 篇        │
│  連續記錄: 12 天        │
│  本月: 8 篇             │
│                         │
│  🎁 已解鎖配件 (6/10)  │
│  [帽子] [衣服] [褲子]   │
│  [鞋子] [項鍊] [包包]   │
│                         │
│  🔒 待解鎖配件         │
│  [特殊皮膚] @ 100篇     │
│  進度: ████░░░░░░ 47%   │
│                         │
└─────────────────────────┘
```

## 成就頁面布局

```
┌──────────────────────────┐
│   🏆 我的成就            │
├──────────────────────────┤
│                          │
│ 📝 記錄里程碑            │
│ ✓ 10 篇日記 (2026/3/15) │
│ ✓ 50 篇日記 (2026/5/01) │
│ ⏳ 100 篇日記 (47% 進度) │
│ ◯ 365 篇日記            │
│                          │
│ 🎯 連續記錄              │
│ ✓ 7 天連續 (2026/3/20)  │
│ ✓ 30 天連續 (2026/4/18) │
│ ◯ 100 天連續            │
│                          │
│ 🎊 特殊成就              │
│ ✓ 每日問答高手          │
│   (完成 20 個問答)       │
│ ✓ AI 聊天大使            │
│   (完成 10 個聊天日記)   │
│                          │
└──────────────────────────┘
```

## 測試要點

### 單元測試
- [ ] 記錄次數計數正確
- [ ] 解鎖條件檢查邏輯正確
- [ ] 配件應用與卸下邏輯正確
- [ ] 成就資料正確序列化

### UI 測試
- [ ] 角色展示清晰美觀
- [ ] 解鎖動畫流暢無卡頓
- [ ] 配件在角色上正確顯示
- [ ] 成就頁面所有內容正確呈現

### 集成測試
- [ ] 日記記錄後解鎖檢查正確觸發
- [ ] 解鎖資料正確存儲與同步
- [ ] 帳戶切換時數據一致性
- [ ] 舊帳戶遷移時成就保留

## 非功能需求

- **效能**：
  - 角色加載 < 500ms
  - 解鎖檢查 < 1 秒
  - 動畫幀率 ≥ 60fps
  
- **儲存**：角色資料 < 5MB（包含圖片）
- **同步**：成就資料實時同步至 Firestore

## 配件美術要求

- **格式**：PNG (透明背景) 或 SVG
- **解析度**：2x, 3x (@2x, @3x)
- **大小**：單個配件 < 500KB
- **風格**：可愛/溫暖美學，與 isola 品牌一致

## 相依項

- 美術配件素材完整（≥ 20 個配件）
- SwiftData 存儲空間
- Firestore 同步正常

## 社群功能預留

未來階段可考慮：
- 配件交換/贈送
- 成就分享
- 排行榜
- 協作解鎖

## 相關文件

- [情緒日曆規格](emotion-calendar.md)
- [AI 週報規格](weekly-report.md)
