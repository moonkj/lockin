import SwiftUI

/// 최근 7일 집중 기록을 7개 점으로 시각화.
/// 점수가 있는 날은 accent 색으로 채움, 0점 혹은 기록 없는 날은 회색 외곽선.
/// Dashboard 에서 오늘의 집중 카드 아래 얇게 배치해 "어제까지의 흐름" 을 한눈에.
struct StreakDotsCard: View {
    let history: [DailyFocus]  // 오래된 → 최신 순, 정확히 7개 이하
    /// 남은 스트릭 보존 토큰 수 (0 or 1). 기본 0 이면 카피 숨김.
    var freezeTokens: Int = 0

    /// 최근 7일을 정확히 채운다. 기록 없는 날은 "0점 entry" 로 패딩하되
    /// 날짜는 실제 달력 기준 (오늘부터 6일 전까지) 으로 채워서 요일 라벨이 보이도록 한다.
    private var displayDays: [DailyFocus] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var byDate: [String: DailyFocus] = [:]
        for entry in history {
            byDate[entry.date] = entry
        }
        var result: [DailyFocus] = []
        for offset in (0..<7).reversed() {
            guard let dayDate = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let key = Self.dateFormatter.string(from: dayDate)
            if let recorded = byDate[key] {
                result.append(recorded)
            } else {
                // 기록 없는 날도 실제 날짜를 가진 0점 entry — 요일 라벨 표시 용.
                result.append(DailyFocus(date: key, score: 0))
            }
        }
        return result
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

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
                HStack(spacing: 8) {
                    Text("이번 주 최고 \(bestScore)점")
                        .scaledFont(11)
                        .foregroundStyle(AppColors.secondaryText)
                    if freezeTokens > 0 {
                        Text("· 쉬는 날 \(freezeTokens)개 남음")
                            .scaledFont(11)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                }
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
        // VoiceOver: 점만 보면 색상 차이로만 상태 전달 — 숫자와 요일을 함께 읽어주도록 combine.
        let a11yLabel: String = {
            if day.date.isEmpty { return "기록 없음" }
            if filled { return "\(day.shortWeekday) \(day.score)점" }
            return "\(day.shortWeekday) 0점"
        }()
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(a11yLabel)
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
