import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

@MainActor
final class BadgesViewTests: XCTestCase {

    func testBadgesView_rendersSummary() throws {
        let deps = AppDependencies.preview()
        deps.persistence.totalReturnCount = 12
        let view = BadgesView().environmentObject(deps)
        XCTAssertNoThrow(try view.inspect().find(text: "집중 지킴 12회"))
    }

    func testBadgesView_rendersFooterNote() throws {
        let view = BadgesView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(
            text: "순위 뱃지는 참가자 100명 이상인 랭킹에서만 획득할 수 있어요."
        ))
    }

    func testBadgesView_rendersLockedState() throws {
        let view = BadgesView().environmentObject(AppDependencies.preview())
        // 미획득 상태 메시지.
        XCTAssertNoThrow(try view.inspect().find(text: "아직 잠겨 있어요"))
    }

    func testBadgesView_rendersTitleInToolbar() throws {
        let view = BadgesView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(button: "닫기"))
    }

    func testBadgesView_rendersAllBadgeTitles() throws {
        let view = BadgesView().environmentObject(AppDependencies.preview())
        // 일부 타이틀 — 전부 렌더링되는지 샘플링.
        XCTAssertNoThrow(try view.inspect().find(text: "첫 집중 지킴"))
        XCTAssertNoThrow(try view.inspect().find(text: "완벽한 하루"))
        XCTAssertNoThrow(try view.inspect().find(text: "100시간 집중"))
        XCTAssertNoThrow(try view.inspect().find(text: "상위 1%"))
        XCTAssertNoThrow(try view.inspect().find(text: "1등"))
    }
}
