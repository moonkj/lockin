import XCTest
@testable import LockinFocus

/// BadgeEngine 전체 트리거 + 경계값 + 중복 수여 방지 커버리지.
final class BadgeEngineTests: XCTestCase {
    private var store: InMemoryPersistenceStore!

    override func setUp() {
        super.setUp()
        store = InMemoryPersistenceStore()
    }

    // MARK: - onReturn 누적 뱃지

    func testOnReturn_firstReturn_unlocks() {
        let unlocked = BadgeEngine.onReturn(persistence: store)
        XCTAssertTrue(unlocked.contains(.firstReturn))
        XCTAssertEqual(store.totalReturnCount, 1)
    }

    func testOnReturn_tenth_unlocksNovice() {
        for _ in 0..<9 { _ = BadgeEngine.onReturn(persistence: store) }
        let unlocked = BadgeEngine.onReturn(persistence: store)
        XCTAssertTrue(unlocked.contains(.returnNovice))
    }

    func testOnReturn_fiftieth_unlocksAdept() {
        for _ in 0..<49 { _ = BadgeEngine.onReturn(persistence: store) }
        let unlocked = BadgeEngine.onReturn(persistence: store)
        XCTAssertTrue(unlocked.contains(.returnAdept))
    }

    func testOnReturn_hundredth_unlocksMaster() {
        for _ in 0..<99 { _ = BadgeEngine.onReturn(persistence: store) }
        let unlocked = BadgeEngine.onReturn(persistence: store)
        XCTAssertTrue(unlocked.contains(.returnMaster))
    }

    func testOnReturn_doesNotDoubleAward() {
        _ = BadgeEngine.onReturn(persistence: store)
        let second = BadgeEngine.onReturn(persistence: store)
        XCTAssertFalse(second.contains(.firstReturn))
    }

    // MARK: - onScoreChanged / perfectDay

    func testOnScoreChanged_perfectDay_unlocks() {
        store.focusScoreToday = 100
        let unlocked = BadgeEngine.onScoreChanged(persistence: store)
        XCTAssertTrue(unlocked.contains(.perfectDay))
    }

    func testOnScoreChanged_below100_noPerfectDay() {
        store.focusScoreToday = 99
        let unlocked = BadgeEngine.onScoreChanged(persistence: store)
        XCTAssertFalse(unlocked.contains(.perfectDay))
    }

    // MARK: - onStrictSurvived

    func testOnStrictSurvived_firstTime_unlocksSurvivor() {
        let unlocked = BadgeEngine.onStrictSurvived(persistence: store)
        XCTAssertTrue(unlocked.contains(.strictSurvivor))
        XCTAssertEqual(store.totalStrictSurvived, 1)
    }

    func testOnStrictSurvived_thirdTime_unlocksSurvivor3() {
        _ = BadgeEngine.onStrictSurvived(persistence: store)
        _ = BadgeEngine.onStrictSurvived(persistence: store)
        let unlocked = BadgeEngine.onStrictSurvived(persistence: store)
        XCTAssertTrue(unlocked.contains(.strictSurvivor3))
    }

    // MARK: - onManualFocusStarted

    func testOnManualFocusStarted_first_unlocksFirstManualFocus() {
        let unlocked = BadgeEngine.onManualFocusStarted(persistence: store)
        XCTAssertTrue(unlocked.contains(.firstManualFocus))
        XCTAssertEqual(store.totalManualFocusStarts, 1)
    }

    func testOnManualFocusStarted_second_noDoubleAward() {
        _ = BadgeEngine.onManualFocusStarted(persistence: store)
        let second = BadgeEngine.onManualFocusStarted(persistence: store)
        XCTAssertFalse(second.contains(.firstManualFocus))
    }

    // MARK: - onManualFocusEnded — 파밍 방지 가드 + 누적 티어

    func testOnManualFocusEnded_shortSession_rejected() {
        let unlocked = BadgeEngine.onManualFocusEnded(elapsed: 30, persistence: store)
        XCTAssertTrue(unlocked.isEmpty)
        XCTAssertEqual(store.totalFocusSeconds, 0, "1분 미만은 누적 금지")
    }

    func testOnManualFocusEnded_oneMinute_accumulatesButNoTier() {
        let unlocked = BadgeEngine.onManualFocusEnded(elapsed: 60, persistence: store)
        XCTAssertTrue(unlocked.isEmpty, "1분 만으로는 티어 뱃지 안 나옴")
        XCTAssertEqual(store.totalFocusSeconds, 60)
    }

    func testOnManualFocusEnded_oneHour_unlocksFocusHour1() {
        let unlocked = BadgeEngine.onManualFocusEnded(elapsed: 3600, persistence: store)
        XCTAssertTrue(unlocked.contains(.focusHour1))
    }

    func testOnManualFocusEnded_fiftyHours_unlocksAllPriorTiers() {
        // 누적 50시간 한 번에 — 1, 5, 20, 50시간 뱃지 동시 해제.
        let unlocked = BadgeEngine.onManualFocusEnded(elapsed: 50 * 3600, persistence: store)
        XCTAssertTrue(unlocked.contains(.focusHour1))
        XCTAssertTrue(unlocked.contains(.focusHour5))
        XCTAssertTrue(unlocked.contains(.focusHour20))
        XCTAssertTrue(unlocked.contains(.focusHour50))
    }

    func testOnManualFocusEnded_hundredHours_unlocksFocusHour100() {
        let unlocked = BadgeEngine.onManualFocusEnded(elapsed: 100 * 3600, persistence: store)
        XCTAssertTrue(unlocked.contains(.focusHour100))
    }

    // MARK: - onRankingFetched

    private func makeEntries(count: Int, myRank: Int, userID: String) -> [LeaderboardEntry] {
        (0..<count).map { idx in
            LeaderboardEntry(
                userID: idx + 1 == myRank ? userID : "other-\(idx)",
                nickname: "N\(idx)",
                dailyScore: 100 - idx,
                dailyDate: "2026-04-23",
                weeklyTotal: 0, weeklyWeek: "",
                monthlyTotal: 0, monthlyMonth: "",
                updatedAt: Date()
            )
        }
    }

    func testOnRankingFetched_under100Participants_noAward() {
        let entries = makeEntries(count: 99, myRank: 1, userID: "me")
        let unlocked = BadgeEngine.onRankingFetched(
            entries: entries, userID: "me", persistence: store
        )
        XCTAssertTrue(unlocked.isEmpty, "100명 미만 랭킹에선 수여 금지")
    }

    func testOnRankingFetched_exactly100_rank1_unlocksAllTiers() {
        let entries = makeEntries(count: 100, myRank: 1, userID: "me")
        let unlocked = BadgeEngine.onRankingFetched(
            entries: entries, userID: "me", persistence: store
        )
        XCTAssertTrue(unlocked.contains(.rankFirst))
        XCTAssertTrue(unlocked.contains(.rankSecond))
        XCTAssertTrue(unlocked.contains(.rankThird))
        XCTAssertTrue(unlocked.contains(.rankTop1))
        XCTAssertTrue(unlocked.contains(.rankTop50))
    }

    func testOnRankingFetched_rank2_excludesFirst() {
        let entries = makeEntries(count: 100, myRank: 2, userID: "me")
        let unlocked = BadgeEngine.onRankingFetched(
            entries: entries, userID: "me", persistence: store
        )
        XCTAssertFalse(unlocked.contains(.rankFirst))
        XCTAssertTrue(unlocked.contains(.rankSecond))
        XCTAssertTrue(unlocked.contains(.rankThird))
    }

    func testOnRankingFetched_rank50_top50Only() {
        let entries = makeEntries(count: 100, myRank: 50, userID: "me")
        let unlocked = BadgeEngine.onRankingFetched(
            entries: entries, userID: "me", persistence: store
        )
        XCTAssertTrue(unlocked.contains(.rankTop50))
        XCTAssertFalse(unlocked.contains(.rankTop30))
        XCTAssertFalse(unlocked.contains(.rankFirst))
    }

    func testOnRankingFetched_rank51_noTop50() {
        let entries = makeEntries(count: 100, myRank: 51, userID: "me")
        let unlocked = BadgeEngine.onRankingFetched(
            entries: entries, userID: "me", persistence: store
        )
        XCTAssertFalse(unlocked.contains(.rankTop50))
    }

    func testOnRankingFetched_userNotInEntries_noAward() {
        let entries = makeEntries(count: 100, myRank: 999, userID: "nobody")
        let unlocked = BadgeEngine.onRankingFetched(
            entries: entries, userID: "me", persistence: store
        )
        XCTAssertTrue(unlocked.isEmpty)
    }

    func testOnRankingFetched_doesNotDoubleAward() {
        let entries = makeEntries(count: 100, myRank: 1, userID: "me")
        _ = BadgeEngine.onRankingFetched(entries: entries, userID: "me", persistence: store)
        let second = BadgeEngine.onRankingFetched(
            entries: entries, userID: "me", persistence: store
        )
        XCTAssertTrue(second.isEmpty)
    }
}
