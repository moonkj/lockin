import Foundation

/// 친구 초대 딥링크.
///
/// URL 포맷: `lockinfocus://friend?uid=<UUID>&nick=<percent-encoded nickname>`
///
/// 공유 쪽 사용자는 자기 userID + 닉네임을 담아 `shareURL(...)` 로 링크를 만들고,
/// 수신 쪽 기기는 `parse(_:)` 로 유효한 링크인지 검증한 뒤 친구 목록에 추가한다.
enum FriendInviteLink {
    struct Payload: Equatable {
        let userID: String
        let nickname: String
    }

    /// 내 정보를 담은 초대 URL 생성.
    static func shareURL(myUserID: String, myNickname: String) -> URL? {
        var comps = URLComponents()
        comps.scheme = "lockinfocus"
        comps.host = "friend"
        comps.queryItems = [
            URLQueryItem(name: "uid", value: myUserID),
            URLQueryItem(name: "nick", value: myNickname)
        ]
        return comps.url
    }

    /// URL 을 파싱해 친구 초대 payload 를 반환. 유효하지 않으면 nil.
    static func parse(_ url: URL) -> Payload? {
        guard url.scheme == "lockinfocus", url.host == "friend" else { return nil }
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        let items = comps.queryItems ?? []
        guard let uid = items.first(where: { $0.name == "uid" })?.value, !uid.isEmpty,
              let nick = items.first(where: { $0.name == "nick" })?.value, !nick.isEmpty
        else { return nil }
        return Payload(userID: uid, nickname: nick)
    }
}
