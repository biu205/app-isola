//
//  appLock.swift
//  isola_test
//
//  Created by Qian Hsu on 2026/4/15.
//

import SwiftUI
import LocalAuthentication
import CryptoKit

// MARK: - Manager

@Observable
class AppLockManager {
    static let shared = AppLockManager()

    var isLocked: Bool = false

    var isPinSet: Bool {
        UserDefaults.standard.bool(forKey: "appLock_enabled")
    }
    var isBiometricEnabled: Bool {
        UserDefaults.standard.bool(forKey: "appLock_biometric")
    }
    var availableBiometricType: LABiometryType {
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else { return .none }
        return ctx.biometryType
    }

    private init() {
        isLocked = isPinSet
    }

    func setupPin(_ pin: String) {
        UserDefaults.standard.set(hash(pin), forKey: "appLock_pinHash")
        UserDefaults.standard.set(true, forKey: "appLock_enabled")
    }

    func verifyPin(_ pin: String) -> Bool {
        let stored = UserDefaults.standard.string(forKey: "appLock_pinHash") ?? ""
        return hash(pin) == stored
    }

    func enableBiometric(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "appLock_biometric")
    }

    func setupSecurityQuestion(index: Int, answer: String) {
        UserDefaults.standard.set(index, forKey: "appLock_questionIndex")
        UserDefaults.standard.set(hash(normalize(answer)), forKey: "appLock_answerHash")
    }

    func verifySecurityAnswer(_ answer: String) -> Bool {
        let stored = UserDefaults.standard.string(forKey: "appLock_answerHash") ?? ""
        return hash(normalize(answer)) == stored
    }

    var securityQuestion: String? {
        guard isPinSet else { return nil }
        let idx = UserDefaults.standard.integer(forKey: "appLock_questionIndex")
        guard idx < AppLockManager.questions.count else { return nil }
        return AppLockManager.questions[idx]
    }

    func disableLock() {
        ["appLock_enabled", "appLock_pinHash", "appLock_biometric",
         "appLock_questionIndex", "appLock_answerHash"].forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
        isLocked = false
    }

    func unlock() { isLocked = false }
    func lock() { if isPinSet { isLocked = true } }

    func authenticateWithBiometrics() async -> Bool {
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else { return false }
        do {
            return try await ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                               localizedReason: "解鎖 isola")
        } catch {
            return false
        }
    }

    static let questions = [
        "你的第一隻寵物叫什麼名字？",
        "你小時候住的街道叫什麼？",
        "你媽媽的娘家姓氏是？",
        "你最喜歡的電影是什麼？",
        "你的出生城市是哪裡？"
    ]

    private func hash(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .compactMap { String(format: "%02x", $0) }.joined()
    }
    private func normalize(_ s: String) -> String {
        s.lowercased().trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Shared PIN Dots + Numpad

private struct PinDotsView: View {
    let count: Int
    let total: Int = 4

    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i < count ? Color.primary : Color.clear)
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
            }
        }
    }
}

private struct NumPadView: View {
    let onTap: (String) -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 12) {
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
            ForEach(row, id: \.self) { key in
                numKey(key)
            }
        }
    }

    private func numKey(_ key: String) -> some View {
        Button { onTap(key) } label: {
            Text(key)
                .font(.title)
                .frame(width: 72, height: 72)
                .background(Color(UIColor.systemGray5))
                .clipShape(Circle())
        }
        .foregroundColor(.primary)
    }
}

// MARK: - Settings Entry (App鎖 in SettingView)

struct AppLockSettingView: View {
    @State private var manager = AppLockManager.shared
    @State private var showSetup = false
    @State private var showDisableConfirm = false
    @State private var showChangePinVerify = false
    @State private var enteredPin = ""
    @State private var wrongPin = false

    var body: some View {
        List {
            Section {
                if manager.isPinSet {
                    HStack {
                        Label("App 鎖已啟用", systemImage: "lock.fill")
                        Spacer()
                        Image(systemName: "checkmark").foregroundColor(.green)
                    }
                    if manager.availableBiometricType != .none {
                        Toggle(biometricLabel, isOn: Binding(
                            get: { manager.isBiometricEnabled },
                            set: { manager.enableBiometric($0) }
                        ))
                    }
                    Button("更改密碼") { showChangePinVerify = true }
                    Button("停用 App 鎖", role: .destructive) { showDisableConfirm = true }
                } else {
                    Button("啟用 App 鎖") { showSetup = true }
                        .foregroundColor(.accentColor)
                }
            } footer: {
                if !manager.isPinSet {
                    Text("設定四位數密碼，保護你的 isola。")
                }
            }
        }
        .navigationTitle("App 鎖")
        .navigationDestination(isPresented: $showSetup) {
            AppLockSetupView(mode: .firstTime) {
                showSetup = false
            }
        }
        .navigationDestination(isPresented: $showChangePinVerify) {
            AppLockSetupView(mode: .change) {
                showChangePinVerify = false
            }
        }
        .confirmationDialog("確定要停用 App 鎖嗎？", isPresented: $showDisableConfirm, titleVisibility: .visible) {
            Button("停用", role: .destructive) { manager.disableLock() }
            Button("取消", role: .cancel) {}
        }
    }

    private var biometricLabel: String {
        manager.availableBiometricType == .faceID ? "使用 Face ID" : "使用 Touch ID"
    }
}

// MARK: - Setup Flow

struct AppLockSetupView: View {
    enum Mode { case firstTime, change }

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

    enum Step { case verifyOld, enterPin, confirmPin, biometric, securityQuestion }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            switch step {
            case .verifyOld:
                verifyOldPinView
            case .enterPin:
                enterPinView
            case .confirmPin:
                confirmPinView
            case .biometric:
                biometricView
            case .securityQuestion:
                securityQuestionView
            }
            Spacer()
        }
        .navigationBarBackButtonHidden(step != .verifyOld && step != .enterPin)
        .onAppear {
            step = (mode == .change) ? .verifyOld : .enterPin
        }
    }

    // 驗證舊密碼（更改密碼時）
    private var verifyOldPinView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.rotation")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            Text("輸入目前密碼").font(.title2.bold())
            PinDotsView(count: verifyOldPin.count)
                .animation(.easeInOut, value: verifyOldPin.count)
            if wrongOldPin {
                Text("密碼錯誤，請再試一次")
                    .foregroundColor(.red)
                    .font(.caption)
                    .transition(.opacity)
            }
            NumPadView(
                onTap: { digit in
                    guard verifyOldPin.count < 4 else { return }
                    verifyOldPin += digit
                    wrongOldPin = false
                    if verifyOldPin.count == 4 {
                        if manager.verifyPin(verifyOldPin) {
                            step = .enterPin
                            verifyOldPin = ""
                        } else {
                            withAnimation { wrongOldPin = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                verifyOldPin = ""
                            }
                        }
                    }
                },
                onDelete: {
                    if !verifyOldPin.isEmpty { verifyOldPin.removeLast() }
                }
            )
        }
        .padding(.horizontal)
    }

    // 設定新密碼
    private var enterPinView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            Text("設定四位數密碼").font(.title2.bold())
            Text("這組密碼用來保護你的 isola")
                .font(.subheadline)
                .foregroundColor(.secondary)
            PinDotsView(count: firstPin.count)
                .animation(.easeInOut, value: firstPin.count)
            NumPadView(
                onTap: { digit in
                    guard firstPin.count < 4 else { return }
                    firstPin += digit
                    if firstPin.count == 4 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            step = .confirmPin
                        }
                    }
                },
                onDelete: {
                    if !firstPin.isEmpty { firstPin.removeLast() }
                }
            )
        }
        .padding(.horizontal)
    }

    // 確認密碼
    private var confirmPinView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            Text("再輸入一次確認").font(.title2.bold())
            PinDotsView(count: confirmPin.count)
                .animation(.easeInOut, value: confirmPin.count)
            if mismatch {
                Text("密碼不相符，請重新輸入")
                    .foregroundColor(.red)
                    .font(.caption)
                    .transition(.opacity)
            }
            NumPadView(
                onTap: { digit in
                    guard confirmPin.count < 4 else { return }
                    confirmPin += digit
                    mismatch = false
                    if confirmPin.count == 4 {
                        if confirmPin == firstPin {
                            manager.setupPin(confirmPin)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                step = manager.availableBiometricType != .none ? .biometric : .securityQuestion
                            }
                        } else {
                            withAnimation { mismatch = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                confirmPin = ""
                                firstPin = ""
                                step = .enterPin
                            }
                        }
                    }
                },
                onDelete: {
                    if !confirmPin.isEmpty { confirmPin.removeLast() }
                }
            )
        }
        .padding(.horizontal)
    }

    // 詢問是否啟用生物辨識
    private var biometricView: some View {
        VStack(spacing: 24) {
            Image(systemName: manager.availableBiometricType == .faceID ? "faceid" : "touchid")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            Text(manager.availableBiometricType == .faceID ? "使用 Face ID？" : "使用 Touch ID？")
                .font(.title2.bold())
            Text("啟用後可以快速解鎖，不需輸入密碼")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            VStack(spacing: 12) {
                Button {
                    manager.enableBiometric(true)
                    step = .securityQuestion
                } label: {
                    Text("啟用").frame(maxWidth: .infinity).padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                Button {
                    manager.enableBiometric(false)
                    step = .securityQuestion
                } label: {
                    Text("略過").frame(maxWidth: .infinity).padding()
                        .background(Color(UIColor.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 32)
        }
    }

    // 設定安全問題
    private var securityQuestionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "questionmark.shield.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            Text("設定安全問題").font(.title2.bold())
            Text("忘記密碼時，用來驗證身分以重設密碼")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("選擇問題").font(.caption).foregroundColor(.secondary)
                Picker("安全問題", selection: $selectedQuestion) {
                    ForEach(AppLockManager.questions.indices, id: \.self) { i in
                        Text(AppLockManager.questions[i]).tag(i)
                    }
                }
                .pickerStyle(.menu)
                .padding(12)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
            }
            .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 8) {
                Text("你的答案").font(.caption).foregroundColor(.secondary)
                TextField("輸入答案", text: $answer)
                    .padding(12)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 24)

            Button {
                guard !answer.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                manager.setupSecurityQuestion(index: selectedQuestion, answer: answer)
                onComplete()
            } label: {
                Text("完成設定").frame(maxWidth: .infinity).padding()
                    .background(answer.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color(.systemGray4) : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(answer.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Unlock Screen

struct AppLockUnlockView: View {
    @State private var manager = AppLockManager.shared
    @State private var pin = ""
    @State private var shake = false
    @State private var showReset = false

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.accentColor)
                Text("isola").font(.largeTitle.bold())
                Text("請輸入密碼").font(.subheadline).foregroundColor(.secondary)
                PinDotsView(count: pin.count)
                    .offset(x: shake ? -8 : 0)
                    .animation(shake ? .easeInOut(duration: 0.05).repeatCount(5, autoreverses: true) : .default,
                               value: shake)
                NumPadView(
                    onTap: { digit in
                        guard pin.count < 4 else { return }
                        pin += digit
                        if pin.count == 4 {
                            if manager.verifyPin(pin) {
                                manager.unlock()
                            } else {
                                withAnimation { shake = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    shake = false
                                    pin = ""
                                }
                            }
                        }
                    },
                    onDelete: {
                        if !pin.isEmpty { pin.removeLast() }
                    }
                )
                if manager.isBiometricEnabled && manager.availableBiometricType != .none {
                    Button {
                        Task {
                            if await manager.authenticateWithBiometrics() {
                                manager.unlock()
                            }
                        }
                    } label: {
                        Image(systemName: manager.availableBiometricType == .faceID ? "faceid" : "touchid")
                            .font(.system(size: 32))
                            .foregroundColor(.accentColor)
                    }
                }
                Button("忘記密碼？") { showReset = true }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .sheet(isPresented: $showReset) {
            AppLockResetView {
                showReset = false
                manager.unlock()
            }
        }
        .onAppear {
            if manager.isBiometricEnabled {
                Task {
                    if await manager.authenticateWithBiometrics() {
                        manager.unlock()
                    }
                }
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

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()
                Image(systemName: "key.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                Text("重設密碼").font(.title2.bold())
                Text("回答安全問題以驗證你的身分")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let question = manager.securityQuestion {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(question)
                            .font(.body.bold())
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(10)

                        TextField("輸入答案", text: $answer)
                            .padding(14)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(10)
                            .autocorrectionDisabled()
                            .onChange(of: answer) { _, _ in wrong = false }

                        if wrong {
                            Text("答案不正確，請再試一次")
                                .font(.caption)
                                .foregroundColor(.red)
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
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                Spacer()
            }
            .navigationTitle("忘記密碼")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showNewPin) {
                AppLockSetupView(mode: .firstTime) {
                    onSuccess()
                }
            }
        }
    }
}
