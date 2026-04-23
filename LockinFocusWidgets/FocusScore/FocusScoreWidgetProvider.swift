import WidgetKit
import Foundation

/// 오늘 집중 점수를 App Group UserDefaults 에서 읽어 15분마다 새 entry 를 공급.
/// 저장된 `focusScoreDate` 가 오늘이 아니면 0 으로 취급 (자정 리셋 동기화).
struct FocusScoreWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusScoreEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (FocusScoreEntry) -> Void) {
        completion(current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusScoreEntry>) -> Void) {
        let entry = current()
        let nextRefresh = Date().addingTimeInterval(15 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func current() -> FocusScoreEntry {
        let now = Date()
        let defaults = UserDefaults(suiteName: AppGroup.identifier)
        let rawScore = defaults?.integer(forKey: SharedKeys.focusScoreToday) ?? 0
        let storedDate = defaults?.string(forKey: PersistenceKeys.focusScoreDateKey)
        let score = (storedDate == Self.todayString()) ? rawScore : 0
        return FocusScoreEntry(date: now, score: score)
    }

    private static func todayString() -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
