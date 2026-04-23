import XCTest
@testable import LockinFocus

final class RouteParserTests: XCTestCase {

    func testParse_weeklyReportHost() {
        XCTAssertEqual(
            RouteParser.parse(URL(string: "lockinfocus://weeklyReport")!),
            .weeklyReport
        )
    }

    func testParse_quoteDetailHost() {
        XCTAssertEqual(
            RouteParser.parse(URL(string: "lockinfocus://quoteDetail")!),
            .quoteDetail
        )
    }

    func testParse_wrongScheme_nil() {
        XCTAssertNil(RouteParser.parse(URL(string: "https://weeklyReport")!))
    }

    func testParse_unknownHost_nil() {
        XCTAssertNil(RouteParser.parse(URL(string: "lockinfocus://nope")!))
    }

    func testParse_fallsBackToLastPathComponent() {
        // 호스트 없을 때 path 의 마지막 세그먼트를 키로 사용.
        XCTAssertEqual(
            RouteParser.parse(URL(string: "lockinfocus:///quoteDetail")!),
            .quoteDetail
        )
    }
}
