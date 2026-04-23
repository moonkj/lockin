import XCTest
@testable import LockinFocus

/// AppDependencies 의 celebrate 큐 + route API 검증.
@MainActor
final class AppDependenciesTests: XCTestCase {

    func testCelebrate_single_setsCurrent() {
        let deps = AppDependencies.preview()
        deps.celebrate([.firstReturn])
        XCTAssertEqual(deps.currentCelebratedBadge, .firstReturn)
    }

    func testCelebrate_multiple_showsOneQueuesRest() {
        let deps = AppDependencies.preview()
        deps.celebrate([.firstReturn, .perfectDay, .streak3Days])
        XCTAssertEqual(deps.currentCelebratedBadge, .firstReturn)
        deps.dismissCelebratedBadge()
        XCTAssertEqual(deps.currentCelebratedBadge, .perfectDay)
        deps.dismissCelebratedBadge()
        XCTAssertEqual(deps.currentCelebratedBadge, .streak3Days)
        deps.dismissCelebratedBadge()
        XCTAssertNil(deps.currentCelebratedBadge)
    }

    func testCelebrate_emptyArray_noop() {
        let deps = AppDependencies.preview()
        deps.celebrate([])
        XCTAssertNil(deps.currentCelebratedBadge)
    }

    func testCelebrate_afterDismissed_nextBadgeShows() {
        let deps = AppDependencies.preview()
        deps.celebrate([.firstReturn])
        deps.dismissCelebratedBadge()
        deps.celebrate([.perfectDay])
        XCTAssertEqual(deps.currentCelebratedBadge, .perfectDay)
    }

    func testRequestRoute_setsPendingRoute() {
        let deps = AppDependencies.preview()
        deps.requestRoute(.weeklyReport)
        XCTAssertEqual(deps.pendingRoute, .weeklyReport)
    }

    func testConsumeRoute_clearsPendingRoute() {
        let deps = AppDependencies.preview()
        deps.requestRoute(.quoteDetail)
        deps.consumeRoute()
        XCTAssertNil(deps.pendingRoute)
    }

    func testRoute_rawValues_stable() {
        // Route 의 rawValue 는 URL scheme 과 계약 — rename 시 RouteParser 깨짐.
        XCTAssertEqual(AppDependencies.Route.weeklyReport.rawValue, "weeklyReport")
        XCTAssertEqual(AppDependencies.Route.quoteDetail.rawValue, "quoteDetail")
    }

    func testStrictMode_autoExpires_viaGlobalTicker() async throws {
        let deps = AppDependencies.preview()
        // 2초 후 만료되는 엄격 모드 설정.
        let end = Date().addingTimeInterval(2)
        deps.persistence.strictModeEndAt = end
        XCTAssertTrue(deps.persistence.isStrictModeActive)

        // 전역 ticker 가 주기적으로 체크해서 endAt 을 지나면 nil 로 정리.
        // 3초 기다려 확실히 만료.
        try await Task.sleep(nanoseconds: 3_500_000_000)
        XCTAssertNil(deps.persistence.strictModeEndAt, "만료된 엄격 모드는 ticker 가 자동 정리")
        XCTAssertFalse(deps.persistence.isStrictModeActive)
    }

    func testTick_updatesOverTime() async throws {
        let deps = AppDependencies.preview()
        let initial = deps.tick
        try await Task.sleep(nanoseconds: 1_200_000_000)
        XCTAssertGreaterThan(deps.tick, initial)
    }
}
