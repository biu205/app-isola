import Foundation
import HealthKit

final class HealthKitService {
    let store = HKHealthStore()

    var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [
            HKQuantityType(.heartRateVariabilitySDNN),
            HKQuantityType(.heartRate),
            HKQuantityType(.restingHeartRate),
            HKQuantityType(.oxygenSaturation),
            HKQuantityType(.stepCount),
            HKQuantityType(.appleSleepingWristTemperature),
            HKQuantityType(.timeInDaylight),
            HKCategoryType(.sleepAnalysis),
        ]
        if let bodyTemp = HKObjectType.quantityType(forIdentifier: .bodyTemperature) {
            types.insert(bodyTemp)
        }
        return types
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthError.notAvailable
        }
        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    // MARK: - Sample Queries

    func fetchSamples(
        type: HKQuantityTypeIdentifier,
        unit: HKUnit,
        days: Int = 7
    ) async throws -> [HealthSample] {
        let quantityType = HKQuantityType(type)
        let predicate = recentPredicate(days: days)
        let sort = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: sort
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let result = (samples as? [HKQuantitySample] ?? []).map {
                    HealthSample(date: $0.startDate, value: $0.quantity.doubleValue(for: unit))
                }
                continuation.resume(returning: result)
            }
            self.store.execute(query)
        }
    }

    // MARK: - Daily Statistics (Steps, Sunlight)

    func fetchDailyStats(
        type: HKQuantityTypeIdentifier,
        unit: HKUnit,
        days: Int = 7
    ) async throws -> [HealthSample] {
        let quantityType = HKQuantityType(type)
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: now)) ?? now
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: calendar.startOfDay(for: now),
                intervalComponents: DateComponents(day: 1)
            )
            query.initialResultsHandler = { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                var samples: [HealthSample] = []
                results?.enumerateStatistics(from: startDate, to: now) { stats, _ in
                    let value = stats.sumQuantity()?.doubleValue(for: unit) ?? 0
                    samples.append(HealthSample(date: stats.startDate, value: value))
                }
                continuation.resume(returning: samples)
            }
            self.store.execute(query)
        }
    }

    // MARK: - Sleep

    func fetchSleepSessions(days: Int = 7) async throws -> [SleepSession] {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let predicate = recentPredicate(days: days)
        let sort = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: sort
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let sessions = self.groupSleepSamples(samples as? [HKCategorySample] ?? [])
                continuation.resume(returning: sessions)
            }
            self.store.execute(query)
        }
    }

    private func groupSleepSamples(_ samples: [HKCategorySample]) -> [SleepSession] {
        let calendar = Calendar.current
        var groups: [Date: [HKCategorySample]] = [:]

        for sample in samples {
            let day = calendar.startOfDay(for: sample.endDate)
            groups[day, default: []].append(sample)
        }

        return groups.sorted { $0.key < $1.key }.compactMap { date, daySamples in
            var rem = 0.0, deep = 0.0, light = 0.0, awake = 0.0, inBed = 0.0

            for s in daySamples {
                let mins = s.endDate.timeIntervalSince(s.startDate) / 60
                switch HKCategoryValueSleepAnalysis(rawValue: s.value) {
                case .asleepREM:                     rem += mins
                case .asleepDeep:                    deep += mins
                case .asleepCore, .asleepUnspecified: light += mins
                case .awake:                         awake += mins
                case .inBed:                         inBed += mins
                default: break
                }
            }

            let total = rem + deep + light
            guard total > 60 else { return nil }
            return SleepSession(
                date: date,
                totalMinutes: total,
                remMinutes: rem,
                deepMinutes: deep,
                lightMinutes: light,
                awakeMinutes: awake,
                inBedMinutes: max(inBed, total + awake)
            )
        }
    }

    // MARK: - Helpers

    private func recentPredicate(days: Int) -> NSPredicate {
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return HKQuery.predicateForSamples(withStart: start, end: Date())
    }

    // MARK: - Sleep Observer (for notifications)

    /// 設定睡眠資料監聽；有新資料時呼叫 onNewData
    func setupSleepObserver(onNewData: @escaping @Sendable () -> Void) {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let query = HKObserverQuery(sampleType: sleepType, predicate: nil) { [weak self] _, completionHandler, error in
            defer { completionHandler() }
            guard error == nil, let self else { return }
            Task {
                if await self.hasRecentSleepData() {
                    onNewData()
                }
            }
        }
        store.execute(query)
        store.enableBackgroundDelivery(for: sleepType, frequency: .immediate) { success, _ in
            if !success { print("[HealthKit] 睡眠背景傳遞未能啟用，請確認已開啟 Background Delivery 能力") }
        }
    }

    /// 檢查過去 16 小時是否有睡眠資料
    func hasRecentSleepData() async -> Bool {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let start = Date().addingTimeInterval(-16 * 3600)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, _ in
                continuation.resume(returning: !(samples ?? []).isEmpty)
            }
            self.store.execute(query)
        }
    }
}

enum HealthError: LocalizedError {
    case notAvailable
    case noData(MetricType)

    var errorDescription: String? {
        switch self {
        case .notAvailable:    return "此裝置不支援 HealthKit"
        case .noData(let m):   return "目前沒有「\(m.displayName)」的資料"
        }
    }
}
