#if ADMIN_TOOLS_ENABLED
import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

@MainActor
final class AdminViewsTests: XCTestCase {

    // MARK: - AdminEntryView

    func testAdminEntryView_rendersHeader() throws {
        let view = AdminEntryView(onSuccess: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("관리자 모드")))
    }

    func testAdminEntryView_rendersSecureFieldPrompt() throws {
        let view = AdminEntryView(onSuccess: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("7자리 관리자 비밀번호를 입력하세요.")))
    }

    func testAdminEntryView_hasCancelButton() throws {
        try XCTSkipIfViewInspectorBlocked()
        let view = AdminEntryView(onSuccess: {})
        XCTAssertNoThrow(try view.inspect().find(button: L("취소")))
    }

    // MARK: - AdminPanelView

    func testAdminPanelView_rendersCurrentValueLabel() throws {
        let view = AdminPanelView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("현재 값")))
    }

    func testAdminPanelView_rendersCumulativeReturnsLabel() throws {
        let view = AdminPanelView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("누적 돌아가기")))
    }

    func testAdminPanelView_hasCloseButton() throws {
        try XCTSkipIfViewInspectorBlocked()
        let view = AdminPanelView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(button: L("닫기")))
    }
}
#else
import XCTest
final class AdminViewsTests: XCTestCase {
    func testAdminTools_disabled_skipped() {
        XCTAssertTrue(true)
    }
}
#endif
