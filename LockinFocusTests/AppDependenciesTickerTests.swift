import XCTest
@testable import LockinFocus

@MainActor
final class AppDependenciesTickerTests: XCTestCase {

    func testInit_startsTickerAndObserver() {
        let deps = AppDependencies.preview()
        XCTAssertNotNil(deps.tick)
    }

    func testCelebrate_queueDrainsInOrder() {
        let deps = AppDependencies.preview()
        deps.celebrate([.firstReturn, .returnNovice, .perfectDay])
        XCTAssertEqual(deps.currentCelebratedBadge, .firstReturn)
        deps.dismissCelebratedBadge()
        XCTAssertEqual(deps.currentCelebratedBadge, .returnNovice)
        deps.dismissCelebratedBadge()
        XCTAssertEqual(deps.currentCelebratedBadge, .perfectDay)
        deps.dismissCelebratedBadge()
        XCTAssertNil(deps.currentCelebratedBadge)
    }

    func testCelebrate_multipleBatchesInterleave() {
        let deps = AppDependencies.preview()
        deps.celebrate([.firstReturn])
        deps.celebrate([.perfectDay])
        XCTAssertEqual(deps.currentCelebratedBadge, .firstReturn)
        deps.dismissCelebratedBadge()
        XCTAssertEqual(deps.currentCelebratedBadge, .perfectDay)
    }

    func testDismissCelebratedBadge_noCurrent_safe() {
        let deps = AppDependencies.preview()
        deps.dismissCelebratedBadge()
        XCTAssertNil(deps.currentCelebratedBadge)
    }

    func testRequestRoute_thenConsume_clears() {
        let deps = AppDependencies.preview()
        deps.requestRoute(.weeklyReport)
        XCTAssertEqual(deps.pendingRoute, .weeklyReport)
        deps.consumeRoute()
        XCTAssertNil(deps.pendingRoute)
    }

    func testStrictMode_tickerClearsOnExpiry() async throws {
        let deps = AppDependencies.preview()
        deps.persistence.strictModeEndAt = Date().addingTimeInterval(1.5)
        XCTAssertTrue(deps.persistence.isStrictModeActive)
        // 2.5 초 대기 — ticker 가 최소 한 번은 돌아서 nil 로 청소했을 것.
        try await Task.sleep(nanoseconds: 2_500_000_000)
        XCTAssertNil(deps.persistence.strictModeEndAt)
    }
}
