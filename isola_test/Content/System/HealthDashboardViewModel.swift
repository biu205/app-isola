import Foundation
import HealthKit
import Observation

@Observable
@MainActor
final class HealthDashboardViewModel {
    private let service = HealthKitService()

    var isAuthorized = false
    var isLoading = false
    var errorMessage: String?

    // 7-day display samples
    var hrvSamples: [HealthSample] = []
    var heartRateSamples: [HealthSample] = []
    var restingHRSamples: [HealthSample] = []
    var spo2Samples: [HealthSample] = []
    var temperatureSamples: [HealthSample] = []
    var stepSamples: [HealthSample] = []
    var sunlightSamples: [HealthSample] = []
    var sleepSessions: [SleepSession] = []

    // 28-day baseline samples (for z-score)
    var baselineHRVSamples: [HealthSample] = []
    var baselineRHRSamples: [HealthSample] = []
    var baselineTempSamples: [HealthSample] = []

    // MARK: - Baselines

    var hrvBaseline: Baseline? { HealthScoringEngine.makeBaseline(from: baselineHRVSamples) }
    var rhrBaseline: Baseline? { HealthScoringEngine.makeBaseline(from: baselineRHRSamples) }
    var tempBaselineMean: Double? {
        guard !baselineTempSamples.isEmpty else { return nil }
        return baselineTempSamples.map(\.value).reduce(0, +) / Double(baselineTempSamples.count)
    }

    // RR baseline derived from HR samples (28-day HR → RR)
    var rrBaseline: Baseline? {
        let rrSamples = baselineHRVSamples.map { s in
            HealthSample(date: s.date, value: 60_000 / max(s.value, 1))
        }
        return HealthScoringEngine.makeBaseline(from: rrSamples)
    }

    // MARK: - Current values

    var currentHRV: Double?         { hrvSamples.last?.value }
    var currentHeartRate: Double?   { heartRateSamples.last?.value }
    var currentRHR: Double?         { restingHRSamples.last?.value }
    var currentSpo2: Double?        { spo2Samples.last.map { $0.value * 100 } }
    var currentTemperature: Double? { temperatureSamples.last?.value }
    var todaySteps: Double?         { stepSamples.last?.value }
    var todaySunlight: Double?      { sunlightSamples.last?.value }
    var latestSleep: SleepSession?  { sleepSessions.last }

    var currentRR: Double? {
        guard let hr = currentHeartRate, hr > 0 else { return nil }
        return 60_000 / hr
    }

    var tempDelta: Double? {
        guard let t = currentTemperature, let base = tempBaselineMean else { return nil }
        return t - base
    }

    // MARK: - Legacy stress (kept for MetricDetailView)

    var stressPercent: Double {
        guard let hrv = currentHRV else { return 0 }
        let clamped = max(20, min(100, hrv))
        return (1.0 - (clamped - 20) / 80) * 100
    }

    var stressLabel: String {
        switch stressPercent {
        case ..<30:  return "放鬆"
        case ..<60:  return "中等壓力"
        case ..<80:  return "高壓"
        default:     return "極度壓力"
        }
    }

    // MARK: - Scoring

    var categoryScores: [CategoryScore] {
        let s1 = HealthScoringEngine.computeS1(
            hr: currentHeartRate, rhr: currentRHR, hrv: currentHRV, rr: currentRR,
            hrvBaseline: hrvBaseline, rrBaseline: rrBaseline
        )
        let s2 = HealthScoringEngine.computeS2(
            sleepHours: latestSleep?.totalHours, hrv: currentHRV, rhr: currentRHR,
            hrvBaseline: hrvBaseline, rhrBaseline: rhrBaseline
        )
        let s3 = HealthScoringEngine.computeS3(spo2: currentSpo2, tempDelta: tempDelta)
        let s4 = HealthScoringEngine.computeS4(steps: todaySteps, sunMinutes: todaySunlight)

        return [
            CategoryScore(type: .cardiovascular,   score: s1),
            CategoryScore(type: .recoveryAndSleep,  score: s2),
            CategoryScore(type: .oxygenAndTemp,     score: s3),
            CategoryScore(type: .dailyActivity,     score: s4),
        ]
    }

    var overallScore: OverallScore {
        let cats = categoryScores
        let total = HealthScoringEngine.computeTotal(
            s1: cats[0].score, s2: cats[1].score,
            s3: cats[2].score, s4: cats[3].score,
            spo2: currentSpo2, rhr: currentRHR
        )
        return OverallScore(total: total, categories: cats)
    }

    // MARK: - Helpers for views

    func samples(for metric: MetricType) -> [HealthSample] {
        switch metric {
        case .hrv:              return hrvSamples
        case .heartRate:        return heartRateSamples
        case .restingHeartRate: return restingHRSamples
        case .rrInterval:       return heartRateSamples.map {
            HealthSample(date: $0.date, value: 60_000 / max($0.value, 1))
        }
        case .stress:           return hrvSamples.map {
            let c = max(20, min(100, $0.value))
            return HealthSample(date: $0.date, value: (1 - (c - 20) / 80) * 100)
        }
        case .spo2:             return spo2Samples.map {
            HealthSample(date: $0.date, value: $0.value * 100)
        }
        case .temperature:      return temperatureSamples
        case .steps:            return stepSamples
        case .sunlight:         return sunlightSamples
        case .sleep:            return sleepSessions.map {
            HealthSample(date: $0.date, value: $0.totalHours)
        }
        }
    }

    func currentValue(for metric: MetricType) -> Double? {
        switch metric {
        case .hrv:              return currentHRV
        case .heartRate:        return currentHeartRate
        case .restingHeartRate: return currentRHR
        case .rrInterval:       return currentRR
        case .stress:           return currentHRV != nil ? stressPercent : nil
        case .spo2:             return currentSpo2
        case .temperature:      return currentTemperature
        case .steps:            return todaySteps
        case .sunlight:         return todaySunlight
        case .sleep:            return latestSleep?.totalHours
        }
    }

    // MARK: - Authorization & Fetch

    func requestAuthorization() {
        Task {
            do {
                try await service.requestAuthorization()
                isAuthorized = true
                await fetchAllData()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func fetchAllData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let msUnit  = HKUnit.secondUnit(with: .milli)
        let bpmUnit = HKUnit(from: "count/min")
        let minUnit = HKUnit(from: "min")

        // 7-day display data
        async let hrv   = try? service.fetchSamples(type: .heartRateVariabilitySDNN, unit: msUnit, days: 7)
        async let hr    = try? service.fetchSamples(type: .heartRate, unit: bpmUnit, days: 1)
        async let rhr   = try? service.fetchSamples(type: .restingHeartRate, unit: bpmUnit, days: 7)
        async let spo2  = try? service.fetchSamples(type: .oxygenSaturation, unit: .percent(), days: 7)
        async let temp  = try? fetchBestTemperature(days: 7)
        async let steps = try? service.fetchDailyStats(type: .stepCount, unit: .count(), days: 7)
        async let sun   = try? service.fetchDailyStats(type: .timeInDaylight, unit: minUnit, days: 7)
        async let sleep = try? service.fetchSleepSessions(days: 7)

        // 28-day baseline data
        async let bHRV  = try? service.fetchSamples(type: .heartRateVariabilitySDNN, unit: msUnit, days: 28)
        async let bRHR  = try? service.fetchSamples(type: .restingHeartRate, unit: bpmUnit, days: 28)
        async let bTemp = try? fetchBestTemperature(days: 28)

        hrvSamples         = await hrv   ?? []
        heartRateSamples   = await hr    ?? []
        restingHRSamples   = await rhr   ?? []
        spo2Samples        = await spo2  ?? []
        temperatureSamples = await temp  ?? []
        stepSamples        = await steps ?? []
        sunlightSamples    = await sun   ?? []
        sleepSessions      = await sleep ?? []

        baselineHRVSamples  = await bHRV  ?? []
        baselineRHRSamples  = await bRHR  ?? []
        baselineTempSamples = await bTemp ?? []
    }

    private func fetchBestTemperature(days: Int) async throws -> [HealthSample] {
        let samples = try? await service.fetchSamples(
            type: .appleSleepingWristTemperature,
            unit: .degreeCelsius(),
            days: days
        )
        if let samples, !samples.isEmpty { return samples }
        return (try? await service.fetchSamples(
            type: .bodyTemperature,
            unit: .degreeCelsius(),
            days: days
        )) ?? []
    }
}
