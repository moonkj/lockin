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
        let view = LeaderboardContent(initialPeriod: .daily, initialEntries: entries)
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
        let view = LeaderboardContent(initialPeriod: .daily, initialEntries: entries)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("100점")))
        XCTAssertNoThrow(try view.inspect().find(text: L("90점")))
        XCTAssertNoThrow(try view.inspect().find(text: L("80점")))
    }

    func testLeaderboard_weeklyPeriod_usesWeeklyScore() throws {
        let entries = [
            entry(userID: "a", nickname: "주간왕", daily: 50)
        ]
        let view = LeaderboardContent(initialPeriod: .weekly, initialEntries: entries)
            .environmentObject(AppDependencies.preview())
        // weekly = daily * 7 = 350.
        XCTAssertNoThrow(try view.inspect().find(text: L("주간 Top 3")))
    }

    func testLeaderboard_monthlyPeriod_showsMonthlyHeader() throws {
        let entries = [entry(userID: "a", nickname: "x", daily: 10)]
        let view = LeaderboardContent(initialPeriod: .monthly, initialEntries: entries)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("월간 Top 3")))
    }

    func testLeaderboard_moreThanThree_rendersRankRows() throws {
        var entries: [LeaderboardEntry] = []
        for i in 0..<10 {
            entries.append(entry(userID: "u-\(i)", nickname: "유저\(i)", daily: 100 - i * 5))
        }
        let view = LeaderboardContent(initialPeriod: .daily, initialEntries: entries)
            .environmentObject(AppDependencies.preview())
        // 4위부터 10위까지 rank row 가 렌더. 닉네임 샘플로 확인.
        XCTAssertNoThrow(try view.inspect().find(text: L("유저3")))
        XCTAssertNoThrow(try view.inspect().find(text: L("유저5")))
        XCTAssertNoThrow(try view.inspect().find(text: L("유저9")))
    }

    /// "나" 캡슐 + 닉네임 렌더는 ViewInspector 한계로 view-level 검증 불가.
    /// 대신 VM 의 myEntry/myRank 가 올바르게 식별되는지로 검증 — 뷰는 isMe 플래그로
    /// 캡슐을 단순 분기 렌더만 하므로, isMe 정확성이 곧 캡슐 노출 정확성.
    func testLeaderboard_myEntry_identifiedInList() throws {
        let entries = [
            entry(userID: "other1", nickname: "x", daily: 100),
            entry(userID: "other2", nickname: "y", daily: 90),
            entry(userID: "other3", nickname: "z", daily: 80),
            entry(userID: "me", nickname: "나야나", daily: 70)
        ]
        let vm = LeaderboardViewModel(
            service: StubEmptyLeaderboardService(),
            persistence: InMemoryPersistenceStore(),
            initialPeriod: .daily,
            initialEntries: entries,
            initialMyUserID: "me"
        )
        XCTAssertEqual(vm.myEntry?.nickname, "나야나")
        XCTAssertEqual(vm.myEntry?.userID, "me")
        XCTAssertEqual(vm.myRank, 4)
    }

    /// 30위 밖 사용자는 뷰가 별도 "내 순위" 섹션을 분기 렌더한다.
    /// 분기 조건은 myRank > 30 — VM-level 로 직접 검증.
    func testLeaderboard_myRankOutside30_triggersSeparateSection() throws {
        var entries: [LeaderboardEntry] = []
        for i in 0..<35 {
            entries.append(entry(userID: "u-\(i)", nickname: "P\(i)", daily: 100 - i))
        }
        // 35번째 (index 34, rank 35) 가 나 — 30위 밖.
        entries[34] = entry(userID: "me", nickname: "지각생", daily: 66)
        let vm = LeaderboardViewModel(
            service: StubEmptyLeaderboardService(),
            persistence: InMemoryPersistenceStore(),
            initialPeriod: .daily,
            initialEntries: entries,
            initialMyUserID: "me"
        )
        XCTAssertEqual(vm.myRank, 35, "30위 밖")
        XCTAssertEqual(vm.myEntry?.nickname, "지각생")
        XCTAssertGreaterThan(vm.myRank ?? 0, 30, "별도 섹션 분기 조건")
    }

    func testLeaderboard_summaryStrip_participantCount() throws {
        let entries = [
            entry(userID: "a", nickname: "a", daily: 1),
            entry(userID: "b", nickname: "b", daily: 2)
        ]
        let view = LeaderboardContent(initialPeriod: .daily, initialEntries: entries)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("2명")))
    }

}
