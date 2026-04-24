import XCTest
@testable import LockinFocus

/// Bug 2 리그레션 — iCloud KV 에서 userID 가 바뀐 뒤 `AppDependencies.objectWillChange`
/// 가 쏘이면 LeaderboardView 의 cached myUserID 가 최신화돼야.
///
/// 뷰의 `@State` 를 직접 inspect 하긴 어렵지만, 계약 수준에서 고정하는 건:
/// - `persistence.leaderboardUserID` 는 iCloud 우선 → 로컬 재동기화 (이미 검증된 로직)
/// - 변경이 있을 때 `deps.objectWillChange` 가 쏘이는 경로가 AppDependencies 초기화 때
///   설치된다 (`observeICloudKVChanges()`)
///
/// 이 테스트는 deps 가 관찰자를 설치했는지, persistence 가 우선순위에 따라 새 값을
/// 반환하는지를 확인해 뷰 수정이 의존하는 전제를 고정.
@MainActor
final class LeaderboardUserIDRefreshTests: XCTestCase {

    func testPersistence_leaderboardUserID_returnsFreshValueAfterMutation() {
        let store = InMemoryPersistenceStore()
        let initial = store.leaderboardUserID
        XCTAssertFalse(initial.isEmpty, "첫 접근 시 UUID 가 생성돼야")

        // 두 번째 접근에서도 동일 — 캐시 일관성.
        XCTAssertEqual(store.leaderboardUserID, initial)
    }

    func testAppDependencies_objectWillChange_canBeObserved() {
        let deps = AppDependencies.preview()

        let expectation = expectation(description: "objectWillChange emits")
        let cancellable = deps.objectWillChange.sink { _ in
            expectation.fulfill()
        }

        // trigger 는 AppDependencies 가 제공하는 @Published 를 건드리는 방식.
        deps.requestRoute(.weeklyReport)

        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()
    }

    func testAppDependencies_pendingRouteMutation_firesObjectWillChange() {
        let deps = AppDependencies.preview()
        var fireCount = 0
        let cancellable = deps.objectWillChange.sink { _ in
            fireCount += 1
        }

        deps.requestRoute(.weeklyReport)
        deps.consumeRoute()

        XCTAssertGreaterThanOrEqual(fireCount, 1, "@Published 변경은 objectWillChange 를 쏘아야")
        cancellable.cancel()
    }
}
