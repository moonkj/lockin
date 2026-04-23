import XCTest
@testable import LockinFocus

/// Badge enum 의 모든 case 에 대해 title/detail/symbol/accentColor 가 정의돼 있고
/// 중복 id 가 없음을 검증해 switch exhaustiveness 회귀를 방어한다.
final class BadgeModelTests: XCTestCase {

    func testAllBadges_haveNonEmptyTitle() {
        for badge in Badge.allCases {
            XCTAssertFalse(
                badge.title.isEmpty,
                "\(badge.id) 는 title 이 비어있음"
            )
        }
    }

    func testAllBadges_haveNonEmptyDetail() {
        for badge in Badge.allCases {
            XCTAssertFalse(
                badge.detail.isEmpty,
                "\(badge.id) 는 detail 이 비어있음"
            )
        }
    }

    func testAllBadges_haveSymbol() {
        for badge in Badge.allCases {
            XCTAssertFalse(
                badge.symbol.isEmpty,
                "\(badge.id) 는 symbol 이 비어있음"
            )
        }
    }

    func testAllBadges_haveUniqueIDs() {
        let ids = Badge.allCases.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "중복된 badge id 존재")
    }

    func testBadgeCount_matchesExpectedSpec() {
        // 귀환 4 + 점수/스트릭 3 + 엄격 2 + 수동/시간 6 + 주평균 3 + 순위% 5 + 순위등수 3 = 26.
        XCTAssertEqual(Badge.allCases.count, 26)
    }

    func testAllBadges_accentColor_invokesSwitch() {
        // 모든 case 에 대해 accentColor 가 crash 없이 반환되는지 확인 —
        // switch exhaustiveness 회귀 방지 + coverage 100%.
        for badge in Badge.allCases {
            _ = badge.accentColor
        }
    }

    func testBadgeRawValues_staySameForPersistenceCompatibility() {
        // 저장된 earnedBadges 가 rawValue 로 저장되기에 rename 이 회귀가 됨.
        XCTAssertEqual(Badge.firstReturn.rawValue, "firstReturn")
        XCTAssertEqual(Badge.returnMaster.rawValue, "returnMaster")
        XCTAssertEqual(Badge.perfectDay.rawValue, "perfectDay")
        XCTAssertEqual(Badge.rankFirst.rawValue, "rankFirst")
        XCTAssertEqual(Badge.focusHour100.rawValue, "focusHour100")
    }
}
