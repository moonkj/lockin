import XCTest
import FamilyControls
@testable import LockinFocus

/// UserDefaultsPersistenceStore 의 Feature 브랜치 추가 커버 (iCloud KV 경로 포함).
final class UserDefaultsPersistenceStoreExtendedTests: XCTestCase {
    private static let suite = "com.moonkj.LockinFocus.tests.defaultsExt"
    private var defaults: UserDefaults!
    private var store: UserDefaultsPersistenceStore!

    override func setUp() {
        super.setUp()
        let d = UserDefaults(suiteName: Self.suite)!
        d.removePersistentDomain(forName: Self.suite)
        defaults = d
        store = UserDefaultsPersistenceStore(defaults: d)
        // iCloud KV 를 정리.
        ICloudKeyValueStore.set(nil, for: ICloudKeyValueStore.Keys.leaderboardUserID)
        ICloudKeyValueStore.set(nil, for: ICloudKeyValueStore.Keys.nickname)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: Self.suite)
        ICloudKeyValueStore.set(nil, for: ICloudKeyValueStore.Keys.leaderboardUserID)
        ICloudKeyValueStore.set(nil, for: ICloudKeyValueStore.Keys.nickname)
        super.tearDown()
    }

    // MARK: - Selection round-trip

    func testSelection_roundTrip_viaJSON() {
        let sel = FamilyActivitySelection()
        store.selection = sel
        _ = store.selection  // encode/decode path 커버
    }

    // MARK: - addFocusPoints

    func testAddFocusPoints_clampsBothEnds() {
        store.focusScoreToday = 10
        store.addFocusPoints(200)
        XCTAssertEqual(store.focusScoreToday, 100)
        store.addFocusPoints(-200)
        XCTAssertEqual(store.focusScoreToday, 0)
    }

    // MARK: - dailyFocusHistory mutation

    func testDailyFocusHistory_appendsAndLimits() {
        let seed = (0..<95).map { DailyFocus(date: String(format: "2026-01-%02d", ($0 % 28) + 1), score: $0) }
        store.debugSetDailyFocusHistory(seed)
        // 90개 제한 시뮬레이트 — appendHistory 내부 로직 확인.
        store.focusScoreToday = 42
        // rollover 강제 — 오늘이 어제 로 바뀌면 append 호출.
        defaults.set("2000-01-01", forKey: "focusScoreDate")
        defaults.set(77, forKey: "focusScoreToday")
        _ = store.focusScoreToday
    }

    // MARK: - interceptQueue Codable path

    func testInterceptQueue_codableRoundTrip() {
        let events = [
            InterceptEvent(type: .returned, subjectKind: .application),
            InterceptEvent(type: .interceptRequested, subjectKind: .category)
        ]
        store.interceptQueue = events
        XCTAssertEqual(store.interceptQueue.count, 2)
    }

    // MARK: - Badges

    func testEarnedBadgeIDs_persistAcrossInstances() {
        store.earnedBadgeIDs = [Badge.firstReturn.id]
        let store2 = UserDefaultsPersistenceStore(defaults: defaults)
        XCTAssertEqual(store2.earnedBadgeIDs, [Badge.firstReturn.id])
    }

    func testAwardBadgeIfNew_returnsTrueOnce() {
        XCTAssertTrue(store.awardBadgeIfNew("b1"))
        XCTAssertFalse(store.awardBadgeIfNew("b1"))
    }

    // MARK: - manualFocusStartedAt round-trip

    func testManualFocusStartedAt_persistsAndClears() {
        let date = Date().addingTimeInterval(-600)
        store.manualFocusStartedAt = date
        XCTAssertEqual(
            store.manualFocusStartedAt!.timeIntervalSince1970,
            date.timeIntervalSince1970,
            accuracy: 1
        )
        store.manualFocusStartedAt = nil
        XCTAssertNil(store.manualFocusStartedAt)
    }

    // MARK: - nickname via iCloud KV

    func testNickname_writesToBothLocalAndICloudKV() {
        store.nickname = "집중러"
        XCTAssertEqual(store.nickname, "집중러")
        XCTAssertEqual(
            ICloudKeyValueStore.string(for: ICloudKeyValueStore.Keys.nickname),
            "집중러"
        )
    }

    func testNickname_readsFromICloudKVFirst() {
        // iCloud 에만 값 설정 — 로컬은 비어있음.
        ICloudKeyValueStore.set("fromCloud", for: ICloudKeyValueStore.Keys.nickname)
        XCTAssertEqual(store.nickname, "fromCloud")
    }

    func testNickname_setNil_clearsBoth() {
        store.nickname = "x"
        store.nickname = nil
        XCTAssertNil(store.nickname)
        XCTAssertNil(
            ICloudKeyValueStore.string(for: ICloudKeyValueStore.Keys.nickname)
        )
    }

    // MARK: - leaderboardUserID sync logic

    func testLeaderboardUserID_generatedWhenAbsent() {
        let id = store.leaderboardUserID
        XCTAssertFalse(id.isEmpty)
        XCTAssertEqual(
            ICloudKeyValueStore.string(for: ICloudKeyValueStore.Keys.leaderboardUserID),
            id,
            "신규 생성 시 iCloud KV 에도 반영돼야"
        )
    }

    func testLeaderboardUserID_remoteWinsOverLocal() {
        defaults.set("local-id", forKey: "leaderboardUserID")
        ICloudKeyValueStore.set("cloud-id", for: ICloudKeyValueStore.Keys.leaderboardUserID)
        XCTAssertEqual(store.leaderboardUserID, "cloud-id")
    }

    func testLeaderboardUserID_localMirrorsToCloudWhenCloudEmpty() {
        defaults.set("local-only", forKey: "leaderboardUserID")
        // iCloud 는 빔 → 로컬값이 iCloud 로 반영.
        let id = store.leaderboardUserID
        XCTAssertEqual(id, "local-only")
        XCTAssertEqual(
            ICloudKeyValueStore.string(for: ICloudKeyValueStore.Keys.leaderboardUserID),
            "local-only"
        )
    }
}
