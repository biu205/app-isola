//
//  appLock.swift
//  isola_test
//
//  Created by Qian Hsu on 2026/4/15.
//

import SwiftUI
import LocalAuthentication
import CryptoKit
import Security

// MARK: - Manager

@Observable
class AppLockManager {
    static let shared = AppLockManager()

    var isLocked: Bool = false

    // Cached so body doesn't call LAContext on every render
    private(set) var cachedBiometricType: LABiometryType = .none

    var isPinSet: Bool {
        UserDefaults.standard.bool(forKey: "appLock_enabled")
    }
    var isBiometricEnabled: Bool {
        UserDefaults.standard.bool(forKey: "appLock_biometric")
    }
    var availableBiometricType: LABiometryType { cachedBiometricType }

    private init() {
        isLocked = isPinSet
        let ctx = LAContext()
        var err: NSError?
        if ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) {
            cachedBiometricType = ctx.biometryType
        }
    }

    func setupPin(_ pin: String) {
        keychainSave(saltedHash(pin), forKey: "appLock_pinHash")
        UserDefaults.standard.set(true, forKey: "appLock_enabled")
    }

    func verifyPin(_ pin: String) -> Bool {
        if let keychainHash = keychainLoad(forKey: "appLock_pinHash") {
            return saltedHash(pin) == keychainHash
        }
        // Migrate legacy unsalted UserDefaults hash on first successful verify
        if let legacyHash = UserDefaults.standard.string(forKey: "appLock_pinHash") {
            let unsalted = unsaltedHash(pin)
            if unsalted == legacyHash {
                keychainSave(saltedHash(pin), forKey: "appLock_pinHash")
                UserDefaults.standard.removeObject(forKey: "appLock_pinHash")
                return true
            }
            return false
        }
        return false
    }

    func enableBiometric(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "appLock_biometric")
    }

    func setupSecurityQuestion(index: Int, answer: String) {
        UserDefaults.standard.set(index, forKey: "appLock_questionIndex")
        keychainSave(saltedHash(normalize(answer)), forKey: "appLock_answerHash")
    }

    func verifySecurityAnswer(_ answer: String) -> Bool {
        if let keychainHash = keychainLoad(forKey: "appLock_answerHash") {
            return saltedHash(normalize(answer)) == keychainHash
        }
        // Migrate legacy
        if let legacyHash = UserDefaults.standard.string(forKey: "appLock_answerHash") {
            let unsalted = unsaltedHash(normalize(answer))
            if unsalted == legacyHash {
                keychainSave(saltedHash(normalize(answer)), forKey: "appLock_answerHash")
                UserDefaults.standard.removeObject(forKey: "appLock_answerHash")
                return true
            }
            return false
        }
        return false
    }

    var securityQuestion: String? {
        guard isPinSet else { return nil }
        let idx = UserDefaults.standard.integer(forKey: "appLock_questionIndex")
        guard idx < AppLockManager.questions.count else { return nil }
        return AppLockManager.questions[idx]
    }

    func disableLock() {
        ["appLock_enabled", "appLock_biometric", "appLock_questionIndex"].forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
        keychainDelete(forKey: "appLock_pinHash")
        keychainDelete(forKey: "appLock_answerHash")
        isLocked = false
    }

    func unlock() { isLocked = false }
    func lock() { if isPinSet { isLocked = true } }

    func authenticateWithBiometrics() async -> Bool {
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else { return false }
        do {
            return try await ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "解鎖 isola")
        } catch { return false }
    }

    static let questions = [
        "你的第一隻寵物叫什麼名字？",
        "你小時候住的街道叫什麼？",
        "你媽媽的姓氏是？",
        "你最喜歡的電影是什麼？",
        "你的出生城市是哪裡？"
    ]

    // MARK: - Hashing (salted SHA-256)

    private var installSalt: String {
        if let existing = keychainLoad(forKey: "appLock_salt") { return existing }
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let salt = bytes.map { String(format: "%02x", $0) }.joined()
        keychainSave(salt, forKey: "appLock_salt")
        return salt
    }

    private func saltedHash(_ input: String) -> String {
        SHA256.hash(data: Data((installSalt + input).utf8))
            .compactMap { String(format: "%02x", $0) }.joined()
    }

    private func unsaltedHash(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .compactMap { String(format: "%02x", $0) }.joined()
    }

    private func normalize(_ s: String) -> String {
        s.lowercased().trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Keychain helpers

    private let keychainService = "isola.applock"

    private func keychainSave(_ value: String, forKey account: String) {
        let data = Data(value.utf8)
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: account,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        query[kSecValueData] = data
        SecItemAdd(query as CFDictionary, nil)
    }

    private func keychainLoad(forKey account: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func keychainDelete(forKey account: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Shared PIN Dots

private struct PinDotsView: View {
    let count: Int
    private let total = 4

    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<total, id: \.self) { i in
                if i < count {
                    Image("度Ｑ1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 30, height: 30)
                        .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                }
            }
        }
    }
}

// MARK: - Shared Numpad

private struct NumPadView: View {
    let isDark: Bool
    let onTap: (String) -> Void
    let onDelete: () -> Void

    private var keyBg: Color {
        // matches systemGray5 approximation for both modes
        isDark ? Color(red: 0.22, green: 0.22, blue: 0.24) : Color(white: 0.90)
    }

    var body: some View {
        VStack(spacing: 30) {
            numRow(["1","2","3"])
            numRow(["4","5","6"])
            numRow(["7","8","9"])
            HStack(spacing: 24) {
                Circle().fill(Color.clear).frame(width: 72, height: 72)
                numKey("0")
                Button { onDelete() } label: {
                    Image(systemName: "delete.left")
                        .font(.title2)
                        .frame(width: 72, height: 72)
                }
                .foregroundColor(.primary)
            }
        }
    }

    private func numRow(_ row: [String]) -> some View {
        HStack(spacing: 24) {
            ForEach(row, id: \.self) { key in numKey(key) }
        }
    }

    private func numKey(_ key: String) -> some View {
        Button { onTap(key) } label: {
            Text(key)
                .font(.title)
                .frame(width: 72, height: 72)
                .background(keyBg)
                .clipShape(Circle())
        }
        .foregroundColor(.primary)
    }
}

// MARK: - Settings Entry (App鎖 in SettingView)

struct AppLockSettingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var manager = AppLockManager.shared
    @State private var showSetup = false
    @State private var showDisableConfirm = false
    @State private var showChangePinVerify = false
    @AppStorage("appearanceMode") private var appearanceMode: Int = AppTheme.system.rawValue

    private var isDark: Bool {
        switch AppTheme(rawValue: appearanceMode) ?? .system {
        case .light: return false
        case .dark: return true
        case .system: return Calendar.current.component(.hour, from: Date()) >= 19
        }
    }
    private var currentTheme: AppTheme { AppTheme(rawValue: appearanceMode) ?? .system }
    private var backgroundColor: Color {
        isDark ? Color(red: 0.082, green: 0.114, blue: 0.169)
               : Color(red: 0.992, green: 0.984, blue: 0.941)
    }
    private var textColor: Color { isDark ? .white : .black }
    private var cardBackground: Color {
        isDark ? Color(red: 0.173, green: 0.173, blue: 0.180) : Color(white: 0.97)
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            if manager.isPinSet {
                // 已啟用：置中展示 + 底部設定卡片
                VStack(spacing: 0) {
                    Spacer()

                    // 上方置中：圖示 + 狀態
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.12))
                                .frame(width: 120, height: 120)
                            Image("健康度Ｑ")
                                .resizable()
                                .frame(width: 100, height: 80)
                                .font(.system(size: 52))
                                .foregroundColor(.accentColor)
                        }
                        VStack(spacing: 8) {
                            Text("App 鎖已啟用")
                                .font(.title2.bold())
                                .foregroundColor(textColor)
                            Label("你的 isola 受到保護", systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }

                    Spacer()

                    // 下方：設定選項卡片
                    VStack(spacing: 0) {
                        if manager.availableBiometricType != .none {
                            HStack {
                                Text(biometricLabel).foregroundColor(textColor)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { manager.isBiometricEnabled },
                                    set: { manager.enableBiometric($0) }
                                ))
                                .labelsHidden()
                            }
                            .padding(.horizontal, 20)
                            .frame(height: 56)
                            Divider().padding(.horizontal, 20)
                        }

                        Button { showChangePinVerify = true } label: {
                            Text("更改密碼")
                                .foregroundColor(.accentColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .frame(height: 56)
                        }

                        Divider().padding(.horizontal, 20)

                        Button { showDisableConfirm = true } label: {
                            Text("停用 App 鎖")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .frame(height: 56)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(cardBackground)
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
                }

            } else {
                // 未啟用：置中引導畫面
                VStack(spacing: 28) {
                    Spacer()
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 72, weight: .thin))
                        .foregroundColor(.secondary)

                    VStack(spacing: 10) {
                        Text("保護你的 isola")
                            .font(.title2.bold())
                            .foregroundColor(textColor)
                        Text("設定四位數密碼，防止他人查看你的日記")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    Button { showSetup = true } label: {
                        Label("啟用 App 鎖", systemImage: "lock.fill")
                            .font(.body.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 36)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(Color.accentColor))
                    }
                    Spacer()
                }
            }

            // 停用確認懸浮視窗
            if showDisableConfirm {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { showDisableConfirm = false }

                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.red)
                            .padding(.top, 28)

                        Text("停用 App 鎖")
                            .font(.title3.bold())
                            .foregroundColor(textColor)

                        Text("停用後，任何人都可以\n直接開啟 isola。")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8)
                    }

                    Divider()

                    Button {
                        showDisableConfirm = false
                        manager.disableLock()
                    } label: {
                        Text("停用")
                            .font(.body.bold())
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }

                    Divider()

                    Button {
                        showDisableConfirm = false
                    } label: {
                        Text("取消")
                            .font(.body)
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(cardBackground)
                )
                .padding(.horizontal, 48)
                .padding(.bottom, 50)
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showDisableConfirm)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showDisableConfirm)
        .navigationTitle("App 鎖")
        .preferredColorScheme(currentTheme.colorScheme)
        .navigationDestination(isPresented: $showSetup) {
            AppLockSetupView(mode: .firstTime) { showSetup = false }
        }
        .navigationDestination(isPresented: $showChangePinVerify) {
            AppLockSetupView(mode: .change) { showChangePinVerify = false }
        }
    }

    private var biometricLabel: String {
        manager.availableBiometricType == .faceID ? "使用 Face ID" : "使用 Touch ID"
    }
}

// MARK: - Setup Flow

struct AppLockSetupView: View {
    enum Mode { case firstTime, change }
    enum Step { case verifyOld, enterPin, confirmPin, biometric, securityQuestion, success }

    let mode: Mode
    let onComplete: () -> Void

    @State private var step: Step = .enterPin
    @State private var firstPin = ""
    @State private var confirmPin = ""
    @State private var mismatch = false
    @State private var selectedQuestion = 0
    @State private var answer = ""
    @State private var verifyOldPin = ""
    @State private var wrongOldPin = false
    @State private var manager = AppLockManager.shared
    @AppStorage("appearanceMode") private var appearanceMode: Int = AppTheme.system.rawValue

    private var isDark: Bool {
        switch AppTheme(rawValue: appearanceMode) ?? .system {
        case .light: return false
        case .dark: return true
        case .system: return Calendar.current.component(.hour, from: Date()) >= 19
        }
    }
    private var currentTheme: AppTheme { AppTheme(rawValue: appearanceMode) ?? .system }
    private var backgroundColor: Color {
        isDark ? Color(red: 0.082, green: 0.114, blue: 0.169)
               : Color(red: 0.992, green: 0.984, blue: 0.941)
    }
    private var textColor: Color { isDark ? .white : .black }
    private var fieldBackground: Color {
        isDark ? Color(red: 0.173, green: 0.173, blue: 0.180) : Color(white: 0.93)
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                switch step {
                case .verifyOld:        verifyOldPinView
                case .enterPin:         enterPinView
                case .confirmPin:       confirmPinView
                case .biometric:        biometricView
                case .securityQuestion: securityQuestionView
                case .success:          successView
                }
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(step != .verifyOld && step != .enterPin)
        .preferredColorScheme(currentTheme.colorScheme)
        .onAppear {
            step = (mode == .change) ? .verifyOld : .enterPin
        }
    }

    // MARK: Step Views

    private var verifyOldPinView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.rotation")
                .font(.system(size: 48)).foregroundColor(.accentColor)
            Text("輸入目前密碼").font(.title2.bold()).foregroundColor(textColor)
            PinDotsView(count: verifyOldPin.count)
                .animation(.easeInOut, value: verifyOldPin.count)
            if wrongOldPin {
                Text("密碼錯誤，請再試一次")
                    .foregroundColor(.red).font(.caption).transition(.opacity)
            }
            NumPadView(isDark: isDark,
                onTap: { digit in
                    guard verifyOldPin.count < 4 else { return }
                    verifyOldPin += digit; wrongOldPin = false
                    if verifyOldPin.count == 4 {
                        if manager.verifyPin(verifyOldPin) {
                            step = .enterPin; verifyOldPin = ""
                        } else {
                            withAnimation { wrongOldPin = true }
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(400))
                                verifyOldPin = ""
                            }
                        }
                    }
                },
                onDelete: { if !verifyOldPin.isEmpty { verifyOldPin.removeLast() } }
            )
        }
        .padding(.horizontal)
    }

    private var enterPinView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48)).foregroundColor(.accentColor)
            Text("設定四位數密碼").font(.title2.bold()).foregroundColor(textColor)
            Text("這組密碼用來保護你的 isola")
                .font(.subheadline).foregroundColor(.secondary)
            PinDotsView(count: firstPin.count)
                .animation(.easeInOut, value: firstPin.count)
            NumPadView(isDark: isDark,
                onTap: { digit in
                    guard firstPin.count < 4 else { return }
                    firstPin += digit
                    if firstPin.count == 4 {
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(150))
                            step = .confirmPin
                        }
                    }
                },
                onDelete: { if !firstPin.isEmpty { firstPin.removeLast() } }
            )
        }
        .padding(.horizontal)
    }

    private var confirmPinView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48)).foregroundColor(.accentColor)
            Text("再輸入一次確認").font(.title2.bold()).foregroundColor(textColor)
            PinDotsView(count: confirmPin.count)
                .animation(.easeInOut, value: confirmPin.count)
            if mismatch {
                Text("密碼不相符，請重新輸入")
                    .foregroundColor(.red).font(.caption).transition(.opacity)
            }
            NumPadView(isDark: isDark,
                onTap: { digit in
                    guard confirmPin.count < 4 else { return }
                    confirmPin += digit; mismatch = false
                    if confirmPin.count == 4 {
                        if confirmPin == firstPin {
                            manager.setupPin(confirmPin)
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(150))
                                step = manager.availableBiometricType != .none ? .biometric : .securityQuestion
                            }
                        } else {
                            withAnimation { mismatch = true }
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(400))
                                confirmPin = ""; firstPin = ""; step = .enterPin
                            }
                        }
                    }
                },
                onDelete: { if !confirmPin.isEmpty { confirmPin.removeLast() } }
            )
        }
        .padding(.horizontal)
    }

    private var biometricView: some View {
        VStack(spacing: 24) {
            Image(systemName: manager.availableBiometricType == .faceID ? "faceid" : "touchid")
                .font(.system(size: 64)).foregroundColor(.accentColor)
            Text(manager.availableBiometricType == .faceID ? "使用 Face ID？" : "使用 Touch ID？")
                .font(.title2.bold()).foregroundColor(textColor)
            Text("啟用後可以快速解鎖，不需輸入密碼")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal)
            VStack(spacing: 12) {
                Button {
                    manager.enableBiometric(true); step = .securityQuestion
                } label: {
                    Text("啟用").frame(maxWidth: .infinity).padding()
                        .background(Color.accentColor).foregroundColor(.white).cornerRadius(12)
                }
                Button {
                    manager.enableBiometric(false); step = .securityQuestion
                } label: {
                    Text("略過").frame(maxWidth: .infinity).padding()
                        .background(fieldBackground).foregroundColor(textColor).cornerRadius(12)
                }
            }
            .padding(.horizontal, 32)
        }
    }

    private var securityQuestionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "questionmark.shield.fill")
                .font(.system(size: 48)).foregroundColor(.accentColor)
            Text("設定安全問題").font(.title2.bold()).foregroundColor(textColor)
            Text("忘記密碼時，用來驗證身分以重設密碼")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("選擇問題").font(.caption).foregroundColor(.secondary)
                Picker("安全問題", selection: $selectedQuestion) {
                    ForEach(AppLockManager.questions.indices, id: \.self) { i in
                        Text(AppLockManager.questions[i]).tag(i)
                    }
                }
                .pickerStyle(.menu)
                .padding(12)
                .background(fieldBackground)
                .cornerRadius(10)
            }
            .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 8) {
                Text("你的答案").font(.caption).foregroundColor(.secondary)
                TextField("輸入答案", text: $answer)
                    .foregroundColor(textColor)
                    .padding(12)
                    .background(fieldBackground)
                    .cornerRadius(10)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 24)

            Button {
                guard !answer.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                manager.setupSecurityQuestion(index: selectedQuestion, answer: answer)
                withAnimation { step = .success }
            } label: {
                Text("完成設定").frame(maxWidth: .infinity).padding()
                    .background(answer.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.gray.opacity(0.35) : Color.accentColor)
                    .foregroundColor(.white).cornerRadius(12)
            }
            .disabled(answer.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal, 32)
        }
    }

    // 設定完成畫面
    private var successView: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 130, height: 130)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 58))
                        .foregroundColor(.green)
                }

                VStack(spacing: 12) {
                    Text(mode == .change ? "密碼更改完成！" : "App 鎖設定完成！")
                        .font(.title2.bold())
                        .foregroundColor(textColor)
                    Text(mode == .change
                         ? "你的新密碼已生效。"
                         : "之後開啟 isola 時，\n需要輸入密碼才能進入。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            Spacer()

            Button { onComplete() } label: {
                Text("完成")
                    .font(.body.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Color.accentColor))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 36)
        }
    }
}

// MARK: - Unlock Screen

struct AppLockUnlockView: View {
    @State private var manager = AppLockManager.shared
    @State private var pin = ""
    @State private var shake = false
    @State private var showReset = false
    @AppStorage("appearanceMode") private var appearanceMode: Int = AppTheme.system.rawValue

    private var isDark: Bool {
        switch AppTheme(rawValue: appearanceMode) ?? .system {
        case .light: return false
        case .dark: return true
        case .system: return Calendar.current.component(.hour, from: Date()) >= 19
        }
    }
    private var currentTheme: AppTheme { AppTheme(rawValue: appearanceMode) ?? .system }
    private var backgroundColor: Color {
        isDark ? Color(red: 0.082, green: 0.114, blue: 0.169)
               : Color(red: 0.992, green: 0.984, blue: 0.941)
    }
    private var textColor: Color { isDark ? .white : .black }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.system(size: 56)).foregroundColor(.accentColor)
                Text("isola").font(.largeTitle.bold()).foregroundColor(textColor)
                Text("請輸入密碼").font(.subheadline).foregroundColor(.secondary)
                PinDotsView(count: pin.count)
                    .offset(x: shake ? -8 : 0)
                    .animation(shake ? .easeInOut(duration: 0.05).repeatCount(5, autoreverses: true) : .default,
                               value: shake)
                NumPadView(isDark: isDark,
                    onTap: { digit in
                        guard pin.count < 4 else { return }
                        pin += digit
                        if pin.count == 4 {
                            if manager.verifyPin(pin) {
                                manager.unlock()
                            } else {
                                withAnimation { shake = true }
                                Task { @MainActor in
                                    try? await Task.sleep(for: .milliseconds(350))
                                    shake = false; pin = ""
                                }
                            }
                        }
                    },
                    onDelete: { if !pin.isEmpty { pin.removeLast() } }
                )
                if manager.isBiometricEnabled && manager.availableBiometricType != .none {
                    Button {
                        Task { if await manager.authenticateWithBiometrics() { manager.unlock() } }
                    } label: {
                        Image(systemName: manager.availableBiometricType == .faceID ? "faceid" : "touchid")
                            .font(.system(size: 32)).foregroundColor(.accentColor)
                    }
                }
                Button("忘記密碼？") { showReset = true }
                    .font(.footnote).foregroundColor(.secondary)
                Spacer()
            }
        }
        .preferredColorScheme(currentTheme.colorScheme)
        .sheet(isPresented: $showReset) {
            AppLockResetView {
                showReset = false
                manager.unlock()
            }
        }
        .onAppear {
            if manager.isBiometricEnabled {
                Task { if await manager.authenticateWithBiometrics() { manager.unlock() } }
            }
        }
    }
}

// MARK: - Reset via Security Question

struct AppLockResetView: View {
    let onSuccess: () -> Void

    @State private var manager = AppLockManager.shared
    @State private var answer = ""
    @State private var wrong = false
    @State private var showNewPin = false
    @AppStorage("appearanceMode") private var appearanceMode: Int = AppTheme.system.rawValue

    private var isDark: Bool {
        switch AppTheme(rawValue: appearanceMode) ?? .system {
        case .light: return false
        case .dark: return true
        case .system: return Calendar.current.component(.hour, from: Date()) >= 19
        }
    }
    private var currentTheme: AppTheme { AppTheme(rawValue: appearanceMode) ?? .system }
    private var backgroundColor: Color {
        isDark ? Color(red: 0.082, green: 0.114, blue: 0.169)
               : Color(red: 0.992, green: 0.984, blue: 0.941)
    }
    private var textColor: Color { isDark ? .white : .black }
    private var fieldBackground: Color {
        isDark ? Color(red: 0.173, green: 0.173, blue: 0.180) : Color(white: 0.93)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()
                VStack(spacing: 28) {
                    Spacer()
                    Image(systemName: "key.fill")
                        .font(.system(size: 48)).foregroundColor(.accentColor)
                    Text("重設密碼").font(.title2.bold()).foregroundColor(textColor)
                    Text("回答安全問題以驗證你的身分")
                        .font(.subheadline).foregroundColor(.secondary)

                    if let question = manager.securityQuestion {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(question)
                                .font(.body.bold()).foregroundColor(textColor)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(fieldBackground)
                                .cornerRadius(10)

                            TextField("輸入答案", text: $answer)
                                .foregroundColor(textColor)
                                .padding(14)
                                .background(fieldBackground)
                                .cornerRadius(10)
                                .autocorrectionDisabled()
                                .onChange(of: answer) { _, _ in wrong = false }

                            if wrong {
                                Text("答案不正確，請再試一次")
                                    .font(.caption).foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    Button {
                        if manager.verifySecurityAnswer(answer) {
                            showNewPin = true
                        } else {
                            withAnimation { wrong = true }
                            answer = ""
                        }
                    } label: {
                        Text("驗證").frame(maxWidth: .infinity).padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white).cornerRadius(12)
                    }
                    .padding(.horizontal, 32)
                    Spacer()
                }
            }
            .navigationTitle("忘記密碼")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showNewPin) {
                AppLockSetupView(mode: .firstTime) { onSuccess() }
            }
        }
        .preferredColorScheme(currentTheme.colorScheme)
    }
}
