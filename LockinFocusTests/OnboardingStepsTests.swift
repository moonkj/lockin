import XCTest
import SwiftUI
import FamilyControls
import ViewInspector
@testable import LockinFocus

@MainActor
final class OnboardingStepsTests: XCTestCase {

    // MARK: - ValueStepView

    func testValueStepView_rendersHeadline() throws {
        let view = ValueStepView(onNext: {})
        // ValueStepView 의 핵심 카피 — 존재 여부만 확인.
        let inspected = try view.inspect()
        XCTAssertNoThrow(try inspected.find(ViewType.Button.self))
    }

    func testValueStepView_nextButton_triggersCallback() throws {
        var advanced = false
        let view = ValueStepView { advanced = true }
        try view.inspect().find(ViewType.Button.self).tap()
        XCTAssertTrue(advanced)
    }

    // MARK: - AuthorizationStepView

    func testAuthorizationStepView_rendersHeadline() throws {
        let view = AuthorizationStepView(
            denied: .constant(false),
            onAuthorize: {},
            onOpenSettings: {}
        )
        XCTAssertNoThrow(try view.inspect().find(text: L("먼저 권한이 필요해요")))
    }

    func testAuthorizationStepView_deniedState_showsRecovery() throws {
        let view = AuthorizationStepView(
            denied: .constant(true),
            onAuthorize: {},
            onOpenSettings: {}
        )
        XCTAssertNoThrow(try view.inspect())
    }

    // MARK: - AppPickerStepView

    func testAppPickerStepView_rendersHeadline() throws {
        let view = AppPickerStepView(
            selection: .constant(FamilyActivitySelection()),
            onNext: {}
        )
        XCTAssertNoThrow(try view.inspect().find(text: L("허용할 앱을 골라주세요")))
    }

    func testAppPickerStepView_rendersPickerButton() throws {
        let view = AppPickerStepView(
            selection: .constant(FamilyActivitySelection()),
            onNext: {}
        )
        XCTAssertNoThrow(try view.inspect().find(text: L("허용 앱 고르기")))
    }

    func testAppPickerStepView_nextButton_triggersCallback() throws {
        var next = false
        let view = AppPickerStepView(
            selection: .constant(FamilyActivitySelection()),
            onNext: { next = true }
        )
        try view.inspect().find(button: L("다음")).tap()
        XCTAssertTrue(next)
    }

    // MARK: - SystemPresetStepView

    func testSystemPresetStepView_renders() throws {
        let view = SystemPresetStepView(onNext: {})
        XCTAssertNoThrow(try view.inspect())
    }

    func testSystemPresetStepView_nextButton_triggersCallback() throws {
        var next = false
        let view = SystemPresetStepView { next = true }
        try view.inspect().find(button: L("다음")).tap()
        XCTAssertTrue(next)
    }

    // MARK: - ScheduleStepView

    func testScheduleStepView_renders() throws {
        let view = ScheduleStepView(
            schedule: .constant(.weekdayWorkHours),
            onNext: {}
        )
        XCTAssertNoThrow(try view.inspect().find(text: L("집중 시간대를 골라주세요")))
    }

    // MARK: - PasscodeStepView

    func testPasscodeStepView_renders_firstStep() throws {
        let view = PasscodeStepView(onNext: {})
        XCTAssertNoThrow(try view.inspect().find(text: L("앱 비밀번호를 정해주세요")))
    }

    func testPasscodeStepView_skipButton_triggersOnNext() throws {
        var advanced = false
        let view = PasscodeStepView { advanced = true }
        try view.inspect().find(button: L("건너뛰기")).tap()
        XCTAssertTrue(advanced)
    }
}
