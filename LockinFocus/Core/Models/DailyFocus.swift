import Foundation

/// 하루 집중 기록 — 주간 리포트의 원자 단위.
/// `date` 는 `yyyy-MM-dd` POSIX 문자열(UserDefaults 저장·정렬 편의).
struct DailyFocus: Codable, Equatable, Hashable, Identifiable {
    let date: String
    let score: Int

    var id: String { date }

    var displayDate: Date {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: date) ?? Date()
    }

    /// 요일 짧은 라벨(월/화/수/...).
    var shortWeekday: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "E"
        return f.string(from: displayDate)
    }
}
