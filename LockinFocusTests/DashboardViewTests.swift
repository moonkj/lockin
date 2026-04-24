import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

@MainActor
final class DashboardViewTests: XCTestCase {

    func testDashboardView_rendersHeaderTitle() throws {
        let view = DashboardView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("락인 포커스")))
    }

    func testDashboardView_rendersFocusScoreCard() throws {
        let view = DashboardView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("오늘의 집중")))
    }

    func testDashboardView_rendersAllowedAppsSection() throws {
        let view = DashboardView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("허용 앱")))
    }

    func testDashboardView_rendersStartButton() throws {
        let view = DashboardView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("지금 집중 시작")))
    }

    func testDashboardView_rendersNextScheduleSection() throws {
        let view = DashboardView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("다음 스케줄")))
    }

    func testDashboardView_rendersQuoteCard() throws {
        let view = DashboardView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("오늘의 명언")))
    }

    func testDashboardView_emptyAllowedApps_showsHint() throws {
        let view = DashboardView().environmentObject(AppDependencies.preview())
        // 허용 앱 0개면 하단에 안내 문구.
        XCTAssertNoThrow(try view.inspect().find(
            text: "허용 앱이 0개예요. 집중을 시작하면 시스템 자동 보호 앱(전화·메시지·설정) 외 대부분 앱이 잠깁니다."
        ))
    }
}
