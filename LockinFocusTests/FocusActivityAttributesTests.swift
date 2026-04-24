import XCTest
#if canImport(ActivityKit)
import ActivityKit
#endif
@testable import LockinFocus

/// `FocusActivityAttributes.State` 는 Codable + Hashable 계약이 있어
/// 시스템이 직렬화해 Widget 프로세스로 넘긴다. 필드/값이 바뀌면 기존 세션과
/// 호환 불가해 Live Activity 가 스테일 상태로 남거나 업데이트 실패한다 —
/// 계약 회귀 방지용 테스트.
@available(iOS 16.2, *)
final class FocusActivityAttributesTests: XCTestCase {

    // MARK: - State.isStrict

    func testIsStrict_nilEndDate_false() {
        let state = FocusActivityAttributes.State(
            startDate: Date(),
            strictEndDate: nil,
            allowedCount: 5,
            focusScore: 42
        )
        XCTAssertFalse(state.isStrict)
    }

    func testIsStrict_withEndDate_true() {
        let state = FocusActivityAttributes.State(
            startDate: Date(),
            strictEndDate: Date().addingTimeInterval(3600),
            allowedCount: 5,
            focusScore: 42
        )
        XCTAssertTrue(state.isStrict)
    }

    // MARK: - Codable roundtrip

    func testState_codable_preservesAllFields() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = Date(timeIntervalSince1970: 1_700_003_600)
        let original = FocusActivityAttributes.State(
            startDate: start,
            strictEndDate: end,
            allowedCount: 7,
            focusScore: 88
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FocusActivityAttributes.State.self, from: data)

        XCTAssertEqual(decoded.startDate, start)
        XCTAssertEqual(decoded.strictEndDate, end)
        XCTAssertEqual(decoded.allowedCount, 7)
        XCTAssertEqual(decoded.focusScore, 88)
    }

    func testState_codable_nilStrictEndDate_roundtrips() throws {
        let original = FocusActivityAttributes.State(
            startDate: Date(),
            strictEndDate: nil,
            allowedCount: 0,
            focusScore: 0
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FocusActivityAttributes.State.self, from: data)
        XCTAssertNil(decoded.strictEndDate)
        XCTAssertFalse(decoded.isStrict)
    }

    // MARK: - Hashable

    func testState_hashable_sameFieldsSameHash() {
        let now = Date()
        let a = FocusActivityAttributes.State(startDate: now, strictEndDate: nil, allowedCount: 3, focusScore: 10)
        let b = FocusActivityAttributes.State(startDate: now, strictEndDate: nil, allowedCount: 3, focusScore: 10)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func testState_hashable_differentScore_differentInstance() {
        let now = Date()
        let a = FocusActivityAttributes.State(startDate: now, strictEndDate: nil, allowedCount: 3, focusScore: 10)
        let b = FocusActivityAttributes.State(startDate: now, strictEndDate: nil, allowedCount: 3, focusScore: 20)
        XCTAssertNotEqual(a, b)
    }
}

/// FocusActivityService 는 시뮬레이터/테스트에서 실제 Activity 생성이 되지 않으므로
/// (ActivityKit 은 실기기 전용) 호출이 crash 없이 no-op 로 수렴하는지만 검증.
@available(iOS 16.2, *)
final class FocusActivityServiceTests: XCTestCase {

    func testStart_doesNotCrash_onSimulator() {
        FocusActivityService.start(
            startDate: Date(),
            strictEndDate: nil,
            allowedCount: 5,
            focusScore: 42
        )
        // 시뮬레이터에서 Activity.request 는 실패하지만 crash 없이 통과해야.
        XCTAssertTrue(true)
    }

    func testUpdate_noActiveSession_isNoOp() {
        FocusActivityService.update(strictEndDate: nil, allowedCount: 1, focusScore: 1)
        XCTAssertTrue(true)
    }

    func testEnd_noActiveSession_isNoOp() {
        FocusActivityService.end()
        XCTAssertTrue(true)
    }

    func testEndAll_doesNotCrash() {
        FocusActivityService.endAll()
        XCTAssertTrue(true)
    }

    // 빠른 연속 start() 호출이 시뮬레이터에서 Activity.request 실패로 조용히
    // no-op 되어야 하는 계약. 실기기에서는 update 경로로 바뀌어 중복 Activity 가
    // 안 뜨게 되는 고정.
    func testStart_rapidDouble_doesNotCrash() {
        FocusActivityService.start(
            startDate: Date(),
            strictEndDate: nil,
            allowedCount: 3,
            focusScore: 10
        )
        FocusActivityService.start(
            startDate: Date(),
            strictEndDate: Date().addingTimeInterval(3600),
            allowedCount: 3,
            focusScore: 20
        )
        XCTAssertTrue(true)
    }

    func testStart_thenEnd_thenStart_safe() {
        FocusActivityService.start(startDate: Date(), strictEndDate: nil, allowedCount: 1, focusScore: 1)
        FocusActivityService.end()
        FocusActivityService.start(startDate: Date(), strictEndDate: nil, allowedCount: 2, focusScore: 2)
        FocusActivityService.end()
        XCTAssertTrue(true)
    }
}
