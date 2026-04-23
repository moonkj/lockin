import WidgetKit
import Foundation

/// 명언 위젯 타임라인 — 하루 한 개, 자정마다 다음 엔트리로 롤오버.
struct QuoteWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        let now = Date()
        completion(QuoteEntry(date: now, quote: QuoteProvider.today(now: now)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let now = Date()
        let entry = QuoteEntry(date: now, quote: QuoteProvider.today(now: now))
        let nextRefresh = nextMidnight(after: now)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func nextMidnight(after date: Date) -> Date {
        let cal = Calendar.current
        return cal.nextDate(
            after: date,
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? date.addingTimeInterval(60 * 60 * 24)
    }
}
