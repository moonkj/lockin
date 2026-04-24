import FamilyControls
import Foundation

/// App Group `UserDefaults` 기반 실구현.
/// - `FamilyActivitySelection`, `Schedule`, `[InterceptEvent]` 는 JSON Data 로 저장.
/// - `focusScoreToday`, `hasCompletedOnboarding` 은 네이티브 `.integer / .bool`.
/// - `drainInterceptQueue()` 는 Extension 이 쓴 **원시 포맷** 큐를 디코딩하고 비운다.
final class UserDefaultsPersistenceStore: PersistenceStore {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = AppGroup.sharedDefaults) {
        self.defaults = defaults
    }

    // MARK: - FamilyActivitySelection

    var selection: FamilyActivitySelection {
        get {
            guard let data = defaults.data(forKey: SharedKeys.familySelection) else {
                return FamilyActivitySelection()
            }
            return (try? decoder.decode(FamilyActivitySelection.self, from: data))
                ?? FamilyActivitySelection()
        }
        set {
            if let data = try? encoder.encode(newValue) {
                defaults.set(data, forKey: SharedKeys.familySelection)
            }
        }
    }

    // MARK: - Schedule

    var schedule: Schedule {
        get {
            guard let data = defaults.data(forKey: PersistenceKeys.schedule) else {
                return .weekdayWorkHours
            }
            return (try? decoder.decode(Schedule.self, from: data)) ?? .weekdayWorkHours
        }
        set {
            if let data = try? encoder.encode(newValue) {
                defaults.set(data, forKey: PersistenceKeys.schedule)
            }
        }
    }

    // MARK: - Scalars

    var focusScoreToday: Int {
        get {
            rolloverFocusScoreIfNewDay()
            return defaults.integer(forKey: SharedKeys.focusScoreToday)
        }
        set {
            let clamped = max(0, min(100, newValue))
            defaults.set(clamped, forKey: SharedKeys.focusScoreToday)
            defaults.set(Self.todayString(), forKey: PersistenceKeys.focusScoreDateKey)
        }
    }

    func addFocusPoints(_ points: Int) {
        rolloverFocusScoreIfNewDay()
        let current = defaults.integer(forKey: SharedKeys.focusScoreToday)
        let next = max(0, min(100, current + points))
        defaults.set(next, forKey: SharedKeys.focusScoreToday)
        defaults.set(Self.todayString(), forKey: PersistenceKeys.focusScoreDateKey)
    }

    private func rolloverFocusScoreIfNewDay() {
        let today = Self.todayString()
        let stored = defaults.string(forKey: PersistenceKeys.focusScoreDateKey)
        if stored != today {
            // 어제(= 이전 기록) 점수를 history 에 적층.
            if let prevDate = stored {
                let prevScore = defaults.integer(forKey: SharedKeys.focusScoreToday)
                appendHistory(DailyFocus(date: prevDate, score: prevScore))
            }
            defaults.set(0, forKey: SharedKeys.focusScoreToday)
            defaults.set(today, forKey: PersistenceKeys.focusScoreDateKey)
            // 돌아가기 점수 규칙 B: 하루 한도(40)와 쿨다운도 날짜와 함께 리셋해야
            // 자정을 넘겨도 오늘 새로 40점까지 적립할 수 있다.
            defaults.set(0, forKey: PersistenceKeys.todayReturnPoints)
            defaults.removeObject(forKey: PersistenceKeys.lastReturnAt)
        }
    }

    func dailyFocusHistory(lastDays: Int) -> [DailyFocus] {
        rolloverFocusScoreIfNewDay()
        let all = readHistory()
        // 오늘(진행 중) 점수도 포함해서 반환.
        let today = DailyFocus(
            date: Self.todayString(),
            score: defaults.integer(forKey: SharedKeys.focusScoreToday)
        )
        var combined = all.filter { $0.date != today.date } + [today]
        combined.sort { $0.date < $1.date }
        return Array(combined.suffix(lastDays))
    }

    private func readHistory() -> [DailyFocus] {
        guard let data = defaults.data(forKey: PersistenceKeys.dailyFocusHistory) else {
            return []
        }
        return (try? decoder.decode([DailyFocus].self, from: data)) ?? []
    }

    // MARK: - Badges

    var earnedBadgeIDs: Set<String> {
        get {
            let arr = defaults.stringArray(forKey: PersistenceKeys.earnedBadges) ?? []
            return Set(arr)
        }
        set {
            defaults.set(Array(newValue), forKey: PersistenceKeys.earnedBadges)
        }
    }

    var totalReturnCount: Int {
        get { defaults.integer(forKey: PersistenceKeys.totalReturnCount) }
        set { defaults.set(newValue, forKey: PersistenceKeys.totalReturnCount) }
    }

    var totalStrictSurvived: Int {
        get { defaults.integer(forKey: PersistenceKeys.totalStrictSurvived) }
        set { defaults.set(newValue, forKey: PersistenceKeys.totalStrictSurvived) }
    }

    var totalFocusSeconds: Int {
        get { defaults.integer(forKey: PersistenceKeys.totalFocusSeconds) }
        set { defaults.set(newValue, forKey: PersistenceKeys.totalFocusSeconds) }
    }

    var totalManualFocusStarts: Int {
        get { defaults.integer(forKey: PersistenceKeys.totalManualFocusStarts) }
        set { defaults.set(newValue, forKey: PersistenceKeys.totalManualFocusStarts) }
    }

    func awardBadgeIfNew(_ id: String) -> Bool {
        var set = earnedBadgeIDs
        guard !set.contains(id) else { return false }
        set.insert(id)
        earnedBadgeIDs = set
        return true
    }

    // MARK: - Score rule B

    private static let returnCooldownSeconds: TimeInterval = 3 * 60
    private static let returnDailyCap: Int = 40
    private static let returnUnitPoint: Int = 5
    private static let sessionMinSeconds: TimeInterval = 15 * 60
    private static let sessionBonus: Int = 15
    private static let dailyLoginBonus: Int = 5

    func awardReturnPoint() -> Bool {
        rolloverFocusScoreIfNewDay()
        let now = Date()
        // 쿨다운.
        if let lastTs = defaults.object(forKey: PersistenceKeys.lastReturnAt) as? TimeInterval {
            let last = Date(timeIntervalSince1970: lastTs)
            if now.timeIntervalSince(last) < Self.returnCooldownSeconds { return false }
        }
        // 하루 상한.
        let today = defaults.integer(forKey: PersistenceKeys.todayReturnPoints)
        guard today < Self.returnDailyCap else { return false }

        let awarded = min(Self.returnUnitPoint, Self.returnDailyCap - today)
        focusScoreToday = min(100, focusScoreToday + awarded)
        defaults.set(today + awarded, forKey: PersistenceKeys.todayReturnPoints)
        defaults.set(now.timeIntervalSince1970, forKey: PersistenceKeys.lastReturnAt)
        return true
    }

    var manualFocusStartedAt: Date? {
        get {
            let v = defaults.double(forKey: PersistenceKeys.manualFocusStartedAt)
            return v > 0 ? Date(timeIntervalSince1970: v) : nil
        }
        set {
            if let date = newValue {
                defaults.set(date.timeIntervalSince1970, forKey: PersistenceKeys.manualFocusStartedAt)
            } else {
                defaults.removeObject(forKey: PersistenceKeys.manualFocusStartedAt)
            }
        }
    }

    func awardSessionCompletionIfEligible(now: Date) -> Bool {
        guard let start = manualFocusStartedAt else { return false }
        let elapsed = now.timeIntervalSince(start)
        guard elapsed >= Self.sessionMinSeconds else { return false }

        // force-quit + 재기동으로 오래된 startedAt 을 재사용해 반복 수령하는 exploit 방어:
        // 하루 1회만 세션 보너스 지급. 이미 오늘 받았다면 startedAt 만 정리하고 false.
        let today = Self.todayString()
        if defaults.string(forKey: PersistenceKeys.lastSessionBonusDate) == today {
            manualFocusStartedAt = nil
            return false
        }

        // 15분 이상 확정된 뒤에만 start 를 비운다 — 짧은 세션에 잘못 리셋되지 않도록.
        manualFocusStartedAt = nil
        rolloverFocusScoreIfNewDay()
        focusScoreToday = min(100, focusScoreToday + Self.sessionBonus)
        defaults.set(today, forKey: PersistenceKeys.lastSessionBonusDate)
        return true
    }

    func awardDailyLoginIfNew() -> Bool {
        let today = Self.todayString()
        let stored = defaults.string(forKey: PersistenceKeys.lastDailyLoginDate)
        guard stored != today else { return false }
        rolloverFocusScoreIfNewDay()
        focusScoreToday = min(100, focusScoreToday + Self.dailyLoginBonus)
        defaults.set(today, forKey: PersistenceKeys.lastDailyLoginDate)
        return true
    }

    func debugSetDailyFocusHistory(_ entries: [DailyFocus]) {
        if let data = try? encoder.encode(entries) {
            defaults.set(data, forKey: PersistenceKeys.dailyFocusHistory)
        }
    }

    // MARK: - Leaderboard

    /// iCloud KV → 로컬 cache → 없음 순서로 조회. 쓰기는 양쪽에.
    /// 같은 Apple ID 로 로그인된 기기 간 값이 자동 공유된다.
    var nickname: String? {
        get {
            if let remote = ICloudKeyValueStore.string(for: ICloudKeyValueStore.Keys.nickname) {
                // iCloud 값이 앞서면 로컬도 맞춰 둔다.
                defaults.set(remote, forKey: PersistenceKeys.nickname)
                return remote
            }
            let v = defaults.string(forKey: PersistenceKeys.nickname)
            return (v?.isEmpty ?? true) ? nil : v
        }
        set {
            defaults.set(newValue, forKey: PersistenceKeys.nickname)
            ICloudKeyValueStore.set(newValue, for: ICloudKeyValueStore.Keys.nickname)
        }
    }

    /// iCloud KV → 로컬 → 신규 생성. 신규 생성 시 양쪽 모두에 기록해
    /// 이후 다른 기기에서도 같은 ID 를 재사용하도록 한다.
    var leaderboardUserID: String {
        if let remote = ICloudKeyValueStore.string(for: ICloudKeyValueStore.Keys.leaderboardUserID) {
            defaults.set(remote, forKey: PersistenceKeys.leaderboardUserID)
            return remote
        }
        if let local = defaults.string(forKey: PersistenceKeys.leaderboardUserID),
           !local.isEmpty {
            // 이 기기에서 먼저 생성됐던 ID — iCloud 로 올려 다른 기기와 공유.
            ICloudKeyValueStore.set(local, for: ICloudKeyValueStore.Keys.leaderboardUserID)
            return local
        }
        let fresh = UUID().uuidString
        defaults.set(fresh, forKey: PersistenceKeys.leaderboardUserID)
        ICloudKeyValueStore.set(fresh, for: ICloudKeyValueStore.Keys.leaderboardUserID)
        return fresh
    }

    var friendUserIDs: [String] {
        get { defaults.stringArray(forKey: PersistenceKeys.friendUserIDs) ?? [] }
        set { defaults.set(newValue, forKey: PersistenceKeys.friendUserIDs) }
    }

    var friendNicknameCache: [String: String] {
        get {
            // `as? [String: String]` 캐스트는 값 중 하나라도 String 이 아니면 전체 nil 을
            // 반환해 누적된 친구 닉네임이 통째로 날아간다. compactMapValues 로 String 값만
            // 살려 부분 손상에도 복구 가능하도록.
            guard let raw = defaults.dictionary(forKey: PersistenceKeys.friendNicknameCache) else { return [:] }
            return raw.compactMapValues { $0 as? String }
        }
        set { defaults.set(newValue, forKey: PersistenceKeys.friendNicknameCache) }
    }

    var focusGoalScore: Int {
        get {
            // 키가 없으면 기본 80 반환. 사용자가 0 으로 낮추는 건 허용하되 UI 에서 표시는 감춤.
            let v = defaults.object(forKey: PersistenceKeys.focusGoalScore) as? Int
            return v ?? 80
        }
        set {
            defaults.set(max(0, min(100, newValue)), forKey: PersistenceKeys.focusGoalScore)
        }
    }

    var useBiometricForPasscode: Bool {
        get { defaults.bool(forKey: PersistenceKeys.useBiometricForPasscode) }
        set { defaults.set(newValue, forKey: PersistenceKeys.useBiometricForPasscode) }
    }

    var dailySummaryNotification: Bool {
        get { defaults.bool(forKey: PersistenceKeys.dailySummaryNotification) }
        set { defaults.set(newValue, forKey: PersistenceKeys.dailySummaryNotification) }
    }

    var streakFreezeToken: Int {
        get {
            let v = defaults.integer(forKey: PersistenceKeys.streakFreezeToken)
            return max(0, min(1, v))
        }
        set {
            defaults.set(max(0, min(1, newValue)), forKey: PersistenceKeys.streakFreezeToken)
        }
    }

    var streakFreezeLastWeek: String {
        get { defaults.string(forKey: PersistenceKeys.streakFreezeLastWeek) ?? "" }
        set { defaults.set(newValue, forKey: PersistenceKeys.streakFreezeLastWeek) }
    }

    private func appendHistory(_ entry: DailyFocus) {
        var history = readHistory()
        history.removeAll { $0.date == entry.date }
        history.append(entry)
        // 90일 초과분 drop.
        if history.count > 90 {
            history = Array(history.suffix(90))
        }
        if let data = try? encoder.encode(history) {
            defaults.set(data, forKey: PersistenceKeys.dailyFocusHistory)
        }
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: PersistenceKeys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: PersistenceKeys.hasCompletedOnboarding) }
    }

    var isManualFocusActive: Bool {
        get { defaults.bool(forKey: PersistenceKeys.isManualFocusActive) }
        set { defaults.set(newValue, forKey: PersistenceKeys.isManualFocusActive) }
    }

    var strictModeEndAt: Date? {
        get {
            let v = defaults.double(forKey: PersistenceKeys.strictModeEndAt)
            return v > 0 ? Date(timeIntervalSince1970: v) : nil
        }
        set {
            if let date = newValue {
                defaults.set(date.timeIntervalSince1970, forKey: PersistenceKeys.strictModeEndAt)
            } else {
                defaults.removeObject(forKey: PersistenceKeys.strictModeEndAt)
                // end 가 지워지면 start + uptime + duration 도 함께 — 시계 조작 탐지 대칭성 유지.
                defaults.removeObject(forKey: PersistenceKeys.strictModeStartAt)
                defaults.removeObject(forKey: PersistenceKeys.strictModeStartUptime)
                defaults.removeObject(forKey: PersistenceKeys.strictModeDurationSeconds)
            }
        }
    }

    var strictModeStartAt: Date? {
        get {
            let v = defaults.double(forKey: PersistenceKeys.strictModeStartAt)
            return v > 0 ? Date(timeIntervalSince1970: v) : nil
        }
        set {
            if let date = newValue {
                defaults.set(date.timeIntervalSince1970, forKey: PersistenceKeys.strictModeStartAt)
            } else {
                defaults.removeObject(forKey: PersistenceKeys.strictModeStartAt)
            }
        }
    }

    var strictModeStartUptime: Double? {
        get {
            let v = defaults.double(forKey: PersistenceKeys.strictModeStartUptime)
            return v > 0 ? v : nil
        }
        set {
            if let v = newValue {
                defaults.set(v, forKey: PersistenceKeys.strictModeStartUptime)
            } else {
                defaults.removeObject(forKey: PersistenceKeys.strictModeStartUptime)
            }
        }
    }

    var strictModeDurationSeconds: Double? {
        get {
            let v = defaults.double(forKey: PersistenceKeys.strictModeDurationSeconds)
            return v > 0 ? v : nil
        }
        set {
            if let v = newValue {
                defaults.set(v, forKey: PersistenceKeys.strictModeDurationSeconds)
            } else {
                defaults.removeObject(forKey: PersistenceKeys.strictModeDurationSeconds)
            }
        }
    }

    var focusEndCountToday: Int {
        rolloverFocusEndCountIfNewDay()
        return defaults.integer(forKey: PersistenceKeys.focusEndCountToday)
    }

    func recordManualFocusEnd() {
        rolloverFocusEndCountIfNewDay()
        let count = defaults.integer(forKey: PersistenceKeys.focusEndCountToday)
        defaults.set(count + 1, forKey: PersistenceKeys.focusEndCountToday)
        defaults.set(Self.todayString(), forKey: PersistenceKeys.focusEndCountDateKey)
    }

    private func rolloverFocusEndCountIfNewDay() {
        let today = Self.todayString()
        let stored = defaults.string(forKey: PersistenceKeys.focusEndCountDateKey)
        if stored != today {
            defaults.set(0, forKey: PersistenceKeys.focusEndCountToday)
            defaults.set(today, forKey: PersistenceKeys.focusEndCountDateKey)
        }
    }

    // MARK: - Progressive unlock delay

    func currentUnlockDelaySeconds() -> Int {
        rolloverUnlockCountIfNewDay()
        let count = defaults.integer(forKey: PersistenceKeys.todayUnlockCount)
        switch count {
        case 0: return 10
        case 1: return 30
        default: return 60
        }
    }

    func recordManualUnlock() {
        rolloverUnlockCountIfNewDay()
        let count = defaults.integer(forKey: PersistenceKeys.todayUnlockCount)
        defaults.set(count + 1, forKey: PersistenceKeys.todayUnlockCount)
        defaults.set(Self.todayString(), forKey: PersistenceKeys.todayUnlockDateKey)
    }

    private func rolloverUnlockCountIfNewDay() {
        let today = Self.todayString()
        let stored = defaults.string(forKey: PersistenceKeys.todayUnlockDateKey)
        if stored != today {
            // 시계 되돌림 방지: 저장된 날짜가 오늘보다 "뒤"(미래 → 다시 과거 복귀 시도)면
            // count 를 초기화하지 않고 보존. 예: 오늘 3번 해제 후 시스템 시간을
            // 어제로 되돌려 10s 지연을 10s 로 리셋하는 공격 차단.
            // POSIX yyyy-MM-dd 는 사전식 비교 == 시간적 비교.
            if let stored, stored > today {
                // 과거로 이동한 걸 감지 — count 는 유지, 날짜는 갱신하지 않아
                // 이후에도 계속 높은 count 판정 유지.
                return
            }
            defaults.set(0, forKey: PersistenceKeys.todayUnlockCount)
            defaults.set(today, forKey: PersistenceKeys.todayUnlockDateKey)
        }
    }

    /// yyyy-MM-dd 포맷 고정 Date → String 변환기.
    /// DateFormatter 생성은 수백 μs 비용이라 매 호출마다 만들면 hot path (onTick, body)
    /// 에서 누적 코스트가 커진다. static let 은 thread-safe (iOS 7+).
    private static let ymdFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static func todayString() -> String {
        ymdFormatter.string(from: Date())
    }

    // MARK: - InterceptQueue (Codable 보관)

    var interceptQueue: [InterceptEvent] {
        get {
            guard let data = defaults.data(forKey: PersistenceKeys.codableInterceptQueue) else {
                return []
            }
            return (try? decoder.decode([InterceptEvent].self, from: data)) ?? []
        }
        set {
            if let data = try? encoder.encode(newValue) {
                defaults.set(data, forKey: PersistenceKeys.codableInterceptQueue)
            }
        }
    }

    // MARK: - Raw queue drain

    /// Extension 이 기록한 원시 `[[String: Any]]` 큐를 `InterceptEvent` 로 변환 후 비운다.
    /// 원시 키 이름은 `ShieldActionExtensionHandler` 의 `enqueue` 와 동일해야 한다.
    func drainInterceptQueue() -> [InterceptEvent] {
        let rawAny = defaults.array(forKey: PersistenceKeys.rawInterceptQueue)
            as? [[String: Any]] ?? []
        // 안전 상한 — Extension 오작동이나 적대적 기록이 OOM 을 유발하지 않도록 10k 엔트리로 캡.
        let capped = Array(rawAny.prefix(10_000))
        let raw = capped

        let events: [InterceptEvent] = raw.compactMap { entry in
            guard
                let ts = entry["timestamp"] as? TimeInterval,
                let typeRaw = entry["type"] as? String,
                let subjectRaw = entry["subjectKind"] as? String,
                let type = mapType(typeRaw),
                let subjectKind = InterceptEvent.SubjectKind(rawValue: subjectRaw)
            else {
                return nil
            }
            return InterceptEvent(
                timestamp: Date(timeIntervalSince1970: ts),
                type: type,
                subjectKind: subjectKind
            )
        }

        defaults.removeObject(forKey: PersistenceKeys.rawInterceptQueue)
        return events
    }

    /// Extension 의 문자열 타입(`"intercept_requested"`, `"returned"`) → enum 변환.
    private func mapType(_ raw: String) -> InterceptEvent.EventType? {
        switch raw {
        case "returned": return .returned
        case "intercept_requested", "interceptRequested": return .interceptRequested
        default: return nil
        }
    }
}
