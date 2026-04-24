import Foundation

/// 스트릭 보존권 관리.
///
/// 매주 1개 토큰이 자동 지급된다 (ISO 주 단위, 상한 1). 스트릭 계산 시 0점 인 날이
/// 하나 있으면 토큰이 있으면 "메운" 것으로 간주해 연속이 유지된다.
///
/// 현재 MVP 정책: 토큰은 **매주 한 번 갱신**되는 "쉬는 날 쿠폰" 으로, 소모 기록을
/// 별도로 추적하지 않고 streak 계산 시 virtually 적용한다. 이렇게 하면 persistence
/// 상태는 (토큰 1 개 / 없음) 만 관리하면 되고, 다음 주로 넘어가면 자연스럽게 갱신.
/// 연속으로 이틀 이상 0점이면 그 뒤로는 토큰이 있어도 streak 중단.
enum StreakEngine {

    /// 현재 ISO 주 식별자. `LeaderboardPeriodID.weekly` 재사용으로 통일.
    static func currentWeekID(now: Date = Date()) -> String {
        LeaderboardPeriodID.weekly(now)
    }

    /// 이번 주에 토큰이 아직 지급 안 됐으면 지급. 지급이 일어났으면 true.
    /// 호출처: 앱 시작 시 + Dashboard onAppear.
    @discardableResult
    static func grantWeeklyTokenIfNeeded(persistence: PersistenceStore, now: Date = Date()) -> Bool {
        let week = currentWeekID(now: now)
        guard persistence.streakFreezeLastWeek != week else { return false }
        // 1 이 상한. 이미 있으면 덮어쓰지 않음 (사용자가 이번 주 써도 다음 주 지급까지 유지).
        if persistence.streakFreezeToken < 1 {
            persistence.streakFreezeToken = 1
        }
        persistence.streakFreezeLastWeek = week
        return true
    }

    /// 7일 히스토리에서 스트릭 계산 — 토큰 보존을 반영.
    /// 반환: (streak 연속 일수, freezeUsed 토큰 적용 여부).
    /// 알고리즘: 최신 → 과거 스캔. 첫 번째 0점 날만 토큰으로 메울 수 있다 (연속 2일 0점은 중단).
    static func streak(history: [DailyFocus], persistence: PersistenceStore) -> (streak: Int, freezeUsed: Bool) {
        var count = 0
        var tokensLeft = persistence.streakFreezeToken
        var used = false
        for entry in history.reversed() {
            if entry.score > 0 {
                count += 1
            } else if tokensLeft > 0 {
                tokensLeft -= 1
                used = true
                count += 1
            } else {
                break
            }
        }
        return (count, used)
    }
}
