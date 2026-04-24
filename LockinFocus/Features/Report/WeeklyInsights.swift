import Foundation

/// 주간 리포트 최상단 카드에 띄울 한 줄 인사이트.
/// 단순한 하드코딩 규칙 몇 개로 7일 기록을 스캔해 가장 눈에 띄는 1개만 선택.
/// 규칙이 하나도 매치 안 하면 nil 반환 → 카드 자체를 숨김.
///
/// **i18n**: 카피 키는 한국어 원문이며, `Bundle.main.localizedString(forKey:value:table:)`
/// 으로 사용자 locale 에 맞는 번역으로 치환된다. 키가 없는 언어는 ko 원문 fallback.
enum WeeklyInsights {

    private static func tr(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: key, table: nil)
    }

    /// 생성. `history` 는 오래된 → 최신 순 (최대 7개).
    static func generate(history: [DailyFocus], best7d: Int?) -> String? {
        guard !history.isEmpty else { return nil }
        let scores = history.map(\.score)
        let nonZero = scores.filter { $0 > 0 }
        guard !nonZero.isEmpty else { return nil }

        // 1. 최고 기록 근접 (1~5점 차). diff == 0 은 Rule 5 (오늘 = 주간최고) 가 잡는다.
        if let best = best7d, best > 0, let todayScore = scores.last {
            let diff = best - todayScore
            if (1...5).contains(diff) && todayScore > 0 {
                return String(
                    format: tr("어제 최고 기록까지 %d점. 오늘 기세를 이어가볼 수 있어요."),
                    diff
                )
            }
        }

        // 2. 연속 기록 (오늘 포함) 3일 이상. 구체성이 높아 평균 상승보다 우선.
        var streak = 0
        for s in scores.reversed() {
            if s > 0 { streak += 1 } else { break }
        }
        if streak >= 3 {
            return String(format: tr("%d일 연속 집중 중이에요. 꾸준함이 쌓이고 있어요."), streak)
        }

        // 3. 주 평균 상승 — 전반부 vs 후반부.
        if scores.count >= 4 {
            let mid = scores.count / 2
            let firstHalf = Array(scores.prefix(mid))
            let secondHalf = Array(scores.suffix(scores.count - mid))
            let avgA = Double(firstHalf.reduce(0, +)) / Double(firstHalf.count)
            let avgB = Double(secondHalf.reduce(0, +)) / Double(secondHalf.count)
            if avgB >= avgA + 10 {
                return String(
                    format: tr("이번 주 후반 평균이 %d점 올랐어요. 흐름이 좋아요."),
                    Int(avgB - avgA)
                )
            }
        }

        // 4. 첫 기록 복귀 — 0 점 날 뒤에 점수가 다시 생김.
        if scores.count >= 2,
           let last = scores.last, last > 0,
           scores.dropLast().last == 0 {
            return tr("하루 쉬고 다시 돌아왔어요. 멋진 복귀예요.")
        }

        // 5. 주간 최고치 갱신 (오늘이 7일 중 최고).
        if let maxScore = scores.max(), let todayScore = scores.last,
           maxScore == todayScore, scores.count >= 2, maxScore > 0 {
            return String(format: tr("오늘이 이번 주 최고 %d점이에요."), maxScore)
        }

        return nil
    }
}
