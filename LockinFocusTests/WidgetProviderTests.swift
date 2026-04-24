import XCTest
import WidgetKit
@testable import LockinFocus

/// Widget 타깃의 Entry / Provider 타입(FocusScoreEntry, QuoteEntry 등)은
/// 별도 컴파일 단위라 메인 앱 테스트 번들에서 직접 참조할 수 없다.
/// 대신 위젯이 의존하는 "메인 앱이 노출하는 계약"을 고정:
/// - App Group identifier
/// - UserDefaults 키 이름 (focusScoreToday / focusScoreDate / dailyFocusHistory)
/// - 위젯이 쓰는 QuoteProvider.today() 의 결정론적 반환
@MainActor
final class WidgetProviderTests: XCTestCase {

    // MARK: - App Group identifier (widget entitlement 과 일치해야)

    func testWidgetDataBoundary_appGroupIdentifier() {
        XCTAssertEqual(AppGroup.identifier, "group.com.moonkj.LockinFocus")
    }

    func testWidgetDataBoundary_sharedDefaultsAccessible() {
        let d = UserDefaults(suiteName: AppGroup.identifier)
        XCTAssertNotNil(d)
    }

    // MARK: - UserDefaults 키 이름 안정성

    func testWidgetDataBoundary_focusScoreTodayKey() {
        XCTAssertEqual(SharedKeys.focusScoreToday, "focusScoreToday")
    }

    func testWidgetDataBoundary_focusScoreDateKey() {
        XCTAssertEqual(PersistenceKeys.focusScoreDateKey, "focusScoreDate")
    }

    func testWidgetDataBoundary_dailyFocusHistoryKey() {
        XCTAssertEqual(PersistenceKeys.dailyFocusHistory, "dailyFocusHistory")
    }

    // MARK: - QuoteProvider.today 결정론적 (위젯 timeline refresh 안정성)

    func testQuoteProvider_todayDeterministicForSameDate() {
        let ref = Date()
        let a = QuoteProvider.today(now: ref)
        let b = QuoteProvider.today(now: ref)
        XCTAssertEqual(a, b)
    }

    func testQuoteProvider_allQuotesNonEmpty() {
        XCTAssertFalse(QuoteProvider.allQuotes().isEmpty)
    }
}
