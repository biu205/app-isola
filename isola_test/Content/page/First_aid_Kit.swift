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
    private var bg: Color { isDark ? Color(hex: "#151D2B") : Color(hex: "#FDFBF0") }


    // MARK: - Week Range (Monday first)
    private var weekInterval: DateInterval {
        var cal = Calendar.current
        cal.firstWeekday = 2
        return cal.dateInterval(of: .weekOfYear, for: Date())
            ?? DateInterval(start: Date(), duration: 7 * 86400)
    }
    private var weekStart: Date { weekInterval.start }
    private var weekEnd: Date   { weekInterval.end }

    // Entries that count toward unlock (not freeNote)
    private var weeklyQAEntries: [DiaryEntry] {
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
        return Set(weeklyQAEntries.map { cal.startOfDay(for: $0.date) }).count
    }

    private var isUnlocked: Bool { qualifyingDays >= 3 }

    // 7 values (nil = no entry that day), Mon-Sun
    private var weeklyDailyMoods: [Double?] {
        let cal = Calendar.current
        return (0..<7).map { offset -> Double? in
            guard let dayStart = cal.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let entries = weeklyQAEntries.filter {
                $0.date >= dayStart && $0.date < dayEnd && $0.moodIndex != nil
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

                VStack(alignment: .leading, spacing: 0) {
                    // Header row
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("心情週報")
                                .font(.system(size: 28, weight: .bold))
                            Text("在這一週裡，共回答了\(weeklyQAEntries.count)個問題")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }.padding(.top, 24)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

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
                                    dailyMoods: weeklyDailyMoods
                                )
                                .environment(healthVM)
                            } label: {
                                Text("點擊查看週報")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 22)
                                    .padding(.vertical, 12)
                                    .background(Color(hex: "#C69C55"))
                                    .cornerRadius(25)
                            }
                        } else {
                            Text("再寫\(max(0, 3 - qualifyingDays))天才能解鎖")
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 12)
                                .background(Color.gray.opacity(0.4))
                                .cornerRadius(25)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    Spacer()

                    // DuQ area
                    if isUnlocked {
                        DuQScatterView(moods: weeklyDailyMoods)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 100)
                    } else {
                        Image("還沒到度Ｑ")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 120)
                    }
                }
            }
        }
        .preferredColorScheme(currentTheme.colorScheme)
    }
}

// MARK: - DuQ Scattered Display

struct DuQScatterView: View {
    let moods: [Double?]

    // (xOffset, yOffset, size)
    private let layout: [(CGFloat, CGFloat, CGFloat)] = [
        (-68, -50, 82),
        ( 16, -10, 92),
        ( 88, -42, 76),
        (-88,  36, 80),
        (  0,  66, 88),
        ( 84,  46, 74),
        (-28, 138, 80),
    ]

    private func imageName(for mood: Double?) -> String {
        guard let m = mood else { return "空白沒寫度Ｑ" }
        switch m {
        case ..<1.0:    return "非常不愉快度Ｑ"
        case 1.0..<2.0: return "不愉快度Ｑ"
        case 2.0..<3.0: return "度Ｑ"
        case 3.0..<4.0: return "愉快度Ｑ"
        default:        return "非常愉快度Ｑ"
        }
    }

    var body: some View {
        ZStack {
            ForEach(0..<min(7, moods.count), id: \.self) { i in
                let (dx, dy, size) = layout[i]
                Image(imageName(for: moods[i]))
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .offset(x: dx, y: dy)
            }
        }
        .frame(height: 300)
    }
}

#Preview {
    MoodReportView()
}
