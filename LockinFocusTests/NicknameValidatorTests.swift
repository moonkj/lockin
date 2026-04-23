import XCTest
@testable import LockinFocus

final class NicknameValidatorTests: XCTestCase {

    func testValidate_acceptsNormalName() {
        let result = NicknameValidator.validate("집중러")
        guard case .success(let name) = result else {
            return XCTFail("정상 닉네임이 success 로 떨어져야 한다")
        }
        XCTAssertEqual(name, "집중러")
    }

    func testValidate_trimsWhitespace() {
        let result = NicknameValidator.validate("   집중러   ")
        guard case .success(let name) = result else { return XCTFail() }
        XCTAssertEqual(name, "집중러")
    }

    func testValidate_tooShort_lengthOne() {
        XCTAssertEqual(NicknameValidator.validate("가"), .failure(.tooShort))
    }

    func testValidate_tooShort_empty() {
        XCTAssertEqual(NicknameValidator.validate(""), .failure(.tooShort))
    }

    func testValidate_tooShort_whitespaceOnly() {
        XCTAssertEqual(NicknameValidator.validate("     "), .failure(.tooShort))
    }

    func testValidate_minLength_twoChars_accepted() {
        XCTAssertEqual(
            NicknameValidator.validate("가나"),
            .success("가나")
        )
    }

    func testValidate_maxLength_twentyChars_accepted() {
        let twenty = String(repeating: "가", count: 20)
        XCTAssertEqual(NicknameValidator.validate(twenty), .success(twenty))
    }

    func testValidate_tooLong_twentyOneChars() {
        let tooLong = String(repeating: "가", count: 21)
        XCTAssertEqual(NicknameValidator.validate(tooLong), .failure(.tooLong))
    }

    func testValidate_bannedWord_korean() {
        XCTAssertEqual(
            NicknameValidator.validate("시발러너"),
            .failure(.containsBannedWord)
        )
    }

    func testValidate_bannedWord_english_caseInsensitive() {
        XCTAssertEqual(
            NicknameValidator.validate("FuckThat"),
            .failure(.containsBannedWord)
        )
    }

    func testValidate_bannedWord_withSpaces_stillCaught() {
        XCTAssertEqual(
            NicknameValidator.validate("시 발"),
            .failure(.containsBannedWord)
        )
    }

    func testValidate_bannedWord_sexual() {
        XCTAssertEqual(
            NicknameValidator.validate("sex"),
            .failure(.containsBannedWord)
        )
    }

    func testValidate_cleanEnglishName_accepted() {
        XCTAssertEqual(
            NicknameValidator.validate("FocusHero"),
            .success("FocusHero")
        )
    }

    func testValidationError_localizedDescriptions() {
        XCTAssertNotNil(NicknameValidator.ValidationError.tooShort.errorDescription)
        XCTAssertNotNil(NicknameValidator.ValidationError.tooLong.errorDescription)
        XCTAssertNotNil(NicknameValidator.ValidationError.containsBannedWord.errorDescription)
    }
}

extension NicknameValidator.ValidationError: Equatable {
    public static func == (
        lhs: NicknameValidator.ValidationError,
        rhs: NicknameValidator.ValidationError
    ) -> Bool {
        switch (lhs, rhs) {
        case (.tooShort, .tooShort),
             (.tooLong, .tooLong),
             (.containsBannedWord, .containsBannedWord):
            return true
        default:
            return false
        }
    }
}
