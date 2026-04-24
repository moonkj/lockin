import XCTest
import SwiftUI
import FamilyControls
import ViewInspector
@testable import LockinFocus

@MainActor
final class DashboardCardsTests: XCTestCase {

    // MARK: - FocusScoreCard

    func testFocusScoreCard_zeroScore_showsDash() throws {
        let view = FocusScoreCard(score: 0)
        XCTAssertNoThrow(try view.inspect().find(text: L("오늘의 집중")))
        XCTAssertNoThrow(try view.inspect().find(text: "—"))
        XCTAssertNoThrow(try view.inspect().find(text: L("오늘이 시작이에요")))
    }

    func testFocusScoreCard_positiveScore_showsNumberAndStageLabel() throws {
        let view = FocusScoreCard(score: 55)
        XCTAssertNoThrow(try view.inspect().find(text: "55"))
        XCTAssertNoThrow(try view.inspect().find(text: "/ 100"))
        // 55 점 → young 단계 ("자라는 나무")
        XCTAssertNoThrow(try view.inspect().find(text: L("자라는 나무")))
    }

    func testFocusScoreCard_perfectScore_flourishLabel() throws {
        let view = FocusScoreCard(score: 100)
        XCTAssertNoThrow(try view.inspect().find(text: L("열매 맺는 나무")))
    }

    // MARK: - AllowedAppsCard

    func testAllowedAppsCard_empty_showsPlaceholder() throws {
        let sel = FamilyActivitySelection()
        let view = AllowedAppsCard(selection: sel, onEdit: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("허용 앱")))
        XCTAssertNoThrow(try view.inspect().find(text: L("설정된 허용 앱이 없습니다")))
        XCTAssertNoThrow(try view.inspect().find(text: L("편집")))
    }

    func testAllowedAppsCard_editButton_triggersCallback() throws {
        var edited = false
        let view = AllowedAppsCard(selection: FamilyActivitySelection()) { edited = true }
        try view.inspect().find(ViewType.Button.self).tap()
        XCTAssertTrue(edited)
    }

    // MARK: - NextScheduleCard

    func testNextScheduleCard_disabled_showsOff() throws {
        let view = NextScheduleCard(schedule: .allDay, onEdit: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("다음 스케줄")))
        XCTAssertNoThrow(try view.inspect().find(text: L("꺼짐")))
    }

    func testNextScheduleCard_weekdayWork_showsRange() throws {
        let view = NextScheduleCard(schedule: .weekdayWorkHours, onEdit: {})
        // "평일 · 09:00 – 17:00" 이런 포맷
        XCTAssertNoThrow(try view.inspect().find(text: L("평일 · 09:00 – 17:00")))
    }

    func testNextScheduleCard_editButton_triggersCallback() throws {
        var edited = false
        let view = NextScheduleCard(schedule: .weekdayWorkHours) { edited = true }
        try view.inspect().find(ViewType.Button.self).tap()
        XCTAssertTrue(edited)
    }

    func testNextScheduleCard_allDaysEnabled_showsEveryday() throws {
        var sched = Schedule.allDay
        sched.isEnabled = true
        let view = NextScheduleCard(schedule: sched, onEdit: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("매일 · 00:00 – 23:59")))
    }

    func testNextScheduleCard_weekendOnly_showsWeekend() throws {
        var sched = Schedule.weekdayWorkHours
        sched.weekdays = [1, 7]
        let view = NextScheduleCard(schedule: sched, onEdit: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("주말 · 09:00 – 17:00")))
    }

    // MARK: - DailyQuoteCard

    func testDailyQuoteCard_rendersHeader() throws {
        let view = DailyQuoteCard(onTap: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("오늘의 명언")))
    }

    func testDailyQuoteCard_tap_triggersCallback() throws {
        var tapped = false
        let view = DailyQuoteCard { tapped = true }
        try view.inspect().find(ViewType.Button.self).tap()
        XCTAssertTrue(tapped)
    }
}
