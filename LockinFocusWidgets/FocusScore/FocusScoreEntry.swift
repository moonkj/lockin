import WidgetKit

struct FocusScoreEntry: TimelineEntry {
    let date: Date
    let score: Int
    /// 최근 7일 점수 (오래된 → 최신). `.systemLarge` 에서만 채움.
    let weeklyHistory: [Int]?
    /// 현재 수동 집중 활성 중인지. Smart deep-link 분기용.
    let isManualFocusActive: Bool

    /// 위젯 탭 시 열릴 URL — 현재 상태에 따라 다른 target.
    /// - 활성 중: nil → 앱만 열어 현재 Dashboard 상태로 복귀.
    /// - 점수 0 + 비활성: `startFocus` Route → 자동 포커스 세션 시작.
    /// - 그 외: `weeklyReport` (기존 동작 유지, 오늘 결과 확인).
    var deepLinkURL: URL? {
        if isManualFocusActive {
            return nil
        } else if score == 0 {
            return URL(string: "lockinfocus://startFocus")
        } else {
            return URL(string: "lockinfocus://weeklyReport")
        }
    }

    static let placeholder = FocusScoreEntry(date: Date(), score: 0, weeklyHistory: nil, isManualFocusActive: false)

    static let largePreview = FocusScoreEntry(
        date: Date(),
        score: 55,
        weeklyHistory: [20, 45, 30, 70, 55, 40, 55],
        isManualFocusActive: false
    )
}
