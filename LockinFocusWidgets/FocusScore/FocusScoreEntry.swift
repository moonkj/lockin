import WidgetKit

struct FocusScoreEntry: TimelineEntry {
    let date: Date
    let score: Int

    static let placeholder = FocusScoreEntry(date: Date(), score: 0)
}
