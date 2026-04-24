import WidgetKit
import Foundation

/// 오늘 집중 점수를 App Group UserDefaults 에서 읽어 위젯 entry 로 공급.
/// `.systemLarge` 에서는 최근 7일 히스토리도 함께 읽는다.
struct FocusScoreWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusScoreEntry {
        context.family == .systemLarge ? .largePreview : .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusScoreEntry) -> Void) {
        completion(current(family: context.family))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusScoreEntry>) -> Void) {
        let entry = current(family: context.family)
        let nextRefresh = Date().addingTimeInterval(15 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func current(family: WidgetFamily) -> FocusScoreEntry {
        let now = Date()
        let defaults = UserDefaults(suiteName: AppGroup.identifier)
        let rawScore = defaults?.integer(forKey: SharedKeys.focusScoreToday) ?? 0
        let storedDate = defaults?.string(forKey: PersistenceKeys.focusScoreDateKey)
        let score = (storedDate == Self.todayString()) ? rawScore : 0
        let isActive = defaults?.bool(forKey: PersistenceKeys.isManualFocusActive) ?? false

        let history: [Int]? = (family == .systemLarge)
            ? readWeeklyHistory(defaults: defaults, todayScore: score)
            : nil

        return FocusScoreEntry(
            date: now,
            score: score,
            weeklyHistory: history,
            isManualFocusActive: isActive
        )
    }

    private func readWeeklyHistory(defaults: UserDefaults?, todayScore: Int) -> [Int] {
        guard
            let defaults,
            let data = defaults.data(forKey: PersistenceKeys.dailyFocusHistory),
            let decoded = try? JSONDecoder().decode([DailyFocus].self, from: data)
        else {
            return Array(repeating: 0, count: 6) + [todayScore]
        }
        let sorted = decoded.sorted { $0.date < $1.date }
        let todayKey = Self.todayString()
        // history 는 어제까지 누적 기록. 마지막에 today 를 추가.
        let withoutToday = sorted.filter { $0.date != todayKey }
        let last6 = Array(withoutToday.suffix(6)).map(\.score)
        let padCount = 6 - last6.count
        let padding = Array(repeating: 0, count: max(0, padCount))
        return padding + last6 + [todayScore]
    }

    private static let ymdFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static func todayString() -> String {
        ymdFormatter.string(from: Date())
    }
}
