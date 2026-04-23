import XCTest
@testable import LockinFocus

/// 점수 규칙 B — 돌아가기 +5 (3분 쿨다운 + 일 40 한도), 세션 15분 보너스, 데일리 로그인 +5.
/// UserDefaultsPersistenceStore 의 주입 가능 initializer 를 통해 격리된 suite 에서 검증.
final class ScoreRuleBTests: XCTestCase {

    private static let suiteName = "com.moonkj.LockinFocus.tests.ruleB"
    private var defaults: UserDefaults!
    private var store: UserDefaultsPersistenceStore!

    override func setUp() {
        super.setUp()
        let suite = UserDefaults(suiteName: Self.suiteName)!
        suite.removePersistentDomain(forName: Self.suiteName)
        defaults = suite
        store = UserDefaultsPersistenceStore(defaults: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: Self.suiteName)
        super.tearDown()
    }

    // MARK: - awardReturnPoint

    func testAwardReturnPoint_firstCall_awards5() {
        XCTAssertTrue(store.awardReturnPoint())
        XCTAssertEqual(store.focusScoreToday, 5)
    }

    func testAwardReturnPoint_withinCooldown_rejected() {
        XCTAssertTrue(store.awardReturnPoint())
        XCTAssertFalse(store.awardReturnPoint(), "3분 쿨다운 중이라 바로 재호출 시 false")
        XCTAssertEqual(store.focusScoreToday, 5)
    }

    func testAwardReturnPoint_dailyCap_fortyPoints() {
        // 쿨다운 우회를 위해 lastReturnAt 을 과거로 강제한 뒤 8번 호출.
        for i in 0..<10 {
            defaults.removeObject(forKey: "lastReturnAt")
            let awarded = store.awardReturnPoint()
            if i < 8 {
                XCTAssertTrue(awarded, "8회차까지는 누적 성공")
            }
        }
        // 40점을 넘어서는 호출은 실패.
        defaults.removeObject(forKey: "lastReturnAt")
        XCTAssertFalse(store.awardReturnPoint(), "40점 한도 도달 후 더 안 들어감")
    }

    // MARK: - awardSessionCompletionIfEligible

    func testSessionCompletion_shortSession_noAward_andPreservesStart() {
        let start = Date().addingTimeInterval(-5 * 60)
        store.manualFocusStartedAt = start
        XCTAssertFalse(store.awardSessionCompletionIfEligible(now: Date()))
        // 15분 이전에는 startedAt 이 유지돼야 (fix #4).
        XCTAssertNotNil(store.manualFocusStartedAt)
    }

    func testSessionCompletion_fifteenMinutes_awardsAndClears() {
        store.manualFocusStartedAt = Date().addingTimeInterval(-15 * 60)
        XCTAssertTrue(store.awardSessionCompletionIfEligible(now: Date()))
        XCTAssertEqual(store.focusScoreToday, 15)
        XCTAssertNil(store.manualFocusStartedAt)
    }

    func testSessionCompletion_noStart_returnsFalse() {
        store.manualFocusStartedAt = nil
        XCTAssertFalse(store.awardSessionCompletionIfEligible(now: Date()))
    }

    // MARK: - awardDailyLoginIfNew

    func testDailyLogin_firstCall_awards5() {
        XCTAssertTrue(store.awardDailyLoginIfNew())
        XCTAssertEqual(store.focusScoreToday, 5)
    }

    func testDailyLogin_sameDaySecondCall_rejected() {
        XCTAssertTrue(store.awardDailyLoginIfNew())
        XCTAssertFalse(store.awardDailyLoginIfNew())
    }

    // MARK: - addFocusPoints 경계

    func testAddFocusPoints_clampsToHundred() {
        store.focusScoreToday = 95
        store.addFocusPoints(20)
        XCTAssertEqual(store.focusScoreToday, 100)
    }

    func testAddFocusPoints_clampsToZero() {
        store.focusScoreToday = 10
        store.addFocusPoints(-50)
        XCTAssertEqual(store.focusScoreToday, 0)
    }

    // MARK: - Rollover 자정 리셋 (fix #2 회귀 방지)

    func testRollover_resetsTodayReturnPoints() {
        // 오늘 날짜로 쿨다운·한도값을 설정해둔 뒤, 저장된 날짜를 어제로 강제 변경.
        defaults.set(20, forKey: "todayReturnPoints")
        defaults.set(Date().timeIntervalSince1970, forKey: "lastReturnAt")
        defaults.set("2000-01-01", forKey: "focusScoreDate")
        defaults.set(77, forKey: "focusScoreToday")

        // getter 호출 시 rollover 가 발동돼야 한다.
        _ = store.focusScoreToday

        XCTAssertEqual(store.focusScoreToday, 0, "자정 넘으면 점수 0 으로")
        XCTAssertEqual(defaults.integer(forKey: "todayReturnPoints"), 0,
                       "todayReturnPoints 도 리셋돼야 오늘 새로 적립 가능")
        XCTAssertNil(defaults.object(forKey: "lastReturnAt"),
                     "lastReturnAt 도 리셋돼야 쿨다운이 오늘 기준으로 다시 시작")
    }

    func testRollover_appendsHistoryWithPreviousScore() {
        defaults.set("2000-01-01", forKey: "focusScoreDate")
        defaults.set(55, forKey: "focusScoreToday")

        _ = store.focusScoreToday  // 롤오버 트리거

        let history = store.dailyFocusHistory(lastDays: 7)
        XCTAssertTrue(
            history.contains(where: { $0.date == "2000-01-01" && $0.score == 55 }),
            "이전 날짜 점수가 history 에 적층되어야"
        )
    }
}
