import DeviceActivity
import ManagedSettings
import Foundation

/// 스케줄(예: 평일 9–17시) 구간 진입·종료·임계값 도달 이벤트를 처리한다.
/// 실제 차단(shield) 적용/해제는 ManagedSettingsStore 를 통해 이루어진다.
/// Extension 메모리/실행시간 제한이 있으니 무거운 로직은 메인 앱에서 처리.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // TODO: BlockingEngine 에서 저장해둔 FamilyActivitySelection 을 적용
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)
        // TODO: 사용 시간 임계값 도달 시 단계별 차단(Progressive) 단계 상승
    }
}
