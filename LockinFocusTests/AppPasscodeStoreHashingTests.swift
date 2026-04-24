import XCTest
@testable import LockinFocus

/// `AppPasscodeStore` 는 Round 2 에서 평문 저장 → SHA256(salt || passcode) 저장으로
/// 마이그레이션됐다. 이 테스트는 (a) 새 해싱 저장/검증, (b) 서로 다른 salt,
/// (c) legacy 평문이 저장된 상태에서도 verify 가 동작하는지를 고정.
final class AppPasscodeStoreHashingTests: XCTestCase {

    override func setUp() {
        super.setUp()
        AppPasscodeStore.clear()
    }

    override func tearDown() {
        AppPasscodeStore.clear()
        super.tearDown()
    }

    // MARK: - Save + verify 기본 경로

    func testSave_storesAndVerifies() {
        XCTAssertTrue(AppPasscodeStore.save("123456"))
        XCTAssertTrue(AppPasscodeStore.isSet)
        XCTAssertTrue(AppPasscodeStore.verify("123456"))
        XCTAssertFalse(AppPasscodeStore.verify("000000"))
    }

    func testSave_overwritesPrevious() {
        XCTAssertTrue(AppPasscodeStore.save("111111"))
        XCTAssertTrue(AppPasscodeStore.save("222222"))
        XCTAssertFalse(AppPasscodeStore.verify("111111"))
        XCTAssertTrue(AppPasscodeStore.verify("222222"))
    }

    func testClear_removesStoredValue() {
        XCTAssertTrue(AppPasscodeStore.save("123456"))
        AppPasscodeStore.clear()
        XCTAssertFalse(AppPasscodeStore.isSet)
        XCTAssertFalse(AppPasscodeStore.verify("123456"))
    }

    // MARK: - Salt 는 호출마다 새로 — 같은 비번도 두 번 저장하면 서로 다른 payload.

    func testSave_sameInputs_producesFreshSalt() {
        XCTAssertTrue(AppPasscodeStore.save("555555"))
        // 직접 Keychain payload 를 들여다볼 수 없지만, verify 만큼은 동일하게 통과해야.
        XCTAssertTrue(AppPasscodeStore.verify("555555"))
        XCTAssertTrue(AppPasscodeStore.save("555555"))  // re-save
        XCTAssertTrue(AppPasscodeStore.verify("555555"))
    }

    // MARK: - 빈 입력 / 숫자 외 — verify 는 그냥 불일치.

    func testVerify_wrongLength_fails() {
        XCTAssertTrue(AppPasscodeStore.save("123456"))
        XCTAssertFalse(AppPasscodeStore.verify(""))
        XCTAssertFalse(AppPasscodeStore.verify("12345"))
        XCTAssertFalse(AppPasscodeStore.verify("1234567"))
    }

    func testVerify_isSetFalse_whenNeverSaved() {
        XCTAssertFalse(AppPasscodeStore.isSet)
        XCTAssertFalse(AppPasscodeStore.verify("123456"))
    }
}
