import Foundation

/// 날짜 기반 오늘의 명언 선택기.
///
/// 1) `Resources/Quotes/quotes_ko.json` (OneDay 앱에서 이식, ~400개) 을 번들에서 로드.
/// 2) 같은 날짜에는 항상 같은 명언: `dayOfYear % count`.
/// 3) 번들 로드 실패 시 소량의 fallback 샘플로 graceful degrade.
enum QuoteProvider {
    /// 하루에 고정된 명언 한 개 반환.
    static func today(calendar: Calendar = .current, now: Date = Date()) -> DailyQuote {
        let all = loadAll()
        guard !all.isEmpty else { return fallbackDefault }
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        let index = (dayOfYear - 1 + all.count) % all.count
        return all[index]
    }

    /// 전체 명언 리스트 (확장/디버그용).
    static func allQuotes() -> [DailyQuote] { loadAll() }

    // MARK: - Bundle loading

    private struct QuotesFile: Decodable {
        struct Entry: Decodable {
            let text: String
            let author: String?
        }
        let quotes: [Entry]
    }

    private static var cache: [DailyQuote]?

    private static func loadAll() -> [DailyQuote] {
        if let cache { return cache }

        guard
            let url = Bundle.main.url(forResource: "quotes_ko", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode(QuotesFile.self, from: data)
        else {
            cache = fallbackSample
            return cache ?? []
        }

        let mapped = decoded.quotes.map { entry in
            DailyQuote(
                text: entry.text,
                author: (entry.author?.isEmpty ?? true) ? nil : entry.author
            )
        }
        cache = mapped
        return mapped
    }

    // MARK: - Fallback

    private static let fallbackDefault = DailyQuote(
        text: "오늘도 한 걸음.",
        author: nil
    )

    private static let fallbackSample: [DailyQuote] = [
        .init(text: "시작이 반이다.", author: nil),
        .init(text: "천 리 길도 한 걸음부터.", author: "노자"),
        .init(text: "오늘의 나는 어제의 나보다 한 발 나아갔다.", author: nil),
        .init(text: "집중은 최고의 선물이다.", author: "마사 베크"),
        .init(text: "단순함은 궁극의 정교함이다.", author: "레오나르도 다빈치"),
    ]
}
