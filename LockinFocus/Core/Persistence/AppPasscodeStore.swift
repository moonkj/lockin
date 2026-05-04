import Foundation
import Security
import CryptoKit

/// 앱 비밀번호(6자리 숫자) 를 Keychain 에 안전하게 저장·검증한다.
/// 디바이스 암호와 별개의 **앱 내부 비번**. 기기를 공유해도 이 비번만 노출 안 되면 엄격 모드
/// 해제 권한이 없다.
///
/// **저장 방식 (v2)**: 평문이 아니라 `SHA256(salt || passcode)` + 랜덤 per-install salt.
/// Keychain 자체도 암호화돼 있지만 디버거 · jailbreak · Keychain dump 같은 경로로
/// 값이 읽혀도 원본을 복원할 수 없게 추가 방어층을 둔다.
/// v1 (평문 저장) 과의 호환: 읽어봤는데 hash 포맷이 아니면 평문으로 간주해 검증하고,
/// 검증 성공 즉시 hash 로 re-save 해 마이그레이션.
///
/// Keychain 항목은 `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` — 기기 잠금 해제
/// 상태일 때만 읽히고 iCloud 백업 대상도 아님.
enum AppPasscodeStore {
    private static let service = "com.moonkj.LockinFocus.appPasscode"
    private static let account = "primary"
    /// 해싱 포맷 prefix — 읽은 값이 hash 인지 legacy 평문인지 구분하는 sentinel.
    /// 포맷: `v2:<hex salt 32>:<hex sha256 64>`
    private static let hashPrefix = "v2:"

    /// 현재 비번이 설정돼 있는지.
    static var isSet: Bool { readRaw() != nil }

    /// 비번을 저장. 기존 값이 있으면 덮어쓴다.
    @discardableResult
    static func save(_ passcode: String) -> Bool {
        let payload = makeHashPayload(passcode: passcode)
        return writeRaw(payload)
    }

    /// 입력값이 저장된 비번과 일치하는지. legacy 평문도 허용 (자동 migration).
    /// Brute-force 방어: 5회 연속 실패 시 5분 lockout. lockout 중 호출은 항상 false.
    static func verify(_ input: String) -> Bool {
        if isLockedOut() { return false }
        guard let stored = readRaw() else { return false }
        let ok: Bool
        if stored.hasPrefix(hashPrefix) {
            ok = verifyHash(input: input, payload: stored)
        } else {
            // v1 legacy: constant-time 비교 후 성공 시 hash 로 re-save.
            let legacyMatch = constantTimeEquals(stored, input)
            if legacyMatch { _ = save(input) }
            ok = legacyMatch
        }
        if ok {
            resetFailureCount()
        } else {
            recordFailure()
        }
        return ok
    }

    // MARK: - Brute-force lockout

    /// 누적 실패 횟수 + lockout 만료 timestamp 를 App Group UserDefaults 에 보관.
    /// Keychain 보다 UserDefaults 가 적합 — 사용자가 앱 삭제 시 함께 사라져도 문제 없음
    /// (실패 카운터가 사라져도 보안 약화 아님 — 비번 자체는 keychain 에).
    private enum LockoutKeys {
        static let failureCount = "appPasscodeFailureCount"
        static let lockoutUntil = "appPasscodeLockoutUntil"
    }
    static let maxFailuresBeforeLockout = 5
    static let lockoutSeconds: TimeInterval = 5 * 60

    /// 현재 lockout 중이면 true. 만료 시각이 지났으면 자동으로 false (정리는 다음 verify 시).
    static func isLockedOut(now: Date = Date()) -> Bool {
        guard let d = sharedDefaults() else { return false }
        let until = d.double(forKey: LockoutKeys.lockoutUntil)
        return until > now.timeIntervalSince1970
    }

    /// lockout 까지 남은 초. 0 이하면 풀림.
    static func lockoutRemainingSeconds(now: Date = Date()) -> TimeInterval {
        guard let d = sharedDefaults() else { return 0 }
        let until = d.double(forKey: LockoutKeys.lockoutUntil)
        return max(0, until - now.timeIntervalSince1970)
    }

    private static func recordFailure(now: Date = Date()) {
        guard let d = sharedDefaults() else { return }
        let count = d.integer(forKey: LockoutKeys.failureCount) + 1
        d.set(count, forKey: LockoutKeys.failureCount)
        if count >= maxFailuresBeforeLockout {
            d.set(now.timeIntervalSince1970 + lockoutSeconds, forKey: LockoutKeys.lockoutUntil)
            d.set(0, forKey: LockoutKeys.failureCount)  // lockout 진입 후 카운터 reset
        }
    }

    private static func resetFailureCount() {
        guard let d = sharedDefaults() else { return }
        d.set(0, forKey: LockoutKeys.failureCount)
        d.removeObject(forKey: LockoutKeys.lockoutUntil)
    }

    private static func sharedDefaults() -> UserDefaults? {
        UserDefaults(suiteName: "group.com.moonkj.LockinFocus")
    }

    /// 비번 삭제.
    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Hashing

    private static func makeHashPayload(passcode: String) -> String {
        var saltBytes = [UInt8](repeating: 0, count: 16)
        let rc = SecRandomCopyBytes(kSecRandomDefault, saltBytes.count, &saltBytes)
        // SecRandom 실패는 극히 드물다 — 그래도 fallback 으로 UUID bytes 사용.
        if rc != errSecSuccess {
            let uuid = UUID().uuid
            saltBytes = [
                uuid.0, uuid.1, uuid.2, uuid.3, uuid.4, uuid.5, uuid.6, uuid.7,
                uuid.8, uuid.9, uuid.10, uuid.11, uuid.12, uuid.13, uuid.14, uuid.15
            ]
        }
        let salt = Data(saltBytes)
        let digest = sha256(salt: salt, passcode: passcode)
        return "\(hashPrefix)\(salt.hexString):\(digest.hexString)"
    }

    private static func verifyHash(input: String, payload: String) -> Bool {
        let parts = payload.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count == 3,
              let saltHex = parts[safe: 1],
              let expectedHex = parts[safe: 2],
              let salt = Data(hex: String(saltHex))
        else { return false }
        let actual = sha256(salt: salt, passcode: input).hexString
        return constantTimeEquals(String(expectedHex), actual)
    }

    private static func sha256(salt: Data, passcode: String) -> Data {
        var hasher = SHA256()
        hasher.update(data: salt)
        hasher.update(data: Data(passcode.utf8))
        return Data(hasher.finalize())
    }

    /// 타이밍 공격 방지용 상수시간 비교. 짧은 6자리 비번이라 실제 위험은 낮지만 비용 0.
    private static func constantTimeEquals(_ a: String, _ b: String) -> Bool {
        let ab = Array(a.utf8)
        let bb = Array(b.utf8)
        if ab.count != bb.count { return false }
        var diff: UInt8 = 0
        for i in 0..<ab.count {
            diff |= ab[i] ^ bb[i]
        }
        return diff == 0
    }

    // MARK: - Keychain IO

    private static func writeRaw(_ value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(base as CFDictionary)

        var attrs = base
        attrs[kSecValueData as String] = data
        attrs[kSecAttrAccessible as String] =
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        return SecItemAdd(attrs as CFDictionary, nil) == errSecSuccess
    }

    private static func readRaw() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let str = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return str
    }
}

// MARK: - Small utilities

private extension Data {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }

    init?(hex: String) {
        let clean = hex.lowercased()
        guard clean.count % 2 == 0 else { return nil }
        var bytes: [UInt8] = []
        bytes.reserveCapacity(clean.count / 2)
        var idx = clean.startIndex
        while idx < clean.endIndex {
            let next = clean.index(idx, offsetBy: 2)
            guard let b = UInt8(clean[idx..<next], radix: 16) else { return nil }
            bytes.append(b)
            idx = next
        }
        self.init(bytes)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
