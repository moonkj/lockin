import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

@MainActor
final class ScheduleStepViewTests: XCTestCase {

    func testScheduleStepView_rendersHeadline() throws {
        let view = ScheduleStepView(schedule: .constant(.weekdayWorkHours), onNext: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("집중 시간대를 골라주세요")))
        XCTAssertNoThrow(try view.inspect().find(text: L("나중에 언제든 바꿀 수 있어요.")))
    }

    func testScheduleStepView_rendersAllPresets() throws {
        let view = ScheduleStepView(schedule: .constant(.weekdayWorkHours), onNext: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("지금부터")))
        XCTAssertNoThrow(try view.inspect().find(text: L("평일 09:00 – 17:00")))
        XCTAssertNoThrow(try view.inspect().find(text: L("직접 설정")))
    }

    func testScheduleStepView_rendersSubtitles() throws {
        let view = ScheduleStepView(schedule: .constant(.weekdayWorkHours), onNext: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("수동으로 끄기 전까지 계속")))
        XCTAssertNoThrow(try view.inspect().find(text: L("월 – 금, 업무 시간대")))
        XCTAssertNoThrow(try view.inspect().find(text: L("요일과 시간을 직접 고르기")))
    }

    func testScheduleStepView_nextButton_triggersCallback() throws {
        var next = false
        let binding = Binding<Schedule>(
            get: { .weekdayWorkHours },
            set: { _ in }
        )
        let view = ScheduleStepView(schedule: binding, onNext: { next = true })
        try view.inspect().find(button: L("다음")).tap()
        XCTAssertTrue(next)
    }

    func testSchedulePreset_allCases_haveTitles() {
        for preset in ScheduleStepView.Preset.allCases {
            XCTAssertFalse(preset.title.isEmpty)
            XCTAssertFalse(preset.subtitle.isEmpty)
            XCTAssertFalse(preset.rawValue.isEmpty)
        }
    }

    func testSchedulePreset_id_equalsRaw() {
        XCTAssertEqual(ScheduleStepView.Preset.now.id, "now")
        XCTAssertEqual(ScheduleStepView.Preset.weekdayWork.id, "weekdayWork")
        XCTAssertEqual(ScheduleStepView.Preset.custom.id, "custom")
    }
}
