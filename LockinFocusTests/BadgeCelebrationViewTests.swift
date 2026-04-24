import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

@MainActor
final class BadgeCelebrationViewTests: XCTestCase {

    func testRendersBadgeTitle() throws {
        let view = BadgeCelebrationView(badge: .perfectDay, onConfirm: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("완벽한 하루")))
    }

    func testRendersBadgeDetail() throws {
        let view = BadgeCelebrationView(badge: .firstReturn, onConfirm: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("차단 화면에서 처음으로 돌아섰어요.")))
    }

    func testRendersConfirmLabel() throws {
        let view = BadgeCelebrationView(badge: .streak3Days, onConfirm: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("확인")))
    }

    func testRendersHeaderLabel() throws {
        let view = BadgeCelebrationView(badge: .streak3Days, onConfirm: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("뱃지 획득")))
    }

    func testConfirmButton_triggersCallback() throws {
        var called = false
        let view = BadgeCelebrationView(badge: .perfectDay) { called = true }
        try view.inspect().find(button: L("확인")).tap()
        XCTAssertTrue(called)
    }
}
