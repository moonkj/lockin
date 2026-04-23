import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

@MainActor
final class ScheduleEditorDetailTests: XCTestCase {

    func testScheduleEditor_rendersWeekdayButtons() throws {
        let view = ScheduleEditorView(
            schedule: .constant(.weekdayWorkHours),
            onSave: {}
        )
        // 요일 7개 - 월/화/수/목/금/토/일 각각 button 으로 렌더링.
        for label in ["월", "화", "수", "목", "금", "토", "일"] {
            XCTAssertNoThrow(
                try view.inspect().find(text: label),
                "요일 버튼 \(label) 가 렌더되어야"
            )
        }
    }

    func testScheduleEditor_rendersToggle() throws {
        let view = ScheduleEditorView(
            schedule: .constant(.weekdayWorkHours),
            onSave: {}
        )
        XCTAssertNoThrow(try view.inspect().find(text: "이 스케줄 사용"))
    }

    func testScheduleEditor_saveButtonTriggersCallback() throws {
        var saved = false
        let binding = Binding<Schedule>(get: { .weekdayWorkHours }, set: { _ in })
        let view = ScheduleEditorView(schedule: binding, onSave: { saved = true })
        try view.inspect().find(button: "저장").tap()
        XCTAssertTrue(saved)
    }

    func testScheduleEditor_disabled_stillRenders() throws {
        var disabled = Schedule.weekdayWorkHours
        disabled.isEnabled = false
        let view = ScheduleEditorView(
            schedule: .constant(disabled),
            onSave: {}
        )
        XCTAssertNoThrow(try view.inspect().find(text: "이 스케줄 사용"))
    }
}
