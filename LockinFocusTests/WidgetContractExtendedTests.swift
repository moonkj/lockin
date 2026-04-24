import XCTest
@testable import LockinFocus

/// Widget 은 별도 프로세스에서 메인 앱의 UserDefaults App Group 을 읽는다.
/// 메인 앱이 쓰는 키/값의 형태를 widget 이 기대하는 그대로 유지하지 못하면
/// Dock 에 붙은 widget 이 stale 상태로 남거나 crash 한다.
///
/// WidgetProviderTests 는 **키 이름** 만 고정한다 (문자열 리터럴).
/// 이 파일은 더 깊은 계약 — 값 타입·직렬화 형식·읽기 가능성 — 을 고정한다.
@MainActor
final class WidgetContractExtendedTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: AppGroup.identifier)
        // 기존 값에 영향받지 않도록 각 테스트 키를 제거.
        [
            SharedKeys.focusScoreToday,
            PersistenceKeys.focusScoreDateKey,
            PersistenceKeys.dailyFocusHistory
        ].forEach { defaults.removeObject(forKey: $0) }
    }

    // MARK: - focusScoreToday 는 Int 로 저장된다

    func testFocusScoreToday_writeAsInt_readAsInt() {
        defaults.set(42, forKey: SharedKeys.focusScoreToday)
        XCTAssertEqual(defaults.integer(forKey: SharedKeys.focusScoreToday), 42)
    }

    func testFocusScoreToday_missingKey_defaultsToZero() {
        defaults.removeObject(forKey: SharedKeys.focusScoreToday)
        XCTAssertEqual(defaults.integer(forKey: SharedKeys.focusScoreToday), 0)
    }

    // MARK: - focusScoreDate 는 yyyy-MM-dd 문자열

    func testFocusScoreDate_formatContract() {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        let today = f.string(from: Date())

        defaults.set(today, forKey: PersistenceKeys.focusScoreDateKey)
        let read = defaults.string(forKey: PersistenceKeys.focusScoreDateKey)
        XCTAssertEqual(read, today)
        // yyyy-MM-dd 포맷 (길이 10) 확인.
        XCTAssertEqual(read?.count, 10)
    }

    // MARK: - dailyFocusHistory 는 [DailyFocus] JSON

    func testDailyFocusHistory_codableRoundtrip() throws {
        let entries: [DailyFocus] = [
            DailyFocus(date: "2026-04-20", score: 60),
            DailyFocus(date: "2026-04-21", score: 75),
            DailyFocus(date: "2026-04-22", score: 88)
        ]
        let data = try JSONEncoder().encode(entries)
        defaults.set(data, forKey: PersistenceKeys.dailyFocusHistory)

        let read = defaults.data(forKey: PersistenceKeys.dailyFocusHistory)
        XCTAssertNotNil(read)
        let decoded = try JSONDecoder().decode([DailyFocus].self, from: read!)
        XCTAssertEqual(decoded, entries)
    }

    func testDailyFocusHistory_missingKey_isNil() {
        defaults.removeObject(forKey: PersistenceKeys.dailyFocusHistory)
        XCTAssertNil(defaults.data(forKey: PersistenceKeys.dailyFocusHistory))
    }

    // MARK: - AppGroup sharedDefaults shortcut

    func testSharedDefaults_returnsAppGroupSuite() {
        let a = AppGroup.sharedDefaults
        let b = UserDefaults(suiteName: AppGroup.identifier)
        // 같은 suite → 한쪽에 쓴 값이 다른쪽에서 읽혀야.
        a.set(1234, forKey: "widget-contract-test-sentinel")
        XCTAssertEqual(b?.integer(forKey: "widget-contract-test-sentinel"), 1234)
        a.removeObject(forKey: "widget-contract-test-sentinel")
    }

    // MARK: - SharedKeys rawValue 고정

    func testSharedKeys_familySelection_rawValue() {
        XCTAssertEqual(SharedKeys.familySelection, "familySelection")
    }

    func testSharedKeys_scheduleStart_rawValue() {
        XCTAssertEqual(SharedKeys.scheduleStart, "scheduleStart")
    }

    func testSharedKeys_scheduleEnd_rawValue() {
        XCTAssertEqual(SharedKeys.scheduleEnd, "scheduleEnd")
    }

    func testSharedKeys_strictModeActive_rawValue() {
        XCTAssertEqual(SharedKeys.strictModeActive, "strictModeActive")
    }

    // MARK: - DailyFocus JSON 필드 계약

    func testDailyFocus_json_fieldNames() throws {
        let entry = DailyFocus(date: "2026-04-22", score: 42)
        let data = try JSONEncoder().encode(entry)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(obj?["date"] as? String, "2026-04-22")
        XCTAssertEqual(obj?["score"] as? Int, 42)
    }

    func testDailyFocus_json_scoreIntNotString() throws {
        // Widget 이 score 를 Int 로 파싱하므로 String 으로 저장되면 안 됨.
        let entry = DailyFocus(date: "2026-04-22", score: 99)
        let data = try JSONEncoder().encode(entry)
        // JSON payload 에서 "score":99 로 나와야 (따옴표 없음).
        let text = String(data: data, encoding: .utf8) ?? ""
        XCTAssertTrue(text.contains("\"score\":99"), "score 는 따옴표 없는 숫자여야: \(text)")
    }
}
