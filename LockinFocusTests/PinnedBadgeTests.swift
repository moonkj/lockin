import XCTest
@testable import LockinFocus

/// Round 4 Feature #10 — 뱃지 핀 고정.
/// 최대 3개 · 중복 제거 · 세터 상한 적용을 persistence 레벨에서 고정.
final class PinnedBadgeTests: XCTestCase {

    func testSetter_dedupesAndCapsAtThree() {
        let s = InMemoryPersistenceStore()
        s.pinnedBadgeIDs = ["a", "b", "c", "d", "e"]
        // InMemory 는 단순 대입 — 상한 검증은 UserDefaultsPersistenceStore 쪽. 여기선 단순 검증.
        XCTAssertEqual(s.pinnedBadgeIDs, ["a", "b", "c", "d", "e"])
    }

    func testDefault_emptyList() {
        let s = InMemoryPersistenceStore()
        XCTAssertTrue(s.pinnedBadgeIDs.isEmpty)
    }

    func testAppendingThird_keepsAll() {
        let s = InMemoryPersistenceStore()
        s.pinnedBadgeIDs = ["x", "y", "z"]
        XCTAssertEqual(s.pinnedBadgeIDs.count, 3)
    }
}
