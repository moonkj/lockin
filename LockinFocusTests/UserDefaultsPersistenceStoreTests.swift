import XCTest
@testable import LockinFocus

/// `UserDefaultsPersistenceStore` 의 주입 가능 이니셜라이저(`init(defaults:)`) 를
/// 활용해 **테스트 전용 suite** 를 사용한다. App Group 실 suite 에 오염되지 않도록
/// setUp/tearDown 에서 suite 를 강제로 비운다.
///
/// **핵심 회귀 테스트**: `testDrainInterceptQueue_decodesExtensionRawFormat` —
/// ShieldActionExtension 이 `[[String: Any]]` 로 enqueue 한 레거시 포맷을
/// `UserDefaultsPersistenceStore.drainInterceptQueue()` 가 여전히 디코딩할 수 있는지
/// 확인한다. Debugger Report H1 에서 증명된 계약을 미래 회귀로부터 보호.
final class UserDefaultsPersistenceStoreTests: XCTestCase {

    private static let testSuiteName = "com.moonkj.LockinFocus.tests"

    private var defaults: UserDefaults!
    private var store: UserDefaultsPersistenceStore!

    override func setUp() {
        super.setUp()
        // 주입 가능한 init(defaults:) 존재 확인: 없으면 여기서 컴파일 실패.
        let suite = UserDefaults(suiteName: Self.testSuiteName)!
        // 이전 테스트 잔여 제거.
        suite.removePersistentDomain(forName: Self.testSuiteName)
        defaults = suite
        store = UserDefaultsPersistenceStore(defaults: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: Self.testSuiteName)
        defaults = nil
        store = nil
        super.tearDown()
    }

    // Schedule JSON 인코딩 저장 후 동일 suite 에서 새 store 인스턴스로
    // 읽어도 동일한 값이 복원되는지(앱 재시작 시나리오 근사).
    func testScheduleRoundTrip_viaJSON() {
        var custom = Schedule.weekdayWorkHours
        custom.startHour = 10
        custom.endHour = 18
        store.schedule = custom

        // "앱 재시작" 을 모방: 새 store 인스턴스로 같은 defaults 를 바라보게 한다.
        let store2 = UserDefaultsPersistenceStore(defaults: defaults)
        XCTAssertEqual(store2.schedule, custom)
    }

    // 정수 스칼라 값 persistence 왕복.
    func testFocusScoreToday_persists() {
        store.focusScoreToday = 73
        let store2 = UserDefaultsPersistenceStore(defaults: defaults)
        XCTAssertEqual(store2.focusScoreToday, 73)
    }

    // 온보딩 플래그 왕복 — RootView 분기 회귀 방지.
    func testHasCompletedOnboarding_persists() {
        XCTAssertFalse(store.hasCompletedOnboarding)
        store.hasCompletedOnboarding = true
        let store2 = UserDefaultsPersistenceStore(defaults: defaults)
        XCTAssertTrue(store2.hasCompletedOnboarding)
    }

    // **핵심 회귀 테스트**: Extension 이 App Group UserDefaults 에 `[[String: Any]]`
    // 원시 포맷으로 쓰는 큐를 `drainInterceptQueue()` 가 정확히 디코딩 + 비우기.
    //
    // Extension 이 쓰는 키: "interceptQueue" (PersistenceKeys.rawInterceptQueue 과 동일).
    // 필드: timestamp(TimeInterval), type(String), subjectKind(String).
    // type 은 "returned" | "intercept_requested" | "interceptRequested" 를 모두 허용.
    func testDrainInterceptQueue_decodesExtensionRawFormat() {
        let rawQueue: [[String: Any]] = [
            [
                "timestamp": 1_714_000_000.0,
                "type": "returned",
                "subjectKind": "application"
            ],
            [
                "timestamp": 1_714_000_100.0,
                "type": "interceptRequested",
                "subjectKind": "category"
            ]
        ]
        defaults.set(rawQueue, forKey: "interceptQueue")

        let events = store.drainInterceptQueue()
        XCTAssertEqual(events.count, 2, "Extension raw 큐 2건이 모두 디코딩되어야 한다.")

        XCTAssertEqual(events[0].type, .returned)
        XCTAssertEqual(events[0].subjectKind, .application)
        XCTAssertEqual(events[0].timestamp.timeIntervalSince1970, 1_714_000_000.0, accuracy: 0.001)

        XCTAssertEqual(events[1].type, .interceptRequested)
        XCTAssertEqual(events[1].subjectKind, .category)

        // drain 후 큐는 반드시 비어야 한다.
        XCTAssertNil(defaults.array(forKey: "interceptQueue"))
        let second = store.drainInterceptQueue()
        XCTAssertTrue(second.isEmpty)
    }

    // Extension 의 legacy snake_case `"intercept_requested"` 도 매핑되는지 회귀 방지.
    func testDrainInterceptQueue_acceptsLegacySnakeCaseType() {
        let rawQueue: [[String: Any]] = [
            [
                "timestamp": 1_714_000_200.0,
                "type": "intercept_requested",
                "subjectKind": "webDomain"
            ]
        ]
        defaults.set(rawQueue, forKey: "interceptQueue")

        let events = store.drainInterceptQueue()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].type, .interceptRequested)
        XCTAssertEqual(events[0].subjectKind, .webDomain)
    }

    // 잘못된 필드는 silently drop (partial failure 허용).
    func testDrainInterceptQueue_dropsMalformedEntries() {
        let rawQueue: [[String: Any]] = [
            ["timestamp": 1_714_000_300.0, "type": "returned", "subjectKind": "application"],
            ["timestamp": 1_714_000_400.0, "type": "UNKNOWN_TYPE", "subjectKind": "application"],
            ["timestamp": 1_714_000_500.0, "type": "returned", "subjectKind": "UNKNOWN_KIND"]
        ]
        defaults.set(rawQueue, forKey: "interceptQueue")

        let events = store.drainInterceptQueue()
        XCTAssertEqual(events.count, 1, "알 수 없는 enum raw 는 drop, 정상 1건만 통과.")
    }
}
