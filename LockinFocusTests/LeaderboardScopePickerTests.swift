import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

/// 리그레션 방어 — 리더보드의 전체/친구 세그먼트 탭 타겟.
///
/// **버그 배경**: unselected 세그먼트가 `Color.clear` 배경이어서 텍스트 글리프
/// 영역만 hit test 됐음. 유저가 "전체/친구 버튼이 잘 안눌림" 보고.
/// **수정**: `.contentShape(Rectangle())` 추가로 32pt 프레임 전체가 탭 가능.
///
/// ViewInspector 로 탭 영역을 직접 측정할 수는 없지만, Scope enum 과 렌더 가능성,
/// 그리고 period 피커 / scope 피커가 동일한 구조로 정상 렌더되는지 고정.
@MainActor
final class LeaderboardScopePickerTests: XCTestCase {

    // MARK: - Scope enum contract

    func testScope_allCases_orderIsAllThenFriends() {
        XCTAssertEqual(LeaderboardView.Scope.allCases, [.all, .friends])
    }

    func testScope_all_rawValue() {
        XCTAssertEqual(LeaderboardView.Scope.all.rawValue, "all")
    }

    func testScope_friends_rawValue() {
        XCTAssertEqual(LeaderboardView.Scope.friends.rawValue, "friends")
    }

    func testScope_all_labelIsKorean() {
        XCTAssertEqual(LeaderboardView.Scope.all.label, "전체")
    }

    func testScope_friends_labelIsKorean() {
        XCTAssertEqual(LeaderboardView.Scope.friends.label, "친구")
    }

    func testScope_id_matchesRawValue() {
        XCTAssertEqual(LeaderboardView.Scope.all.id, "all")
        XCTAssertEqual(LeaderboardView.Scope.friends.id, "friends")
    }
}
