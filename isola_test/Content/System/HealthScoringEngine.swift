import Foundation

struct Baseline {
    let mean: Double
    let std: Double

    func zScore(_ value: Double) -> Double {
        guard std > 0 else {
            return mean > 0 ? (value - mean) / mean : 0
        }
        return (value - mean) / std
    }
}

struct HealthScoringEngine {

    static func makeBaseline(from samples: [HealthSample]) -> Baseline? {
        guard samples.count >= 7 else { return nil }
        let values = samples.map(\.value)
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return Baseline(mean: mean, std: sqrt(variance))
    }

    // MARK: - Sub-scores

    static func scoreHR(_ hr: Double) -> Double {
        clamp(100 - 2 * abs(hr - 75))
    }

    static func scoreRHR(_ rhr: Double) -> Double {
        switch rhr {
        case 55..<76:  return 100
        case 76..<86:  return 85
        case 86..<96:  return 65
        case 96..<101: return 40
        case 45..<55:  return 75
        default:       return rhr > 100 ? 20 : 50
        }
    }

    static func scoreHRV(_ hrv: Double, baseline: Baseline?) -> Double {
        let b = baseline ?? Baseline(mean: 50, std: 20)
        return clamp(100 + 15 * b.zScore(hrv))
    }

    static func scoreRR(_ rr: Double, baseline: Baseline?) -> Double {
        let b = baseline ?? Baseline(mean: 800, std: 100)
        return clamp(100 - 12 * abs(b.zScore(rr)))
    }

    static func scoreSleep(_ hours: Double) -> Double {
        switch hours {
        case 7...9:    return 100
        case 6.5..<7:  return 85
        case 9..<9.5:  return 85
        case 6..<6.5:  return 65
        case 5..<6:    return 40
        default:       return hours > 9.5 ? 70 : 20
        }
    }

    static func scoreStress(hrv: Double?, rhr: Double?,
                            hrvBaseline: Baseline?, rhrBaseline: Baseline?) -> Double? {
        let bHRV = hrvBaseline ?? Baseline(mean: 50, std: 20)
        let bRHR = rhrBaseline ?? Baseline(mean: 65, std: 10)
        let zHRV = hrv.map { bHRV.zScore($0) }
        let zRHR = rhr.map { bRHR.zScore($0) }
        switch (zRHR, zHRV) {
        case let (r?, h?): return 100 - clamp(50 + 15 * r - 15 * h)
        case let (r?, nil): return 100 - clamp(50 + 15 * r)
        case let (nil, h?): return 100 - clamp(50 - 15 * h)
        default: return nil
        }
    }

    static func scoreSpO2(_ spo2: Double) -> Double {
        switch spo2 {
        case 97...:   return 100
        case 95..<97: return 90
        case 93..<95: return 70
        case 90..<93: return 40
        default:      return 20
        }
    }

    static func scoreTempDelta(_ delta: Double) -> Double {
        switch abs(delta) {
        case ..<0.3:        return 100
        case 0.3..<0.5:     return 85
        case 0.5..<0.8:     return 65
        case 0.8..<1.0:     return 40
        default:            return 20
        }
    }

    static func scoreSteps(_ steps: Double) -> Double {
        switch steps {
        case 10000...:      return 100
        case 8000..<10000:  return 85
        case 6000..<8000:   return 70
        case 3000..<6000:   return 50
        default:            return 25
        }
    }

    static func scoreSunlight(_ minutes: Double) -> Double {
        switch minutes {
        case 60...:   return 100
        case 30..<60: return 80
        case 15..<30: return 60
        case 5..<15:  return 35
        default:      return 15
        }
    }

    // MARK: - Category scores

    static func computeS1(hr: Double?, rhr: Double?, hrv: Double?, rr: Double?,
        hrvBaseline: Baseline?, rrBaseline: Baseline?) -> Double? {
        var pairs: [(Double, Double)] = []
        if let v = hr  { pairs.append((scoreHR(v), 0.35)) }
        if let v = rhr { pairs.append((scoreRHR(v), 0.25)) }
        if let v = hrv { pairs.append((scoreHRV(v, baseline: hrvBaseline), 0.30)) }
        if let v = rr  { pairs.append((scoreRR(v, baseline: rrBaseline), 0.10)) }
        return weightedAverage(pairs)
    }

    static func computeS2(sleepHours: Double?, hrv: Double?, rhr: Double?,
        hrvBaseline: Baseline?, rhrBaseline: Baseline?) -> Double? {
        let sSleep  = sleepHours.map { scoreSleep($0) }
        let sStress = scoreStress(hrv: hrv, rhr: rhr, hrvBaseline: hrvBaseline, rhrBaseline: rhrBaseline)
        switch (sSleep, sStress) {
        case let (sl?, st?): return weightedAverage([(sl, 0.60), (st, 0.40)])
        case let (sl?, nil): return sl
        case let (nil, st?): return st
        default:             return nil
        }
    }

    static func computeS3(spo2: Double?, tempDelta: Double?) -> Double? {
        let sO = spo2.map { scoreSpO2($0) }
        let sT = tempDelta.map { scoreTempDelta($0) }
        switch (sO, sT) {
        case let (o?, t?): return weightedAverage([(o, 0.60), (t, 0.40)])
        case let (o?, nil): return o
        case let (nil, t?): return t
        default:            return nil
        }
    }

    static func computeS4(steps: Double?, sunMinutes: Double?) -> Double? {
        let sA = steps.map { scoreSteps($0) }
        let sS = sunMinutes.map { scoreSunlight($0) }
        switch (sA, sS) {
        case let (a?, s?): return weightedAverage([(a, 0.65), (s, 0.35)])
        case let (a?, nil): return a
        case let (nil, s?): return s
        default:            return nil
        }
    }

    static func computeTotal(s1: Double?, s2: Double?, s3: Double?, s4: Double?,
        spo2: Double?, rhr: Double?) -> Double? {
        var pairs: [(Double, Double)] = []
        if let v = s1 { pairs.append((v, 0.30)) }
        if let v = s2 { pairs.append((v, 0.30)) }
        if let v = s3 { pairs.append((v, 0.20)) }
        if let v = s4 { pairs.append((v, 0.20)) }
        guard var score = weightedAverage(pairs) else { return nil }
        if let o = spo2, o < 93 { score = min(score, 54) }
        if let r = rhr,  r > 110 { score = min(score, 54) }
        return score
    }

    // MARK: - Helpers

    private static func clamp(_ x: Double) -> Double { min(100, max(0, x)) }

    private static func weightedAverage(_ pairs: [(Double, Double)]) -> Double? {
        guard !pairs.isEmpty else { return nil }
        let totalWeight = pairs.map(\.1).reduce(0, +)
        guard totalWeight >= 0.5 else { return nil }
        return pairs.map { $0.0 * $0.1 }.reduce(0, +) / totalWeight
    }
}
