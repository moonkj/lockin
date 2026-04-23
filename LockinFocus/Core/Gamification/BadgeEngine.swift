import Foundation

/// 사용자 액션에 반응해 뱃지 잠금 해제 여부를 판단한다.
/// 각 이벤트는 해당 누적 카운터를 갱신하고 아직 안 받은 뱃지가 있으면 award.
enum BadgeEngine {
    /// Intercept "돌아가기" 선택 시 호출.
    /// - Returns: 이번 호출로 새로 획득한 뱃지 목록.
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

    /// 오늘 점수가 갱신된 후 호출. 100점 도달 시 perfectDay 뱃지.
    @discardableResult
    static func onScoreChanged(persistence: PersistenceStore) -> [Badge] {
        var unlocked: [Badge] = []
        if persistence.focusScoreToday >= 100,
           persistence.awardBadgeIfNew(Badge.perfectDay.id) {
            unlocked.append(.perfectDay)
        }
        unlocked.append(contentsOf: checkStreak(persistence: persistence))
        return unlocked
    }

    /// 엄격 모드 해제 3단계 완주 시 호출.
    @discardableResult
    static func onStrictSurvived(persistence: PersistenceStore) -> [Badge] {
        persistence.totalStrictSurvived += 1
        if persistence.awardBadgeIfNew(Badge.strictSurvivor.id) {
            return [.strictSurvivor]
        }
        return []
    }

    /// 도파민 디톡스 시작 시 호출.
    @discardableResult
    static func onDetoxStarted(persistence: PersistenceStore) -> [Badge] {
        persistence.totalDetoxStarted += 1
        if persistence.awardBadgeIfNew(Badge.detoxStarter.id) {
            return [.detoxStarter]
        }
        return []
    }

    // MARK: - Streak

    /// 최근 14일 기록에서 "점수>0" 인 날이 오늘부터 뒤로 몇 일 연속 있는지 세어 3/7일 뱃지 체크.
    private static func checkStreak(persistence: PersistenceStore) -> [Badge] {
        let history = persistence.dailyFocusHistory(lastDays: 14)
            .sorted { $0.date > $1.date } // 최신부터
        var streak = 0
        for entry in history {
            if entry.score > 0 {
                streak += 1
            } else {
                break
            }
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
}
