import WidgetKit

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: DailyQuote

    static let placeholder = QuoteEntry(
        date: Date(),
        quote: DailyQuote(text: "오늘도 한 걸음.", author: nil)
    )
}
