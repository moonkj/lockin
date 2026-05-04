import XCTest
@testable import LockinFocus

@MainActor
final class RouterStoreTests: XCTestCase {

    // MARK: - Route

    func testRequestRoute_setsPendingRoute() {
        let store = makeStore()
        XCTAssertNil(store.pendingRoute)
        store.requestRoute(.weeklyReport)
        XCTAssertEqual(store.pendingRoute, .weeklyReport)
    }

    func testConsumeRoute_clearsPendingRoute() {
        let store = makeStore()
        store.requestRoute(.startFocus)
        store.consumeRoute()
        XCTAssertNil(store.pendingRoute)
    }

    func testRequestRoute_overwritesExisting() {
        let store = makeStore()
        store.requestRoute(.weeklyReport)
        store.requestRoute(.endFocus)
        XCTAssertEqual(store.pendingRoute, .endFocus)
    }

    // MARK: - Friend Invite — Self detection

    func testRequestFriendInvite_selfUID_isIgnored() {
        let myID = "my-uid-123"
        let store = makeStore(myUserID: myID)
        let payload = FriendInviteLink.Payload(userID: myID, nickname: "나")
        store.requestFriendInvite(payload)
        XCTAssertNil(store.pendingFriendInvite)
    }

    func testRequestFriendInvite_otherUID_setsPending() {
        let store = makeStore(myUserID: "me")
        let payload = FriendInviteLink.Payload(userID: "friend-1", nickname: "친구일")
        store.requestFriendInvite(payload)
        XCTAssertEqual(store.pendingFriendInvite, payload)
    }

    // MARK: - Friend Invite — Throttle

    func testRequestFriendInvite_within200ms_globalThrottleIgnoresSecond() {
        let store = makeStore(myUserID: "me")
        let p1 = FriendInviteLink.Payload(userID: "friend-A", nickname: "에이")
        let p2 = FriendInviteLink.Payload(userID: "friend-B", nickname: "비비")
        store.requestFriendInvite(p1)
        // 즉시 다른 UID 로 요청 — 200ms 내 글로벌 throttle 로 무시.
        store.requestFriendInvite(p2)
        XCTAssertEqual(store.pendingFriendInvite, p1)
    }

    func testRequestFriendInvite_sameUID_within1s_isIgnored() {
        let store = makeStore(myUserID: "me")
        let p = FriendInviteLink.Payload(userID: "friend-same", nickname: "동일")
        store.requestFriendInvite(p)
        store.consumeFriendInvite()
        // 같은 UID 1초 내 재요청은 무시.
        store.requestFriendInvite(p)
        XCTAssertNil(store.pendingFriendInvite)
    }

    func testRequestFriendInvite_after200ms_differentUID_passesThrottle() {
        let store = makeStore(myUserID: "me")
        let p1 = FriendInviteLink.Payload(userID: "friend-A", nickname: "에이")
        store.requestFriendInvite(p1)
        store.consumeFriendInvite()
        Thread.sleep(forTimeInterval: 0.25)
        let p2 = FriendInviteLink.Payload(userID: "friend-B", nickname: "비비")
        store.requestFriendInvite(p2)
        XCTAssertEqual(store.pendingFriendInvite, p2)
    }

    // MARK: - acceptFriendInvite

    func testAcceptFriendInvite_addsToFriendIDs_andCachesNickname() {
        let persistence = InMemoryPersistenceStore()
        let store = RouterStore(persistence: persistence) { "me" }
        let p = FriendInviteLink.Payload(userID: "F1", nickname: "친구하나")
        store.requestFriendInvite(p)
        store.acceptFriendInvite()
        XCTAssertEqual(persistence.friendUserIDs, ["F1"])
        XCTAssertEqual(persistence.friendNicknameCache["F1"], "친구하나")
        XCTAssertNil(store.pendingFriendInvite)
    }

    func testAcceptFriendInvite_duplicate_doesNotDouble() {
        let persistence = InMemoryPersistenceStore()
        persistence.friendUserIDs = ["F1"]
        persistence.friendNicknameCache = ["F1": "기존이름"]
        let store = RouterStore(persistence: persistence) { "me" }
        let p = FriendInviteLink.Payload(userID: "F1", nickname: "다시")
        store.requestFriendInvite(p)
        store.acceptFriendInvite()
        XCTAssertEqual(persistence.friendUserIDs, ["F1"])
        // 닉네임은 갱신됨 (validator 통과 시).
        XCTAssertEqual(persistence.friendNicknameCache["F1"], "다시")
    }

    func testAcceptFriendInvite_atMaxCapacity_evictsOldest() {
        let persistence = InMemoryPersistenceStore()
        let cap = RouterStore.maxFriendCount
        persistence.friendUserIDs = (0..<cap).map { "F\($0)" }
        let store = RouterStore(persistence: persistence) { "me" }
        let p = FriendInviteLink.Payload(userID: "NEW", nickname: "신입")
        store.requestFriendInvite(p)
        store.acceptFriendInvite()
        XCTAssertEqual(persistence.friendUserIDs.count, cap)
        XCTAssertFalse(persistence.friendUserIDs.contains("F0"))
        XCTAssertTrue(persistence.friendUserIDs.contains("NEW"))
    }

    func testAcceptFriendInvite_prunesCacheToCurrentFriends() {
        let persistence = InMemoryPersistenceStore()
        persistence.friendUserIDs = ["F1"]
        // 친구 목록에 없는 stale 캐시 항목.
        persistence.friendNicknameCache = ["F1": "원래", "GHOST": "유령"]
        let store = RouterStore(persistence: persistence) { "me" }
        let p = FriendInviteLink.Payload(userID: "F2", nickname: "친구둘")
        store.requestFriendInvite(p)
        store.acceptFriendInvite()
        XCTAssertNil(persistence.friendNicknameCache["GHOST"])
        XCTAssertEqual(persistence.friendNicknameCache["F2"], "친구둘")
    }

    func testAcceptFriendInvite_noPending_isNoOp() {
        let persistence = InMemoryPersistenceStore()
        let store = RouterStore(persistence: persistence) { "me" }
        store.acceptFriendInvite()
        XCTAssertTrue(persistence.friendUserIDs.isEmpty)
    }

    func testConsumeFriendInvite_clears() {
        let store = makeStore(myUserID: "me")
        let p = FriendInviteLink.Payload(userID: "F1", nickname: "하나")
        store.requestFriendInvite(p)
        store.consumeFriendInvite()
        XCTAssertNil(store.pendingFriendInvite)
    }

    // MARK: - safeDisplayName

    func testSafeDisplayName_validNickname_returnsCleaned() {
        XCTAssertEqual(RouterStore.safeDisplayName(for: "정상이름"), "정상이름")
    }

    func testSafeDisplayName_invalidNickname_withPosition_returnsAnonLabel() {
        XCTAssertEqual(RouterStore.safeDisplayName(for: "a", position: 3), "친구 3")
    }

    func testSafeDisplayName_invalidNickname_noPosition_returnsGenericLabel() {
        XCTAssertEqual(RouterStore.safeDisplayName(for: "a"), "친구")
    }

    // MARK: - Helpers

    private func makeStore(myUserID: String = "me") -> RouterStore {
        RouterStore(persistence: InMemoryPersistenceStore()) { myUserID }
    }
}
