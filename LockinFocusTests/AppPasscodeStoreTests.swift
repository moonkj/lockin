import XCTest
@testable import LockinFocus

/// AppPasscodeStore — Keychain 기반. 테스트 시작 시 clear 로 격리.
final class AppPasscodeStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        AppPasscodeStore.clear()
    }

    override func tearDown() {
        AppPasscodeStore.clear()
        super.tearDown()
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
}
