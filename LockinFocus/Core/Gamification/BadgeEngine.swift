import Foundation

/// 사용자 액션에 반응해 뱃지 잠금 해제 여부를 판단한다.
enum BadgeEngine {
    // MARK: - Return

    @discardableResult
    static func onReturn(persistence: PersistenceStore) -> [Badge] {
        persistence.totalReturnCount += 1
        var unlocked: [Badge] = []
        let n = persistence.totalReturnCount

        if n >= 1, persistence.awardBadgeIfNew(Badge.firstReturn.id) {
            unlocked.append(.firstReturn)
        }
        if n >= 10, persistence.awardBadgeIfNew(Badge.returnNovice.id) {
            unlocked.append(.returnNovice)
        }
        if n >= 50, persistence.awardBadgeIfNew(Badge.returnAdept.id) {
            unlocked.append(.returnAdept)
        }
        if n >= 100, persistence.awardBadgeIfNew(Badge.returnMaster.id) {
            unlocked.append(.returnMaster)
        }
        return unlocked
    }

    // MARK: - Score / streak / week average

    @discardableResult
    static func onScoreChanged(persistence: PersistenceStore) -> [Badge] {
        var unlocked: [Badge] = []
        if persistence.focusScoreToday >= 100,
           persistence.awardBadgeIfNew(Badge.perfectDay.id) {
            unlocked.append(.perfectDay)
        }
        unlocked.append(contentsOf: checkStreak(persistence: persistence))
        unlocked.append(contentsOf: checkWeekAverage(persistence: persistence))
        return unlocked
    }

    // MARK: - Strict

    @discardableResult
    static func onStrictSurvived(persistence: PersistenceStore) -> [Badge] {
        persistence.totalStrictSurvived += 1
        var unlocked: [Badge] = []
        if persistence.awardBadgeIfNew(Badge.strictSurvivor.id) {
            unlocked.append(.strictSurvivor)
        }
        if persistence.totalStrictSurvived >= 3,
           persistence.awardBadgeIfNew(Badge.strictSurvivor3.id) {
            unlocked.append(.strictSurvivor3)
        }
        return unlocked
    }

    // MARK: - Manual focus (start)

    @discardableResult
    static func onManualFocusStarted(persistence: PersistenceStore) -> [Badge] {
        persistence.totalManualFocusStarts += 1
        if persistence.totalManualFocusStarts == 1,
           persistence.awardBadgeIfNew(Badge.firstManualFocus.id) {
            return [.firstManualFocus]
        }
        return []
    }

    // MARK: - Manual focus (end) — accumulate focus seconds, tier badges

    /// 세션 종료 시 경과 초를 누적 total 에 더하고 시간 뱃지 체크.
    @discardableResult
    static func onManualFocusEnded(
        elapsed: TimeInterval,
        persistence: PersistenceStore
    ) -> [Badge] {
        // 뱃지 파밍 방지: 1분 미만 세션은 누적에 넣지 않는다.
        // 세션 보너스(+15) 는 별도로 15분 기준을 따로 판정한다.
        guard elapsed >= 60 else { return [] }
        persistence.totalFocusSeconds += Int(elapsed)
        let minutes = persistence.totalFocusSeconds / 60

        var unlocked: [Badge] = []
        if minutes >= 60, persistence.awardBadgeIfNew(Badge.focusHour1.id) {
            unlocked.append(.focusHour1)
        }
        if minutes >= 300, persistence.awardBadgeIfNew(Badge.focusHour5.id) {
            unlocked.append(.focusHour5)
        }
        if minutes >= 1200, persistence.awardBadgeIfNew(Badge.focusHour20.id) {
            unlocked.append(.focusHour20)
        }
        if minutes >= 3000, persistence.awardBadgeIfNew(Badge.focusHour50.id) {
            unlocked.append(.focusHour50)
        }
        if minutes >= 6000, persistence.awardBadgeIfNew(Badge.focusHour100.id) {
            unlocked.append(.focusHour100)
        }
        return unlocked
    }

    // MARK: - Ranking

    /// 랭킹 로드 직후 호출. 참가자 100명 이상일 때만 순위 뱃지를 판정한다.
    /// 상위 50/30/10/5/1%, 3/2/1등은 누적형 — rank 1이면 Third/Second/First 모두 획득.
    @discardableResult
    static func onRankingFetched(
        entries: [LeaderboardEntry],
        userID: String,
        persistence: PersistenceStore
    ) -> [Badge] {
        guard entries.count >= 100 else { return [] }
        guard let idx = entries.firstIndex(where: { $0.userID == userID }) else { return [] }
        let rank = idx + 1
        let count = entries.count

        var unlocked: [Badge] = []

        // 절대 순위 — 누적형.
        if rank <= 3, persistence.awardBadgeIfNew(Badge.rankThird.id) {
            unlocked.append(.rankThird)
        }
        if rank <= 2, persistence.awardBadgeIfNew(Badge.rankSecond.id) {
            unlocked.append(.rankSecond)
        }
        if rank == 1, persistence.awardBadgeIfNew(Badge.rankFirst.id) {
            unlocked.append(.rankFirst)
        }

        // 상위 X% — rank*100 <= count*X 를 만족하면 해당 구간 안.
        func inTop(_ pct: Int) -> Bool { rank * 100 <= count * pct }
        if inTop(50), persistence.awardBadgeIfNew(Badge.rankTop50.id) {
            unlocked.append(.rankTop50)
        }
        if inTop(30), persistence.awardBadgeIfNew(Badge.rankTop30.id) {
            unlocked.append(.rankTop30)
        }
        if inTop(10), persistence.awardBadgeIfNew(Badge.rankTop10.id) {
            unlocked.append(.rankTop10)
        }
        if inTop(5), persistence.awardBadgeIfNew(Badge.rankTop5.id) {
            unlocked.append(.rankTop5)
        }
        if inTop(1), persistence.awardBadgeIfNew(Badge.rankTop1.id) {
            unlocked.append(.rankTop1)
        }

        return unlocked
    }

    // MARK: - Helpers

    private static func checkStreak(persistence: PersistenceStore) -> [Badge] {
        let history = persistence.dailyFocusHistory(lastDays: 14)
            .sorted { $0.date > $1.date }
        var streak = 0
        for entry in history {
            if entry.score > 0 { streak += 1 } else { break }
        }
        var unlocked: [Badge] = []
        if streak >= 3, persistence.awardBadgeIfNew(Badge.streak3Days.id) {
            unlocked.append(.streak3Days)
        }
        if streak >= 7, persistence.awardBadgeIfNew(Badge.streak7Days.id) {
            unlocked.append(.streak7Days)
        }
        return unlocked
    }

    private static func checkWeekAverage(persistence: PersistenceStore) -> [Badge] {
        let history = persistence.dailyFocusHistory(lastDays: 7)
        guard !history.isEmpty else { return [] }
        let avg = history.reduce(0) { $0 + $1.score } / history.count

        var unlocked: [Badge] = []
        if avg >= 60, persistence.awardBadgeIfNew(Badge.weekAverage60.id) {
            unlocked.append(.weekAverage60)
        }
        if avg >= 80, persistence.awardBadgeIfNew(Badge.weekAverage80.id) {
            unlocked.append(.weekAverage80)
        }
        if avg >= 100, persistence.awardBadgeIfNew(Badge.weekAverage100.id) {
            unlocked.append(.weekAverage100)
        }
        return unlocked
    }
}
