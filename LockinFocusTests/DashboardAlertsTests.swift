import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

@MainActor
final class DashboardAlertsTests: XCTestCase {

    func testDashboard_withToast_rendersToastContent() throws {
        let view = DashboardView(
            initialIsManualFocus: false,
            initialToast: "앱 비밀번호를 먼저 설정해주세요. 설정에서 등록할 수 있어요."
        ).environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(
            text: "앱 비밀번호를 먼저 설정해주세요. 설정에서 등록할 수 있어요."
        ))
    }

    func testDashboard_emptyAllowConfirm_rendersWithoutCrash() throws {
        let view = DashboardView(
            initialIsManualFocus: false,
            initialShowEmptyAllowConfirm: true
        ).environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect())
    }

    func testDashboard_strictActiveAlert_rendersWithoutCrash() throws {
        let view = DashboardView(
            initialIsManualFocus: true,
            initialShowStrictActiveAlert: true
        ).environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect())
    }

    func testDashboard_manualFocusActive_labelSwapsToEnd() throws {
        let view = DashboardView(initialIsManualFocus: true)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("집중 종료")))
        XCTAssertThrowsError(try view.inspect().find(text: L("지금 집중 시작")))
    }
}
