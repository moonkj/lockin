import XCTest
@testable import LockinFocus

/// Round 7 P0 — Face ID goal-gating 진리표 테스트.
/// `FocusEndConfirmView.allowBiometric(toggle:score:goal:)` 의 4가지 분기:
/// - 토글 OFF → 무조건 false
/// - goal 0 (목표 비활성) → false
/// - 목표 미달 (score < goal) → false
/// - 목표 달성 (score >= goal) → true (보상)
final class FaceIDGoalGatingTests: XCTestCase {

    func testAllowBiometric_toggleOff_returnsFalse() {
        XCTAssertFalse(FocusEndConfirmView.allowBiometric(toggle: false, score: 100, goal: 80))
    }

    func testAllowBiometric_goalZero_returnsFalse() {
        // 사용자가 목표를 0 으로 설정하면 (UI 에선 표시 숨김) Face ID 도 무조건 6자리.
        XCTAssertFalse(FocusEndConfirmView.allowBiometric(toggle: true, score: 100, goal: 0))
    }

    func testAllowBiometric_belowGoal_returnsFalse() {
        XCTAssertFalse(FocusEndConfirmView.allowBiometric(toggle: true, score: 79, goal: 80))
    }

    func testAllowBiometric_atGoal_returnsTrue() {
        XCTAssertTrue(FocusEndConfirmView.allowBiometric(toggle: true, score: 80, goal: 80))
    }

    func testAllowBiometric_aboveGoal_returnsTrue() {
        XCTAssertTrue(FocusEndConfirmView.allowBiometric(toggle: true, score: 95, goal: 80))
    }

    func testAllowBiometric_perfectScore_anyGoal_returnsTrue() {
        XCTAssertTrue(FocusEndConfirmView.allowBiometric(toggle: true, score: 100, goal: 60))
        XCTAssertTrue(FocusEndConfirmView.allowBiometric(toggle: true, score: 100, goal: 100))
    }

    func testAllowBiometric_zeroScore_anyGoal_returnsFalse() {
        XCTAssertFalse(FocusEndConfirmView.allowBiometric(toggle: true, score: 0, goal: 80))
        XCTAssertFalse(FocusEndConfirmView.allowBiometric(toggle: true, score: 0, goal: 1))
    }
}
