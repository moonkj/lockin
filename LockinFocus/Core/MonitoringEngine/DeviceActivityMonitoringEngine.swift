import DeviceActivity
import Foundation

/// 모니터링 관련 전용 에러 enum.
enum MonitoringError: Error {
    case invalidSchedule
    case startMonitoringFailed(underlying: Error)
}

/// `DeviceActivityCenter` 실구현.
///
/// - 스케줄 감시: `startSchedule(_:name:)` — `intervalStart/End` 로
///   DeviceActivity 주기 모니터링 시작. 실제 shield 적용은
///   `DeviceActivityMonitorExtension.intervalDidStart` 에서 한다.
/// - 5분 일시 해제: `startTemporaryAllow(name:duration:)` — 현재로부터
///   `duration` 경과 시점을 `intervalEnd` 로 잡아 짧은 interval 을 생성.
///   종료 시 Extension 의 `intervalDidEnd` 가 주 shield 를 다시 덮어쓴다.
final class DeviceActivityMonitoringEngine: MonitoringEngine {
    private let center = DeviceActivityCenter()

    func startSchedule(_ schedule: Schedule, name: String) throws {
        let activity = DeviceActivityName(name)
        let daSchedule = DeviceActivitySchedule(
            intervalStart: schedule.startComponents,
            intervalEnd: schedule.endComponents,
            repeats: true
        )
        do {
            try center.startMonitoring(activity, during: daSchedule)
        } catch {
            throw MonitoringError.startMonitoringFailed(underlying: error)
        }
    }

    func stopMonitoring(name: String) {
        center.stopMonitoring([DeviceActivityName(name)])
    }

    func startTemporaryAllow(name: String, duration: TimeInterval) throws {
        let calendar = Calendar.current
        let now = Date()
        let end = now.addingTimeInterval(duration)

        let startComp = calendar.dateComponents([.hour, .minute, .second], from: now)
        let endComp = calendar.dateComponents([.hour, .minute, .second], from: end)

        let daSchedule = DeviceActivitySchedule(
            intervalStart: startComp,
            intervalEnd: endComp,
            repeats: false
        )
        do {
            try center.startMonitoring(DeviceActivityName(name), during: daSchedule)
        } catch {
            throw MonitoringError.startMonitoringFailed(underlying: error)
        }
    }
}
