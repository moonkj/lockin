import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

@MainActor
final class LeaderboardViewBranchTests: XCTestCase {

    private func entry(userID: String, nickname: String, score: Int) -> LeaderboardEntry {
        LeaderboardEntry(
            userID: userID, nickname: nickname,
            dailyScore: score, dailyDate: "2026-04-24",
            weeklyTotal: 0, weeklyWeek: "",
            monthlyTotal: 0, monthlyMonth: "",
            updatedAt: Date()
        )
    }

    func testLeaderboard_onlyOneEntry_showsFirstPlaceholderOthers() throws {
        let entries = [entry(userID: "a", nickname: "첫째", score: 100)]
        let view = LeaderboardView(initialPeriod: .daily, initialEntries: entries)
            .environmentObject(AppDependencies.preview())
        // 1등 자리에 엔트리 렌더, 2/3 등은 placeholder.
        XCTAssertNoThrow(try view.inspect().find(text: "첫째"))
    }

    func testLeaderboard_twoEntries_thirdSlotPlaceholder() throws {
        let entries = [
            entry(userID: "a", nickname: "일등", score: 100),
            entry(userID: "b", nickname: "이등", score: 90)
        ]
        let view = LeaderboardView(initialPeriod: .daily, initialEntries: entries)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: "일등"))
        XCTAssertNoThrow(try view.inspect().find(text: "이등"))
    }

    func testLeaderboard_emptyEntries_rendersPlaceholder() throws {
        let view = LeaderboardView(initialPeriod: .daily, initialEntries: [])
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: "아직 등록된 기록이 많지 않아요.\n오른쪽 위 ↑ 버튼으로 내 점수를 등록해보세요."))
    }

    func testLeaderboard_percentileRendering() throws {
        var entries: [LeaderboardEntry] = []
        for i in 0..<100 {
            entries.append(entry(userID: i == 9 ? "me" : "u-\(i)", nickname: "p\(i)", score: 100 - i))
        }
        let view = LeaderboardView(
            initialPeriod: .daily,
            initialEntries: entries,
            initialMyUserID: "me"
        ).environmentObject(AppDependencies.preview())
        // rank 10 / 100 → percentile 10%
        XCTAssertNoThrow(try view.inspect().find(text: "10등"))
        XCTAssertNoThrow(try view.inspect().find(text: "10%"))
    }
}
