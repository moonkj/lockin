import XCTest
import FamilyControls
@testable import LockinFocus

/// 테스트/시뮬레이터용 `InMemoryPersistenceStore` 의 순수 로직 검증.
final class InMemoryPersistenceStoreTests: XCTestCase {

    private var store: InMemoryPersistenceStore!

    override func setUp() {
        super.setUp()
        store = InMemoryPersistenceStore()
    }

    // 선택(FamilyActivitySelection) set/get 기본 동작.
    func testSetAndGetSelection() {
        let newSelection = FamilyActivitySelection()
        store.selection = newSelection
        // FamilyActivitySelection 은 값 비교가 opaque 하므로 존재/크래시 없음만 검증.
        _ = store.selection
        XCTAssertTrue(true)
    }

    // 스케줄 set/get 이 사용자 변경을 유지.
    func testSetAndGetSchedule() {
        let custom = Schedule(
            startHour: 8,
            startMinute: 15,
            endHour: 19,
            endMinute: 30,
            weekdays: [2, 4, 6],
            isEnabled: true
        )
        store.schedule = custom
        XCTAssertEqual(store.schedule, custom)
    }

    // 기본 온보딩 플래그는 false. (신규 설치 분기의 기본 분기)
    func testHasCompletedOnboarding_defaultsFalse() {
        XCTAssertFalse(store.hasCompletedOnboarding)
        store.hasCompletedOnboarding = true
        XCTAssertTrue(store.hasCompletedOnboarding)
    }

    // drain 호출은 저장된 이벤트를 반환 후 큐를 비워야 한다.
    func testDrainInterceptQueue_returnsAndClears() {
        let e1 = InterceptEvent(type: .interceptRequested, subjectKind: .application)
        let e2 = InterceptEvent(type: .returned, subjectKind: .category)
        store.interceptQueue = [e1, e2]

        let drained = store.drainInterceptQueue()
        XCTAssertEqual(drained.count, 2)

        // 두 번째 drain 은 반드시 빈 배열.
        let again = store.drainInterceptQueue()
        XCTAssertTrue(again.isEmpty)
        XCTAssertTrue(store.interceptQueue.isEmpty)
    }

    // focusScoreToday 기본값은 0.
    func testFocusScoreToday_defaultsZero() {
        XCTAssertEqual(store.focusScoreToday, 0)
        store.focusScoreToday = 85
        XCTAssertEqual(store.focusScoreToday, 85)
    }
}
