import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

@MainActor
final class ToastTests: XCTestCase {

    func testToast_rendersMessageWhenNotNil() throws {
        let binding = Binding<String?>(wrappedValue: "안녕하세요")
        let view = Text("base").toast(message: binding)
        XCTAssertNoThrow(try view.inspect().find(text: "안녕하세요"))
    }

    func testToast_hiddenWhenNil() throws {
        let binding = Binding<String?>(wrappedValue: nil)
        let view = Text("base").toast(message: binding)
        XCTAssertThrowsError(try view.inspect().find(text: "안녕하세요"))
    }
}
