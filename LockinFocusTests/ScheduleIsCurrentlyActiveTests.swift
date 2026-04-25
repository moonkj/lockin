import XCTest
@testable import LockinFocus

/// `Schedule.isCurrentlyActive` 의 요일·시간 판정.
/// 토요일에 평일 스케줄을 등록해도 즉시 shield 가 켜지면 안 되는 버그를 잡는 회귀 가드.
final class ScheduleIsCurrentlyActiveTests: XCTestCase {

    private func cal() -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return c
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        comps.hour = hour; comps.minute = minute
        return cal().date(from: comps) ?? Date()
    }

    // MARK: - 평일 09–17 스케줄

    private var weekdayWork: Schedule {
        Schedule(
            startHour: 9, startMinute: 0,
            endHour: 17, endMinute: 0,
            weekdays: [2, 3, 4, 5, 6],  // 월(2) ~ 금(6)
            isEnabled: true
        )
    }

    func testWeekdayWork_saturday_isInactive() {
        // 2026-04-25 (토) 11:00 — 시간은 활성 구간 안이지만 토요일이라 매치 안 됨.
        let sat11am = date(2026, 4, 25, 11, 0)
        XCTAssertFalse(weekdayWork.isCurrentlyActive(at: sat11am, calendar: cal()))
    }

    func testWeekdayWork_sunday_isInactive() {
        let sun14 = date(2026, 4, 26, 14, 0)
        XCTAssertFalse(weekdayWork.isCurrentlyActive(at: sun14, calendar: cal()))
    }

    func testWeekdayWork_monday_inHours_isActive() {
        // 2026-04-27 (월) 10:30
        let monMid = date(2026, 4, 27, 10, 30)
        XCTAssertTrue(weekdayWork.isCurrentlyActive(at: monMid, calendar: cal()))
    }

    func testWeekdayWork_monday_beforeStart_isInactive() {
        let mon8 = date(2026, 4, 27, 8, 59)
        XCTAssertFalse(weekdayWork.isCurrentlyActive(at: mon8, calendar: cal()))
    }

    func testWeekdayWork_monday_afterEnd_isInactive() {
        let mon17 = date(2026, 4, 27, 17, 0)
        XCTAssertFalse(weekdayWork.isCurrentlyActive(at: mon17, calendar: cal()), "17:00 정각은 [9, 17) 밖")
        let mon20 = date(2026, 4, 27, 20, 0)
        XCTAssertFalse(weekdayWork.isCurrentlyActive(at: mon20, calendar: cal()))
    }

    func testWeekdayWork_atStartBoundary_isActive() {
        let mon9 = date(2026, 4, 27, 9, 0)
        XCTAssertTrue(weekdayWork.isCurrentlyActive(at: mon9, calendar: cal()))
    }

    // MARK: - isEnabled=false

    func testDisabled_alwaysInactive() {
        var s = weekdayWork
        s.isEnabled = false
        let monMid = date(2026, 4, 27, 10, 30)  // 평소면 active 였을 시간
        XCTAssertFalse(s.isCurrentlyActive(at: monMid, calendar: cal()))
    }

    // MARK: - 자정 가로지르는 스케줄 (예: 22-06)

    private var overnight: Schedule {
        Schedule(
            startHour: 22, startMinute: 0,
            endHour: 6, endMinute: 0,
            weekdays: [1, 2, 3, 4, 5, 6, 7],
            isEnabled: true
        )
    }

    func testOvernight_lateNight_isActive() {
        // 23:30 — 시작 후, 자정 전.
        let nightLate = date(2026, 4, 25, 23, 30)
        XCTAssertTrue(overnight.isCurrentlyActive(at: nightLate, calendar: cal()))
    }

    func testOvernight_earlyMorning_isActive() {
        // 04:30 — 다음 날 새벽, 종료 전.
        let earlyMorning = date(2026, 4, 26, 4, 30)
        XCTAssertTrue(overnight.isCurrentlyActive(at: earlyMorning, calendar: cal()))
    }

    func testOvernight_midDay_isInactive() {
        let noon = date(2026, 4, 25, 12, 0)
        XCTAssertFalse(overnight.isCurrentlyActive(at: noon, calendar: cal()))
    }

    // MARK: - allDay preset

    func testAllDay_disabledByDefault() {
        // allDay 는 isEnabled=false 가 기본 — 항상 inactive.
        XCTAssertFalse(Schedule.allDay.isCurrentlyActive())
    }

    func testAllDay_whenEnabled_alwaysActive() {
        var s = Schedule.allDay
        s.isEnabled = true
        // 어떤 요일/시간에도 active.
        let now = Date()
        XCTAssertTrue(s.isCurrentlyActive(at: now))
    }
}
