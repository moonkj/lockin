import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

@MainActor
final class SettingsViewBranchTests: XCTestCase {

    func testSettings_hasSelectionAppsRow() throws {
        let view = SettingsView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("허용 앱")))
        XCTAssertNoThrow(try view.inspect().find(text: L("스케줄")))
    }

    func testSettings_strictFooterExplainsPasscode() throws {
        try XCTSkipIfViewInspectorBlocked()
        let view = SettingsView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(
            text: "앱 비밀번호는 일반 모드의 하루 첫 해제 때만 쓰여요. 엄격 모드는 시간이 지나기 전에는 어떤 방법으로도 풀 수 없어요."
        ))
    }

    func testSettings_strictInactive_rendersStartLabel() throws {
        try XCTSkipIfViewInspectorBlocked()
        let deps = AppDependencies.preview()
        deps.persistence.strictModeEndAt = nil
        let view = SettingsView().environmentObject(deps)
        XCTAssertNoThrow(try view.inspect().find(text: L("엄격 모드 시작")))
        XCTAssertNoThrow(try view.inspect().find(
            text: "설정한 시간 동안은 어떤 방법으로도 해제할 수 없어요."
        ))
    }

    func testSettings_strictActive_hidesStartLabel() throws {
        let deps = AppDependencies.preview()
        deps.persistence.strictModeEndAt = Date().addingTimeInterval(3600)
        let view = SettingsView().environmentObject(deps)
        XCTAssertThrowsError(try view.inspect().find(text: L("엄격 모드 시작")))
    }

    func testSettings_hasAppInfoVersion() throws {
        try XCTSkipIfViewInspectorBlocked()
        let view = SettingsView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("버전")))
    }
}
