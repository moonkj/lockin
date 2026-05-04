import Foundation

/// `NSUbiquitousKeyValueStore` 얇은 래퍼. 같은 Apple ID 로 로그인된 기기 간에
/// 값을 자동 동기화한다(닉네임·leaderboardUserID·친구 목록 공유용).
/// 총 1MB · 키 1MB 한도. 텍스트 값만 다룬다.
enum ICloudKeyValueStore {
    private static let store = NSUbiquitousKeyValueStore.default

    enum Keys {
        static let leaderboardUserID = "cloudLeaderboardUserID"
        static let nickname = "cloudNickname"
        /// 친구 userID 배열을 JSON 으로 저장. UUID(36자) × 500 ≈ 18KB.
        static let friendUserIDs = "cloudFriendUserIDs"
        /// 친구 닉네임 캐시 사전 [userID: nickname] 을 JSON 으로 저장.
        static let friendNicknameCache = "cloudFriendNicknameCache"
    }

    static func string(for key: String) -> String? {
        let v = store.string(forKey: key)
        return (v?.isEmpty ?? true) ? nil : v
    }

    static func set(_ value: String?, for key: String) {
        if let value, !value.isEmpty {
            store.set(value, forKey: key)
        } else {
            store.removeObject(forKey: key)
        }
        store.synchronize()
    }

    /// String 배열 ↔ JSON 직렬화. 빈 배열은 nil 로 저장.
    static func stringArray(for key: String) -> [String]? {
        guard let raw = string(for: key),
              let data = raw.data(using: .utf8),
              let arr = try? JSONDecoder().decode([String].self, from: data)
        else { return nil }
        return arr
    }

    static func setStringArray(_ value: [String]?, for key: String) {
        guard let value, !value.isEmpty,
              let data = try? JSONEncoder().encode(value),
              let json = String(data: data, encoding: .utf8)
        else {
            set(nil, for: key)
            return
        }
        set(json, for: key)
    }

    /// [String: String] 사전 ↔ JSON 직렬화.
    static func stringDictionary(for key: String) -> [String: String]? {
        guard let raw = string(for: key),
              let data = raw.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return nil }
        return dict
    }

    static func setStringDictionary(_ value: [String: String]?, for key: String) {
        guard let value, !value.isEmpty,
              let data = try? JSONEncoder().encode(value),
              let json = String(data: data, encoding: .utf8)
        else {
            set(nil, for: key)
            return
        }
        set(json, for: key)
    }

    @discardableResult
    static func synchronize() -> Bool {
        store.synchronize()
    }
}
