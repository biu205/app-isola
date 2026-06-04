# APP 鎖隱私保護功能規格

## 基本資訊
- **功能名稱**：APP 鎖（App Lock）
- **版本**：v1.1
- **狀態**：實作中
- **優先度**：高
- **建立日期**：2026-05-31

## 目的
透過生物識別（Face ID/Touch ID）與密碼雙重保護，防止未授權人員存取個人隱私日記，建立安全可信任的紀錄環境，鼓勵使用者更坦誠地記錄情緒。

## 範圍

### In-Scope（包含）
- Face ID / Touch ID 身份驗證
- 密碼備份驗證
- 密碼設定與變更
- 密碼遺忘恢復流程
- 驗證失敗次數限制
- 安全儲存（Keychain）

### Out-of-Scope（不包含）
- 部分功能鎖定（階段二）
- PIN 碼替代方案（未規劃）
- 遠端鎖定（不在範圍內）

## 使用者故事

### 故事 1：隱私保護
**As a** 重視隱私的使用者  
**I want to** App 使用生物識別鎖定，防止他人查看我的日記  
**So that** 我能安心地記錄最真實的情緒

### 故事 2：安全備份
**As a** 擔心忘記密碼的使用者  
**I want to** 設定密碼作為 Face/Touch ID 失敗時的備份  
**So that** 我不會被永久鎖在 App 外

### 故事 3：密碼恢復
**As a** 忘記密碼的使用者  
**I want to** 透過身份驗證（郵件/安全問題）重設密碼  
**So that** 我能重新存取 App

## 功能流程

### 初次設定

```
1. 使用者首次打開 App
2. 系統檢測裝置是否支援 Face/Touch ID
3. 若支援，提示「設定安全鎖定」
4. 使用者選擇：
   a. 啟用 Face ID / Touch ID
   b. 不使用生物識別
5. 若選 a，完成設定
6. 若選 b，提示「強烈建議啟用」但允許跳過
7. 設定密碼作為備份
8. 確認密碼
9. 顯示「設定完成」
```

### 日常使用

```
1. 使用者退出 App 或鎖屏
2. 重新打開 App
3. 系統立即要求生物識別驗證
4. 使用者進行 Face ID / Touch ID
5. 若成功，進入 App
6. 若失敗，允許重試（最多 3 次）
7. 3 次失敗後，要求輸入密碼
8. 密碼正確則進入 App
9. 密碼錯誤則顯示錯誤訊息與「忘記密碼」選項
```

### 密碼遺忘

```
1. 使用者點擊「忘記密碼」
2. 系統提示「驗證你的身份」
3. 選項 A: 透過 Email 驗證
   - 發送驗證碼至註冊郵箱
   - 使用者輸入驗證碼
4. 選項 B: 回答安全問題（之前設定）
   - 系統顯示 2 個安全問題
   - 使用者正確回答 2 個即可
5. 驗證成功後進入「重設密碼」頁面
6. 使用者輸入新密碼 × 2
7. 密碼重設完成
```

## 驗收標準

- [ ] 首次啟動時正確偵測生物識別能力
- [ ] Face ID / Touch ID 驗證能正常工作
- [ ] 驗證失敗時顯示友善提示
- [ ] 3 次失敗後顯示密碼輸入選項
- [ ] 密碼能正確設定與驗證
- [ ] 密碼儲存至 Keychain（已加密）
- [ ] 忘記密碼流程能正常運行
- [ ] Email 驗證碼正確發送
- [ ] 安全問題設定與驗證正確
- [ ] 未驗證時無法存取 App 內容
- [ ] App 背景化後返回時需重新驗證

## 技術實現

### 使用的框架
- **LocalAuthentication**：Face ID / Touch ID
- **Security**：密碼加密
- **Keychain Services**：安全儲存

### 密碼儲存與驗證

```swift
import LocalAuthentication
import Security

class AppLockManager {
    
    // 設定密碼
    func setPassword(_ password: String) throws {
        let hashedPassword = hashPassword(password)
        try saveToKeychain(hashedPassword, key: "app_lock_password")
    }
    
    // 驗證密碼
    func verifyPassword(_ password: String) -> Bool {
        guard let storedHash = retrieveFromKeychain(key: "app_lock_password") else {
            return false
        }
        let inputHash = hashPassword(password)
        return inputHash == storedHash
    }
    
    // 密碼雜湊
    private func hashPassword(_ password: String) -> String {
        // 使用 bcrypt 或 PBKDF2
        // 推薦使用 bcrypt 更安全
        return BCrypt.hash(password)
    }
    
    // 生物識別驗證
    func authenticateWithBiometric(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, 
                                        error: &error) else {
            completion(false, error)
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                               localizedReason: "驗證身份以存取 isola") { success, error in
            completion(success, error)
        }
    }
}
```

### Keychain 儲存

```swift
// 儲存密碼至 Keychain
func saveToKeychain(_ value: String, key: String) throws {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecValueData as String: value.data(using: .utf8)!,
        kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    ]
    
    SecItemDelete(query as CFDictionary)
    let status = SecItemAdd(query as CFDictionary, nil)
    
    guard status == errSecSuccess else {
        throw KeychainError.saveFailed
    }
}

// 從 Keychain 讀取
func retrieveFromKeychain(key: String) -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecReturnData as String: true
    ]
    
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    
    guard status == errSecSuccess,
          let data = result as? Data,
          let string = String(data: data, encoding: .utf8) else {
        return nil
    }
    return string
}
```

### 驗證失敗計數

```swift
class BiometricFailureTracker {
    private let maxAttempts = 3
    private let lockoutDuration: TimeInterval = 60 // 秒
    
    private var failureCount = 0
    private var lockoutEndTime: Date?
    
    func recordFailure() {
        failureCount += 1
        if failureCount >= maxAttempts {
            lockoutEndTime = Date().addingTimeInterval(lockoutDuration)
        }
    }
    
    func isLockedOut() -> Bool {
        guard let endTime = lockoutEndTime else { return false }
        if Date() > endTime {
            failureCount = 0
            lockoutEndTime = nil
            return false
        }
        return true
    }
    
    func reset() {
        failureCount = 0
        lockoutEndTime = nil
    }
}
```

## 資料結構

```swift
struct AppLockSettings {
    var isBiometricEnabled: Bool
    var biometricType: BiometricType // faceID, touchID, none
    var passwordSet: Bool
    var lastAuthenticationTime: Date?
    var failureCount: Int
    var isLockedOut: Bool
}

enum BiometricType {
    case faceID
    case touchID
    case none
}
```

## 設定流程 UI

```
┌─────────────────────────┐
│   🔒 設定安全鎖定       │
├─────────────────────────┤
│                         │
│ 1️⃣ 啟用 Face ID        │
│ [啟用] [跳過]           │
│                         │
│ 2️⃣ 設定密碼            │
│ 密碼: [___________]     │
│ 確認: [___________]     │
│                         │
│ ℹ️ 密碼需 8-16 個字符   │
│ 包含大小寫與數字        │
│                         │
│ [完成設定]              │
│                         │
└─────────────────────────┘
```

## 驗證 UI

```
┌──────────────────────────┐
│   🔓 驗證身份             │
├──────────────────────────┤
│                          │
│ 使用 Face ID 解鎖 isola │
│                          │
│ [生物識別圖示]           │
│                          │
│ 驗證失敗 1/3             │
│ 重試或輸入密碼           │
│                          │
│ 密碼: [___________]      │
│                          │
│ [驗證] [忘記密碼]        │
│                          │
└──────────────────────────┘
```

## 測試要點

### 單元測試
- [ ] 密碼雜湊正確
- [ ] Keychain 儲存與讀取正確
- [ ] 驗證失敗計數邏輯正確
- [ ] 鎖定時間判定正確

### 功能測試
- [ ] Face ID / Touch ID 設定正常
- [ ] 生物識別驗證工作流正常
- [ ] 密碼驗證工作流正常
- [ ] 3 次失敗後鎖定生物識別
- [ ] 忘記密碼流程正常

### 安全測試
- [ ] 密碼不會以明文存儲
- [ ] Keychain 訪問權限限制（僅本 App）
- [ ] 背景時 App 內容不可見
- [ ] 無法透過日誌或偵錯工具訪問密碼

## 非功能需求

- **安全性**：
  - 密碼使用 bcrypt 加密（強度係數 ≥ 10）
  - 所有驗證信息本地處理，不上傳伺服器
  - 驗證失敗後 60 秒鎖定
  
- **效能**：
  - 生物識別驗證 < 2 秒
  - 密碼驗證 < 1 秒
  - 背景回到前景時立即要求驗證
  
- **可用性**：
  - 驗證介面清晰易懂
  - 提供視覺反饋（成功/失敗）
  - 忘記密碼流程不超過 3 步

## 隱私合規

- 生物識別數據永不上傳或儲存至伺服器
- 密碼僅本地加密存儲
- 使用者可隨時禁用 App 鎖
- 符合 GDPR 與 CCPA 規範

## 密碼要求

| 要求 | 詳情 |
|------|------|
| 最少長度 | 8 個字符 |
| 最大長度 | 16 個字符 |
| 必須包含 | 大寫、小寫、數字各至少 1 個 |
| 不允許 | 連續相同字符（e.g., "AAA"） |
| 不允許 | 常見密碼（e.g., "123456", "password"） |

## 相關文件

- [安全性與隱私規格](security-privacy.md)（未建立）
- [使用者認證規格](authentication.md)（未建立）
