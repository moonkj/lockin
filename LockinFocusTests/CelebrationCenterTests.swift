import XCTest
@testable import LockinFocus

@MainActor
final class CelebrationCenterTests: XCTestCase {

    func testCelebrate_emptyArray_isNoOp() {
        let c = CelebrationCenter()
        c.celebrate([])
        XCTAssertNil(c.currentBadge)
    }

    func testCelebrate_singleBadge_setsCurrent() {
        let c = CelebrationCenter()
        let b = Badge.firstReturn
        c.celebrate([b])
        XCTAssertEqual(c.currentBadge?.id, b.id)
    }

    func testCelebrate_multipleBadges_firstShownRestQueued() {
        let c = CelebrationCenter()
        let b1 = Badge.firstReturn
        let b2 = Badge.streak3Days
        let b3 = Badge.perfectDay
        c.celebrate([b1, b2, b3])
        XCTAssertEqual(c.currentBadge?.id, b1.id)
        c.dismiss()
        XCTAssertEqual(c.currentBadge?.id, b2.id)
        c.dismiss()
        XCTAssertEqual(c.currentBadge?.id, b3.id)
        c.dismiss()
        XCTAssertNil(c.currentBadge)
    }

    func testCelebrate_whileShowing_appendsToQueue() {
        let c = CelebrationCenter()
        c.celebrate([Badge.firstReturn])
        // 두 번째 묶음이 도착해도 현재 표시중인 거 유지하고 큐에 쌓임.
        c.celebrate([Badge.streak3Days])
        XCTAssertEqual(c.currentBadge?.id, Badge.firstReturn.id)
        c.dismiss()
        XCTAssertEqual(c.currentBadge?.id, Badge.streak3Days.id)
    }

    func testDismiss_emptyQueue_setsNilCurrent() {
        let c = CelebrationCenter()
        c.celebrate([Badge.firstReturn])
        c.dismiss()
        XCTAssertNil(c.currentBadge)
        // 추가 dismiss 도 안전.
        c.dismiss()
        XCTAssertNil(c.currentBadge)
    }

    /// AppDependencies 가 위임 forwarding 을 통해 호환 API 유지.
    func testAppDependencies_celebrateForwarding_works() {
        let deps = AppDependencies.preview()
        deps.celebrate([Badge.firstReturn])
        XCTAssertEqual(deps.currentCelebratedBadge?.id, Badge.firstReturn.id)
        deps.dismissCelebratedBadge()
        XCTAssertNil(deps.currentCelebratedBadge)
    }
}
