import XCTest
@testable import LockinFocus

/// `FriendInviteLink` 은 `lockinfocus://friend?uid=X&nick=Y` 포맷을 왕복한다.
/// build → parse 라운드트립이 깨지면 다른 기기가 링크를 해석하지 못해 친구 추가가 실패하므로
/// 회귀 방지 차원에서 모든 경로를 가둔다.
final class FriendInviteLinkTests: XCTestCase {

    // MARK: - shareURL

    func testShareURL_rendersCanonicalScheme() {
        let url = FriendInviteLink.shareURL(myUserID: "uuid-1", myNickname: "집중러")
        XCTAssertEqual(url?.scheme, "lockinfocus")
        XCTAssertEqual(url?.host, "friend")
    }

    func testShareURL_encodesNicknameSafely() {
        let url = FriendInviteLink.shareURL(myUserID: "u", myNickname: "집중 러 & A")
        XCTAssertNotNil(url)
        // queryItems 가 실제 퍼센트 인코딩을 처리하는지.
        let comps = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        let nick = comps?.queryItems?.first(where: { $0.name == "nick" })?.value
        XCTAssertEqual(nick, "집중 러 & A")
    }

    func testShareURL_bothQueryItemsPresent() {
        let url = FriendInviteLink.shareURL(myUserID: "abc", myNickname: "nick")
        let items = URLComponents(url: url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertTrue(items.contains(where: { $0.name == "uid" && $0.value == "abc" }))
        XCTAssertTrue(items.contains(where: { $0.name == "nick" && $0.value == "nick" }))
    }

    // MARK: - parse (happy path)

    func testParse_validURL_returnsPayload() {
        let url = URL(string: "lockinfocus://friend?uid=u1&nick=tester")!
        let payload = FriendInviteLink.parse(url)
        XCTAssertEqual(payload?.userID, "u1")
        XCTAssertEqual(payload?.nickname, "tester")
    }

    func testParse_koreanNickname_preserved() {
        let url = URL(string: "lockinfocus://friend?uid=u1&nick=%EC%A7%91%EC%A4%91%EB%9F%AC")!
        XCTAssertEqual(FriendInviteLink.parse(url)?.nickname, "집중러")
    }

    // MARK: - parse (rejections)

    func testParse_wrongScheme_returnsNil() {
        let url = URL(string: "https://example.com/friend?uid=u1&nick=t")!
        XCTAssertNil(FriendInviteLink.parse(url))
    }

    func testParse_wrongHost_returnsNil() {
        let url = URL(string: "lockinfocus://stranger?uid=u1&nick=t")!
        XCTAssertNil(FriendInviteLink.parse(url))
    }

    func testParse_missingUID_returnsNil() {
        let url = URL(string: "lockinfocus://friend?nick=tester")!
        XCTAssertNil(FriendInviteLink.parse(url))
    }

    func testParse_missingNick_returnsNil() {
        let url = URL(string: "lockinfocus://friend?uid=u1")!
        XCTAssertNil(FriendInviteLink.parse(url))
    }

    func testParse_emptyUID_returnsNil() {
        let url = URL(string: "lockinfocus://friend?uid=&nick=tester")!
        XCTAssertNil(FriendInviteLink.parse(url))
    }

    func testParse_emptyNick_returnsNil() {
        let url = URL(string: "lockinfocus://friend?uid=u1&nick=")!
        XCTAssertNil(FriendInviteLink.parse(url))
    }

    // MARK: - Roundtrip

    func testRoundtrip_buildThenParse_preservesBothFields() {
        let built = FriendInviteLink.shareURL(myUserID: "my-long-uuid-abc", myNickname: "친구A")!
        let parsed = FriendInviteLink.parse(built)
        XCTAssertEqual(parsed?.userID, "my-long-uuid-abc")
        XCTAssertEqual(parsed?.nickname, "친구A")
    }

    func testRoundtrip_specialCharactersSurvive() {
        let built = FriendInviteLink.shareURL(myUserID: "u", myNickname: "A+B=C?")!
        let parsed = FriendInviteLink.parse(built)
        XCTAssertEqual(parsed?.nickname, "A+B=C?")
    }
}
