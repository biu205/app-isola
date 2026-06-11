import Foundation
import SwiftUI

// MARK: - Weekly Report Grade
enum WeeklyGrade: String {
    case sPlusPlus = "S++"
    case sPlus     = "S+"
    case s         = "S"
    case aPlusPlus = "A++"
    case aPlus     = "A+"
    case a         = "A"
    case b         = "B"

    init(score: Double) {
        switch score {
        case 90...:   self = .sPlusPlus
        case 80..<90: self = .sPlus
        case 70..<80: self = .s
        case 60..<70: self = .aPlusPlus
        case 50..<60: self = .aPlus
        case 40..<50: self = .a
        default:      self = .b
        }
    }

    var label: String { rawValue }

    var color: Color {
        switch self {
        case .sPlusPlus: return Color(hue: 0.12, saturation: 0.85, brightness: 0.82)
        case .sPlus:     return Color(hue: 0.12, saturation: 0.70, brightness: 0.85)
        case .s:         return Color(hue: 0.36, saturation: 0.65, brightness: 0.70)
        case .aPlusPlus: return Color(hue: 0.36, saturation: 0.55, brightness: 0.72)
        case .aPlus:     return Color(hue: 0.36, saturation: 0.45, brightness: 0.72)
        case .a:         return Color(hue: 0.36, saturation: 0.35, brightness: 0.72)
        case .b:         return .gray
        }
    }
}

// MARK: - Health Grade
enum GradeLevel: String {
    case a, b, c, d, e

    init(score: Double) {
        switch score {
        case 85...: self = .a
        case 70..<85: self = .b
        case 55..<70: self = .c
        case 40..<55: self = .d
        default: self = .e
        }
    }

    var label: String {
        switch self {
        case .a: return "優良"
        case .b: return "良好"
        case .c: return "注意"
        case .d: return "偏低"
        case .e: return "警示"
        }
    }

    var imageName: String {
        switch self {
        case .a: return "超級健康度Ｑ"
        case .b: return "健康度Ｑ"
        case .c: return "普通度Ｑ"
        case .d: return "有點不健康度Ｑ"
        case .e: return "不健康度Ｑ"
        }
    }

    var color: Color {
        switch self {
        case .a: return Color(hex:"#6DBF55")
        case .b: return Color(hex:"#E2EF74")
        case .c: return Color(hex:"#E6DA71")
        case .d: return Color(hex:"#DC9867")
        case .e: return Color(hex:"#B05955")
        }
    }
}

enum HealthCategoryType: String, CaseIterable, Identifiable {
    case cardiovascular
    case recoveryAndSleep
    case oxygenAndTemp
    case dailyActivity

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cardiovascular:   return "內在穩定"
        case .recoveryAndSleep: return "睡眠與恢復"
        case .oxygenAndTemp:    return "健康警示"
        case .dailyActivity:    return "日常活動"
        }
    }

    var subtitle: String {
        switch self {
        case .cardiovascular:   return "心率、靜息心率、HRV、RR 間期"
        case .recoveryAndSleep: return "睡眠、壓力指數"
        case .oxygenAndTemp:    return "血氧、手腕溫度"
        case .dailyActivity:    return "步數、日曬時間"
        }
    }

    var cardColor: Color {
        switch self {
        case .cardiovascular:   return Color(hex: "#9CD3D9")
        case .recoveryAndSleep: return Color(hex: "#F6B595")
        case .oxygenAndTemp:    return Color(hex: "#FCE967")
        case .dailyActivity:    return Color(hex: "#9CBCD9")
        }
    }

    func backgroundColor(isDark: Bool) -> Color {
        switch self {
        case .cardiovascular:   return isDark ? Color(hex: "#3D4849") : Color(hex: "#E9F1F1")
        case .recoveryAndSleep: return isDark ? Color(hex: "#4E4139") : Color(hex: "#F5EBE6")
        case .oxygenAndTemp:    return isDark ? Color(hex: "#514D30") : Color(hex: "#F8F5DF")
        case .dailyActivity:    return isDark ? Color(hex: "#3C4248") : Color(hex: "#E8ECF1")
        }
    }

    var metrics: [MetricType] {
        switch self {
        case .cardiovascular:   return [.heartRate, .restingHeartRate, .hrv, .rrInterval]
        case .recoveryAndSleep: return [.sleep, .stress]
        case .oxygenAndTemp:    return [.spo2, .temperature]
        case .dailyActivity:    return [.steps, .sunlight]
        }
    }
}

struct CategoryScore {
    let type: HealthCategoryType
    let score: Double?

    var grade: GradeLevel? { score.map { GradeLevel(score: $0) } }
    var isAvailable: Bool { score != nil }
}

struct OverallScore {
    let total: Double?
    let categories: [CategoryScore]

    var grade: GradeLevel? { total.map { GradeLevel(score: $0) } }

    private var lowestCategory: CategoryScore? {
        categories.filter(\.isAvailable).min { ($0.score ?? 0) < ($1.score ?? 0) }
    }

    var feedbackText: String {
        guard let lowest = lowestCategory, let score = lowest.score else {
            return "資料不足，請確認 HealthKit 授權"
        }
        switch GradeLevel(score: score) {
        case .a, .b:
            return "整體狀態不錯，繼續保持！"
        case .c:
            switch lowest.type {
            case .cardiovascular:   return "心律數據有些波動，留意休息品質"
            case .recoveryAndSleep: return "睡眠或壓力需要關注，今晚早點入睡"
            case .oxygenAndTemp:    return "血氧或體溫有偏移，注意身體狀況"
            case .dailyActivity:    return "活動量偏少，今天多走幾步吧"
            }
        case .d, .e:
            switch lowest.type {
            case .cardiovascular:   return "心律指標偏低，建議多休息並重新測量"
            case .recoveryAndSleep: return "恢復狀況不佳，今天以靜養為主"
            case .oxygenAndTemp:    return "血氧或體溫異常，必要時尋求醫療協助"
            case .dailyActivity:    return "活動量明顯不足，嘗試短暫散步"
            }
        }
    }
}
