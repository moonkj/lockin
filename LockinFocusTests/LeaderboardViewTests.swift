import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

@MainActor
final class LeaderboardViewTests: XCTestCase {

    func testLeaderboardView_rendersPeriodTabs() throws {
        let view = LeaderboardView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: "일간"))
        XCTAssertNoThrow(try view.inspect().find(text: "주간"))
        XCTAssertNoThrow(try view.inspect().find(text: "월간"))
    }

    func testLeaderboardView_rendersTopThreeHeader() throws {
        let view = LeaderboardView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: "일간 Top 3"))
    }

    func testLeaderboardView_rendersSummaryStripLabels() throws {
        let view = LeaderboardView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: "참여자"))
        XCTAssertNoThrow(try view.inspect().find(text: "내 등수"))
        XCTAssertNoThrow(try view.inspect().find(text: "상위"))
    }

    func testLeaderboardView_hasCloseButton() throws {
        let view = LeaderboardView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(button: "닫기"))
    }

    func testLeaderboardView_emptyState_showsHint() throws {
        let view = LeaderboardView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: "아직 등록된 기록이 많지 않아요.\n오른쪽 위 ↑ 버튼으로 내 점수를 등록해보세요."))
    }

    func testLeaderboardView_placeholderMedals_renderRank() throws {
        let view = LeaderboardView().environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: "1등"))
        XCTAssertNoThrow(try view.inspect().find(text: "2등"))
        XCTAssertNoThrow(try view.inspect().find(text: "3등"))
    }
}
