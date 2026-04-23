import WidgetKit

struct FocusScoreEntry: TimelineEntry {
    let date: Date
    let score: Int
    /// 최근 7일 점수 (오래된 → 최신). `.systemLarge` 에서만 채움.
    let weeklyHistory: [Int]?

    static let placeholder = FocusScoreEntry(date: Date(), score: 0, weeklyHistory: nil)

    static let largePreview = FocusScoreEntry(
        date: Date(),
        score: 55,
        weeklyHistory: [20, 45, 30, 70, 55, 40, 55]
    )
}
