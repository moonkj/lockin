import XCTest
@testable import LockinFocus

@MainActor
final class ClockTickerTests: XCTestCase {

    // MARK: - Init

    func testInit_withInitialStrictActive_true() {
        let t = ClockTicker(initialStrictActive: true) { true }
        XCTAssertTrue(t.strictActive)
    }

    func testInit_withInitialStrictActive_false() {
        let t = ClockTicker(initialStrictActive: false) { false }
        XCTAssertFalse(t.strictActive)
    }

    func testInit_tickDefaultsToNow() {
        let before = Date()
        let t = ClockTicker(initialStrictActive: false) { false }
        let after = Date()
        XCTAssertGreaterThanOrEqual(t.tick, before.addingTimeInterval(-0.1))
        XCTAssertLessThanOrEqual(t.tick, after.addingTimeInterval(0.1))
    }

    // MARK: - start / pause / resume

    func testStart_thenPause_doesNotCrash() {
        let t = ClockTicker(initialStrictActive: false) { false }
        t.start()
        t.pause()
        // pause 후엔 timer 가 invalidate — 이후 추가 pause/resume 도 안전.
        t.pause()
    }

    func testResume_whenAlreadyRunning_isIdempotent() {
        let t = ClockTicker(initialStrictActive: false) { false }
        t.start()
        // 이미 timer 동작 중 — resume 호출은 nop.
        t.resume()
        t.pause()
    }

    func testResume_afterPause_invokesAfterTickImmediately() async throws {
        var afterTickCount = 0
        let t = ClockTicker(initialStrictActive: false) { false }
        t.afterTick = { afterTickCount += 1 }
        t.start()
        t.pause()
        afterTickCount = 0  // start/pause 동안의 콜백은 무시.
        t.resume()
        // resume 은 즉시 onTick 한 번 호출 (포그라운드 복귀 fast path).
        XCTAssertGreaterThanOrEqual(afterTickCount, 1)
        t.pause()
    }

    // MARK: - strictActive flip

    func testOnTick_strictFlipFromFalseToTrue_updatesCache() async throws {
        // provider 를 외부에서 제어 가능하게.
        var providedStrict = false
        let t = ClockTicker(initialStrictActive: false) { providedStrict }
        XCTAssertFalse(t.strictActive)
        // strict 활성 직전 → resume 호출 시 onTick 한 번 도는 게 보장됨.
        t.start()
        providedStrict = true
        t.resume()  // 이미 running 이라 nop, but 여기선 명시적으로 한 번 더 깨우기 위해 pause+resume.
        t.pause()
        t.resume()
        // resume 즉시 onTick 호출 → strictActive flip 반영.
        XCTAssertTrue(t.strictActive)
        t.pause()
    }

    func testOnTick_strictFlipFromTrueToFalse_updatesCache() async throws {
        var providedStrict = true
        let t = ClockTicker(initialStrictActive: true) { providedStrict }
        XCTAssertTrue(t.strictActive)
        t.start()
        providedStrict = false
        t.pause()
        t.resume()
        XCTAssertFalse(t.strictActive)
        t.pause()
    }

    // MARK: - afterTick callback wiring

    func testAfterTick_calledOnResume() {
        var calls = 0
        let t = ClockTicker(initialStrictActive: false) { false }
        t.afterTick = { calls += 1 }
        t.pause()  // ensure not running.
        t.resume()
        XCTAssertEqual(calls, 1)
        t.pause()
    }

    func testAfterTick_replacedHandler_isInvoked() {
        var firstCalls = 0
        var secondCalls = 0
        let t = ClockTicker(initialStrictActive: false) { false }
        t.afterTick = { firstCalls += 1 }
        t.afterTick = { secondCalls += 1 }
        t.resume()
        XCTAssertEqual(firstCalls, 0)
        XCTAssertEqual(secondCalls, 1)
        t.pause()
    }

    // MARK: - Tick publish throttle

    func testTickPublish_strictActive_publishesOnEveryOnTick() async throws {
        let t = ClockTicker(initialStrictActive: true) { true }
        let initial = t.tick
        // resume → 즉시 onTick → strict 활성이므로 tick 갱신.
        try await Task.sleep(nanoseconds: 50_000_000)  // 50ms 흐른 뒤 resume 해서 차이 나도록.
        t.resume()
        XCTAssertGreaterThan(t.tick, initial)
        t.pause()
    }

    func testTickPublish_strictInactive_throttledTo10s() async throws {
        let t = ClockTicker(initialStrictActive: false) { false }
        let initial = t.tick
        try await Task.sleep(nanoseconds: 50_000_000)
        t.resume()
        // strict 비활성: 10초 미만 경과면 tick 미갱신.
        XCTAssertEqual(t.tick, initial)
        t.pause()
    }
}
