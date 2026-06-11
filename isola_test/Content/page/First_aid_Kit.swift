//
//  First_aid_Kit.swift
//  isola_test
//
//  Created by Qian Hsu on 2026/4/5.
//

import SwiftUI
import SwiftData

struct MoodReportView: View {
    @AppStorage("appearanceMode") private var appearanceMode: Int = AppTheme.system.rawValue
    @Environment(HealthDashboardViewModel.self) private var healthVM
    @Query(sort: \DiaryEntry.date) private var allEntries: [DiaryEntry]

    private var currentTheme: AppTheme { AppTheme(rawValue: appearanceMode) ?? .system }
    private var isDark: Bool { currentTheme.colorScheme == .dark }
    private var bg: Color 
    { isDark ? Color(hex: "#151D2B") : Color(hex: "#FDFBF0") }


    // MARK: - Week Range (Monday first)
    private var weekInterval: DateInterval {
        var cal = Calendar.current
        cal.firstWeekday = 2
        return cal.dateInterval(of: .weekOfYear, for: Date())
            ?? DateInterval(start: Date(), duration: 7 * 86400)
    }
    private var weekStart: Date { weekInterval.start }
    private var weekEnd: Date   { weekInterval.end }

    // All QA entries this week (used for day counting and subtitle)
    private var rawQAEntries: [DiaryEntry] {
        allEntries.filter {
            $0.date >= weekStart && $0.date < weekEnd &&
            ($0.type == "daily" || $0.type == "introspection" || $0.type == "duqChat")
        }
    }

    private var weeklyFreeNotes: [DiaryEntry] {
        allEntries.filter {
            $0.date >= weekStart && $0.date < weekEnd && $0.type == "freeNote"
        }
    }

    private var qualifyingDays: Int {
        let cal = Calendar.current
        return Set(rawQAEntries.map { cal.startOfDay(for: $0.date) }).count
    }

    private var isUnlocked: Bool { qualifyingDays >= 3 }

    // Gated: returns [] when fewer than 3 qualifying days
    private var weeklyQAEntries: [DiaryEntry] {
        isUnlocked ? rawQAEntries : []
    }

    // 7 values (nil = no entry that day), Mon-Sun
    // 含 DuQChat — 給月報塔顯示用
    private var weeklyDailyMoods: [Double?] {
        moodSlots(qaOnly: false)
    }

    // 僅 daily/introspection — 給 Page6 總結用
    private var weeklyQAMoods: [Double?] {
        moodSlots(qaOnly: true)
    }

    private func moodSlots(qaOnly: Bool) -> [Double?] {
        let cal = Calendar.current
        return (0..<7).map { offset -> Double? in
            guard let dayStart = cal.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let entries = weeklyQAEntries.filter {
                $0.date >= dayStart && $0.date < dayEnd &&
                $0.moodIndex != nil &&
                (!qaOnly || $0.type == "daily" || $0.type == "introspection")
            }
            guard !entries.isEmpty else { return nil }
            let sum = entries.compactMap(\.moodIndex).reduce(0, +)
            return Double(sum) / Double(entries.count)
        }
    }

// MARK:- View 
    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()

                // Tower pinned to bottom-center
                VStack {
                    Spacer()
                    if isUnlocked {
                        DuQScatterView(moods: weeklyDailyMoods)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 30)
                    } else {
                        Image("還沒到度Ｑ")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 60)
                    }
                }

                // Text content overlaid on top
                VStack(alignment: .leading, spacing: 0) {
                    // Header row
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("心情週報")
                                .font(.system(size: 28, weight: .bold))
                            Text("在這一週裡，共回答了 \(rawQAEntries.count) 個問題")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }.padding(.top, 24)
                        .padding(.vertical, 20)
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 60)

                    // Button row
                    HStack {
                        Spacer()
                        if isUnlocked {
                            NavigationLink {
                                WeeklyReportStoryView(
                                    weekStart: weekStart,
                                    weekEnd: weekEnd,
                                    qaEntries: weeklyQAEntries,
                                    freeNoteCount: weeklyFreeNotes.count,
                                    dailyMoods: weeklyDailyMoods,
                                    qaDailyMoods: weeklyQAMoods
                                )
                                .environment(healthVM)
                            } label: {
                                Text("點擊查看週報")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 20)
                                    .background(Color(hex: "#C69C55"))
                                    .cornerRadius(100)
                            }
                        } else {
                            Text("再寫\(max(0, 3 - qualifyingDays))天才能解鎖")
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 20)
                                .background(Color.gray.opacity(0.4))
                                .cornerRadius(100)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 20)
                    

                    Spacer()
                }
            }
        }
        .preferredColorScheme(currentTheme.colorScheme)
    }
}

// MARK: - DuQ Tower Display 

struct DuQScatterView: View {
    let moods: [Double?]   // 7 values, index 0 = Mon … 6 = Sun

    private let itemSize: CGFloat = 120

    private func imageName(for mood: Double) -> String {
        let index = max(0, min(4, Int(mood.rounded())))
        let names = ["非常不愉快度Ｑ2", "不愉快度Ｑ2", "度Ｑ2", "愉快度Ｑ2", "非常愉快度Ｑ2"]
        return names[index]
    }

    private let step: CGFloat = 71

    var body: some View {
        // Render Mon(0) first → back layer; Sun(6) last → front layer at top.
        // Offset formula: y = (3 - i) * step  →  i=6 sits at top (-3*step), i=0 at bottom (+3*step).
        ZStack {
            ForEach(0..<7) { i in
                let yOffset = CGFloat(3 - i) * step
                if i < moods.count, let mood = moods[i] {
                    Image(imageName(for: mood))
                        .resizable()
                        .scaledToFit()
                        .frame(width: itemSize, height: itemSize)
                        .offset(y: yOffset)
                } else {
                    Color.clear
                        .frame(width: itemSize, height: itemSize)
                        .offset(y: yOffset)
                }
            }
        }
        .frame(height: itemSize + 6 * step)
    }
}

#Preview {
    MoodReportView()
}
