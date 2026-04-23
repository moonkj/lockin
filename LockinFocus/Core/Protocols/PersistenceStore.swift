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
    var isStrictModeActive: Bool { get set }
    /// 도파민 디톡스 전용 허용 세트 (평소 selection 보다 더 짧게 고르는 용도).
    var detoxSelection: FamilyActivitySelection { get set }
    /// 도파민 디톡스 현재 활성 여부.
    var isDetoxActive: Bool { get set }
    var interceptQueue: [InterceptEvent] { get set }

    /// Extension 이 쓴 원본 큐 (`[[String: Any]]`) 를 `[InterceptEvent]` 로 디코딩.
    /// 처리 후 큐를 비운다.
    func drainInterceptQueue() -> [InterceptEvent]

    /// 지연 해제 점증: 다음 intercept 에서 사용할 카운트다운 초.
    /// 1회차 10초, 2회차 30초, 3회 이상 60초. 자정에 리셋.
    func currentUnlockDelaySeconds() -> Int

    /// "그래도 열기" 확정 시 호출. 오늘 카운트 +1.
    func recordManualUnlock()

    /// 게이미피케이션: 오늘 집중 점수에 정해진 값 더하기 (최대 100 고정).
    /// Intercept 에서 "돌아가기" 를 누르는 것 같은 좋은 행동을 보상하는 데 쓴다.
    /// 자정 리셋 로직은 구현체가 담당.
    func addFocusPoints(_ points: Int)

    /// 주간 리포트용 최근 N일치 집중 기록. 오늘 점수 리셋 시점에 자동 축적된다.
    func dailyFocusHistory(lastDays: Int) -> [DailyFocus]

    // MARK: - Badges
    var earnedBadgeIDs: Set<String> { get set }
    var totalReturnCount: Int { get set }
    var totalStrictSurvived: Int { get set }
    var totalDetoxStarted: Int { get set }

    /// 아직 없는 뱃지면 적재 후 true. 이미 있으면 false.
    func awardBadgeIfNew(_ id: String) -> Bool
}
