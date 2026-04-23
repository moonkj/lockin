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
    var detoxSelection: FamilyActivitySelection
    var isDetoxActive: Bool
    var interceptQueue: [InterceptEvent]

    var earnedBadgeIDs: Set<String> = []
    var totalReturnCount: Int = 0
    var totalStrictSurvived: Int = 0
    var totalDetoxStarted: Int = 0

    func awardBadgeIfNew(_ id: String) -> Bool {
        guard !earnedBadgeIDs.contains(id) else { return false }
        earnedBadgeIDs.insert(id)
        return true
    }

    init(
        selection: FamilyActivitySelection = FamilyActivitySelection(),
        schedule: Schedule = .weekdayWorkHours,
        focusScoreToday: Int = 0,
        hasCompletedOnboarding: Bool = false,
        isManualFocusActive: Bool = false,
        isStrictModeActive: Bool = false,
        detoxSelection: FamilyActivitySelection = FamilyActivitySelection(),
        isDetoxActive: Bool = false,
        interceptQueue: [InterceptEvent] = []
    ) {
        self.selection = selection
        self.schedule = schedule
        self.focusScoreToday = focusScoreToday
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.isManualFocusActive = isManualFocusActive
        self.isStrictModeActive = isStrictModeActive
        self.detoxSelection = detoxSelection
        self.isDetoxActive = isDetoxActive
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
    private var history: [DailyFocus] = []

    func addFocusPoints(_ points: Int) {
        rolloverIfScoreDayChanged()
        focusScoreToday = max(0, min(100, focusScoreToday + points))
    }

    func dailyFocusHistory(lastDays: Int) -> [DailyFocus] {
        rolloverIfScoreDayChanged()
        let today = DailyFocus(date: Self.todayString(), score: focusScoreToday)
        var combined = history.filter { $0.date != today.date } + [today]
        combined.sort { $0.date < $1.date }
        return Array(combined.suffix(lastDays))
    }

    private func rolloverIfScoreDayChanged() {
        let today = Self.todayString()
        if focusScoreDate != today {
            if !focusScoreDate.isEmpty {
                history.append(DailyFocus(date: focusScoreDate, score: focusScoreToday))
                if history.count > 90 {
                    history = Array(history.suffix(90))
                }
            }
            focusScoreToday = 0
            focusScoreDate = today
        }
    }

    private static func todayString() -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
