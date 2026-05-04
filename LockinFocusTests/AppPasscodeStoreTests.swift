import XCTest
@testable import LockinFocus

/// AppPasscodeStore — Keychain 기반. 테스트 시작 시 clear 로 격리.
final class AppPasscodeStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        AppPasscodeStore.clear()
        clearLockoutState()
    }

    override func tearDown() {
        AppPasscodeStore.clear()
        clearLockoutState()
        super.tearDown()
    }

    /// 테스트 격리 — App Group UserDefaults 의 lockout 카운터/만료 비움.
    private func clearLockoutState() {
        let d = UserDefaults(suiteName: "group.com.moonkj.LockinFocus")
        d?.removeObject(forKey: "appPasscodeFailureCount")
        d?.removeObject(forKey: "appPasscodeLockoutUntil")
    }

    func testIsSet_false_whenEmpty() {
        XCTAssertFalse(AppPasscodeStore.isSet)
    }

    func testSave_thenIsSet_true() {
        XCTAssertTrue(AppPasscodeStore.save("123456"))
        XCTAssertTrue(AppPasscodeStore.isSet)
    }

    func testVerify_correctPasscode_true() {
        _ = AppPasscodeStore.save("654321")
        XCTAssertTrue(AppPasscodeStore.verify("654321"))
    }

    func testVerify_wrongPasscode_false() {
        _ = AppPasscodeStore.save("654321")
        XCTAssertFalse(AppPasscodeStore.verify("111111"))
    }

    func testClear_removesExistingPasscode() {
        _ = AppPasscodeStore.save("abcdef")
        AppPasscodeStore.clear()
        XCTAssertFalse(AppPasscodeStore.isSet)
        XCTAssertFalse(AppPasscodeStore.verify("abcdef"))
    }

    func testSave_overwritesExisting() {
        _ = AppPasscodeStore.save("111111")
        _ = AppPasscodeStore.save("222222")
        XCTAssertFalse(AppPasscodeStore.verify("111111"))
        XCTAssertTrue(AppPasscodeStore.verify("222222"))
    }

    // MARK: - Brute-force lockout

    func testLockout_triggersAfterMaxFailures() {
        _ = AppPasscodeStore.save("123456")
        XCTAssertFalse(AppPasscodeStore.isLockedOut())
        // 4회 실패 — 아직 lockout 아님.
        for _ in 0..<4 {
            _ = AppPasscodeStore.verify("000000")
        }
        XCTAssertFalse(AppPasscodeStore.isLockedOut(), "4회 실패까지는 lockout 아님")
        // 5회째 실패 — lockout 진입.
        _ = AppPasscodeStore.verify("000000")
        XCTAssertTrue(AppPasscodeStore.isLockedOut())
    }

    func testLockout_blocksEvenCorrectPasscode() {
        _ = AppPasscodeStore.save("123456")
        for _ in 0..<5 {
            _ = AppPasscodeStore.verify("000000")
        }
        XCTAssertTrue(AppPasscodeStore.isLockedOut())
        // lockout 중에는 정답이어도 false.
        XCTAssertFalse(AppPasscodeStore.verify("123456"))
    }

    func testLockout_resetsOnSuccessBeforeMax() {
        _ = AppPasscodeStore.save("123456")
        // 4회 실패 후 1회 성공 — 카운터 reset.
        for _ in 0..<4 {
            _ = AppPasscodeStore.verify("000000")
        }
        XCTAssertTrue(AppPasscodeStore.verify("123456"))
        // 다시 4회 실패해도 lockout 안 됨 (카운터 0 부터).
        for _ in 0..<4 {
            _ = AppPasscodeStore.verify("000000")
        }
        XCTAssertFalse(AppPasscodeStore.isLockedOut())
    }

    func testLockout_remainingSeconds_positive() {
        _ = AppPasscodeStore.save("123456")
        for _ in 0..<5 {
            _ = AppPasscodeStore.verify("000000")
        }
        let remaining = AppPasscodeStore.lockoutRemainingSeconds()
        XCTAssertGreaterThan(remaining, 4 * 60, "lockout 5분 초과")
        XCTAssertLessThanOrEqual(remaining, 5 * 60)
    }
}
