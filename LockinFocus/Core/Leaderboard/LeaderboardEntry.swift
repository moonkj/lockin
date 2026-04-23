import CloudKit
import Foundation

/// 랭킹 기간 구분.
enum LeaderboardPeriod: String, CaseIterable, Identifiable {
    case daily, weekly, monthly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .daily:   return "일간"
        case .weekly:  return "주간"
        case .monthly: return "월간"
        }
    }
}

/// 현재 로컬 기준의 period 식별자 문자열.
/// - daily: `yyyy-MM-dd`
/// - weekly: `yyyy-Www` (ISO 8601 주)
/// - monthly: `yyyy-MM`
enum LeaderboardPeriodID {
    static func daily(_ now: Date = Date()) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: now)
    }

    static func weekly(_ now: Date = Date()) -> String {
        let cal = Calendar(identifier: .iso8601)
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        return String(format: "%04d-W%02d", comps.yearForWeekOfYear ?? 0, comps.weekOfYear ?? 0)
    }

    static func monthly(_ now: Date = Date()) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM"
        return f.string(from: now)
    }

    static func current(_ period: LeaderboardPeriod, now: Date = Date()) -> String {
        switch period {
        case .daily:   return daily(now)
        case .weekly:  return weekly(now)
        case .monthly: return monthly(now)
        }
    }
}

/// CloudKit Public DB 의 `LeaderboardEntry` 레코드.
/// 한 사용자당 하나의 record 를 유지하고, 일간/주간/월간 점수를 함께 저장한다.
struct LeaderboardEntry: Identifiable, Hashable {
    static let recordType = "LeaderboardEntry"

    let userID: String
    let nickname: String
    let dailyScore: Int
    let dailyDate: String
    let weeklyTotal: Int
    let weeklyWeek: String
    let monthlyTotal: Int
    let monthlyMonth: String
    let updatedAt: Date

    var id: String { userID }

    func score(for period: LeaderboardPeriod) -> Int {
        switch period {
        case .daily:   return dailyScore
        case .weekly:  return weeklyTotal
        case .monthly: return monthlyTotal
        }
    }

    func periodID(for period: LeaderboardPeriod) -> String {
        switch period {
        case .daily:   return dailyDate
        case .weekly:  return weeklyWeek
        case .monthly: return monthlyMonth
        }
    }

    init(
        userID: String,
        nickname: String,
        dailyScore: Int,
        dailyDate: String,
        weeklyTotal: Int,
        weeklyWeek: String,
        monthlyTotal: Int,
        monthlyMonth: String,
        updatedAt: Date
    ) {
        self.userID = userID
        self.nickname = nickname
        self.dailyScore = dailyScore
        self.dailyDate = dailyDate
        self.weeklyTotal = weeklyTotal
        self.weeklyWeek = weeklyWeek
        self.monthlyTotal = monthlyTotal
        self.monthlyMonth = monthlyMonth
        self.updatedAt = updatedAt
    }

    init?(record: CKRecord) {
        guard
            let nickname = record["nickname"] as? String,
            let updatedAt = record["updatedAt"] as? Date
        else { return nil }
        self.userID = record.recordID.recordName
        self.nickname = nickname
        self.dailyScore = (record["dailyScore"] as? Int) ?? 0
        self.dailyDate = (record["dailyDate"] as? String) ?? ""
        self.weeklyTotal = (record["weeklyTotal"] as? Int) ?? 0
        self.weeklyWeek = (record["weeklyWeek"] as? String) ?? ""
        self.monthlyTotal = (record["monthlyTotal"] as? Int) ?? 0
        self.monthlyMonth = (record["monthlyMonth"] as? String) ?? ""
        self.updatedAt = updatedAt
    }
}
