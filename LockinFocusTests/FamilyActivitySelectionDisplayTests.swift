import XCTest
import FamilyControls
@testable import LockinFocus

final class FamilyActivitySelectionDisplayTests: XCTestCase {

    func testEmpty_returnsNil() {
        let sel = FamilyActivitySelection()
        XCTAssertNil(sel.displayBreakdown)
        XCTAssertEqual(sel.totalItemCount, 0)
    }
}
