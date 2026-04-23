import XCTest
@testable import LockinFocus

/// `Schedule` 모델의 기본 불변성, 프리셋 상수, Codable 안정성 회귀 방지.
final class ScheduleTests: XCTestCase {

    // 평일(월~금) 프리셋의 weekdays 가 Calendar 규약(1=Sun...7=Sat)에 맞게 정의되어 있는지.
    func testWeekdayWorkHours_hasCorrectWeekdays() {
        let schedule = Schedule.weekdayWorkHours
        XCTAssertEqual(schedule.weekdays, [2, 3, 4, 5, 6])
        XCTAssertEqual(schedule.startHour, 9)
        XCTAssertEqual(schedule.startMinute, 0)
        XCTAssertEqual(schedule.endHour, 17)
        XCTAssertEqual(schedule.endMinute, 0)
        XCTAssertTrue(schedule.isEnabled)
    }

    // Codable round-trip: 기본 프리셋을 JSON 직렬화 후 디코딩해도 값이 동일해야 한다.
    // UserDefaultsPersistenceStore.schedule 이 이 경로를 그대로 사용하므로 회귀 방지 핵심.
    func testSchedule_codableRoundTrip() throws {
        let original = Schedule.weekdayWorkHours
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Schedule.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    // startComponents / endComponents 가 hour/minute 을 정확히 반영하는지.
    func testStartComponents_returnsCorrectHourMinute() {
        let schedule = Schedule(
            startHour: 13,
            startMinute: 30,
            endHour: 18,
            endMinute: 45,
            weekdays: [2],
            isEnabled: true
        )
        XCTAssertEqual(schedule.startComponents.hour, 13)
        XCTAssertEqual(schedule.startComponents.minute, 30)
        XCTAssertEqual(schedule.endComponents.hour, 18)
        XCTAssertEqual(schedule.endComponents.minute, 45)
    }

    // `.allDay` 프리셋 기본값 확인.
    func testAllDay_hasAllWeekdaysAndDisabled() {
        let s = Schedule.allDay
        XCTAssertEqual(s.weekdays, [1, 2, 3, 4, 5, 6, 7])
        XCTAssertFalse(s.isEnabled)
    }
}
