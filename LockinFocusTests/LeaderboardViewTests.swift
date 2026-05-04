import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

@MainActor
final class LeaderboardViewTests: XCTestCase {

    func testLeaderboardView_rendersPeriodTabs() throws {
        let view = LeaderboardContent(deps: AppDependencies.preview()).environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("일간")))
        XCTAssertNoThrow(try view.inspect().find(text: L("주간")))
        XCTAssertNoThrow(try view.inspect().find(text: L("월간")))
    }

    func testLeaderboardView_rendersTopThreeHeader() throws {
        let view = LeaderboardContent(deps: AppDependencies.preview()).environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("일간 Top 3")))
    }

    func testLeaderboardView_rendersSummaryStripLabels() throws {
        let view = LeaderboardContent(deps: AppDependencies.preview()).environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("참여자")))
        XCTAssertNoThrow(try view.inspect().find(text: L("내 등수")))
        XCTAssertNoThrow(try view.inspect().find(text: L("상위")))
    }

    func testLeaderboardView_hasCloseButton() throws {
        let view = LeaderboardContent(deps: AppDependencies.preview()).environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(button: L("닫기")))
    }

    func testLeaderboardView_emptyState_showsHint() throws {
        let view = LeaderboardContent(deps: AppDependencies.preview()).environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("아직 등록된 기록이 많지 않아요.\n오른쪽 위 ↑ 버튼으로 내 점수를 등록해보세요.")))
    }

    func testLeaderboardView_placeholderMedals_renderRank() throws {
        let view = LeaderboardContent(deps: AppDependencies.preview()).environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("1등")))
        XCTAssertNoThrow(try view.inspect().find(text: L("2등")))
        XCTAssertNoThrow(try view.inspect().find(text: L("3등")))
    }
}
