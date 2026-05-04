import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

@MainActor
final class OnboardingContainerViewTests: XCTestCase {

    private func makeDeps() -> AppDependencies {
        let d = AppDependencies.preview()
        d.persistence.hasCompletedOnboarding = false
        return d
    }

    func testContainer_step0_rendersValueStep() throws {
        let view = OnboardingContainerView(initialStep: 0)
            .environmentObject(makeDeps())
        XCTAssertNoThrow(try view.inspect().find(ViewType.Button.self))
        // 뒤로 버튼은 step 0 에선 숨김.
        XCTAssertThrowsError(try view.inspect().find(text: L("뒤로")))
    }

    func testContainer_step1_rendersAuthorizationStep() throws {
        try XCTSkipIfViewInspectorBlocked()
        let view = OnboardingContainerView(initialStep: 1)
            .environmentObject(makeDeps())
        XCTAssertNoThrow(try view.inspect().find(text: L("먼저 권한이 필요해요")))
        XCTAssertNoThrow(try view.inspect().find(text: L("뒤로")))
    }

    func testContainer_step2_rendersSystemPresetStep() throws {
        let view = OnboardingContainerView(initialStep: 2)
            .environmentObject(makeDeps())
        XCTAssertNoThrow(try view.inspect().find(button: L("다음")))
    }

    func testContainer_step3_rendersAppPickerStep() throws {
        try XCTSkipIfViewInspectorBlocked()
        let view = OnboardingContainerView(initialStep: 3)
            .environmentObject(makeDeps())
        XCTAssertNoThrow(try view.inspect().find(text: L("허용할 앱을 골라주세요")))
    }

    func testContainer_step4_rendersScheduleStep() throws {
        try XCTSkipIfViewInspectorBlocked()
        let view = OnboardingContainerView(initialStep: 4)
            .environmentObject(makeDeps())
        XCTAssertNoThrow(try view.inspect().find(text: L("집중 시간대를 골라주세요")))
    }

    func testContainer_step5_rendersPasscodeStep() throws {
        try XCTSkipIfViewInspectorBlocked()
        let view = OnboardingContainerView(initialStep: 5)
            .environmentObject(makeDeps())
        XCTAssertNoThrow(try view.inspect().find(text: L("앱 비밀번호를 정해주세요")))
        XCTAssertNoThrow(try view.inspect().find(button: L("건너뛰기")))
    }

    func testContainer_backButton_rendersOnNonZeroSteps() throws {
        try XCTSkipIfViewInspectorBlocked()
        for step in 1...5 {
            let view = OnboardingContainerView(initialStep: step)
                .environmentObject(makeDeps())
            XCTAssertNoThrow(
                try view.inspect().find(text: L("뒤로")),
                "step \(step) 에서 뒤로 버튼이 렌더되어야"
            )
        }
    }
}
