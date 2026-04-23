import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

@MainActor
final class SheetViewsTests: XCTestCase {

    // MARK: - NicknameSetupView

    func testNicknameSetupView_rendersHeader() throws {
        let deps = AppDependencies.preview()
        let view = NicknameSetupView { _ in }.environmentObject(deps)
        XCTAssertNoThrow(try view.inspect().find(text: "닉네임 만들기"))
    }

    func testNicknameSetupView_hasCancelButton() throws {
        let deps = AppDependencies.preview()
        let view = NicknameSetupView { _ in }.environmentObject(deps)
        XCTAssertNoThrow(try view.inspect().find(button: "취소"))
    }

    // MARK: - AppPasscodeSetupView

    func testAppPasscodeSetupView_firstStep_showsHeadline() throws {
        let view = AppPasscodeSetupView { _ in }
        XCTAssertNoThrow(try view.inspect().find(text: "앱 비밀번호 설정"))
    }

    func testAppPasscodeSetupView_hasCancelButton() throws {
        let view = AppPasscodeSetupView { _ in }
        XCTAssertNoThrow(try view.inspect().find(button: "취소"))
    }

    // MARK: - AppPasscodeEntryView

    func testAppPasscodeEntryView_rendersHeader() throws {
        let view = AppPasscodeEntryView(onSuccess: {})
        XCTAssertNoThrow(try view.inspect().find(text: "앱 비밀번호 입력"))
    }

    // MARK: - StrictDurationPickerView

    func testStrictDurationPickerView_rendersPresets() throws {
        let presets: [(label: String, seconds: TimeInterval)] = [
            ("30분", 1800),
            ("1시간", 3600),
            ("2시간", 7200)
        ]
        let view = StrictDurationPickerView(presets: presets, onStart: { _ in })
        XCTAssertNoThrow(try view.inspect().find(text: "얼마나 집중할까요?"))
        XCTAssertNoThrow(try view.inspect().find(text: "30분"))
        XCTAssertNoThrow(try view.inspect().find(text: "1시간"))
        XCTAssertNoThrow(try view.inspect().find(text: "2시간"))
    }

    func testStrictDurationPickerView_hasStartButton() throws {
        let view = StrictDurationPickerView(presets: [("30분", 1800)], onStart: { _ in })
        XCTAssertNoThrow(try view.inspect().find(button: "시작하기"))
    }

    // MARK: - QuoteDetailSheet

    func testQuoteDetailSheet_renders() throws {
        let view = QuoteDetailSheet()
        XCTAssertNoThrow(try view.inspect().find(text: "\u{201C}"))
    }

    func testQuoteDetailSheet_hasShareLinkLabel() throws {
        let view = QuoteDetailSheet()
        XCTAssertNoThrow(try view.inspect().find(text: "공유하기"))
    }

    // MARK: - FocusEndConfirmView

    func testFocusEndConfirmView_firstOrdinal_showsSentenceHint() throws {
        let view = FocusEndConfirmView(ordinal: 1, onConfirm: {})
        XCTAssertNoThrow(try view.inspect().find(text: "정말 종료할까요?"))
    }

    func testFocusEndConfirmView_secondOrdinal_showsBreathMessage() throws {
        let view = FocusEndConfirmView(ordinal: 2, onConfirm: {})
        XCTAssertNoThrow(try view.inspect().find(text: "잠시 숨을 고르면서 한 번 더 생각해봐요."))
    }

    func testFocusEndConfirmView_hasContinueFocusButton() throws {
        let view = FocusEndConfirmView(ordinal: 2, onConfirm: {})
        XCTAssertNoThrow(try view.inspect().find(button: "계속 집중하기"))
    }

    func testFocusEndConfirmView_firstOrdinal_hasFirstDayHint() throws {
        let view = FocusEndConfirmView(ordinal: 1, onConfirm: {})
        XCTAssertNoThrow(try view.inspect().find(text: "오늘 첫 해제예요. 잠시 숨을 고르고 다음 단계로 넘어가요."))
    }

    func testFocusEndConfirmView_thirdOrdinal_usesBreathMessage() throws {
        let view = FocusEndConfirmView(ordinal: 3, onConfirm: {})
        XCTAssertNoThrow(try view.inspect().find(text: "잠시 숨을 고르면서 한 번 더 생각해봐요."))
    }
}
