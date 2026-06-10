import Foundation
import UserNotifications

final class NotificationManager: @unchecked Sendable {
    static let shared = NotificationManager()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    // MARK: - Keys
    static let journalEnabledKey  = "notif_journal_enabled"
    static let sleepEnabledKey    = "notif_sleep_enabled"
    static let journalHourKey     = "notif_journal_hour"
    static let journalMinuteKey   = "notif_journal_minute"
    private let sleepLastSentKey  = "notif_sleep_last_sent_date"

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    // MARK: - Permission

    @discardableResult
    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Journal Notifications

    var journalEnabled: Bool {
        UserDefaults.standard.bool(forKey: Self.journalEnabledKey)
    }

    var journalHour: Int {
        guard UserDefaults.standard.object(forKey: Self.journalHourKey) != nil else { return 20 }
        return UserDefaults.standard.integer(forKey: Self.journalHourKey)
    }

    var journalMinute: Int {
        UserDefaults.standard.integer(forKey: Self.journalMinuteKey)
    }

    /// 排程未來 30 天的日記提醒（每次設定變更或 App 啟動時呼叫）
    func scheduleJournalReminders(answeredToday: Bool) {
        cancelAllJournalReminders()
        guard journalEnabled else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let now = Date()

        for i in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: i, to: today) else { continue }

            if i == 0 && answeredToday { continue }

            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = journalHour
            components.minute = journalMinute

            // 今天但時間已過 → 跳過
            if i == 0, let fireDate = calendar.date(from: components), fireDate <= now { continue }

            let content = UNMutableNotificationContent()
            content.title = "isola"
            content.body = "是時候回答今天的問答了喔！"
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let id = "journal_\(Self.dateFormatter.string(from: date))"
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    /// 取消所有未來 35 天的日記提醒
    func cancelAllJournalReminders() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let ids = (0..<35).compactMap { i -> String? in
            guard let date = calendar.date(byAdding: .day, value: i, to: today) else { return nil }
            return "journal_\(Self.dateFormatter.string(from: date))"
        }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// 用戶完成今天的日記後，取消今天的提醒
    func cancelTodayJournalReminder() {
        let today = Self.dateFormatter.string(from: Date())
        center.removePendingNotificationRequests(withIdentifiers: ["journal_\(today)"])
    }

    // MARK: - Sleep Notification

    /// 偵測到睡眠資料時呼叫；同一天只發一次
    func sendSleepNotificationIfNeeded() {
        guard UserDefaults.standard.bool(forKey: Self.sleepEnabledKey) else { return }

        let todayStr = Self.dateFormatter.string(from: Date())
        let lastSentStr = UserDefaults.standard.string(forKey: sleepLastSentKey) ?? ""
        guard lastSentStr != todayStr else { return }

        let content = UNMutableNotificationContent()
        content.title = "isola"
        content.body = "昨晚的睡眠資料已更新，來看看你的睡眠品質吧！"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "sleep_quality_\(todayStr)",
            content: content,
            trigger: trigger
        )
        center.add(request)
        UserDefaults.standard.set(todayStr, forKey: sleepLastSentKey)
    }
}
