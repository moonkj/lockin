import Foundation
import Security

/// 앱 비밀번호(4~6자리 숫자) 를 Keychain 에 안전하게 저장·검증한다.
/// 디바이스 암호와 별개의 **앱 내부 비번**. 기기를 공유해도 이 비번만 노출 안 되면 엄격 모드
/// 해제 권한이 없다.
///
/// 평문 저장을 피하기 위해 Keychain 의 `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
/// 접근 클래스를 사용한다 — 기기 잠금 해제 상태일 때만 읽히고 iCloud 백업 대상도 아님.
enum AppPasscodeStore {
    private static let service = "com.moonkj.LockinFocus.appPasscode"
    private static let account = "primary"

    /// 현재 비번이 설정돼 있는지.
    static var isSet: Bool { read() != nil }

    /// 비번을 저장. 기존 값이 있으면 덮어쓴다.
    @discardableResult
    static func save(_ passcode: String) -> Bool {
        guard let data = passcode.data(using: .utf8) else { return false }
        // 중복 제거.
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

    /// 입력값이 저장된 비번과 일치하는지.
    static func verify(_ input: String) -> Bool {
        guard let stored = read() else { return false }
        return stored == input
    }

    /// 비번 삭제 (엄격 모드 해제 성공 시 초기화 용도로는 사용하지 말 것).
    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    private static func read() -> String? {
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
