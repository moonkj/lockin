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
        XCTAssertNoThrow(try view.inspect().find(text: L("닉네임 만들기")))
    }

    func testNicknameSetupView_hasCancelButton() throws {
        let deps = AppDependencies.preview()
        let view = NicknameSetupView { _ in }.environmentObject(deps)
        XCTAssertNoThrow(try view.inspect().find(button: L("취소")))
    }

    // MARK: - AppPasscodeSetupView

    func testAppPasscodeSetupView_firstStep_showsHeadline() throws {
        let view = AppPasscodeSetupView { _ in }
        XCTAssertNoThrow(try view.inspect().find(text: L("앱 비밀번호 설정")))
    }

    func testAppPasscodeSetupView_hasCancelButton() throws {
        let view = AppPasscodeSetupView { _ in }
        XCTAssertNoThrow(try view.inspect().find(button: L("취소")))
    }

    // MARK: - AppPasscodeEntryView

    func testAppPasscodeEntryView_rendersHeader() throws {
        let view = AppPasscodeEntryView(onSuccess: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("앱 비밀번호 입력")))
    }

    // MARK: - StrictDurationPickerView

    func testStrictDurationPickerView_rendersPresets() throws {
        let presets: [(label: String, seconds: TimeInterval)] = [
            ("30분", 1800),
            ("1시간", 3600),
            ("2시간", 7200)
        ]
        let view = StrictDurationPickerView(presets: presets, onStart: { _ in })
        XCTAssertNoThrow(try view.inspect().find(text: L("얼마나 집중할까요?")))
        XCTAssertNoThrow(try view.inspect().find(text: L("30분")))
        XCTAssertNoThrow(try view.inspect().find(text: L("1시간")))
        XCTAssertNoThrow(try view.inspect().find(text: L("2시간")))
    }

    func testStrictDurationPickerView_hasStartButton() throws {
        let view = StrictDurationPickerView(presets: [("30분", 1800)], onStart: { _ in })
        XCTAssertNoThrow(try view.inspect().find(button: L("시작하기")))
    }

    // MARK: - QuoteDetailSheet

    func testQuoteDetailSheet_renders() throws {
        let view = QuoteDetailSheet()
        XCTAssertNoThrow(try view.inspect().find(text: "\u{201C}"))
    }

    func testQuoteDetailSheet_hasShareLinkLabel() throws {
        let view = QuoteDetailSheet()
        XCTAssertNoThrow(try view.inspect().find(text: L("공유하기")))
    }

    // MARK: - FocusEndConfirmView

    func testFocusEndConfirmView_firstOrdinal_showsSentenceHint() throws {
        let view = FocusEndConfirmView(ordinal: 1, onConfirm: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("정말 종료할까요?")))
    }

    func testFocusEndConfirmView_secondOrdinal_showsBreathMessage() throws {
        let view = FocusEndConfirmView(ordinal: 2, onConfirm: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("잠시 숨을 고르면서 한 번 더 생각해봐요.")))
    }

    func testFocusEndConfirmView_hasContinueFocusButton() throws {
        let view = FocusEndConfirmView(ordinal: 2, onConfirm: {})
        XCTAssertNoThrow(try view.inspect().find(button: L("계속 집중하기")))
    }

    func testFocusEndConfirmView_firstOrdinal_hasFirstDayHint() throws {
        let view = FocusEndConfirmView(ordinal: 1, onConfirm: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("오늘 첫 해제예요. 잠시 숨을 고르고 다음 단계로 넘어가요.")))
    }

    func testFocusEndConfirmView_thirdOrdinal_usesBreathMessage() throws {
        let view = FocusEndConfirmView(ordinal: 3, onConfirm: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("잠시 숨을 고르면서 한 번 더 생각해봐요.")))
    }

    // MARK: - FocusEndConfirmView — sentence step (injected)

    func testFocusEndConfirmView_sentenceStep_showsTargetSentenceHint() throws {
        let view = FocusEndConfirmView(
            ordinal: 1,
            initialStep: .sentence,
            onConfirm: {}
        )
        XCTAssertNoThrow(try view.inspect().find(text: L("이 문장을 그대로 써주세요")))
    }

    func testFocusEndConfirmView_sentenceStep_showsExampleQuote() throws {
        let view = FocusEndConfirmView(
            ordinal: 1,
            initialStep: .sentence,
            onConfirm: {}
        )
        XCTAssertNoThrow(try view.inspect().find(text: L("\"나는 지금 꼭 집중을 풀어야 한다\"")))
    }

    func testFocusEndConfirmView_sentenceStep_wrongTyped_showsError() throws {
        let view = FocusEndConfirmView(
            ordinal: 1,
            initialStep: .sentence,
            initialTyped: "틀린 문장",
            onConfirm: {}
        )
        XCTAssertNoThrow(try view.inspect().find(text: L("문장이 달라요. 예시대로 정확히 써야 해요.")))
    }

    func testFocusEndConfirmView_sentenceStep_hasContinueAndNextButtons() throws {
        let view = FocusEndConfirmView(
            ordinal: 1,
            initialStep: .sentence,
            onConfirm: {}
        )
        XCTAssertNoThrow(try view.inspect().find(button: L("계속 집중하기")))
    }

    // MARK: - FocusEndConfirmView — passcode step (injected)

    func testFocusEndConfirmView_passcodeStep_showsPasscodeHeadline() throws {
        let view = FocusEndConfirmView(
            ordinal: 1,
            initialStep: .passcode,
            onConfirm: {}
        )
        XCTAssertNoThrow(try view.inspect().find(text: L("앱 비밀번호 입력")))
    }
}
