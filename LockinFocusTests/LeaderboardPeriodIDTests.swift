import XCTest
@testable import LockinFocus

final class LeaderboardPeriodIDTests: XCTestCase {

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day; c.hour = 12
        c.calendar = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Seoul")
        return c.date!
    }

    func testDaily_formatYYYYMMDD() {
        let id = LeaderboardPeriodID.daily(date(2026, 4, 23))
        XCTAssertEqual(id.count, 10)
        XCTAssertTrue(id.contains("2026"))
        XCTAssertTrue(id.contains("04"))
    }

    func testWeekly_formatYYYYWww() {
        let id = LeaderboardPeriodID.weekly(date(2026, 1, 5))
        XCTAssertTrue(id.hasPrefix("2026-W") || id.hasPrefix("2025-W"))
        XCTAssertEqual(id.count, 8)
    }

    func testMonthly_formatYYYYMM() {
        let id = LeaderboardPeriodID.monthly(date(2026, 4, 23))
        XCTAssertEqual(id, "2026-04")
    }

    func testMonthly_endOfYearRollover() {
        let id = LeaderboardPeriodID.monthly(date(2026, 12, 31))
        XCTAssertEqual(id, "2026-12")
    }

    func testCurrent_daily_matchesDailyHelper() {
        let now = Date()
        XCTAssertEqual(
            LeaderboardPeriodID.current(.daily, now: now),
            LeaderboardPeriodID.daily(now)
        )
    }

    func testCurrent_weekly_matchesWeeklyHelper() {
        let now = Date()
        XCTAssertEqual(
            LeaderboardPeriodID.current(.weekly, now: now),
            LeaderboardPeriodID.weekly(now)
        )
    }

    func testCurrent_monthly_matchesMonthlyHelper() {
        let now = Date()
        XCTAssertEqual(
            LeaderboardPeriodID.current(.monthly, now: now),
            LeaderboardPeriodID.monthly(now)
        )
    }

    func testPeriod_labels() {
        XCTAssertEqual(LeaderboardPeriod.daily.label, "일간")
        XCTAssertEqual(LeaderboardPeriod.weekly.label, "주간")
        XCTAssertEqual(LeaderboardPeriod.monthly.label, "월간")
    }

    func testPeriod_idRawValue() {
        XCTAssertEqual(LeaderboardPeriod.daily.id, "daily")
        XCTAssertEqual(LeaderboardPeriod.weekly.id, "weekly")
        XCTAssertEqual(LeaderboardPeriod.monthly.id, "monthly")
    }

    func testPeriod_allCases_threeEntries() {
        XCTAssertEqual(LeaderboardPeriod.allCases.count, 3)
    }
}
