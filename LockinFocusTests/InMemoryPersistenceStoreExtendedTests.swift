import XCTest
import FamilyControls
@testable import LockinFocus

/// InMemoryPersistenceStore 의 score rule B, 뱃지 집계, 역할별 기본값 등 세부 동작 커버.
final class InMemoryPersistenceStoreExtendedTests: XCTestCase {
    private var store: InMemoryPersistenceStore!

    override func setUp() {
        super.setUp()
        store = InMemoryPersistenceStore()
        // InMemoryPersistenceStore.focusScoreDate 는 초기값이 빈 문자열이라
        // 첫 점수 관련 메서드 호출 시 rollover 가 발동돼 focusScoreToday 가 0 으로 리셋됨.
        // 각 테스트가 설정값에서 바로 시작하도록 여기서 한 번 발동시켜 "오늘"로 고정.
        store.addFocusPoints(0)
    }

    // MARK: - Init 기본값

    func testInit_defaultValues() {
        XCTAssertFalse(store.hasCompletedOnboarding)
        XCTAssertFalse(store.isManualFocusActive)
        XCTAssertNil(store.strictModeEndAt)
        XCTAssertFalse(store.isStrictModeActive)
        XCTAssertEqual(store.focusScoreToday, 0)
        XCTAssertEqual(store.focusEndCountToday, 0)
    }

    func testInit_customValues_accepted() {
        let custom = InMemoryPersistenceStore(
            focusScoreToday: 50,
            hasCompletedOnboarding: true,
            isManualFocusActive: true,
            strictModeEndAt: Date().addingTimeInterval(3600)
        )
        XCTAssertEqual(custom.focusScoreToday, 50)
        XCTAssertTrue(custom.hasCompletedOnboarding)
        XCTAssertTrue(custom.isManualFocusActive)
        XCTAssertTrue(custom.isStrictModeActive)
    }

    // MARK: - 뱃지 집계

    func testAwardBadgeIfNew_firstCall_true() {
        XCTAssertTrue(store.awardBadgeIfNew("test.badge"))
        XCTAssertTrue(store.earnedBadgeIDs.contains("test.badge"))
    }

    func testAwardBadgeIfNew_duplicate_false() {
        _ = store.awardBadgeIfNew("test.badge")
        XCTAssertFalse(store.awardBadgeIfNew("test.badge"))
    }

    func testBadgeCounters_roundTrip() {
        store.totalReturnCount = 5
        store.totalStrictSurvived = 3
        store.totalFocusSeconds = 3600
        store.totalManualFocusStarts = 7
        XCTAssertEqual(store.totalReturnCount, 5)
        XCTAssertEqual(store.totalStrictSurvived, 3)
        XCTAssertEqual(store.totalFocusSeconds, 3600)
        XCTAssertEqual(store.totalManualFocusStarts, 7)
    }

    // MARK: - currentUnlockDelaySeconds

    func testUnlockDelay_firstCall_10s() {
        XCTAssertEqual(store.currentUnlockDelaySeconds(), 10)
    }

    func testUnlockDelay_afterOneRecord_30s() {
        store.recordManualUnlock()
        XCTAssertEqual(store.currentUnlockDelaySeconds(), 30)
    }

    func testUnlockDelay_afterTwoRecords_60s() {
        store.recordManualUnlock()
        store.recordManualUnlock()
        XCTAssertEqual(store.currentUnlockDelaySeconds(), 60)
    }

    // MARK: - addFocusPoints clamp

    func testAddFocusPoints_clampsToHundred() {
        store.focusScoreToday = 90
        store.addFocusPoints(50)
        XCTAssertEqual(store.focusScoreToday, 100)
    }

    func testAddFocusPoints_clampsToZero() {
        store.focusScoreToday = 10
        store.addFocusPoints(-30)
        XCTAssertEqual(store.focusScoreToday, 0)
    }

    // MARK: - dailyFocusHistory

    func testDailyFocusHistory_returnsTodayEntry() {
        store.focusScoreToday = 42
        let history = store.dailyFocusHistory(lastDays: 1)
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history[0].score, 42)
    }

    func testDailyFocusHistory_limitsToN() {
        let entries = (0..<5).map { DailyFocus(date: "2026-04-\($0 + 1)", score: $0 * 10) }
        store.debugSetDailyFocusHistory(entries)
        let history = store.dailyFocusHistory(lastDays: 3)
        XCTAssertLessThanOrEqual(history.count, 3 + 1) // 과거 + 오늘
    }

    // MARK: - Score rule B on in-memory

    func testAwardReturnPoint_firstCall_returnsTrue() {
        XCTAssertTrue(store.awardReturnPoint())
        XCTAssertEqual(store.focusScoreToday, 5)
    }

    func testAwardReturnPoint_cooldown_rejected() {
        XCTAssertTrue(store.awardReturnPoint())
        XCTAssertFalse(store.awardReturnPoint())
    }

    func testAwardSessionCompletion_shortSession_false() {
        store.manualFocusStartedAt = Date().addingTimeInterval(-5 * 60)
        XCTAssertFalse(store.awardSessionCompletionIfEligible(now: Date()))
        XCTAssertNotNil(store.manualFocusStartedAt, "짧은 세션에는 startedAt 유지")
    }

    func testAwardSessionCompletion_longSession_true() {
        store.manualFocusStartedAt = Date().addingTimeInterval(-20 * 60)
        XCTAssertTrue(store.awardSessionCompletionIfEligible(now: Date()))
        XCTAssertEqual(store.focusScoreToday, 15)
        XCTAssertNil(store.manualFocusStartedAt)
    }

    func testAwardDailyLogin_firstCall_returnsTrue() {
        XCTAssertTrue(store.awardDailyLoginIfNew())
        XCTAssertEqual(store.focusScoreToday, 5)
    }

    func testAwardDailyLogin_sameDay_false() {
        _ = store.awardDailyLoginIfNew()
        XCTAssertFalse(store.awardDailyLoginIfNew())
    }

    // MARK: - focusEndCountToday

    func testFocusEndCount_startsZero() {
        XCTAssertEqual(store.focusEndCountToday, 0)
    }

    func testFocusEndCount_incrementsOnRecord() {
        store.recordManualFocusEnd()
        XCTAssertEqual(store.focusEndCountToday, 1)
        store.recordManualFocusEnd()
        XCTAssertEqual(store.focusEndCountToday, 2)
    }

    // MARK: - Strict mode

    func testStrictMode_endAt_roundTrip() {
        let future = Date().addingTimeInterval(1200)
        store.strictModeEndAt = future
        XCTAssertEqual(store.strictModeEndAt, future)
        XCTAssertTrue(store.isStrictModeActive)
    }

    // MARK: - Nickname / leaderboardUserID

    func testNickname_defaultsNil_thenRoundTrip() {
        XCTAssertNil(store.nickname)
        store.nickname = "집중러"
        XCTAssertEqual(store.nickname, "집중러")
    }

    func testLeaderboardUserID_stableAcrossAccess() {
        let id1 = store.leaderboardUserID
        let id2 = store.leaderboardUserID
        XCTAssertEqual(id1, id2)
        XCTAssertFalse(id1.isEmpty)
    }

    // MARK: - debugSetDailyFocusHistory (admin tool)

    func testDebugSetDailyFocusHistory_replaces() {
        let seed = [
            DailyFocus(date: "2026-04-20", score: 80),
            DailyFocus(date: "2026-04-21", score: 60)
        ]
        store.debugSetDailyFocusHistory(seed)
        let history = store.dailyFocusHistory(lastDays: 10)
        XCTAssertTrue(history.contains(where: { $0.date == "2026-04-20" && $0.score == 80 }))
    }

    // MARK: - earnedBadgeIDs direct mutation

    func testEarnedBadgeIDs_directSet() {
        store.earnedBadgeIDs = [Badge.firstReturn.id, Badge.perfectDay.id]
        XCTAssertEqual(store.earnedBadgeIDs.count, 2)
    }
}
