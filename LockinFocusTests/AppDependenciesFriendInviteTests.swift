import XCTest
@testable import LockinFocus

/// AppDependencies 의 친구 초대 생명주기 — 요청/수락/취소/자기자신 차단.
/// 모든 상태 전이가 PersistenceStore 와 `pendingFriendInvite` 사이를 정합하게 유지해야.
@MainActor
final class AppDependenciesFriendInviteTests: XCTestCase {

    private func makeDeps() -> AppDependencies {
        let deps = AppDependencies.preview()
        // 프리뷰는 leaderboardUserID = "preview-user"
        deps.persistence.friendUserIDs = []
        deps.persistence.friendNicknameCache = [:]
        return deps
    }

    // MARK: - requestFriendInvite

    func testRequestFriendInvite_strangerID_setsPending() {
        let deps = makeDeps()
        let payload = FriendInviteLink.Payload(userID: "friend-1", nickname: "친구A")
        deps.requestFriendInvite(payload)
        XCTAssertEqual(deps.pendingFriendInvite?.userID, "friend-1")
        XCTAssertEqual(deps.pendingFriendInvite?.nickname, "친구A")
    }

    func testRequestFriendInvite_selfID_isIgnored() {
        let deps = makeDeps()
        // preview userID = "preview-user"
        let payload = FriendInviteLink.Payload(userID: "preview-user", nickname: "내자신")
        deps.requestFriendInvite(payload)
        XCTAssertNil(deps.pendingFriendInvite, "자기 자신 초대는 무시돼야")
    }

    // MARK: - consumeFriendInvite

    func testConsumeFriendInvite_clearsPending_withoutAddingFriend() {
        let deps = makeDeps()
        let payload = FriendInviteLink.Payload(userID: "f1", nickname: "X")
        deps.requestFriendInvite(payload)
        deps.consumeFriendInvite()
        XCTAssertNil(deps.pendingFriendInvite)
        XCTAssertTrue(deps.persistence.friendUserIDs.isEmpty, "취소는 친구 추가하지 않음")
    }

    // MARK: - acceptFriendInvite

    func testAcceptFriendInvite_addsToFriendsList() {
        let deps = makeDeps()
        deps.requestFriendInvite(FriendInviteLink.Payload(userID: "f1", nickname: "친구A"))
        deps.acceptFriendInvite()
        XCTAssertEqual(deps.persistence.friendUserIDs, ["f1"])
    }

    func testAcceptFriendInvite_cachesNickname() {
        let deps = makeDeps()
        deps.requestFriendInvite(FriendInviteLink.Payload(userID: "f2", nickname: "친구B"))
        deps.acceptFriendInvite()
        XCTAssertEqual(deps.persistence.friendNicknameCache["f2"], "친구B")
    }

    func testAcceptFriendInvite_clearsPending() {
        let deps = makeDeps()
        deps.requestFriendInvite(FriendInviteLink.Payload(userID: "f3", nickname: "친구C"))
        deps.acceptFriendInvite()
        XCTAssertNil(deps.pendingFriendInvite)
    }

    func testAcceptFriendInvite_noPending_isNoOp() {
        let deps = makeDeps()
        deps.acceptFriendInvite()
        XCTAssertTrue(deps.persistence.friendUserIDs.isEmpty)
        XCTAssertTrue(deps.persistence.friendNicknameCache.isEmpty)
    }

    func testAcceptFriendInvite_duplicateUID_doesNotDuplicate() {
        let deps = makeDeps()
        deps.persistence.friendUserIDs = ["f1"]
        deps.requestFriendInvite(FriendInviteLink.Payload(userID: "f1", nickname: "이름변경"))
        deps.acceptFriendInvite()
        XCTAssertEqual(deps.persistence.friendUserIDs, ["f1"], "중복 userID 는 한 번만")
    }

    func testAcceptFriendInvite_duplicateUID_updatesNicknameCache() {
        let deps = makeDeps()
        deps.persistence.friendUserIDs = ["f1"]
        deps.persistence.friendNicknameCache = ["f1": "옛이름"]
        deps.requestFriendInvite(FriendInviteLink.Payload(userID: "f1", nickname: "새이름"))
        deps.acceptFriendInvite()
        XCTAssertEqual(deps.persistence.friendNicknameCache["f1"], "새이름")
    }

    // MARK: - Multi-friend accumulation

    func testAcceptFriendInvite_multipleUniqueFriends_accumulate() {
        let deps = makeDeps()
        deps.requestFriendInvite(FriendInviteLink.Payload(userID: "f1", nickname: "A"))
        deps.acceptFriendInvite()
        deps.requestFriendInvite(FriendInviteLink.Payload(userID: "f2", nickname: "B"))
        deps.acceptFriendInvite()
        deps.requestFriendInvite(FriendInviteLink.Payload(userID: "f3", nickname: "C"))
        deps.acceptFriendInvite()
        XCTAssertEqual(deps.persistence.friendUserIDs.count, 3)
        XCTAssertEqual(deps.persistence.friendNicknameCache.count, 3)
    }
}
