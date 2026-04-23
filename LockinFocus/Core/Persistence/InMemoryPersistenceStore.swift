import FamilyControls
import Foundation

/// 단위 테스트 / 시뮬레이터 옵션용 메모리 전용 저장소.
/// Preview Mock 과 달리 drain 시 큐를 정상적으로 비우고, 외부 테스트에서
/// 값을 주입/확인하기 좋은 순수 구현을 제공한다.
final class InMemoryPersistenceStore: PersistenceStore {
    var selection: FamilyActivitySelection
    var schedule: Schedule
    var focusScoreToday: Int
    var hasCompletedOnboarding: Bool
    var isManualFocusActive: Bool
    var interceptQueue: [InterceptEvent]

    init(
        selection: FamilyActivitySelection = FamilyActivitySelection(),
        schedule: Schedule = .weekdayWorkHours,
        focusScoreToday: Int = 0,
        hasCompletedOnboarding: Bool = false,
        isManualFocusActive: Bool = false,
        interceptQueue: [InterceptEvent] = []
    ) {
        self.selection = selection
        self.schedule = schedule
        self.focusScoreToday = focusScoreToday
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.isManualFocusActive = isManualFocusActive
        self.interceptQueue = interceptQueue
    }

    func drainInterceptQueue() -> [InterceptEvent] {
        let q = interceptQueue
        interceptQueue.removeAll()
        return q
    }
}
