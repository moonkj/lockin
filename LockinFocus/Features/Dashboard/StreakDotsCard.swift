import SwiftUI

/// 최근 7일 집중 기록을 7개 점으로 시각화.
/// 점수가 있는 날은 accent 색으로 채움, 0점 혹은 기록 없는 날은 회색 외곽선.
/// Dashboard 에서 오늘의 집중 카드 아래 얇게 배치해 "어제까지의 흐름" 을 한눈에.
struct StreakDotsCard: View {
    let history: [DailyFocus]  // 오래된 → 최신 순, 정확히 7개 이하

    private var displayDays: [DailyFocus] {
        // 정확히 7개가 되도록 앞쪽에 빈 DailyFocus 로 패딩.
        let pad = max(0, 7 - history.count)
        let padded = (0..<pad).map { _ in DailyFocus(date: "", score: 0) } + history
        return Array(padded.suffix(7))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("최근 7일 흐름")
                .scaledFont(13, weight: .semibold)
                .foregroundStyle(AppColors.primaryText)

            HStack(spacing: 8) {
                ForEach(Array(displayDays.enumerated()), id: \.offset) { _, day in
                    dayDot(for: day)
                }
            }
            .frame(maxWidth: .infinity)

            if let bestScore = history.map(\.score).max(), bestScore > 0 {
                Text("이번 주 최고 \(bestScore)점")
                    .scaledFont(11)
                    .foregroundStyle(AppColors.secondaryText)
            } else {
                Text("아직 이번 주 기록이 없어요.")
                    .scaledFont(11)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    private func dayDot(for day: DailyFocus) -> some View {
        let stage = TreeStage.from(score: day.score)
        let filled = day.score > 0
        return VStack(spacing: 6) {
            Circle()
                .fill(filled ? stage.accentColor : Color.clear)
                .overlay(
                    Circle()
                        .stroke(filled ? Color.clear : AppColors.divider, lineWidth: 1.5)
                )
                .frame(width: 28, height: 28)

            // 요일 라벨 — 기록 있는 날만 진하게.
            Text(day.date.isEmpty ? "·" : day.shortWeekday)
                .scaledFont(10, weight: filled ? .semibold : .regular)
                .foregroundStyle(filled ? AppColors.primaryText : AppColors.secondaryText)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack(spacing: 12) {
        StreakDotsCard(history: [
            DailyFocus(date: "2026-04-18", score: 42),
            DailyFocus(date: "2026-04-19", score: 78),
            DailyFocus(date: "2026-04-20", score: 15),
            DailyFocus(date: "2026-04-21", score: 95),
            DailyFocus(date: "2026-04-22", score: 0),
            DailyFocus(date: "2026-04-23", score: 60),
            DailyFocus(date: "2026-04-24", score: 33)
        ])
        StreakDotsCard(history: [])
    }
    .padding()
    .background(AppColors.background)
}
