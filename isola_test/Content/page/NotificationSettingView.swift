import SwiftUI

struct NotificationSettingView: View {
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @AppStorage(NotificationManager.journalEnabledKey) private var journalEnabled = false
    @AppStorage(NotificationManager.sleepEnabledKey)   private var sleepEnabled   = false
    @AppStorage(NotificationManager.journalHourKey)    private var journalHour    = 20
    @AppStorage(NotificationManager.journalMinuteKey)  private var journalMinute  = 0
    @AppStorage("bottleAnsweredDate") private var bottleAnsweredDateStr = ""

    private var isDark: Bool {
        switch AppTheme(rawValue: appearanceMode) ?? .system {
        case .light: return false
        case .dark:  return true
        case .system: return Calendar.current.component(.hour, from: Date()) >= 19
        }
    }

    private var textColor: Color        { isDark ? .white : .black }
    private var backgroundColor: Color  { isDark ? Color(hex: "#151D2B") : Color(hex: "#FDFBF0") }

    private var isAnsweredToday: Bool {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return bottleAnsweredDateStr == f.string(from: Date())
    }

    private var journalTimeBinding: Binding<Date> {
        Binding(
            get: {
                let h = journalHour == 0 ? 20 : journalHour
                return Calendar.current.date(from: DateComponents(hour: h, minute: journalMinute)) ?? Date()
            },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                journalHour   = comps.hour   ?? 20
                journalMinute = comps.minute ?? 0
            }
        )
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: 日記提醒
                    sectionHeader("日記提醒")

                    VStack(spacing: 0) {
                        Divider()

                        row {
                            Text("每日提醒")
                                .foregroundColor(textColor)
                            Spacer()
                            Toggle("", isOn: $journalEnabled)
                                .tint(.brown)
                        }

                        if journalEnabled {
                            Divider()
                            row {
                                Text("提醒時間")
                                    .foregroundColor(textColor)
                                Spacer()
                                DatePicker(
                                    "",
                                    selection: journalTimeBinding,
                                    displayedComponents: .hourAndMinute
                                )
                                .labelsHidden()
                                .colorScheme(isDark ? .dark : .light)
                            }
                        }

                        Divider()
                    }
                    .padding(.horizontal)

                    // MARK: 睡眠提醒
                    sectionHeader("睡眠提醒")

                    VStack(spacing: 0) {
                        Divider()

                        row {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("睡眠品質提醒")
                                    .foregroundColor(textColor)
                                Text("偵測到睡眠資料時自動通知")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Toggle("", isOn: $sleepEnabled)
                                .tint(.brown)
                        }

                        Divider()
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle("通知設定")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: journalEnabled) { _, _ in refreshJournalNotifications() }
        .onChange(of: journalHour)    { _, _ in refreshJournalNotifications() }
        .onChange(of: journalMinute)  { _, _ in refreshJournalNotifications() }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .foregroundColor(.gray)
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 8)
    }

    @ViewBuilder
    private func row<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack { content() }
            .padding()
            .frame(minHeight: 60)
    }

    private func refreshJournalNotifications() {
        NotificationManager.shared.scheduleJournalReminders(answeredToday: isAnsweredToday)
    }
}
