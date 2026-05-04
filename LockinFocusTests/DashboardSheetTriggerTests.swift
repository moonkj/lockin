import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

@MainActor
final class DashboardSheetTriggerTests: XCTestCase {

    func testDashboard_headerButtons_exist() throws {
        let view = DashboardView().environmentObject(AppDependencies.preview())
        let inspected = try view.inspect()
        // 4 header buttons (trophy, rosette, chart.bar, gearshape) + start + card buttons.
        let buttons = inspected.findAll(ViewType.Button.self)
        XCTAssertGreaterThanOrEqual(buttons.count, 5)
    }

    func testDashboard_renderingDoesNotCrash_withFocusActive() throws {
        let view = DashboardView(initialIsManualFocus: true)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect())
    }

    func testDashboard_startButton_renders() throws {
        try XCTSkipIfViewInspectorBlocked()
        let view = DashboardView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("지금 집중 시작")))
    }
}
