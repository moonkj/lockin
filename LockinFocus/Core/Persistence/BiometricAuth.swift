import Foundation
import LocalAuthentication

/// 생체 인증 래퍼. Face ID / Touch ID 를 사용해 앱 비밀번호 입력을 대체한다.
///
/// 정책: `.deviceOwnerAuthenticationWithBiometrics` — 기기 패스코드 fallback 은 의도적으로
/// 끄고, 실패 시 우리 앱의 6자리 비번 입력으로 돌려보낸다. 이유: 기기 패스코드를 아는
/// 사람이 생체 실패 시 자동으로 통과하면 "앱 내부 비번" 이라는 설계 목적(기기를
/// 공유해도 내 앱 엄격 모드는 내가 지킨다) 이 깨진다.
enum BiometricAuth {
    /// 이 기기에서 Face ID / Touch ID 를 쓸 수 있는지.
    /// `biometryType` 에서 `.none` 이 아니고 `canEvaluatePolicy` 도 true 여야 사용 가능.
    static var isAvailable: Bool {
        let ctx = LAContext()
        var err: NSError?
        let ok = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
        return ok && ctx.biometryType != .none
    }

    /// 현재 기기 생체 종류.
    static var biometryType: LABiometryType {
        let ctx = LAContext()
        var err: NSError?
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
        return ctx.biometryType
    }

    /// 생체 인증 수행. 성공 시 completion(true), 실패/취소 시 completion(false)
    /// (모든 실패 케이스는 UI 가 6자리 비번 fallback 을 띄우도록 일관 처리).
    static func authenticate(
        reason: String = "엄격 모드를 해제할 때 본인 확인에 사용돼요.",
        completion: @escaping (Bool) -> Void
    ) {
        let ctx = LAContext()
        // 생체 실패 시 바로 우리 앱 비번으로 fallback — 시스템 passcode 우회 경로 차단.
        ctx.localizedFallbackTitle = ""
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            DispatchQueue.main.async { completion(false) }
            return
        }
        ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { ok, _ in
            DispatchQueue.main.async { completion(ok) }
        }
    }
}
