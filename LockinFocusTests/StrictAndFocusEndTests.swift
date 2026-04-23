import XCTest
@testable import LockinFocus

/// 엄격 모드 종료 시각 + 오늘 수동 집중 해제 횟수(ordinal) 로직 검증.
final class StrictAndFocusEndTests: XCTestCase {

    private static let suiteName = "com.moonkj.LockinFocus.tests.strict"
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

    // MARK: - strictModeEndAt

    func testStrictMode_nilByDefault_isInactive() {
        XCTAssertNil(store.strictModeEndAt)
        XCTAssertFalse(store.isStrictModeActive)
    }

    func testStrictMode_futureEndAt_isActive() {
        store.strictModeEndAt = Date().addingTimeInterval(600)
        XCTAssertTrue(store.isStrictModeActive)
        XCTAssertGreaterThan(store.strictModeRemainingSeconds, 0)
    }

    func testStrictMode_pastEndAt_isInactive() {
        store.strictModeEndAt = Date().addingTimeInterval(-10)
        XCTAssertFalse(store.isStrictModeActive)
        XCTAssertEqual(store.strictModeRemainingSeconds, 0)
    }

    func testStrictMode_setNil_clearsValue() {
        store.strictModeEndAt = Date().addingTimeInterval(600)
        store.strictModeEndAt = nil
        XCTAssertNil(store.strictModeEndAt)
    }

    func testStrictMode_persistsViaUserDefaults() {
        let future = Date().addingTimeInterval(1200)
        store.strictModeEndAt = future
        let store2 = UserDefaultsPersistenceStore(defaults: defaults)
        XCTAssertNotNil(store2.strictModeEndAt)
        XCTAssertEqual(
            store2.strictModeEndAt!.timeIntervalSince1970,
            future.timeIntervalSince1970,
            accuracy: 1
        )
    }

    // MARK: - focusEndCountToday

    func testFocusEndCount_startsAtZero() {
        XCTAssertEqual(store.focusEndCountToday, 0)
    }

    func testFocusEndCount_incrementsOnRecord() {
        store.recordManualFocusEnd()
        XCTAssertEqual(store.focusEndCountToday, 1)
        store.recordManualFocusEnd()
        XCTAssertEqual(store.focusEndCountToday, 2)
    }

    func testFocusEndCount_rollsOverOnNewDay() {
        store.recordManualFocusEnd()
        store.recordManualFocusEnd()
        // 날짜 키를 과거로 밀어 rollover 트리거.
        defaults.set("2000-01-01", forKey: "focusEndCountDate")
        XCTAssertEqual(store.focusEndCountToday, 0)
    }

    // MARK: - Progressive unlock delay — 일반 모드 해제 시 대기 시간 로직

    func testUnlockDelay_firstUnlock_10s() {
        XCTAssertEqual(store.currentUnlockDelaySeconds(), 10)
    }

    func testUnlockDelay_secondUnlock_30s() {
        store.recordManualUnlock()
        XCTAssertEqual(store.currentUnlockDelaySeconds(), 30)
    }

    func testUnlockDelay_thirdAndBeyond_60s() {
        store.recordManualUnlock()
        store.recordManualUnlock()
        XCTAssertEqual(store.currentUnlockDelaySeconds(), 60)
        store.recordManualUnlock()
        XCTAssertEqual(store.currentUnlockDelaySeconds(), 60)
    }

    func testUnlockDelay_rollsOverOnNewDay() {
        store.recordManualUnlock()
        store.recordManualUnlock()
        defaults.set("2000-01-01", forKey: "todayUnlockDate")
        XCTAssertEqual(store.currentUnlockDelaySeconds(), 10)
    }
}
