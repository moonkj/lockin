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
        guard elapsed > 0 else { return [] }
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
        return unlocked
    }
}
