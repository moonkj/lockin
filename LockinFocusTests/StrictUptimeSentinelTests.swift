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

    // MARK: - Round 7: onTick 가 sentinel 우회하지 않는지 (CRITICAL 회귀 가드)

    /// 시계 +미래 조작 후 ticker 가 keys 를 정리해버리면 strict 영구 해제 — Debugger Round 2 발견.
    /// 수정: AppDependencies.onTick 이 isStrictModeActive 를 신뢰. 이 테스트는 protocol 계약을
    /// 다시 확인 (uptime 미달이면 wallclock 만료여도 active 유지) + AppDependencies 수정 후 ticker
    /// 가 keys 를 안 정리하는 동작은 시간 기반이라 단위 테스트 어려움. 대신 protocol-level 가드.
    func testWallclockManipulation_uptimeStillValid_keysNotEligibleForCleanup() {
        let s = makeStore()
        let now = Date()
        let uptimeNow = ProcessInfo.processInfo.systemUptime
        // 1h strict 시작 30분 경과 시점에 사용자가 시계 +2h 조작.
        s.strictModeStartAt = now.addingTimeInterval(-7200)   // 시계상 2h 전 시작 (조작됨)
        s.strictModeEndAt = now.addingTimeInterval(-3600)     // 시계상 1h 전 종료 (조작됨)
        s.strictModeStartUptime = uptimeNow - 1800            // 실제 uptime 30분
        s.strictModeDurationSeconds = 3600                    // duration 1시간
        // wallclock 은 만료지만 uptime 미달 → sentinel 이 active 유지.
        XCTAssertTrue(
            s.isStrictModeActive,
            "wallclock 조작 후에도 uptime 이 duration 미달이면 strict 활성 — onTick 도 cleanup 진입 안 함"
        )
    }
}
