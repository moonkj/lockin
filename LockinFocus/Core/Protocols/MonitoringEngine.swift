import DeviceActivity
import Foundation

/// DeviceActivityCenter 래퍼.
protocol MonitoringEngine: AnyObject {
    /// 스케줄 기반 차단 감시 시작. name 은 `DeviceActivityName` 문자열.
    func startSchedule(_ schedule: Schedule, name: String) throws

    /// 지정 name 의 감시 중단.
    func stopMonitoring(name: String)

    /// 일시 허용 5분 타이머 시작. 종료 시점에 `intervalDidEnd` 가 호출되도록.
    func startTemporaryAllow(name: String, duration: TimeInterval) throws
}
