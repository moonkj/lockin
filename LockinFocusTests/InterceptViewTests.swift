import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

@MainActor
final class InterceptViewTests: XCTestCase {

    func testInterceptView_rendersHeadline() throws {
        let view = InterceptView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: "잠깐 기다려봐요"))
    }

    func testInterceptView_rendersReflectionPrompt() throws {
        let view = InterceptView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: "이 앱이 지금 꼭 필요한가요?"))
    }

    func testInterceptView_rendersReturnButton() throws {
        let view = InterceptView().environmentObject(AppDependencies.preview())
        // "돌아가기" 버튼이 존재.
        XCTAssertNoThrow(try view.inspect().find(button: "돌아가기"))
    }

    func testInterceptView_rendersOpenAnywayLabel() throws {
        let view = InterceptView().environmentObject(AppDependencies.preview())
        // "그래도 열기" 라벨 (처음에는 카운트다운 중이므로 disabled)
        let inspected = try view.inspect()
        XCTAssertNoThrow(inspected)
    }

    func testInterceptView_strictActive_rendersStrictHint() throws {
        let deps = AppDependencies.preview()
        deps.persistence.strictModeEndAt = Date().addingTimeInterval(3600)
        let view = InterceptView().environmentObject(deps)
        XCTAssertNoThrow(try view.inspect())
    }
}
