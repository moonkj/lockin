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
    var isStrictModeActive: Bool
    var interceptQueue: [InterceptEvent]

    init(
        selection: FamilyActivitySelection = FamilyActivitySelection(),
        schedule: Schedule = .weekdayWorkHours,
        focusScoreToday: Int = 0,
        hasCompletedOnboarding: Bool = false,
        isManualFocusActive: Bool = false,
        isStrictModeActive: Bool = false,
        interceptQueue: [InterceptEvent] = []
    ) {
        self.selection = selection
        self.schedule = schedule
        self.focusScoreToday = focusScoreToday
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.isManualFocusActive = isManualFocusActive
        self.isStrictModeActive = isStrictModeActive
        self.interceptQueue = interceptQueue
    }

    func drainInterceptQueue() -> [InterceptEvent] {
        let q = interceptQueue
        interceptQueue.removeAll()
        return q
    }

    // Progressive unlock delay (in-memory, same rule as live store).
    private var unlockCount: Int = 0
    /// 초기값은 빈 문자열. 첫 접근 시 rolloverIfNewDay 가 오늘 날짜로 세팅.
    private var unlockDate: String = ""

    func currentUnlockDelaySeconds() -> Int {
        rolloverIfNewDay()
        switch unlockCount {
        case 0: return 10
        case 1: return 30
        default: return 60
        }
    }

    func recordManualUnlock() {
        rolloverIfNewDay()
        unlockCount += 1
        unlockDate = Self.todayString()
    }

    private func rolloverIfNewDay() {
        let today = Self.todayString()
        if unlockDate != today {
            unlockCount = 0
            unlockDate = today
        }
    }

    // Focus score helpers (in-memory).
    private var focusScoreDate: String = ""

    func addFocusPoints(_ points: Int) {
        let today = Self.todayString()
        if focusScoreDate != today {
            focusScoreToday = 0
            focusScoreDate = today
        }
        focusScoreToday = max(0, min(100, focusScoreToday + points))
    }

    private static func todayString() -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
