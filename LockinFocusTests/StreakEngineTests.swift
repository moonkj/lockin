import XCTest
@testable import LockinFocus

/// Round 3 Feature #2 — 스트릭 보존권.
final class StreakEngineTests: XCTestCase {

    private func entry(_ date: String, _ score: Int) -> DailyFocus {
        DailyFocus(date: date, score: score)
    }

    // MARK: - grantWeeklyTokenIfNeeded

    func testGrant_firstCall_deliversToken() {
        let s = InMemoryPersistenceStore()
        let granted = StreakEngine.grantWeeklyTokenIfNeeded(persistence: s)
        XCTAssertTrue(granted)
        XCTAssertEqual(s.streakFreezeToken, 1)
        XCTAssertFalse(s.streakFreezeLastWeek.isEmpty)
    }

    func testGrant_sameWeek_noDuplicate() {
        let s = InMemoryPersistenceStore()
        _ = StreakEngine.grantWeeklyTokenIfNeeded(persistence: s)
        // 토큰을 사용자가 쓴 것처럼 0 으로 내려도 같은 주엔 재지급 X.
        s.streakFreezeToken = 0
        let second = StreakEngine.grantWeeklyTokenIfNeeded(persistence: s)
        XCTAssertFalse(second)
        XCTAssertEqual(s.streakFreezeToken, 0)
    }

    func testGrant_capAtOne() {
        let s = InMemoryPersistenceStore()
        s.streakFreezeToken = 1
        _ = StreakEngine.grantWeeklyTokenIfNeeded(persistence: s)
        XCTAssertEqual(s.streakFreezeToken, 1, "이미 보유 중이면 2 로 올라가지 않음")
    }

    // MARK: - streak 계산

    func testStreak_allPositive_fullLength() {
        let s = InMemoryPersistenceStore()
        s.streakFreezeToken = 0
        let h = [
            entry("2026-04-20", 40),
            entry("2026-04-21", 50),
            entry("2026-04-22", 60)
        ]
        let (streak, used) = StreakEngine.streak(history: h, persistence: s)
        XCTAssertEqual(streak, 3)
        XCTAssertFalse(used)
    }

    func testStreak_zeroInMiddle_noToken_breaks() {
        let s = InMemoryPersistenceStore()
        s.streakFreezeToken = 0
        let h = [
            entry("2026-04-20", 40),
            entry("2026-04-21", 0),
            entry("2026-04-22", 60)
        ]
        let (streak, used) = StreakEngine.streak(history: h, persistence: s)
        XCTAssertEqual(streak, 1, "최신 날만 카운트, 0 에서 중단")
        XCTAssertFalse(used)
    }

    func testStreak_zeroInMiddle_withToken_bridges() {
        let s = InMemoryPersistenceStore()
        s.streakFreezeToken = 1
        let h = [
            entry("2026-04-20", 40),
            entry("2026-04-21", 0),
            entry("2026-04-22", 60)
        ]
        let (streak, used) = StreakEngine.streak(history: h, persistence: s)
        XCTAssertEqual(streak, 3, "토큰이 0점 날을 메워 3일 연속")
        XCTAssertTrue(used)
    }

    func testStreak_twoZerosInARow_tokenBridgesOnlyOne() {
        let s = InMemoryPersistenceStore()
        s.streakFreezeToken = 1
        let h = [
            entry("2026-04-19", 40),
            entry("2026-04-20", 0),
            entry("2026-04-21", 0),
            entry("2026-04-22", 60)
        ]
        let (streak, used) = StreakEngine.streak(history: h, persistence: s)
        // 최신 60 (1) → 0 (토큰 소모, 2) → 0 (토큰 없음, 중단)
        XCTAssertEqual(streak, 2)
        XCTAssertTrue(used)
    }

    func testStreak_emptyHistory() {
        let s = InMemoryPersistenceStore()
        let (streak, used) = StreakEngine.streak(history: [], persistence: s)
        XCTAssertEqual(streak, 0)
        XCTAssertFalse(used)
    }
}
