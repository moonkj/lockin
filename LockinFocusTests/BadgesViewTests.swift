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
        XCTAssertNoThrow(try view.inspect().find(text: L("집중 지킴 12회")))
    }

    func testBadgesView_rendersFooterNote() throws {
        try XCTSkipIfViewInspectorBlocked()
        let view = BadgesView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(
            text: "순위 뱃지는 참가자 100명 이상인 랭킹에서만 획득할 수 있어요."
        ))
    }

    func testBadgesView_rendersLockedState() throws {
        let view = BadgesView().environmentObject(AppDependencies.preview())
        // 미획득 상태 메시지.
        XCTAssertNoThrow(try view.inspect().find(text: L("아직 잠겨 있어요")))
    }

    func testBadgesView_rendersTitleInToolbar() throws {
        try XCTSkipIfViewInspectorBlocked()
        let view = BadgesView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(button: L("닫기")))
    }

    func testBadgesView_rendersAllBadgeTitles() throws {
        let view = BadgesView().environmentObject(AppDependencies.preview())
        // 일부 타이틀 — 전부 렌더링되는지 샘플링.
        XCTAssertNoThrow(try view.inspect().find(text: L("첫 집중 지킴")))
        XCTAssertNoThrow(try view.inspect().find(text: L("완벽한 하루")))
        XCTAssertNoThrow(try view.inspect().find(text: L("100시간 집중")))
        XCTAssertNoThrow(try view.inspect().find(text: L("상위 1%")))
        XCTAssertNoThrow(try view.inspect().find(text: L("1등")))
    }

    func testBadgesView_initialSelectedBadge_rendersDetailOverlay() throws {
        try XCTSkipIfViewInspectorBlocked()
        let view = BadgesView(initialSelectedBadge: .perfectDay)
            .environmentObject(AppDependencies.preview())
        // BadgeDetailCardView 가 overlay 로 올라와 "획득한 뱃지" 라벨이 보여야.
        XCTAssertNoThrow(try view.inspect().find(text: L("획득한 뱃지")))
    }
}
