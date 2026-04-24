import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

@MainActor
final class BadgeDetailCardViewTests: XCTestCase {

    func testRendersHeaderLabel() throws {
        let view = BadgeDetailCardView(badge: .perfectDay, onClose: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("획득한 뱃지")))
    }

    func testRendersTitle() throws {
        let view = BadgeDetailCardView(badge: .returnMaster, onClose: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("집중 지킴 100회")))
    }

    func testRendersDetail() throws {
        let view = BadgeDetailCardView(badge: .firstReturn, onClose: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("차단 화면에서 처음으로 돌아섰어요.")))
    }

    func testRendersCloseButton() throws {
        let view = BadgeDetailCardView(badge: .perfectDay, onClose: {})
        XCTAssertNoThrow(try view.inspect().find(button: L("닫기")))
    }

    func testCloseButton_triggersOnClose() throws {
        var closed = false
        let view = BadgeDetailCardView(badge: .perfectDay) { closed = true }
        try view.inspect().find(button: L("닫기")).tap()
        XCTAssertTrue(closed)
    }
}
