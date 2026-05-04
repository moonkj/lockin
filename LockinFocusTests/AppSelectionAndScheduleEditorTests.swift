import XCTest
import SwiftUI
import FamilyControls
import ViewInspector
@testable import LockinFocus

@MainActor
final class AppSelectionAndScheduleEditorTests: XCTestCase {

    // MARK: - AppSelectionView

    func testAppSelectionView_rendersHeader() throws {
        try XCTSkipIfViewInspectorBlocked()
        let view = AppSelectionView(
            selection: .constant(FamilyActivitySelection()),
            onDone: {}
        )
        XCTAssertNoThrow(try view.inspect().find(text: L("허용 앱")))
    }

    func testAppSelectionView_hasCloseButton() throws {
        try XCTSkipIfViewInspectorBlocked()
        let view = AppSelectionView(
            selection: .constant(FamilyActivitySelection()),
            onDone: {}
        )
        XCTAssertNoThrow(try view.inspect().find(button: L("닫기")))
    }

    func testAppSelectionView_hasSaveButton() throws {
        let view = AppSelectionView(
            selection: .constant(FamilyActivitySelection()),
            onDone: {}
        )
        XCTAssertNoThrow(try view.inspect().find(text: L("저장")))
    }

    // MARK: - ScheduleEditorView

    func testScheduleEditorView_rendersScheduleTitle() throws {
        let view = ScheduleEditorView(
            schedule: .constant(.weekdayWorkHours),
            onSave: {}
        )
        XCTAssertNoThrow(try view.inspect())
    }

    func testScheduleEditorView_hasCancelButton() throws {
        try XCTSkipIfViewInspectorBlocked()
        let view = ScheduleEditorView(
            schedule: .constant(.weekdayWorkHours),
            onSave: {}
        )
        XCTAssertNoThrow(try view.inspect().find(button: L("취소")))
    }

    func testScheduleEditorView_hasSaveButton() throws {
        let view = ScheduleEditorView(
            schedule: .constant(.weekdayWorkHours),
            onSave: {}
        )
        XCTAssertNoThrow(try view.inspect().find(text: L("저장")))
    }

    func testScheduleEditorView_rendersSections() throws {
        let view = ScheduleEditorView(
            schedule: .constant(.weekdayWorkHours),
            onSave: {}
        )
        XCTAssertNoThrow(try view.inspect().find(text: L("요일")))
        XCTAssertNoThrow(try view.inspect().find(text: L("시간")))
    }
}
