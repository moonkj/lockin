import Foundation

/// 하루 하나의 명언. `date` 는 `yyyy-MM-dd` POSIX 문자열.
struct DailyQuote: Identifiable, Equatable, Hashable {
    let text: String
    let author: String?

    var id: String { text }
}
