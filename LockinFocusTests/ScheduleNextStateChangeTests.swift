import XCTest
@testable import LockinFocus

/// Schedule.nextStateChange — Dashboard "다음 스케줄" 카드 statusLine 의 입력값.
/// 활성 → 종료 시각 / 비활성 → 다음 활성 시작 / disabled → nil.
@MainActor
final class ScheduleNextStateChangeTests: XCTestCase {

    private let cal = Calendar(identifier: .gregorian)

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = h; c.minute = min
        return cal.date(from: c)!
    }

    private let weekdayWork = Schedule(
        startHour: 9, startMinute: 0,
        endHour: 17, endMinute: 0,
        weekdays: [2, 3, 4, 5, 6],
        isEnabled: true
    )

    func testNextStateChange_activeMonday11_returnsTodayEnd() {
        let now = date(2026, 4, 27, 11, 0)  // 월 11:00 = 활성
        let next = weekdayWork.nextStateChange(from: now, calendar: cal)
        XCTAssertEqual(next, date(2026, 4, 27, 17, 0), "오늘 17:00 종료")
    }

    func testNextStateChange_inactiveSaturday_returnsNextMondayStart() {
        let now = date(2026, 4, 25, 11, 0)  // 토 — 비활성
        let next = weekdayWork.nextStateChange(from: now, calendar: cal)
        XCTAssertEqual(next, date(2026, 4, 27, 9, 0), "다음 월요일 09:00 시작")
    }

    func testNextStateChange_disabled_returnsNil() {
        var s = weekdayWork
        s.isEnabled = false
        XCTAssertNil(s.nextStateChange(from: date(2026, 4, 27, 11, 0), calendar: cal))
    }

    func testNextStateChange_overnightWrap_activeAt23_returnsTomorrowEnd() {
        // 22:00 ~ 06:00 자정 wrap, 매일.
        let overnight = Schedule(
            startHour: 22, startMinute: 0,
            endHour: 6, endMinute: 0,
            weekdays: [1, 2, 3, 4, 5, 6, 7],
            isEnabled: true
        )
        let now = date(2026, 4, 27, 23, 0)  // 시작 후
        let next = overnight.nextStateChange(from: now, calendar: cal)
        XCTAssertEqual(next, date(2026, 4, 28, 6, 0), "내일 06:00 종료")
    }

    func testNextStateChange_overnightWrap_activeAt03_returnsTodayEnd() {
        let overnight = Schedule(
            startHour: 22, startMinute: 0,
            endHour: 6, endMinute: 0,
            weekdays: [1, 2, 3, 4, 5, 6, 7],
            isEnabled: true
        )
        let now = date(2026, 4, 28, 3, 0)  // 시작은 어제 22시 — 오늘 06시 종료.
        let next = overnight.nextStateChange(from: now, calendar: cal)
        XCTAssertEqual(next, date(2026, 4, 28, 6, 0))
    }

    func testNextStateChange_inactiveSundayNight_returnsMondayMorning() {
        // 일요일 21:00 — 다음 활성은 월요일 09:00.
        let now = date(2026, 4, 26, 21, 0)
        let next = weekdayWork.nextStateChange(from: now, calendar: cal)
        XCTAssertEqual(next, date(2026, 4, 27, 9, 0))
    }
}
