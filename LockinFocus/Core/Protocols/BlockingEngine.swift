import FamilyControls
import ManagedSettings
import Foundation

/// ManagedSettingsStore 래퍼. 시뮬레이터에서는 Noop 주입으로 동작 스킵.
///
/// 전략: **Whitelist (`.all(except:)`)** — 모든 앱을 차단하되 사용자가 "허용 앱"으로 고른
/// 개별 토큰만 예외. 허용 앱 0개 = 최대 집중 상태 (시스템 자동 보호 앱 제외 전부 잠김).
/// iOS 가 전화·메시지·설정은 자동 보호하지만 카메라·지도는 보호 보장 안 됨 — 사용자는
/// 필요한 앱을 Picker 에서 직접 체크할 수 있다.
protocol BlockingEngine: AnyObject {
    /// 사용자의 허용 선택 외 나머지 앱을 전부 shield 에 적용한다.
    /// 빈 selection 도 유효 — 모든 앱 잠김 (시스템 자동 보호 앱만 예외).
    func applyWhitelist(for selection: FamilyActivitySelection)

    /// 현재 적용된 shield 전체 해제.
    func clearShield()

    /// 특정 앱만 일시 허용 후 지정 시간이 지나면 다시 shield 에 포함.
    /// 구현은 MonitoringEngine 의 temp-allow 이벤트를 사용.
    func temporarilyAllow(token: ApplicationToken, for duration: TimeInterval)
}
