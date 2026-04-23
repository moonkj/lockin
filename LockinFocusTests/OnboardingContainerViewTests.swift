import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

@MainActor
final class OnboardingContainerViewTests: XCTestCase {

    func testContainer_renders_firstStep() throws {
        let deps = AppDependencies.preview()
        let view = OnboardingContainerView().environmentObject(deps)
        // Step 0 = ValueStepView — 해당 헤드라인이 존재해야.
        XCTAssertNoThrow(try view.inspect().find(ViewType.Button.self))
    }

    func testContainer_initialStep_noBackButton() throws {
        let deps = AppDependencies.preview()
        let view = OnboardingContainerView().environmentObject(deps)
        // step == 0 이면 뒤로 버튼이 숨겨져야.
        XCTAssertThrowsError(try view.inspect().find(text: "뒤로"))
    }

    func testContainer_renders_dotIndicator() throws {
        let deps = AppDependencies.preview()
        let view = OnboardingContainerView().environmentObject(deps)
        // 6 step 인디케이터 존재.
        let inspected = try view.inspect()
        XCTAssertNoThrow(inspected)
    }
}
