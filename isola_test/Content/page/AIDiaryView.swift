//
//  AIDiaryView.swift
//  isola_test
//

import SwiftUI
import Charts
import Combine

// MARK: - Weekly Report Story View

struct WeeklyReportStoryView: View {
    let weekStart: Date
    let weekEnd: Date
    let qaEntries: [DiaryEntry]        // daily + introspection + duqChat
    let freeNoteCount: Int
    let dailyMoods: [Double?]          // 7 values Mon-Sun (all types, for Page2)
    let qaDailyMoods: [Double?]        // 7 values Mon-Sun (daily/introspection only, for Page6)

    @Environment(\.dismiss) private var dismiss
    @Environment(HealthDashboardViewModel.self) private var healthVM

    @State private var currentPage = 0   // 0-4 (pages 2-6)
    @State private var isPaused = false
    @State private var timerTick: Double = 0
    @State private var geminiSummary: String? = nil
    @State private var geminiHealthTip: String? = nil
    @State private var isLoadingGemini = true

    private let totalPages = 5
    private let pageSeconds: Double = 8.0

    // MARK: - Computed week data

    private var weekLabel: String {
        let cal = Calendar.current
        let month = cal.component(.month, from: weekStart)
        let weekOfMonth = cal.component(.weekOfMonth, from: weekStart)
        let monthCh = ["一","二","三","四","五","六","七","八","九","十","十一","十二"]
        let weekCh  = ["第一","第二","第三","第四","第五"]
        let m = month >= 1 && month <= 12 ? monthCh[month - 1] : "\(month)"
        let w = weekOfMonth >= 1 && weekOfMonth <= 5 ? weekCh[weekOfMonth - 1] : "第\(weekOfMonth)"
        return "\(m)月\(w)周 週報"
    }

    private var averageMood: Double? {
        let vals = dailyMoods.compactMap { $0 }
        guard !vals.isEmpty else { return nil }
        return vals.reduce(0, +) / Double(vals.count)
    }

    private var moodImageName: String {
        guard let avg = averageMood else { return "月報度Ｑ" }
        switch avg {
        case ..<1.0:    return "月報超級不愉快"
        case 1.0..<2.0: return "月報不愉快"
        case 2.0..<3.0: return "月報度Ｑ"
        case 3.0..<4.0: return "月報愉快"
        default:         return "月報超級愉快"
        }
    }

    private var moodLabel: String {
        guard let avg = averageMood else { return "平靜" }
        switch avg {
        case ..<1.0:    return "超難過"
        case 1.0..<2.0: return "難過"
        case 2.0..<3.0: return "平靜"
        case 3.0..<4.0: return "愉快"
        default:         return "超愉快"
        }
    }

    // Health data filtered to this week (fall back to last-7-day data if empty)
    private var weekSleep: [SleepSession] {
        let filtered = healthVM.sleepSessions.filter { $0.date >= weekStart && $0.date < weekEnd }
        return filtered.isEmpty ? healthVM.sleepSessions : filtered
    }

    private var weekSteps: [HealthSample] {
        let filtered = healthVM.stepSamples.filter { $0.date >= weekStart && $0.date < weekEnd }
        return filtered.isEmpty ? healthVM.stepSamples : filtered
    }

    private var avgSleepHours: Double? {
        guard !weekSleep.isEmpty else { return nil }
        return weekSleep.map(\.totalHours).reduce(0, +) / Double(weekSleep.count)
    }

    private var totalSteps: Int {
        Int(weekSteps.map(\.value).reduce(0, +))
    }

    private var weeklyGrade: WeeklyGrade? {
        guard let score = healthVM.overallScore.total else { return nil }
        return WeeklyGrade(score: score)
    }

    private var duqChatCount: Int {
        qaEntries.filter { $0.type == "duqChat" }.count
    }

    private var qaAnsweredCount: Int {
        qaEntries.filter { $0.type == "daily" || $0.type == "introspection" }.count
    }

    // MARK: - Timer

    private let ticker = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            ZStack {
                pageContent
                    .frame(width: geo.size.width, height: geo.size.height)

                // Gesture overlay (not on last page to let buttons work)
                if currentPage < totalPages - 1 {
                    HStack(spacing: 0) {
                        Color.clear.contentShape(Rectangle())
                            .onTapGesture { prevPage() }
                        Color.clear.contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in isPaused = true }
                                    .onEnded   { _ in isPaused = false }
                            )
                        Color.clear.contentShape(Rectangle())
                            .onTapGesture { nextPage() }
                    }
                } else {
                    // Last page: only allow going back from left third
                    HStack {
                        Color.clear.contentShape(Rectangle())
                            .frame(width: geo.size.width / 3)
                            .onTapGesture { prevPage() }
                        Spacer()
                    }
                }

                // Page indicator dots
                VStack {
                    Spacer()
                    HStack(spacing: 7) {
                        ForEach(0..<totalPages, id: \.self) { i in
                            Circle()
                                .fill(i == currentPage
                                      ? Color.primary
                                      : Color.primary.opacity(0.28))
                                .frame(width: 7, height: 7)
                        }
                    }
                    .padding(.bottom, 18)
                }
            }
            }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onReceive(ticker) { _ in
            guard !isPaused, currentPage < totalPages - 1 else { return }
            timerTick += 0.05 / pageSeconds
            if timerTick >= 1.0 { nextPage() }
        }
        .task { await loadGeminiContent() }
    }

    // MARK: - Page switcher

    @ViewBuilder
    private var pageContent: some View {
        switch currentPage {
        case 0:
            Page2MoodView(imageName: moodImageName, moodLabel: moodLabel)
        case 1:
            Page3SummaryView(weekLabel: weekLabel, summary: geminiSummary, isLoading: isLoadingGemini)
        case 2:
            Page4HealthView(
                weekLabel: weekLabel,
                weekStart: weekStart,
                sleepSessions: weekSleep,
                stepSamples: weekSteps,
                avgSleepHours: avgSleepHours,
                totalSteps: totalSteps
            )
        case 3:
            Page5ScoreView(weekLabel: weekLabel, grade: weeklyGrade, healthTip: geminiHealthTip)
        case 4:
            Page6RecapView(
                qaCount: qaAnsweredCount,
                dailyMoods: qaDailyMoods,
                grade: weeklyGrade,
                freeNoteCount: freeNoteCount,
                duqChatCount: duqChatCount,
                onDismiss: { dismiss() }
            )
        default:
            Color.clear
        }
    }

    // MARK: - Navigation

    private func nextPage() {
        guard currentPage < totalPages - 1 else { return }
        withAnimation(.easeInOut(duration: 0.25)) { currentPage += 1 }
        timerTick = 0
    }

    private func prevPage() {
        guard currentPage > 0 else { return }
        withAnimation(.easeInOut(duration: 0.25)) { currentPage -= 1 }
        timerTick = 0
    }

    // MARK: - Gemini

    private func loadGeminiContent() async {
        let cal = Calendar.current
        guard Set(qaEntries.map { cal.startOfDay(for: $0.date) }).count >= 3 else {
            isLoadingGemini = false
            return
        }

        let gemini = GeminiService()

        let entriesText = qaEntries.prefix(20).map {
            "[\($0.type)] \($0.title)：\($0.content)"
        }.joined(separator: "\n---\n")

        let scoreText: String
        if let total = healthVM.overallScore.total {
            scoreText = "生理分數：\(Int(total))分，等級：\(WeeklyGrade(score: total).label)"
        } else {
            scoreText = "暫無生理數據"
        }

        do {
            async let summaryCall = gemini.generateContent(
                messages: [GeminiAPIMessage(role: "user",
                    text: "這是我這週的日記記錄：\n\(entriesText)")],
                systemPrompt: """
                    你是一個溫暖的朋友。根據用戶這週的日記內容，以「你」稱呼用戶，\
                    寫一段100到150字的繁體中文週報摘要。\
                    分成自然段落，每段以完整句子換行，不在句子中間斷行。\
                    語氣溫暖自然。只輸出摘要文字，不加任何標題或格式符號。
                    """,
                maxTokens: 300
            )
            async let tipCall = gemini.generateContent(
                messages: [GeminiAPIMessage(role: "user", text: scoreText)],
                systemPrompt: "根據用戶的生理分數，給出一句10字以內的具體繁體中文健康建議。只輸出建議句子本身。",
                maxTokens: 50
            )
            geminiSummary    = try await summaryCall
            geminiHealthTip  = try await tipCall
        } catch {
            geminiSummary   = "這週你認真地記錄了生活，\n每一天的心情都值得被珍惜。\n繼續保持這份用心吧！"
            geminiHealthTip = "均衡作息，照顧好自己"
        }
        isLoadingGemini = false
    }
}

// MARK: - Page 2: Mood Image (Full Screen)

struct Page2MoodView: View {
    let imageName: String
    let moodLabel: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 6) {
                Text("這週的你")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.black)
                HStack {
                    Spacer()
                    Text("是隻\(moodLabel)度Ｑ")
                        .font(.system(size: 23))
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 150)
        }
    }
}

// MARK: - Page 3: Gemini Summary

struct Page3SummaryView: View {
    let weekLabel: String
    let summary: String?
    let isLoading: Bool

    @Environment(\.colorScheme) private var cs
    private var bg: Color { cs == .dark ? Color(hex: "#151D2B") : Color(hex: "#FDFBF0") }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("這週發生什麼事呢")
                    .font(.system(size: 26, weight: .bold))
                    .padding(.top, 200)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 35)

                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.3)
                        Text("度Ｑ正在整理這週的故事…")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Text(summary ?? "")
                        .font(.system(size: 17))
                        .lineSpacing(9)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 28)
                }

                Spacer()

                Spacer().frame(height: 80)
            }
        }
    }
}

// MARK: - Page 4: Health Charts

struct Page4HealthView: View {
    let weekLabel: String
    let weekStart: Date
    let sleepSessions: [SleepSession]
    let stepSamples: [HealthSample]
    let avgSleepHours: Double?
    let totalSteps: Int

    @Environment(\.colorScheme) private var cs
    private var bg: Color { cs == .dark ? Color(hex: "#151D2B") : Color(hex: "#FDFBF0") }
    private var cardBg: Color { cs == .dark ? Color(white: 0.14) : Color(white: 1.0).opacity(0.85) }

    private struct DaySlot: Identifiable {
        let id: Int
        let label: String
        let value: Double
        let hasData: Bool
    }

    private func shortDay(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        f.locale = Locale(identifier: "en_US")
        return f.string(from: date)
    }

    private var sleepSlots: [DaySlot] {
        let cal = Calendar.current
        return (0..<7).map { i in
            let dayStart = cal.date(byAdding: .day, value: i, to: weekStart) ?? weekStart
            let dayEnd   = cal.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let label    = shortDay(dayStart)
            let sessions = sleepSessions.filter { $0.date >= dayStart && $0.date < dayEnd }
            guard !sessions.isEmpty else { return DaySlot(id: i, label: label, value: 0, hasData: false) }
            let avg = sessions.map(\.totalHours).reduce(0, +) / Double(sessions.count)
            return DaySlot(id: i, label: label, value: avg, hasData: true)
        }
    }

    private var stepSlots: [DaySlot] {
        let cal = Calendar.current
        return (0..<7).map { i in
            let dayStart = cal.date(byAdding: .day, value: i, to: weekStart) ?? weekStart
            let dayEnd   = cal.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let label    = shortDay(dayStart)
            let samples  = stepSamples.filter { $0.date >= dayStart && $0.date < dayEnd }
            guard !samples.isEmpty else { return DaySlot(id: i, label: label, value: 0, hasData: false) }
            let total = samples.map(\.value).reduce(0, +)
            return DaySlot(id: i, label: label, value: total, hasData: true)
        }
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 16) {

                // Sleep section
                if let avg = avgSleepHours {
                    Text("這一週你平均睡了 \(String(format: "%.1f", avg)) 小時！")
                        .font(.system(size: 20, weight: .bold))
                        .padding(.top, 35)
                } else {
                    Text("這一週睡眠資料不足")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                        .padding(.top, 35)

                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("近 7 晚趨勢", systemImage: "chart.bar.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#9B85D9"))

                    Chart {
                        ForEach(sleepSlots) { slot in
                            BarMark(
                                x: .value("日", slot.label),
                                y: .value("時", slot.value)
                            )
                            .foregroundStyle(slot.hasData ? Color(hex: "#9B85D9") : Color.gray.opacity(0.25))
                            .cornerRadius(5)
                        }
                    }
                    .frame(height: 140)
                    .chartYScale(domain: 0...10)
                    .chartYAxis {
                        AxisMarks(values: [0, 2, 4, 6, 8]) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let v = value.as(Int.self) { Text("\(v)h").font(.caption2) }
                            }
                        }
                    }
                }
                .padding(14)
                .background(cardBg)
                .cornerRadius(14)
                .padding(.horizontal, 20)

                // Steps section
                let stepsLabel = totalSteps > 0
                    ? "這一週你共累積了 \(totalSteps) 步數！"
                    : "這一週步數資料不足"

                Text(stepsLabel)
                        .font(.system(size: 20, weight: .bold))
                        .padding(.top, 25)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("步數", systemImage: "figure.walk")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.green)
                        Spacer()
                        if totalSteps > 0 {
                            Text("\(totalSteps)步")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }

                    Chart {
                        ForEach(stepSlots) { slot in
                            BarMark(
                                x: .value("日", slot.label),
                                y: .value("步", slot.value)
                            )
                            .foregroundStyle(slot.hasData ? Color.green.opacity(0.65) : Color.gray.opacity(0.25))
                            .cornerRadius(5)
                        }
                    }
                    .frame(height: 140)
                    .chartYAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let v = value.as(Double.self) { Text("\(Int(v))").font(.caption2) }
                            }
                        }
                    }
                }
                .padding(14)
                .background(cardBg)
                .cornerRadius(14)
                .padding(.horizontal, 20)

                Spacer()
                    .frame(height: 56)
            }
        }
    }
}

// MARK: - Page 5: Health Score

struct Page5ScoreView: View {
    let weekLabel: String
    let grade: WeeklyGrade?
    let healthTip: String?

    @Environment(\.colorScheme) private var cs
    private var bg: Color { cs == .dark ? Color(hex: "#151D2B") : Color(hex: "#FDFBF0") }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("你這週的生理分數是")
                    .font(.system(size: 20, weight: .bold))

                if let g = grade {
                    Text(g.label)
                        .font(.system(size: 150, weight: .bold))
                        .foregroundColor(g.color)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                } else {
                    Text("暫無資料")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }

                Text(healthTip ?? "均衡作息，照顧好自己")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Page 6: Weekly Recap (Last Page)

struct Page6RecapView: View {
    let qaCount: Int
    let dailyMoods: [Double?]
    let grade: WeeklyGrade?
    let freeNoteCount: Int
    let duqChatCount: Int
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var cs
    private var bg: Color    { cs == .dark ? Color(hex: "#151D2B") : Color(hex: "#FDFBF0") }
    private var cardBg: Color { cs == .dark ? Color(white: 0.14) : Color(white: 1.0).opacity(0.7) }

    private func moodImg(_ mood: Double?) -> String {
        guard let m = mood else { return "空白沒寫度Ｑ" }
        let names = ["非常不愉快度Ｑ", "不愉快度Ｑ", "度Ｑ", "愉快度Ｑ", "非常愉快度Ｑ"]
        let index = max(0, min(4, Int(m.rounded())))
        return names[index]
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer().frame(height: 56)

                    Text("在這週裡：")
                        .font(.system(size: 26, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .center)

                    // Summary box
                    VStack(spacing: 22) {
                        // QA count + mood row
                        VStack(spacing: 12) {
                            Text("回答了 \(qaCount) 個問題")
                                .font(.system(size: 16, weight: .medium))

                            HStack(spacing: 4) {
                                ForEach(0..<7, id: \.self) { i in
                                    let mood = i < dailyMoods.count ? dailyMoods[i] : nil
                                    Image(moodImg(mood))
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 44, height: 44)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)

                        Divider()

                        // Health score
                        VStack(spacing: 4) {
                            Text("生理分數")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)

                            if let g = grade {
                                Text(g.label)
                                    .font(.system(size: 72, weight: .bold))
                                    .foregroundColor(g.color)
                            } else {
                                Text("—")
                                    .font(.system(size: 44))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        Divider()

                        // Bottom row — centered
                        HStack(spacing: 40) {
                            VStack(spacing: 8) {
                                Image("浮標")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 54, height: 54)
                                Text("搜集了 \(freeNoteCount) 個浮標")
                                    .font(.system(size: 13, weight: .medium))
                                    .multilineTextAlignment(.center)
                            }
                            VStack(spacing: 8) {
                                Image("度Ｑ")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 54, height: 54)
                                Text("和度Ｑ聊天 \(duqChatCount) 次")
                                    .font(.system(size: 13, weight: .medium))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(cardBg)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color(hex: "#C69C55"), lineWidth: 1.5)
                            )
                    )
                    .padding(.horizontal, 16)

                    // Message
                    VStack(spacing: 2) {
                        Text("下週也要繼續努力")
                        Text("我們一起加油吧")
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)

                    // Confirm button
                    Button(action: onDismiss) {
                        Text("確認完畢")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 160, height: 48)
                            .background(Color(hex: "#C69C55"))
                            .cornerRadius(24)
                    }
                    .padding(.top, 4)

                    Spacer().frame(height: 72)
                }
                .padding(.top, 90)
            }
        }
    }
}

#Preview {
    NavigationStack {
        WeeklyReportStoryView(
            weekStart: Date(),
            weekEnd: Date().addingTimeInterval(7 * 86400),
            qaEntries: [],
            freeNoteCount: 2,
            dailyMoods: [3.0, nil, 1.5, 4.0, 2.0, nil, 3.5],
            qaDailyMoods: [3.0, nil, nil, 4.0, nil, nil, 3.5]
        )
        .environment(HealthDashboardViewModel())
    }
}
