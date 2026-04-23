import Foundation

/// `NSUbiquitousKeyValueStore` 얇은 래퍼. 같은 Apple ID 로 로그인된 기기 간에
/// 값을 자동 동기화한다(닉네임·leaderboardUserID 공유용).
/// 총 1MB · 키 1MB 한도. 텍스트 값만 다룬다.
enum ICloudKeyValueStore {
    private static let store = NSUbiquitousKeyValueStore.default

    enum Keys {
        static let leaderboardUserID = "cloudLeaderboardUserID"
        static let nickname = "cloudNickname"
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

    @discardableResult
    static func synchronize() -> Bool {
        store.synchronize()
    }
}
