import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

@MainActor
final class SettingsViewBranchTests: XCTestCase {

    func testSettings_hasSelectionAppsRow() throws {
        let view = SettingsView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: "허용 앱"))
        XCTAssertNoThrow(try view.inspect().find(text: "스케줄"))
    }

    func testSettings_hasStrictFooter_noPasscode() throws {
        let view = SettingsView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(
            text: "엄격 모드를 쓰려면 먼저 앱 비밀번호를 설정해야 해요."
        ))
    }

    func testSettings_strictInactive_rendersStartLabel() throws {
        let deps = AppDependencies.preview()
        deps.persistence.strictModeEndAt = nil
        let view = SettingsView().environmentObject(deps)
        XCTAssertNoThrow(try view.inspect().find(text: "엄격 모드 시작"))
        XCTAssertNoThrow(try view.inspect().find(
            text: "설정한 시간 동안은 어떤 방법으로도 해제할 수 없어요."
        ))
    }

    func testSettings_strictActive_hidesStartLabel() throws {
        let deps = AppDependencies.preview()
        deps.persistence.strictModeEndAt = Date().addingTimeInterval(3600)
        let view = SettingsView().environmentObject(deps)
        XCTAssertThrowsError(try view.inspect().find(text: "엄격 모드 시작"))
    }

    func testSettings_hasAppInfoVersion() throws {
        let view = SettingsView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: "버전"))
    }
}
