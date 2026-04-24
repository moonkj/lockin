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
    var strictModeEndAt: Date?
    var strictModeStartAt: Date?
    var interceptQueue: [InterceptEvent]

    private var focusEndCount: Int = 0
    private var focusEndCountDate: String = ""

    var focusEndCountToday: Int {
        rolloverFocusEndCountIfNewDay()
        return focusEndCount
    }

    func recordManualFocusEnd() {
        rolloverFocusEndCountIfNewDay()
        focusEndCount += 1
        focusEndCountDate = Self.todayString()
    }

    private func rolloverFocusEndCountIfNewDay() {
        let today = Self.todayString()
        if focusEndCountDate != today {
            focusEndCount = 0
            focusEndCountDate = today
        }
    }

    var earnedBadgeIDs: Set<String> = []
    var totalReturnCount: Int = 0
    var totalStrictSurvived: Int = 0
    var totalFocusSeconds: Int = 0
    var totalManualFocusStarts: Int = 0

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
        strictModeEndAt: Date? = nil,
        interceptQueue: [InterceptEvent] = []
    ) {
        self.selection = selection
        self.schedule = schedule
        self.focusScoreToday = focusScoreToday
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.isManualFocusActive = isManualFocusActive
        self.strictModeEndAt = strictModeEndAt
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

    // MARK: - Score rule B (in-memory)
    var manualFocusStartedAt: Date?
    private var lastReturnAt: Date?
    private var todayReturnPoints: Int = 0
    private var lastDailyLoginDate: String = ""

    func awardReturnPoint() -> Bool {
        rolloverIfScoreDayChanged()
        rolloverTodayReturnPointsIfNeeded()
        let now = Date()
        if let last = lastReturnAt, now.timeIntervalSince(last) < 180 { return false }
        guard todayReturnPoints < 40 else { return false }
        let award = min(5, 40 - todayReturnPoints)
        focusScoreToday = min(100, focusScoreToday + award)
        todayReturnPoints += award
        lastReturnAt = now
        return true
    }

    func awardSessionCompletionIfEligible(now: Date) -> Bool {
        guard let start = manualFocusStartedAt else { return false }
        guard now.timeIntervalSince(start) >= 15 * 60 else { return false }
        let today = Self.todayString()
        if lastSessionBonusDate == today {
            manualFocusStartedAt = nil
            return false
        }
        manualFocusStartedAt = nil
        rolloverIfScoreDayChanged()
        focusScoreToday = min(100, focusScoreToday + 15)
        lastSessionBonusDate = today
        return true
    }

    private var lastSessionBonusDate: String = ""

    func awardDailyLoginIfNew() -> Bool {
        let today = Self.todayString()
        guard lastDailyLoginDate != today else { return false }
        rolloverIfScoreDayChanged()
        focusScoreToday = min(100, focusScoreToday + 5)
        lastDailyLoginDate = today
        return true
    }

    func debugSetDailyFocusHistory(_ entries: [DailyFocus]) {
        history = entries
    }

    // Leaderboard (in-memory)
    var nickname: String?
    private var _leaderboardUserID: String = UUID().uuidString
    var leaderboardUserID: String { _leaderboardUserID }
    var friendUserIDs: [String] = []
    var friendNicknameCache: [String: String] = [:]

    private func rolloverTodayReturnPointsIfNeeded() {
        let today = Self.todayString()
        if focusScoreDate != today {
            todayReturnPoints = 0
        }
    }
}
