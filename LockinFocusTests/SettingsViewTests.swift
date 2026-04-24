import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

@MainActor
final class SettingsViewTests: XCTestCase {

    private func makeDeps() -> AppDependencies {
        AppDependencies.preview()
    }

    func testSettingsView_rendersNavigationTitle() throws {
        let view = SettingsView().environmentObject(makeDeps())
        XCTAssertNoThrow(try view.inspect().find(button: L("닫기")))
    }

    func testSettingsView_rendersBlockingSection() throws {
        let view = SettingsView().environmentObject(makeDeps())
        XCTAssertNoThrow(try view.inspect().find(text: L("허용 앱")))
        XCTAssertNoThrow(try view.inspect().find(text: L("스케줄")))
    }

    func testSettingsView_rendersStrictModeSection() throws {
        let view = SettingsView().environmentObject(makeDeps())
        XCTAssertNoThrow(try view.inspect().find(text: L("엄격 모드")))
    }

    func testSettingsView_rendersPasscodeRow() throws {
        let view = SettingsView().environmentObject(makeDeps())
        XCTAssertNoThrow(try view.inspect().find(text: L("앱 비밀번호 설정")))
    }

    func testSettingsView_rendersNicknameRow() throws {
        let view = SettingsView().environmentObject(makeDeps())
        XCTAssertNoThrow(try view.inspect().find(text: L("닉네임")))
    }

    func testSettingsView_rendersRankingFooter() throws {
        let view = SettingsView().environmentObject(makeDeps())
        XCTAssertNoThrow(try view.inspect().find(
            text: "랭킹에서 다른 사용자에게 보이는 이름이에요. 욕설·성적 단어는 차단돼요."
        ))
    }

    func testSettingsView_rendersVersionLabel() throws {
        let view = SettingsView().environmentObject(makeDeps())
        XCTAssertNoThrow(try view.inspect().find(text: L("버전")))
    }

    func testSettingsView_rendersAppInfoHeader() throws {
        let view = SettingsView().environmentObject(makeDeps())
        XCTAssertNoThrow(try view.inspect().find(text: L("앱 정보")))
    }

    func testSettingsView_strictInactive_showsStartButton() throws {
        // strictModeEndAt nil 상태 (기본) → "엄격 모드 시작" 버튼.
        let view = SettingsView().environmentObject(makeDeps())
        XCTAssertNoThrow(try view.inspect().find(text: L("엄격 모드 시작")))
    }

    func testSettingsView_strictActive_showsRemainingTime() throws {
        let deps = makeDeps()
        deps.persistence.strictModeEndAt = Date().addingTimeInterval(1800)
        let view = SettingsView().environmentObject(deps)
        XCTAssertNoThrow(try view.inspect().find(text: L("활성 중")))
    }

    func testSettingsView_nicknameMissing_showsWarningText() throws {
        let view = SettingsView().environmentObject(makeDeps())
        XCTAssertNoThrow(try view.inspect().find(text: L("미설정")))
    }
}
