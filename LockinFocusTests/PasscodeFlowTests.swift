import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

@MainActor
final class PasscodeFlowTests: XCTestCase {

    override func setUp() {
        super.setUp()
        AppPasscodeStore.clear()
    }

    override func tearDown() {
        AppPasscodeStore.clear()
        super.tearDown()
    }

    // MARK: - AppPasscodeSetupView

    func testAppPasscodeSetupView_firstStep_headlineAndPrompt() throws {
        let view = AppPasscodeSetupView { _ in }
        XCTAssertNoThrow(try view.inspect().find(text: "앱 비밀번호 설정"))
        XCTAssertNoThrow(try view.inspect().find(
            text: "엄격 모드를 해제할 때 쓸 6자리 숫자 비번을 정해주세요. iPhone 잠금 암호와는 별개예요."
        ))
    }

    func testAppPasscodeSetupView_cancelTriggersCallback() throws {
        var saved: Bool?
        let view = AppPasscodeSetupView { s in saved = s }
        try view.inspect().find(button: "취소").tap()
        XCTAssertEqual(saved, false, "취소는 onDone(false) 를 호출해야")
    }

    func testAppPasscodeSetupView_confirmStep_showsSecondHeadline() throws {
        let view = AppPasscodeSetupView(
            onDone: { _ in },
            initialStep: .confirm,
            initialFirst: "123456"
        )
        XCTAssertNoThrow(try view.inspect().find(text: "비밀번호 다시 입력"))
        XCTAssertNoThrow(try view.inspect().find(text: "확인을 위해 한 번 더 입력해주세요."))
    }

    func testAppPasscodeSetupView_withErrorMessage_showsErrorText() throws {
        let view = AppPasscodeSetupView(
            onDone: { _ in },
            initialStep: .first,
            initialErrorMessage: "비밀번호가 달라요. 처음부터 다시 입력해주세요."
        )
        XCTAssertNoThrow(try view.inspect().find(text: "비밀번호가 달라요. 처음부터 다시 입력해주세요."))
    }

    // MARK: - AppPasscodeEntryView

    func testAppPasscodeEntryView_noStoredPasscode_showsPrompt() throws {
        let view = AppPasscodeEntryView(onSuccess: {})
        XCTAssertNoThrow(try view.inspect().find(text: "앱 비밀번호 입력"))
        XCTAssertNoThrow(try view.inspect().find(text: "설정한 6자리 비번을 입력하세요."))
    }

    func testAppPasscodeEntryView_hasCancelButton() throws {
        let view = AppPasscodeEntryView(onSuccess: {})
        XCTAssertNoThrow(try view.inspect().find(button: "취소"))
    }

    func testAppPasscodeEntryView_withError_showsErrorText() throws {
        let view = AppPasscodeEntryView(
            onSuccess: {},
            initialError: "비밀번호가 달라요. 다시 입력해주세요."
        )
        XCTAssertNoThrow(try view.inspect().find(text: "비밀번호가 달라요. 다시 입력해주세요."))
    }

    // MARK: - PasscodeStepView (onboarding)

    func testPasscodeStepView_rendersFirstHeadline() throws {
        let view = PasscodeStepView(onNext: {})
        XCTAssertNoThrow(try view.inspect().find(text: "앱 비밀번호를 정해주세요"))
        XCTAssertNoThrow(try view.inspect().find(text: "하루 첫 집중 해제 때 확인용으로 써요. iPhone 잠금 암호와는 별개예요."))
    }

    func testPasscodeStepView_skipTriggersOnNext() throws {
        var advanced = false
        let view = PasscodeStepView(onNext: { advanced = true })
        try view.inspect().find(button: "건너뛰기").tap()
        XCTAssertTrue(advanced)
    }
}
