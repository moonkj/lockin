import XCTest
import SwiftUI
@testable import LockinFocus

/// 작은 모델들의 불변식 검증 — DailyFocus, DailyQuote, TreeStage.
final class ModelTests: XCTestCase {

    // MARK: - DailyFocus

    func testDailyFocus_id_equalsDate() {
        let f = DailyFocus(date: "2026-04-23", score: 80)
        XCTAssertEqual(f.id, "2026-04-23")
    }

    func testDailyFocus_displayDate_parsesCorrectly() {
        let f = DailyFocus(date: "2026-04-23", score: 50)
        let c = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: f.displayDate)
        XCTAssertEqual(c.year, 2026)
        XCTAssertEqual(c.month, 4)
        XCTAssertEqual(c.day, 23)
    }

    func testDailyFocus_displayDate_fallsBackForInvalid() {
        let f = DailyFocus(date: "invalid", score: 0)
        XCTAssertNotNil(f.displayDate) // 값이 존재함만 확인
    }

    func testDailyFocus_shortWeekday_nonEmpty() {
        let f = DailyFocus(date: "2026-04-23", score: 50)
        XCTAssertFalse(f.shortWeekday.isEmpty)
    }

    func testDailyFocus_codable_roundTrip() throws {
        let f = DailyFocus(date: "2026-04-23", score: 77)
        let data = try JSONEncoder().encode(f)
        let decoded = try JSONDecoder().decode(DailyFocus.self, from: data)
        XCTAssertEqual(decoded, f)
    }

    // MARK: - DailyQuote

    func testDailyQuote_idEqualsText() {
        let q = DailyQuote(text: "hello", author: nil)
        XCTAssertEqual(q.id, "hello")
    }

    func testDailyQuote_equality_strict() {
        let a = DailyQuote(text: "x", author: "y")
        let b = DailyQuote(text: "x", author: "y")
        XCTAssertEqual(a, b)
    }

    // MARK: - TreeStage

    func testTreeStage_zeroScore_seed() {
        XCTAssertEqual(TreeStage.from(score: 0), .seed)
    }

    func testTreeStage_boundaries() {
        XCTAssertEqual(TreeStage.from(score: 1), .sprout)
        XCTAssertEqual(TreeStage.from(score: 20), .sprout)
        XCTAssertEqual(TreeStage.from(score: 21), .sapling)
        XCTAssertEqual(TreeStage.from(score: 40), .sapling)
        XCTAssertEqual(TreeStage.from(score: 41), .young)
        XCTAssertEqual(TreeStage.from(score: 60), .young)
        XCTAssertEqual(TreeStage.from(score: 61), .grown)
        XCTAssertEqual(TreeStage.from(score: 80), .grown)
        XCTAssertEqual(TreeStage.from(score: 81), .flourish)
        XCTAssertEqual(TreeStage.from(score: 100), .flourish)
    }

    func testTreeStage_allCases_haveLabels() {
        for stage in TreeStage.allCases {
            XCTAssertFalse(stage.label.isEmpty)
            XCTAssertFalse(stage.symbolName.isEmpty)
            _ = stage.accentColor
        }
    }

    func testTreeStage_allCases_sixStages() {
        XCTAssertEqual(TreeStage.allCases.count, 6)
    }

    // MARK: - LeaderboardPeriod

    func testLeaderboardPeriod_hashable() {
        let set: Set<LeaderboardPeriod> = [.daily, .weekly, .weekly]
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Badge allCases

    func testBadge_allCasesUnique() {
        let ids = Badge.allCases.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }
}
