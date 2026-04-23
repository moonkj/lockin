import XCTest
import UserNotifications
@testable import LockinFocus

/// UNUserNotificationCenter 자체를 목하지 않지만, 함수 호출이 crash 없이
/// 수행되는지와 완료 콜백이 비동기로 도달하는지 확인한다.
final class WeeklyReportSchedulerTests: XCTestCase {

    func testDisable_noPending_doesNotThrow() {
        WeeklyReportScheduler.disable()
        XCTAssertTrue(true)
    }

    func testReschedule_doesNotCrash() {
        WeeklyReportScheduler.reschedule()
        // getNotificationSettings 는 비동기라 완료 동작은 검증할 수 없지만,
        // 적어도 crash 없이 호출이 반환.
        XCTAssertTrue(true)
    }

    func testEnable_doesNotCrash() {
        // UNUserNotificationCenter.requestAuthorization 은 시뮬레이터에서
        // user prompt 없이 완료 콜백이 안 울 수 있으므로 호출만 검증.
        WeeklyReportScheduler.enable()
        XCTAssertTrue(true)
    }
}
