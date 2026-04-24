import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

/// 초기 entries 주입 경로로 medalCell / rankRow / summary 등의 렌더를 직접 검증.
@MainActor
final class LeaderboardViewRenderTests: XCTestCase {

    private func entry(userID: String, nickname: String, daily: Int) -> LeaderboardEntry {
        LeaderboardEntry(
            userID: userID, nickname: nickname,
            dailyScore: daily, dailyDate: "2026-04-24",
            weeklyTotal: daily * 7, weeklyWeek: "2026-W17",
            monthlyTotal: daily * 30, monthlyMonth: "2026-04",
            updatedAt: Date()
        )
    }

    func testLeaderboard_fullTopThree_rendersMedalNicknames() throws {
        let entries = [
            entry(userID: "a", nickname: "첫째", daily: 100),
            entry(userID: "b", nickname: "둘째", daily: 90),
            entry(userID: "c", nickname: "셋째", daily: 80)
        ]
        let view = LeaderboardView(initialPeriod: .daily, initialEntries: entries)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("첫째")))
        XCTAssertNoThrow(try view.inspect().find(text: L("둘째")))
        XCTAssertNoThrow(try view.inspect().find(text: L("셋째")))
    }

    func testLeaderboard_fullTopThree_showsScorePoints() throws {
        let entries = [
            entry(userID: "a", nickname: "첫째", daily: 100),
            entry(userID: "b", nickname: "둘째", daily: 90),
            entry(userID: "c", nickname: "셋째", daily: 80)
        ]
        let view = LeaderboardView(initialPeriod: .daily, initialEntries: entries)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("100점")))
        XCTAssertNoThrow(try view.inspect().find(text: L("90점")))
        XCTAssertNoThrow(try view.inspect().find(text: L("80점")))
    }

    func testLeaderboard_weeklyPeriod_usesWeeklyScore() throws {
        let entries = [
            entry(userID: "a", nickname: "주간왕", daily: 50)
        ]
        let view = LeaderboardView(initialPeriod: .weekly, initialEntries: entries)
            .environmentObject(AppDependencies.preview())
        // weekly = daily * 7 = 350.
        XCTAssertNoThrow(try view.inspect().find(text: L("주간 Top 3")))
    }

    func testLeaderboard_monthlyPeriod_showsMonthlyHeader() throws {
        let entries = [entry(userID: "a", nickname: "x", daily: 10)]
        let view = LeaderboardView(initialPeriod: .monthly, initialEntries: entries)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("월간 Top 3")))
    }

    func testLeaderboard_moreThanThree_rendersRankRows() throws {
        var entries: [LeaderboardEntry] = []
        for i in 0..<10 {
            entries.append(entry(userID: "u-\(i)", nickname: "유저\(i)", daily: 100 - i * 5))
        }
        let view = LeaderboardView(initialPeriod: .daily, initialEntries: entries)
            .environmentObject(AppDependencies.preview())
        // 4위부터 10위까지 rank row 가 렌더. 닉네임 샘플로 확인.
        XCTAssertNoThrow(try view.inspect().find(text: L("유저3")))
        XCTAssertNoThrow(try view.inspect().find(text: L("유저5")))
        XCTAssertNoThrow(try view.inspect().find(text: L("유저9")))
    }

    func testLeaderboard_myEntry_rendersMeBadge() throws {
        let entries = [
            entry(userID: "other1", nickname: "x", daily: 100),
            entry(userID: "other2", nickname: "y", daily: 90),
            entry(userID: "other3", nickname: "z", daily: 80),
            entry(userID: "me", nickname: "나야나", daily: 70)
        ]
        let view = LeaderboardView(
            initialPeriod: .daily,
            initialEntries: entries,
            initialMyUserID: "me"
        ).environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("나야나")))
        XCTAssertNoThrow(try view.inspect().find(text: L("나")))
    }

    func testLeaderboard_myRankOutside30_rendersSeparateSection() throws {
        var entries: [LeaderboardEntry] = []
        for i in 0..<35 {
            entries.append(entry(userID: "u-\(i)", nickname: "P\(i)", daily: 100 - i))
        }
        // 35번째(index 34, rank 35) 가 나 — 30위 밖.
        entries[34] = entry(userID: "me", nickname: "지각생", daily: 66)
        let view = LeaderboardView(
            initialPeriod: .daily,
            initialEntries: entries,
            initialMyUserID: "me"
        ).environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("내 순위")))
        XCTAssertNoThrow(try view.inspect().find(text: L("지각생")))
    }

    func testLeaderboard_summaryStrip_participantCount() throws {
        let entries = [
            entry(userID: "a", nickname: "a", daily: 1),
            entry(userID: "b", nickname: "b", daily: 2)
        ]
        let view = LeaderboardView(initialPeriod: .daily, initialEntries: entries)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("2명")))
    }
}
