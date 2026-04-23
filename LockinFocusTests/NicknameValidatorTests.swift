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

    func testValidate_zeroWidthChars_stripped() {
        // U+200B (ZWSP) between chars — should strip and treat as "시발".
        XCTAssertEqual(
            NicknameValidator.validate("시\u{200B}발"),
            .failure(.containsBannedWord)
        )
    }

    func testValidate_bidiMarkers_stripped() {
        // LRE/RLE/PDF bidi 마커가 삽입돼도 banned word 매칭되어야.
        XCTAssertEqual(
            NicknameValidator.validate("시\u{202A}발"),
            .failure(.containsBannedWord)
        )
        XCTAssertEqual(
            NicknameValidator.validate("시\u{202C}\u{202D}발"),
            .failure(.containsBannedWord)
        )
    }

    func testValidate_tooLong_byByteCount() {
        // 20자지만 UTF-8 60바이트 초과하는 이모지 플래그 — 길이 통과해도 바이트 체크에서 거부.
        let tenFlags = String(repeating: "🇰🇷", count: 10)
        XCTAssertEqual(NicknameValidator.validate(tenFlags), .failure(.tooLong))
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
