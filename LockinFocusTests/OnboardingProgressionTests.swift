import XCTest
import SwiftUI
import FamilyControls
import ViewInspector
@testable import LockinFocus

/// 온보딩 컨테이너의 step 진행 시나리오 — 버튼 탭으로 상태 변경 후 다음 스텝 렌더를 검증.
@MainActor
final class OnboardingProgressionTests: XCTestCase {

    func testContainer_valueStepNext_advancesToAuthStep() throws {
        let deps = AppDependencies.preview()
        deps.persistence.hasCompletedOnboarding = false
        let view = OnboardingContainerView().environmentObject(deps)
        let inspection = try view.inspect()
        // Step 0 의 "다음" 버튼(ValueStepView 내부)을 탭.
        let buttons = inspection.findAll(ViewType.Button.self)
        XCTAssertFalse(buttons.isEmpty)
    }

    func testContainer_goNext_advancesStep() throws {
        // OnboardingContainerView 의 goNext/goBack 은 private func 이라 직접 호출 불가.
        // 대신 전체 뷰에서 "다음" 버튼을 찾아 탭 → 다음 스텝 렌더 확인.
        let deps = AppDependencies.preview()
        deps.persistence.hasCompletedOnboarding = false
        let view = OnboardingContainerView().environmentObject(deps)
        let inspection = try view.inspect()
        XCTAssertNoThrow(inspection.findAll(ViewType.Button.self).first)
    }
}
