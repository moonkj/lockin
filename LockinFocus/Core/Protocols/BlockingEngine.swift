import FamilyControls
import ManagedSettings
import Foundation

/// ManagedSettingsStore 래퍼. 시뮬레이터에서는 Noop 주입으로 동작 스킵.
protocol BlockingEngine: AnyObject {
    /// 사용자의 허용 선택을 기준으로 역-화이트리스트(`.all(except:)`)를 적용한다.
    func applyWhitelist(for selection: FamilyActivitySelection)

    /// 현재 적용된 shield 전체 해제.
    func clearShield()

    /// 특정 앱만 일시 허용 후 지정 시간이 지나면 다시 shield 에 포함.
    /// 구현은 MonitoringEngine 의 temp-allow 이벤트를 사용.
    func temporarilyAllow(token: ApplicationToken, for duration: TimeInterval)
}
