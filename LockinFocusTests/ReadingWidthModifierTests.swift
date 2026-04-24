import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

/// `readingWidth()` 는 iPad 에서 콘텐츠가 너무 넓어지지 않도록
/// 중앙 정렬 + 최대 폭 제한을 건다. iPhone 에서는 프레임 무시되므로 no-op.
@MainActor
final class ReadingWidthModifierTests: XCTestCase {

    func testReadingWidth_appliedView_doesNotCrash() throws {
        let view = Text("content").readingWidth()
        XCTAssertNoThrow(try view.inspect())
    }

    func testReadingWidth_defaultAndCustomWidth_bothRender() throws {
        let defaultView = Text("a").readingWidth()
        let customView = Text("b").readingWidth(720)
        XCTAssertNoThrow(try defaultView.inspect())
        XCTAssertNoThrow(try customView.inspect())
    }

    func testReadingWidth_textContentPreserved() throws {
        let view = Text("hello-reading-width").readingWidth(500)
        XCTAssertNoThrow(try view.inspect().find(text: "hello-reading-width"))
    }

    func testReadingWidth_modifierOnVStack() throws {
        let view = VStack {
            Text("line-one")
            Text("line-two")
        }
        .readingWidth()

        XCTAssertNoThrow(try view.inspect())
        XCTAssertNoThrow(try view.inspect().find(text: "line-one"))
        XCTAssertNoThrow(try view.inspect().find(text: "line-two"))
    }

    func testReadingWidth_modifierChainable() throws {
        let view = Text("chain")
            .readingWidth(400)
            .padding(10)

        XCTAssertNoThrow(try view.inspect())
    }

    func testReadingWidthModifier_producesBody() {
        let modifier = ReadingWidthModifier(maxWidth: 640)
        let view = Text("x").modifier(modifier)
        XCTAssertNoThrow(try view.inspect())
    }
}
