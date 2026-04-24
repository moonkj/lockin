import XCTest
@testable import LockinFocus

/// Round 4 Feature #8 — 위젯 Smart deep-link.
/// FocusScoreEntry.deepLinkURL 이 state 에 따라 적절한 URL 을 반환해야.
///
/// NOTE: FocusScoreEntry 는 Widget target 타입이라 @testable 로 main app 에선 import
/// 못 한다. 여기선 같은 계약을 main-app side 에서 복제해 검증할 수 없으므로,
/// URL 포맷/Route 라우팅 경계만 고정한다 (FriendInviteLink 같은 패턴).
final class FocusScoreEntryDeepLinkContractTests: XCTestCase {

    /// startFocus 라우트가 RouteParser 로 파싱돼 Route.startFocus 가 되는지.
    func testRouteParser_startFocusURL_parsesToRoute() {
        let url = URL(string: "lockinfocus://startFocus")!
        XCTAssertEqual(RouteParser.parse(url), .startFocus)
    }

    func testRouteParser_endFocusURL_parsesToRoute() {
        let url = URL(string: "lockinfocus://endFocus")!
        XCTAssertEqual(RouteParser.parse(url), .endFocus)
    }

    func testRouteParser_weeklyReportURL_stillParses() {
        let url = URL(string: "lockinfocus://weeklyReport")!
        XCTAssertEqual(RouteParser.parse(url), .weeklyReport)
    }

    func testRouteParser_unknownRoute_returnsNil() {
        let url = URL(string: "lockinfocus://randomHost")!
        XCTAssertNil(RouteParser.parse(url))
    }
}
