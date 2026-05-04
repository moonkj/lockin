import SwiftUI

/// 엄격 모드 잔여 시간을 1초 단위로 표시. ClockTicker 를 `@ObservedObject` 로 직접 구독해
/// SettingsView 전체가 매초 재렌더되지 않도록 격리. SwiftUI 가 ticker.tick 변경에만 이 child
/// 를 무효화한다.
///
/// 부모 (SettingsView) 는 deps.tick / strictRemainingText 를 더 이상 보지 않는다.
struct StrictRemainingTimeText: View {
    @ObservedObject var ticker: ClockTicker
    let endAt: Date?

    var body: some View {
        Text(remainingText)
            .scaledFont(15, weight: .semibold, design: .rounded)
            .foregroundStyle(AppColors.accent)
            .monospacedDigit()
    }

    private var remainingText: String {
        let now = ticker.tick
        guard let end = endAt, end > now else { return "" }
        let total = Int(end.timeIntervalSince(now))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d시간 %d분", h, m) }
        if m > 0 { return String(format: "%d분 %d초", m, s) }
        return String(format: "%d초", s)
    }
}
