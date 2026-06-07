import Foundation
import SwiftUI


struct HealthSample: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Double
}


struct SleepSession: Identifiable {
    let id = UUID()
    let date: Date
    let totalMinutes: Double
    let remMinutes: Double
    let deepMinutes: Double
    let lightMinutes: Double
    let awakeMinutes: Double
    let inBedMinutes: Double
    var efficiency: Double {
        guard inBedMinutes > 0 else { return 0 }
        return (totalMinutes / inBedMinutes) * 100
    }
    var totalHours: Double { totalMinutes / 60.0 }
}


struct FormulaInfo {
    let title: String
    let description: String
    let formula: String?
    let normalRange: String
    let interpretation: String
}


enum ChartStyle { case line, bar }


enum MetricType: String, CaseIterable, Identifiable {
    case hrv, heartRate, restingHeartRate, rrInterval
    case stress, sleep, spo2, temperature, steps, sunlight
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .hrv:              return "HRV"
        case .heartRate:        return "心率"
        case .restingHeartRate: return "靜息心率"
        case .rrInterval:       return "RR 間期"
        case .stress:           return "壓力指數"
        case .sleep:            return "睡眠"
        case .spo2:             return "血氧 SpO₂"
        case .temperature:      return "手腕溫度"
        case .steps:            return "步數"
        case .sunlight:         return "日曬時間"
        }
    }

    var unit: String {
        switch self {
        case .hrv, .rrInterval:          return "ms"
        case .heartRate, .restingHeartRate: return "bpm"
        case .stress, .spo2:             return "%"
        case .sleep:                     return "小時"
        case .temperature:               return "°C"
        case .steps:                     return "步"
        case .sunlight:                  return "分鐘"
        }
    }

    var icon: String {
        switch self {
        case .hrv:              return "waveform.path.ecg"
        case .heartRate:        return "heart.fill"
        case .restingHeartRate: return "heart.circle.fill"
        case .rrInterval:       return "waveform"
        case .stress:           return "brain.head.profile"
        case .sleep:            return "moon.stars.fill"
        case .spo2:             return "lungs.fill"
        case .temperature:      return "thermometer.medium"
        case .steps:            return "figure.walk"
        case .sunlight:         return "sun.max.fill"
        }
    }

    var color: Color {
        switch self {
        case .hrv:              return Color(hue: 0.61, saturation: 0.7, brightness: 0.9)
        case .heartRate:        return Color(hue: 0.00, saturation: 0.8, brightness: 0.9)
        case .restingHeartRate: return Color(hue: 0.95, saturation: 0.7, brightness: 0.9)
        case .rrInterval:       return Color(hue: 0.75, saturation: 0.6, brightness: 0.9)
        case .stress:           return Color(hue: 0.08, saturation: 0.8, brightness: 0.95)
        case .sleep:            return Color(hue: 0.72, saturation: 0.75, brightness: 0.75)
        case .spo2:             return Color(hue: 0.53, saturation: 0.7, brightness: 0.9)
        case .temperature:      return Color(hue: 0.06, saturation: 0.6, brightness: 0.95)
        case .steps:            return Color(hue: 0.38, saturation: 0.65, brightness: 0.85)
        case .sunlight:         return Color(hue: 0.13, saturation: 0.8, brightness: 0.95)
        }
    }

    var chartStyle: ChartStyle {
        switch self {
        case .steps, .sleep, .sunlight,
             .restingHeartRate, .temperature: return .bar
        default:                              return .line
        }
    }

    func formatValue(_ value: Double) -> String {
        switch self {
        case .steps:
            return value >= 10_000
                ? String(format: "%.1fk", value / 1000)
                : String(Int(value))
        case .sleep:         return String(format: "%.1f", value)
        case .spo2, .stress: return String(format: "%.0f", value)
        case .temperature:   return String(format: "%.1f", value)
        case .sunlight:      return String(format: "%.0f", value)
        default:             return String(format: "%.1f", value)
        }
    }


// MARK: 公式說明
    var formulaInfo: FormulaInfo {
        switch self {
        case .hrv:
            return FormulaInfo(
                title: "心率變異性 SDNN",
                description: "所有 NN 間期的標準差，反映自律神經系統整體調節能力。數值越高代表恢復力越強、壓力越低。",
                formula: "SDNN = √( ¹⁄ₙ · Σ(RRᵢ − R̄R)² )",
                normalRange: "成人靜息：20–100 ms",
                interpretation: "< 20 ms：極度壓力｜40–80 ms：健康範圍｜> 80 ms：優秀恢復力"
            )
        case .heartRate:
            return FormulaInfo(
                title: "即時心率 HR",
                description: "每分鐘心跳次數，由 Apple Watch 背側 LED 感測器以光體積描記術（PPG）連續測量。",
                formula: "HR (bpm) = 60,000 ÷ RR (ms)",
                normalRange: "靜息成人：60–100 bpm",
                interpretation: "< 60：心搏過緩｜60–100：正常｜> 100：心搏過速"
            )
        case .restingHeartRate:
            return FormulaInfo(
                title: "靜息心率 RHR",
                description: "完全靜止（通常清晨睡眠末期）時的心率，是心肺功能與自律神經長期健康的指標。",
                formula: "RHR ≈ 靜息期 HR 測量值中位數",
                normalRange: "成人：60–100 bpm；運動員：40–60 bpm",
                interpretation: "連續升高 > 5 bpm 可能表示疾病、過度訓練或脫水。"
            )
        case .rrInterval:
            return FormulaInfo(
                title: "RR 間期",
                description: "相鄰兩次心搏 R 波尖峰之間的時間間隔，是 HRV 計算的基礎原始資料。",
                formula: "RR (ms) = 60,000 ÷ HR (bpm)",
                normalRange: "靜息：600–1,000 ms（對應 60–100 bpm）",
                interpretation: "RMSSD（相鄰差值均方根）可衡量副交感神經（迷走神經）活性。"
            )
        case .stress:
            return FormulaInfo(
                title: "壓力指數（HRV 推算）",
                description: "將 SDNN 線性映射至 0–100% 壓力量表：HRV 越低代表壓力越高。",
                formula: "壓力% = ( 1 − (SDNN − 20) ÷ 80 ) × 100",
                normalRange: "基準：SDNN_min = 20 ms，SDNN_max = 100 ms",
                interpretation: "0–30%：放鬆｜30–60%：中等壓力｜60–80%：高壓｜80–100%：極度壓力"
            )
        case .sleep:
            return FormulaInfo(
                title: "睡眠分析",
                description: "Apple Watch 以加速計、心率與呼吸率演算法辨別睡眠階段：REM、深眠（N3）、淺眠（N1/N2）與清醒。",
                formula: "睡眠效率 = 總睡眠時間 ÷ 總臥床時間 × 100%",
                normalRange: "成人：7–9 小時；效率 > 85%",
                interpretation: "深眠：10–25%｜REM：20–25%｜淺眠：45–55%"
            )
        case .spo2:
            return FormulaInfo(
                title: "血氧飽和度 SpO₂",
                description: "血液中氧合血紅蛋白佔總血紅蛋白的比例，由 Apple Watch 背側紅外光感測器測量。",
                formula: "SpO₂ = HbO₂ ÷ (HbO₂ + Hb) × 100%",
                normalRange: "正常：95–100%",
                interpretation: "< 90%：需立即就醫｜90–94%：偏低需注意｜95–100%：正常"
            )
        case .temperature:
            return FormulaInfo(
                title: "手腕皮膚溫度",
                description: "Apple Watch Series 8+ 於睡眠中測量手腕皮膚溫度，以個人化 30 天基準值追蹤夜間溫度變化。",
                formula: "ΔT = T_夜間測量 − T_個人 30 天基準值",
                normalRange: "偏差 ± 0.5°C 為正常波動範圍",
                interpretation: "持續 > 1°C 可能表示感染；女性可用偏差追蹤排卵週期（升溫約 0.3–0.5°C）。"
            )
        case .steps:
            return FormulaInfo(
                title: "每日步數",
                description: "iPhone / Apple Watch 加速計結合機器學習步態辨識演算法，即時計算行走步數。",
                formula: "步數 = Σ 有效步態週期（垂直加速度峰值）",
                normalRange: "建議每日：7,000–10,000 步",
                interpretation: "< 5,000：久坐｜5,000–7,499：低度活躍｜7,500–9,999：適度活躍｜≥ 10,000：活躍"
            )
        case .sunlight:
            return FormulaInfo(
                title: "日曬時間",
                description: "iPhone 環境光感測器偵測光照強度超過 1,000 lux 的持續時間，有助穩定晝夜節律與促進維生素 D 合成。",
                formula: "日曬分鐘 = 環境光 > 1,000 lux 的累積時間（分鐘）",
                normalRange: "建議每日：20–30 分鐘",
                interpretation: "< 10 min：不足｜10–30 min：適量｜> 30 min：充足（注意防曬）"
            )
        }
    }
}
