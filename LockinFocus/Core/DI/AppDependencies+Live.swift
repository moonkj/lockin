import Foundation

extension AppDependencies {
    /// 실환경 의존성 팩토리. 시뮬레이터에서는 Shield/Monitor 만 Noop 으로 대체하고
    /// 실제 Persistence(App Group UserDefaults) 는 그대로 사용한다.
    static func live() -> AppDependencies {
        let persistence = UserDefaultsPersistenceStore()

        #if targetEnvironment(simulator)
        return AppDependencies(
            persistence: persistence,
            blocking: NoopBlockingEngine(),
            monitoring: NoopMonitoringEngine()
        )
        #else
        let monitoring = DeviceActivityMonitoringEngine()
        let blocking = ManagedSettingsBlockingEngine()
        // 순환 주입 회피를 위한 후주입.
        blocking.bind(monitoring: monitoring)
        return AppDependencies(
            persistence: persistence,
            blocking: blocking,
            monitoring: monitoring
        )
        #endif
    }
}
