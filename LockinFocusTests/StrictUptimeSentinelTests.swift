import XCTest
@testable import LockinFocus

/// Round 3 Security #12 — 엄격 모드 uptime sentinel.
/// wallclock + uptime 둘 다 duration 에 도달해야 해제되는지 고정.
final class StrictUptimeSentinelTests: XCTestCase {

    private func makeStore() -> InMemoryPersistenceStore {
        let s = InMemoryPersistenceStore()
        s.strictModeStartAt = nil
        s.strictModeEndAt = nil
        s.strictModeStartUptime = nil
        s.strictModeDurationSeconds = nil
        return s
    }

    func testActive_onlyWallclockExpired_butUptimeNot_staysActive() {
        let s = makeStore()
        let now = Date()
        let uptimeNow = ProcessInfo.processInfo.systemUptime
        // duration: 1시간, wallclock 은 이미 지나간 것처럼 보이지만 uptime 은 10초 전에 시작.
        s.strictModeStartAt = now.addingTimeInterval(-10)       // 10초 전에 시작했다고 기록.
        s.strictModeEndAt = now.addingTimeInterval(-5)          // wallclock 은 5초 전에 만료.
        s.strictModeStartUptime = uptimeNow - 10                // 실제 uptime 은 10초만 지남.
        s.strictModeDurationSeconds = 3600                      // duration 1시간.
        // wallclock 은 만료됐지만 uptime 이 duration 미달 → active 유지.
        XCTAssertTrue(s.isStrictModeActive, "wallclock 조작 의심 — uptime 이 duration 미달이면 active")
    }

    func testActive_bothExpired_deactivates() {
        let s = makeStore()
        let now = Date()
        let uptimeNow = ProcessInfo.processInfo.systemUptime
        s.strictModeStartAt = now.addingTimeInterval(-3700)
        s.strictModeEndAt = now.addingTimeInterval(-100)
        s.strictModeStartUptime = uptimeNow - 3700
        s.strictModeDurationSeconds = 3600
        XCTAssertFalse(s.isStrictModeActive, "wallclock + uptime 둘 다 지나면 해제")
    }

    func testActive_rebootScenario_trustsWallclockOnly() {
        let s = makeStore()
        let now = Date()
        // 재부팅 시나리오: startUptime 이 uptimeNow 보다 크게 보임 (기기가 리셋되어 uptime 0 부근).
        // 이 경우는 보수적으로 wallclock 만 신뢰.
        s.strictModeStartAt = now.addingTimeInterval(-3700)
        s.strictModeEndAt = now.addingTimeInterval(-100)
        s.strictModeStartUptime = ProcessInfo.processInfo.systemUptime + 100_000  // 말이 안 되는 값 = 재부팅 의심
        s.strictModeDurationSeconds = 3600
        XCTAssertFalse(s.isStrictModeActive, "재부팅 감지 시 wallclock 신뢰 → 만료")
    }

    func testRemaining_returnsLargerOfWallOrUptime() {
        let s = makeStore()
        let now = Date()
        let uptimeNow = ProcessInfo.processInfo.systemUptime
        s.strictModeStartAt = now.addingTimeInterval(-10)
        s.strictModeEndAt = now.addingTimeInterval(-5)   // wallclock 잔여: 0
        s.strictModeStartUptime = uptimeNow - 10         // uptime 잔여: duration - 10
        s.strictModeDurationSeconds = 3600
        // uptime 기준 잔여가 더 크므로 그 값 반환.
        XCTAssertGreaterThan(s.strictModeRemainingSeconds, 3000)
    }

    func testInactive_whenEndAtNil() {
        let s = makeStore()
        XCTAssertFalse(s.isStrictModeActive)
        XCTAssertEqual(s.strictModeRemainingSeconds, 0)
    }
}
