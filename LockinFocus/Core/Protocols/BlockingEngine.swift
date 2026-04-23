import FamilyControls
import ManagedSettings
import Foundation

/// ManagedSettingsStore 래퍼. 시뮬레이터에서는 Noop 주입으로 동작 스킵.
///
/// 전략: **Blocklist** — 사용자가 Picker 에서 고른 앱/카테고리만 차단, 나머지는 자동 허용.
/// 이 전략은 Apple API 가 권장하는 패턴이며 시스템 앱(전화/메시지/설정/카메라 등)을
/// 자동으로 살려둘 수 있다는 장점이 있다. Whitelist(`.all(except:)`) 는 카테고리 토큰을
/// 예외 처리할 수 없어 시스템 앱 자동 허용이 API 레벨에서 불가능했다.
protocol BlockingEngine: AnyObject {
    /// 사용자가 고른 차단 대상(앱 + 카테고리)을 shield 에 적용한다.
    /// 고르지 않은 앱·카테고리는 자동으로 열린다.
    func applyBlocklist(for selection: FamilyActivitySelection)

    /// 현재 적용된 shield 전체 해제.
    func clearShield()

    /// 특정 앱만 일시 허용 후 지정 시간이 지나면 다시 shield 에 포함.
    /// 구현은 MonitoringEngine 의 temp-allow 이벤트를 사용.
    func temporarilyAllow(token: ApplicationToken, for duration: TimeInterval)
}
