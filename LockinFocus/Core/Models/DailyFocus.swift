import Foundation

/// 하루 집중 기록 — 주간 리포트의 원자 단위.
/// `date` 는 `yyyy-MM-dd` POSIX 문자열(UserDefaults 저장·정렬 편의).
struct DailyFocus: Codable, Equatable, Hashable, Identifiable {
    let date: String
    let score: Int

    var id: String { date }

    // thread-safe static formatters — ForEach 가 7~30 개 돌 때 formatter 인스턴스를
    // 그만큼 만들지 않도록 캐시. 수백 μs × 아이템 개수 × 매 렌더 비용 제거.
    private static let parseFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let shortWeekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "E"
        return f
    }()

    var displayDate: Date {
        Self.parseFormatter.date(from: date) ?? Date()
    }

    /// 요일 짧은 라벨(월/화/수/...).
    var shortWeekday: String {
        Self.shortWeekdayFormatter.string(from: displayDate)
    }
}
