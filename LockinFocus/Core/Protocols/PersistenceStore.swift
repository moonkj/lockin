import FamilyControls
import Foundation

/// 앱 상태 저장 추상화. 실구현은 App Group UserDefaults 기반(UserDefaultsPersistenceStore),
/// 시뮬레이터/테스트는 InMemoryPersistenceStore 로 주입한다.
protocol PersistenceStore: AnyObject {
    var selection: FamilyActivitySelection { get set }
    var schedule: Schedule { get set }
    var focusScoreToday: Int { get set }
    var hasCompletedOnboarding: Bool { get set }
    var isManualFocusActive: Bool { get set }
    var interceptQueue: [InterceptEvent] { get set }

    /// Extension 이 쓴 원본 큐 (`[[String: Any]]`) 를 `[InterceptEvent]` 로 디코딩.
    /// 처리 후 큐를 비운다.
    func drainInterceptQueue() -> [InterceptEvent]

    /// 지연 해제 점증: 다음 intercept 에서 사용할 카운트다운 초.
    /// 1회차 10초, 2회차 30초, 3회 이상 60초. 자정에 리셋.
    func currentUnlockDelaySeconds() -> Int

    /// "그래도 열기" 확정 시 호출. 오늘 카운트 +1.
    func recordManualUnlock()
}
