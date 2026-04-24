import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

@MainActor
final class ToastTests: XCTestCase {

    func testToast_rendersMessageWhenNotNil() throws {
        let binding = Binding<String?>(wrappedValue: "안녕하세요")
        let view = Text("base").toast(message: binding)
        XCTAssertNoThrow(try view.inspect().find(text: L("안녕하세요")))
    }

    func testToast_hiddenWhenNil() throws {
        let binding = Binding<String?>(wrappedValue: nil)
        let view = Text("base").toast(message: binding)
        XCTAssertThrowsError(try view.inspect().find(text: L("안녕하세요")))
    }

    func testToast_rendersCustomMessage() throws {
        let binding = Binding<String?>(wrappedValue: "비밀번호를 먼저 설정해주세요")
        let view = Text("base").toast(message: binding)
        XCTAssertNoThrow(try view.inspect().find(text: L("비밀번호를 먼저 설정해주세요")))
    }

    func testToastModifier_appliedToAnyView() throws {
        let binding = Binding<String?>(wrappedValue: "done")
        let view = VStack { Text("content") }.toast(message: binding)
        XCTAssertNoThrow(try view.inspect())
    }

    func testToastBinding_nilToValue_rendersValue() throws {
        let binding = Binding<String?>(wrappedValue: nil)
        let view = Text("x").toast(message: binding)
        XCTAssertNoThrow(try view.inspect())
    }
}
