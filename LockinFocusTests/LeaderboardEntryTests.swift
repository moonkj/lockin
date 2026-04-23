import XCTest
import CloudKit
@testable import LockinFocus

final class LeaderboardEntryTests: XCTestCase {

    func testInit_setsAllFields() {
        let now = Date()
        let entry = LeaderboardEntry(
            userID: "u1",
            nickname: "nick",
            dailyScore: 50,
            dailyDate: "2026-04-23",
            weeklyTotal: 300,
            weeklyWeek: "2026-W17",
            monthlyTotal: 1200,
            monthlyMonth: "2026-04",
            updatedAt: now
        )
        XCTAssertEqual(entry.userID, "u1")
        XCTAssertEqual(entry.nickname, "nick")
        XCTAssertEqual(entry.id, "u1")
    }

    func testScore_byPeriod_returnsCorrectField() {
        let entry = LeaderboardEntry(
            userID: "u", nickname: "n",
            dailyScore: 10, dailyDate: "",
            weeklyTotal: 20, weeklyWeek: "",
            monthlyTotal: 30, monthlyMonth: "",
            updatedAt: Date()
        )
        XCTAssertEqual(entry.score(for: .daily), 10)
        XCTAssertEqual(entry.score(for: .weekly), 20)
        XCTAssertEqual(entry.score(for: .monthly), 30)
    }

    func testPeriodID_byPeriod_returnsCorrectField() {
        let entry = LeaderboardEntry(
            userID: "u", nickname: "n",
            dailyScore: 0, dailyDate: "2026-04-23",
            weeklyTotal: 0, weeklyWeek: "2026-W17",
            monthlyTotal: 0, monthlyMonth: "2026-04",
            updatedAt: Date()
        )
        XCTAssertEqual(entry.periodID(for: .daily), "2026-04-23")
        XCTAssertEqual(entry.periodID(for: .weekly), "2026-W17")
        XCTAssertEqual(entry.periodID(for: .monthly), "2026-04")
    }

    func testRecordInit_failsWithMissingRequiredFields() {
        let record = CKRecord(recordType: LeaderboardEntry.recordType)
        // nickname 과 updatedAt 누락 → nil 반환.
        XCTAssertNil(LeaderboardEntry(record: record))
    }

    func testRecordInit_succeedsWithMinimalFields() {
        let record = CKRecord(recordType: LeaderboardEntry.recordType,
                              recordID: CKRecord.ID(recordName: "uX"))
        record["nickname"] = "nicky" as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        let entry = LeaderboardEntry(record: record)
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.userID, "uX")
        XCTAssertEqual(entry?.nickname, "nicky")
        XCTAssertEqual(entry?.dailyScore, 0, "누락된 숫자 필드는 0 으로 기본값")
    }

    func testHashable_sameUserID_sameHash() {
        let a = LeaderboardEntry(
            userID: "u", nickname: "a", dailyScore: 0, dailyDate: "",
            weeklyTotal: 0, weeklyWeek: "", monthlyTotal: 0, monthlyMonth: "",
            updatedAt: Date()
        )
        let b = LeaderboardEntry(
            userID: "u", nickname: "b", dailyScore: 99, dailyDate: "x",
            weeklyTotal: 99, weeklyWeek: "x", monthlyTotal: 99, monthlyMonth: "x",
            updatedAt: Date()
        )
        XCTAssertEqual(a.id, b.id)
    }
}
