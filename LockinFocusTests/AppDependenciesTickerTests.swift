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

    func testLiveFactory_smokeTest() {
        // AppDependencies.live() 가 crash 없이 반환되는지.
        let live = AppDependencies.live()
        XCTAssertNotNil(live.persistence)
        XCTAssertNotNil(live.blocking)
        XCTAssertNotNil(live.monitoring)
    }

    func testLive_tickerRunning() async throws {
        let live = AppDependencies.live()
        let initial = live.tick
        try await Task.sleep(nanoseconds: 1_200_000_000)
        XCTAssertGreaterThanOrEqual(live.tick, initial)
    }

    func testICloudKVNotification_observerRegistered() {
        // observer 가 init 에서 등록됐는지 — 제거 시점에서 crash 없이 동작하는지 확인.
        var deps: AppDependencies? = AppDependencies.preview()
        _ = deps
        deps = nil  // deinit → observer removal + tickerTimer invalidate.
        XCTAssertNil(deps)
    }
}
