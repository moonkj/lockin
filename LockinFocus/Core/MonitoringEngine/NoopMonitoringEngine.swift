import Foundation

/// 시뮬레이터 라이브 빌드 전용 No-op. DeviceActivity 는 시뮬레이터에서
/// 트리거되지 않으므로 호출을 무시하여 크래시만 방지한다.
final class NoopMonitoringEngine: MonitoringEngine {
    func startSchedule(_ schedule: Schedule, name: String) throws {}
    func stopMonitoring(name: String) {}
    func startTemporaryAllow(name: String, duration: TimeInterval) throws {}
}
