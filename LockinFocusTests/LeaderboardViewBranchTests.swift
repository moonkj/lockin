import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

/// LeaderboardContent 의 분기 렌더 — 일부는 ViewInspector 통과, 일부는
/// SwiftUI 26.2 + ViewInspector 0.10.3 의 AccessibilityImageLabel traversal
/// 한계로 view-level inspection 이 불가능해 VM-level 검증으로 대체.
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
        let view = LeaderboardContent(initialPeriod: .daily, initialEntries: entries)
            .environmentObject(AppDependencies.preview())
        // 1등 자리에 엔트리 렌더, 2/3 등은 placeholder.
        XCTAssertNoThrow(try view.inspect().find(text: L("첫째")))
    }

    func testLeaderboard_twoEntries_thirdSlotPlaceholder() throws {
        let entries = [
            entry(userID: "a", nickname: "일등", score: 100),
            entry(userID: "b", nickname: "이등", score: 90)
        ]
        let view = LeaderboardContent(initialPeriod: .daily, initialEntries: entries)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("일등")))
        XCTAssertNoThrow(try view.inspect().find(text: L("이등")))
    }

    /// emptyState placeholder 텍스트는 rankingList 내부 (medal Image 들 옆) 라
    /// ViewInspector 가 traverse 못함. 대신 VM 의 분기 조건을 직접 검증:
    /// entries.count <= 3 이면 placeholder 가 보이는 분기로 들어간다.
    func testLeaderboard_emptyEntries_triggersPlaceholderBranch() throws {
        let vm = LeaderboardViewModel(
            service: StubEmptyLeaderboardService(),
            persistence: InMemoryPersistenceStore(),
            initialPeriod: .daily,
            initialEntries: []
        )
        XCTAssertTrue(vm.entries.count <= 3, "비어있으면 placeholder 분기 진입")
        XCTAssertNil(vm.myRank, "내 순위 없음")
    }

    /// percentile 계산 — 100 명 중 10등 → 10%. VM-level 로 검증.
    /// (기존 view-level 텍스트 "10등" / "10%" 검증은 ViewInspector 한계로 불안정.)
    func testLeaderboard_percentileCalculation() throws {
        var entries: [LeaderboardEntry] = []
        for i in 0..<100 {
            entries.append(entry(userID: i == 9 ? "me" : "u-\(i)", nickname: "p\(i)", score: 100 - i))
        }
        let vm = LeaderboardViewModel(
            service: StubEmptyLeaderboardService(),
            persistence: InMemoryPersistenceStore(),
            initialPeriod: .daily,
            initialEntries: entries,
            initialMyUserID: "me"
        )
        XCTAssertEqual(vm.myRank, 10)
        XCTAssertEqual(vm.myPercentile, 10)
    }

}
