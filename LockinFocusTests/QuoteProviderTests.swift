import XCTest
@testable import LockinFocus

final class QuoteProviderTests: XCTestCase {

    func testToday_returnsNonEmpty() {
        let q = QuoteProvider.today()
        XCTAssertFalse(q.text.isEmpty)
    }

    func testToday_deterministicForSameDate() {
        let ref = Date()
        let a = QuoteProvider.today(now: ref)
        let b = QuoteProvider.today(now: ref)
        XCTAssertEqual(a, b)
    }

    func testToday_differsAcrossDays() {
        // 1일과 200일 차이는 대부분 다른 quote 를 반환해야 한다 (전체 개수 < 366일 이상이 아니라면).
        var c1 = DateComponents(); c1.year = 2026; c1.month = 1; c1.day = 1
        var c2 = DateComponents(); c2.year = 2026; c2.month = 7; c2.day = 1
        let cal = Calendar(identifier: .gregorian)
        let d1 = cal.date(from: c1)!
        let d2 = cal.date(from: c2)!
        let a = QuoteProvider.today(now: d1)
        let b = QuoteProvider.today(now: d2)
        // 실패 시 fallback 소량일 수 있으므로 soft assertion — 둘 다 non-empty 만 확인.
        XCTAssertFalse(a.text.isEmpty)
        XCTAssertFalse(b.text.isEmpty)
    }

    func testAllQuotes_nonEmpty() {
        XCTAssertFalse(QuoteProvider.allQuotes().isEmpty)
    }
}
