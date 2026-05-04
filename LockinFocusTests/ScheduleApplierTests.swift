import XCTest
import FamilyControls
import ManagedSettings
@testable import LockinFocus

/// Round 7 P0 — ScheduleApplier 의 게이팅 회귀 가드.
/// 토요일에 평일 스케줄을 저장해도 즉시 shield 가 켜지지 않는다 (R6 버그 회귀 방어).
@MainActor
final class ScheduleApplierTests: XCTestCase {

    // MARK: - Recording mocks

    final class RecordingBlockingEngine: BlockingEngine {
        var applyCount = 0
        var clearCount = 0
        var lastSelection: FamilyActivitySelection?

        func applyWhitelist(for selection: FamilyActivitySelection) {
            applyCount += 1
            lastSelection = selection
        }
        func clearShield() {
            clearCount += 1
        }
        func temporarilyAllow(token: ApplicationToken, for duration: TimeInterval) {}
    }

    final class RecordingMonitoringEngine: MonitoringEngine {
        var startCount = 0
        var stopCount = 0

        func startSchedule(_ schedule: Schedule, name: String) throws {
            startCount += 1
        }
        func stopMonitoring(name: String) {
            stopCount += 1
        }
        func startTemporaryAllow(name: String, duration: TimeInterval) throws {}
    }

    private func cal() -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = h; c.minute = min
        return cal().date(from: c)!
    }

    private var weekdayWork: Schedule {
        Schedule(
            startHour: 9, startMinute: 0,
            endHour: 17, endMinute: 0,
            weekdays: [2, 3, 4, 5, 6],   // 월~금
            isEnabled: true
        )
    }

    // MARK: - Tests

    /// **R6 버그 회귀 가드**: 토요일에 평일 스케줄 저장해도 applyWhitelist 호출되지 않음.
    func testApply_saturdayWithWeekdaySchedule_noApply_butRegisters() {
        let blocking = RecordingBlockingEngine()
        let monitoring = RecordingMonitoringEngine()
        let saturday = date(2026, 4, 25, 11, 0)   // 토요일 11:00 KST

        let action = ScheduleApplier.apply(
            schedule: weekdayWork,
            selection: FamilyActivitySelection(),
            blocking: blocking,
            monitoring: monitoring,
            manualFocusActive: false,
            now: saturday
        )

        XCTAssertEqual(action, .clearedAwaitingSchedule)
        XCTAssertEqual(blocking.applyCount, 0, "토요일엔 shield 즉시 적용 안 함")
        XCTAssertEqual(blocking.clearCount, 1, "비활성 시간대엔 shield clear")
        XCTAssertEqual(monitoring.startCount, 1, "DeviceActivity 등록은 됨")
    }

    func testApply_mondayDuringWindow_appliesShield() {
        let blocking = RecordingBlockingEngine()
        let monitoring = RecordingMonitoringEngine()
        let monMidday = date(2026, 4, 27, 11, 0)   // 월요일 11:00

        let action = ScheduleApplier.apply(
            schedule: weekdayWork,
            selection: FamilyActivitySelection(),
            blocking: blocking,
            monitoring: monitoring,
            manualFocusActive: false,
            now: monMidday
        )

        XCTAssertEqual(action, .applied)
        XCTAssertEqual(blocking.applyCount, 1, "활성 시간대엔 shield 즉시 적용")
        XCTAssertEqual(monitoring.startCount, 1)
    }

    func testApply_disabledSchedule_clearsAndStops() {
        let blocking = RecordingBlockingEngine()
        let monitoring = RecordingMonitoringEngine()
        var disabled = weekdayWork
        disabled.isEnabled = false

        let action = ScheduleApplier.apply(
            schedule: disabled,
            selection: FamilyActivitySelection(),
            blocking: blocking,
            monitoring: monitoring,
            manualFocusActive: false,
            now: Date()
        )

        XCTAssertEqual(action, .scheduleDisabledCleared)
        XCTAssertEqual(blocking.clearCount, 1)
        XCTAssertEqual(monitoring.stopCount, 1)
        XCTAssertEqual(monitoring.startCount, 0)
    }

    func testApply_manualFocusActive_doesNotClearShield() {
        let blocking = RecordingBlockingEngine()
        let monitoring = RecordingMonitoringEngine()
        let saturday = date(2026, 4, 25, 11, 0)   // 비활성 시간

        let action = ScheduleApplier.apply(
            schedule: weekdayWork,
            selection: FamilyActivitySelection(),
            blocking: blocking,
            monitoring: monitoring,
            manualFocusActive: true,    // 수동 집중 중
            now: saturday
        )

        XCTAssertEqual(action, .registeredOnly)
        XCTAssertEqual(blocking.clearCount, 0, "수동 집중 중엔 shield 유지")
        XCTAssertEqual(blocking.applyCount, 0)
        XCTAssertEqual(monitoring.startCount, 1)
    }

    func testApply_disabledSchedule_manualActive_keepsShield() {
        let blocking = RecordingBlockingEngine()
        let monitoring = RecordingMonitoringEngine()
        var disabled = weekdayWork
        disabled.isEnabled = false

        let action = ScheduleApplier.apply(
            schedule: disabled,
            selection: FamilyActivitySelection(),
            blocking: blocking,
            monitoring: monitoring,
            manualFocusActive: true,
            now: Date()
        )

        XCTAssertEqual(action, .scheduleDisabledManualKept)
        XCTAssertEqual(blocking.clearCount, 0)
        XCTAssertEqual(monitoring.stopCount, 1)
    }

    // MARK: - 자기 위반 회피 방어 (이전 스케줄 활성 중에 변경)

    /// 사용자가 평일 09–17 차단 활성 시간 (월 11시) 에 스케줄을 18–19 로 옮겨 즉시
    /// 풀려고 시도. ScheduleApplier 가 이전 활성 차단을 유지해야 함.
    func testApply_changeDuringActiveSession_keepsBlockedAndDeferred() {
        let blocking = RecordingBlockingEngine()
        let monitoring = RecordingMonitoringEngine()
        let mon11 = date(2026, 4, 27, 11, 0)
        var newSchedule = weekdayWork
        newSchedule.startHour = 18
        newSchedule.endHour = 19  // 11시는 비활성

        let action = ScheduleApplier.apply(
            schedule: newSchedule,
            selection: FamilyActivitySelection(),
            blocking: blocking,
            monitoring: monitoring,
            manualFocusActive: false,
            previousSchedule: weekdayWork,  // 이전: 09–17, 11시는 활성
            now: mon11
        )

        XCTAssertEqual(action, .deferredAwaitingScheduleEnd)
        XCTAssertEqual(blocking.applyCount, 1, "이전 활성 유지를 위해 shield 적용")
        XCTAssertEqual(blocking.clearCount, 0, "shield 해제 안 함 — 회피 방어")
        XCTAssertEqual(monitoring.startCount, 1, "새 스케줄도 OS 에 등록")
    }

    /// 같은 활성 → 활성 변경은 shield 유지하되 .applied 반환 (deferred 아님).
    func testApply_changeWithinActive_normalApply() {
        let blocking = RecordingBlockingEngine()
        let monitoring = RecordingMonitoringEngine()
        let mon11 = date(2026, 4, 27, 11, 0)
        var newSchedule = weekdayWork
        newSchedule.endHour = 18  // 11시 여전히 활성

        let action = ScheduleApplier.apply(
            schedule: newSchedule,
            selection: FamilyActivitySelection(),
            blocking: blocking,
            monitoring: monitoring,
            manualFocusActive: false,
            previousSchedule: weekdayWork,
            now: mon11
        )

        XCTAssertEqual(action, .applied)
        XCTAssertEqual(blocking.applyCount, 1)
    }

    /// 비활성 → 비활성 변경은 종전대로 .clearedAwaitingSchedule.
    func testApply_changeWhileInactive_clearsNormally() {
        let blocking = RecordingBlockingEngine()
        let monitoring = RecordingMonitoringEngine()
        let saturday = date(2026, 4, 25, 11, 0)
        var newSchedule = weekdayWork
        newSchedule.weekdays = [1]  // 일요일만

        let action = ScheduleApplier.apply(
            schedule: newSchedule,
            selection: FamilyActivitySelection(),
            blocking: blocking,
            monitoring: monitoring,
            manualFocusActive: false,
            previousSchedule: weekdayWork,  // 이전: 평일, 토요일은 비활성
            now: saturday
        )

        XCTAssertEqual(action, .clearedAwaitingSchedule)
        XCTAssertEqual(blocking.clearCount, 1)
    }

    /// 활성 차단 중 사용자가 스케줄 자체를 끔 → 끄기도 즉시 반영하지 않고 차단 유지.
    func testApply_disableDuringActiveSession_keepsBlocked() {
        let blocking = RecordingBlockingEngine()
        let monitoring = RecordingMonitoringEngine()
        let mon11 = date(2026, 4, 27, 11, 0)
        var disabled = weekdayWork
        disabled.isEnabled = false

        let action = ScheduleApplier.apply(
            schedule: disabled,
            selection: FamilyActivitySelection(),
            blocking: blocking,
            monitoring: monitoring,
            manualFocusActive: false,
            previousSchedule: weekdayWork,  // 이전: 활성
            now: mon11
        )

        XCTAssertEqual(action, .deferredAwaitingScheduleEnd)
        XCTAssertEqual(blocking.clearCount, 0, "스케줄 끔에도 차단 유지")
        XCTAssertEqual(monitoring.stopCount, 0, "OS 모니터링도 유지")
    }

    /// previousSchedule nil (온보딩 첫 호출) — 회피 검사 안 함.
    func testApply_nilPreviousSchedule_noAvoidanceCheck() {
        let blocking = RecordingBlockingEngine()
        let monitoring = RecordingMonitoringEngine()
        let saturday = date(2026, 4, 25, 11, 0)

        let action = ScheduleApplier.apply(
            schedule: weekdayWork,
            selection: FamilyActivitySelection(),
            blocking: blocking,
            monitoring: monitoring,
            manualFocusActive: false,
            previousSchedule: nil,
            now: saturday
        )

        XCTAssertEqual(action, .clearedAwaitingSchedule)
    }
}
