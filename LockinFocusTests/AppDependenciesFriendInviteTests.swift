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
        deps.requestFriendInvite(FriendInviteLink.Payload(userID: "f1", nickname: "AA"))
        deps.acceptFriendInvite()
        // 200ms global throttle 우회를 위해 약간의 sleep.
        Thread.sleep(forTimeInterval: 0.25)
        deps.requestFriendInvite(FriendInviteLink.Payload(userID: "f2", nickname: "BB"))
        deps.acceptFriendInvite()
        Thread.sleep(forTimeInterval: 0.25)
        deps.requestFriendInvite(FriendInviteLink.Payload(userID: "f3", nickname: "CC"))
        deps.acceptFriendInvite()
        XCTAssertEqual(deps.persistence.friendUserIDs.count, 3)
        XCTAssertEqual(deps.persistence.friendNicknameCache.count, 3)
    }

    // MARK: - Spam / DoS 방어

    func testRequestFriendInvite_sameUIDTwiceWithin1s_secondIgnored() {
        let deps = makeDeps()
        let payload = FriendInviteLink.Payload(userID: "f1", nickname: "A")
        deps.requestFriendInvite(payload)
        deps.consumeFriendInvite()  // 첫 alert 취소 시뮬.
        // 곧바로 같은 링크가 다시 들어와도 무시돼야 (악성 리다이렉트 루프 보호).
        deps.requestFriendInvite(payload)
        XCTAssertNil(deps.pendingFriendInvite)
    }

    func testRequestFriendInvite_differentUID_after200ms_notDebounced() {
        let deps = makeDeps()
        deps.requestFriendInvite(FriendInviteLink.Payload(userID: "a", nickname: "AA"))
        deps.consumeFriendInvite()
        // 200ms global throttle 통과 후엔 다른 UID 정상 처리.
        Thread.sleep(forTimeInterval: 0.25)
        deps.requestFriendInvite(FriendInviteLink.Payload(userID: "b", nickname: "BB"))
        XCTAssertEqual(deps.pendingFriendInvite?.userID, "b")
    }

    func testAcceptFriendInvite_capAtMaxCount() {
        let deps = makeDeps()
        let max = AppDependencies.maxFriendCount
        // 상한까지 채운 상태.
        deps.persistence.friendUserIDs = (0..<max).map { "f\($0)" }
        XCTAssertEqual(deps.persistence.friendUserIDs.count, max)
        deps.requestFriendInvite(FriendInviteLink.Payload(userID: "overflow", nickname: "O"))
        deps.acceptFriendInvite()
        XCTAssertEqual(deps.persistence.friendUserIDs.count, max, "상한 초과 시 총 개수 유지")
        XCTAssertTrue(deps.persistence.friendUserIDs.contains("overflow"), "새 항목은 들어가야")
        XCTAssertFalse(deps.persistence.friendUserIDs.contains("f0"), "가장 오래된 항목이 밀려나야")
    }

    func testAcceptFriendInvite_nicknameCacheIsPruned() {
        let deps = makeDeps()
        // 친구가 아닌 UID 의 잔재 캐시가 남아있는 상황.
        deps.persistence.friendUserIDs = ["f1"]
        deps.persistence.friendNicknameCache = ["f1": "유지", "stale": "지워야"]
        deps.requestFriendInvite(FriendInviteLink.Payload(userID: "f2", nickname: "새이름"))
        deps.acceptFriendInvite()
        XCTAssertEqual(deps.persistence.friendNicknameCache["stale"], nil, "친구 목록에 없는 키는 pruning")
        XCTAssertEqual(deps.persistence.friendNicknameCache["f1"], "유지")
        XCTAssertEqual(deps.persistence.friendNicknameCache["f2"], "새이름")
    }

    // MARK: - URL nickname sanitization (security)

    func testAcceptFriendInvite_bidiNickname_isCleanedNotAnonymized() {
        let deps = makeDeps()
        // bidi 격리 문자 자체는 strip 되어 깨끗한 닉네임으로 통과 (의도된 동작).
        // 즉, "\u{2068}공격\u{2069}" 는 "공격" 으로 정리되어 cache 에 저장.
        let evil = "\u{2068}공격\u{2069}"
        deps.requestFriendInvite(FriendInviteLink.Payload(userID: "atk1", nickname: evil))
        deps.acceptFriendInvite()
        let cached = deps.persistence.friendNicknameCache["atk1"] ?? ""
        XCTAssertEqual(cached, "공격", "bidi 는 strip 되어 cleaned 형태 저장")
        XCTAssertFalse(cached.contains("\u{2068}"))
        XCTAssertFalse(cached.contains("\u{2069}"))
    }

    func testAcceptFriendInvite_newlineNickname_storesAnonymousLabel() {
        let deps = makeDeps()
        // 개행 주입 — Leaderboard 행을 세로로 늘리는 공격.
        deps.requestFriendInvite(FriendInviteLink.Payload(userID: "atk2", nickname: "악성\n둘째줄"))
        deps.acceptFriendInvite()
        let cached = deps.persistence.friendNicknameCache["atk2"] ?? ""
        XCTAssertFalse(cached.contains("\n"))
    }

    func testAcceptFriendInvite_validNickname_storesAsIs() {
        let deps = makeDeps()
        deps.requestFriendInvite(FriendInviteLink.Payload(userID: "ok1", nickname: "친구A"))
        deps.acceptFriendInvite()
        XCTAssertEqual(deps.persistence.friendNicknameCache["ok1"], "친구A")
    }

    func testSafeDisplayName_validInput_returnsCleaned() {
        XCTAssertEqual(AppDependencies.safeDisplayName(for: "정상"), "정상")
    }

    func testSafeDisplayName_invalidInput_withPosition_anonymizesWithIndex() {
        let evil = "\u{2068}\u{2069}"
        XCTAssertEqual(AppDependencies.safeDisplayName(for: evil, position: 3), "친구 3")
    }

    func testSafeDisplayName_invalidInput_noPosition_genericFriend() {
        XCTAssertEqual(AppDependencies.safeDisplayName(for: "\n"), "친구")
    }

    // MARK: - Global throttle (다른 UID 폭주 방어)

    func testRequestFriendInvite_differentUIDs_within200ms_throttled() {
        let deps = makeDeps()
        deps.requestFriendInvite(FriendInviteLink.Payload(userID: "a", nickname: "A"))
        // 즉시 다른 UID 호출 — global throttle 에 막혀야.
        deps.requestFriendInvite(FriendInviteLink.Payload(userID: "b", nickname: "B"))
        XCTAssertEqual(deps.pendingFriendInvite?.userID, "a", "두번째 호출은 200ms throttle 로 무시")
    }
}
