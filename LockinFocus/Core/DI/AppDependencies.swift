import Foundation
import FamilyControls
import ManagedSettings
import Combine

@MainActor
final class AppDependencies: ObservableObject {
    let persistence: PersistenceStore
    let blocking: BlockingEngine
    let monitoring: MonitoringEngine
    /// 리더보드 서비스 — 테스트에서는 MockLeaderboardService 를 주입.
    /// 프로덕션은 CloudKitLeaderboardService.shared.
    let leaderboardService: LeaderboardServiceProtocol

    /// 라우팅 + 친구 초대 pending state — 별도 ObservableObject (RouterStore) 로 분리.
    /// AppDependencies 는 forwarding 만 보유 (호환).
    /// init 시점엔 persistence 가 위쪽에 선언돼 있어야 — lazy 로 첫 접근 시 생성.
    private(set) lazy var router: RouterStore = {
        RouterStore(persistence: persistence) { [weak self] in
            self?.persistence.leaderboardUserID ?? ""
        }
    }()

    /// (호환 alias) AppDependencies.Route → RouterStore.Route.
    typealias Route = RouterStore.Route

    /// (호환) 기존 호출자가 그대로 쓰던 API — router 로 위임.
    var pendingRoute: Route? { router.pendingRoute }
    func requestRoute(_ route: Route) { router.requestRoute(route) }
    func consumeRoute() { router.consumeRoute() }

    var pendingFriendInvite: FriendInviteLink.Payload? {
        get { router.pendingFriendInvite }
        set { router.pendingFriendInvite = newValue }
    }
    func requestFriendInvite(_ payload: FriendInviteLink.Payload) {
        router.requestFriendInvite(payload)
    }
    func consumeFriendInvite() { router.consumeFriendInvite() }
    func acceptFriendInvite() { router.acceptFriendInvite() }

    /// (호환) AppDependencies.safeDisplayName(...) 정적 호출 — 새로는 RouterStore.safeDisplayName 권장.
    static func safeDisplayName(for raw: String, position: Int? = nil) -> String {
        RouterStore.safeDisplayName(for: raw, position: position)
    }

    /// (호환) maxFriendCount 상수 — 새로는 RouterStore.maxFriendCount.
    static var maxFriendCount: Int { RouterStore.maxFriendCount }

    // MARK: - Shared focus toggle (Siri App Intent 와 Dashboard 공유)

    /// Dashboard 의 "지금 집중 시작" 과 동일한 동작을 App Intent 에서도 호출할 수 있게
    /// AppDependencies 레벨에서 제공. selection 은 persistence 에 저장된 마지막 값을
    /// 사용한다 (Dashboard state 와 동일).
    @discardableResult
    func startManualFocusFromIntent() -> Bool {
        guard !persistence.isManualFocusActive else { return false }
        guard !strictActive else { return false }  // 엄격 중엔 intent 로 재시작 방지.
        let selection = persistence.selection
        let allowedCount = selection.applicationTokens.count
            + selection.categoryTokens.count
            + selection.webDomainTokens.count
        let now = Date()
        blocking.applyWhitelist(for: selection)
        persistence.isManualFocusActive = true
        persistence.manualFocusStartedAt = now
        celebrate(BadgeEngine.onManualFocusStarted(persistence: persistence))
        FocusActivityService.start(
            startDate: now,
            strictEndDate: persistence.strictModeEndAt,
            allowedCount: allowedCount,
            focusScore: persistence.focusScoreToday
        )
        return true
    }

    /// Siri intent "집중 종료". 엄격 모드 중이면 거부 (strict 계약 유지).
    /// 일반 모드에서는 FocusEndConfirmView 플로우를 스킵하고 직접 종료 — intent 사용자는
    /// 이미 음성·자동화 경로로 "끝내겠다" 를 명시적으로 선언했기 때문.
    @discardableResult
    func endManualFocusFromIntent() -> Bool {
        guard persistence.isManualFocusActive else { return false }
        guard !strictActive else { return false }
        let start = persistence.manualFocusStartedAt
        let now = Date()
        blocking.clearShield()
        persistence.isManualFocusActive = false
        persistence.recordManualFocusEnd()
        _ = persistence.awardSessionCompletionIfEligible(now: now)
        var unlocked: [Badge] = []
        if let start {
            unlocked.append(contentsOf: BadgeEngine.onManualFocusEnded(
                elapsed: now.timeIntervalSince(start),
                persistence: persistence
            ))
        }
        unlocked.append(contentsOf: BadgeEngine.onScoreChanged(persistence: persistence))
        celebrate(unlocked)
        FocusActivityService.end()
        return true
    }

    // 친구 초대 accept 는 RouterStore.acceptFriendInvite() 가 처리.
    // AppDependencies.acceptFriendInvite() 는 위에서 forwarding.

    /// 뱃지 축하 큐 — 별도 ObservableObject 로 분리. AppDependencies 는 위임만.
    /// 직접 구독은 `RootView` 가 `@EnvironmentObject` 또는 `@ObservedObject` 로 가능.
    let celebrations = CelebrationCenter()

    /// (호환) 기존 호출자가 그대로 쓰던 API — celebrations 로 위임.
    var currentCelebratedBadge: Badge? { celebrations.currentBadge }
    func celebrate(_ badges: [Badge]) { celebrations.celebrate(badges) }
    func dismissCelebratedBadge() { celebrations.dismiss() }

    /// 전역 1초 타이머 — 별도 ObservableObject (ClockTicker) 로 분리.
    /// AppDependencies 는 forwarding + strict 만료 핸들러 등록만.
    private(set) lazy var ticker: ClockTicker = {
        let t = ClockTicker(
            initialStrictActive: persistence.isStrictModeActive,
            isStrictActiveProvider: { [weak self] in
                self?.persistence.isStrictModeActive ?? false
            }
        )
        t.afterTick = { [weak self] in self?.cleanupStrictIfExpired() }
        return t
    }()

    /// (호환) 기존 호출자가 그대로 쓰던 API — ticker 로 위임.
    var tick: Date { ticker.tick }
    var strictActive: Bool { ticker.strictActive }

    private var kvObserver: NSObjectProtocol?

    /// scenePhase 백그라운드 시 호출.
    func pauseTicker() { ticker.pause() }

    /// scenePhase 포그라운드 복귀 시 호출.
    func resumeTicker() { ticker.resume() }

    /// strict 만료 시 정리 (Haptic + celebrate + Live Activity + 알림).
    /// ClockTicker.afterTick 이 매초 부르고, 진짜 만료일 때만 진입.
    private func cleanupStrictIfExpired() {
        let now = Date()
        guard let end = persistence.strictModeEndAt,
              end <= now,
              !persistence.isStrictModeActive
        else { return }
        // sentinel 통과 → 진짜 만료. wallclock + uptime 둘 다 만료 확인됨.
        persistence.strictModeEndAt = nil
        persistence.strictModeStartAt = nil
        Haptics.success()
        celebrate(BadgeEngine.onStrictSurvived(persistence: persistence))
        FocusActivityService.end()
        StrictCompletionScheduler.cancel()
    }

    /// CelebrationCenter 변경을 deps 관찰자에게도 전파 (기존 `deps.currentCelebratedBadge`
    /// 패턴 호환). 분리는 했지만 호출부 마이그레이션 시까지 forwarding.
    private var celebrationsCancellable: AnyCancellable?

    init(
        persistence: PersistenceStore,
        blocking: BlockingEngine,
        monitoring: MonitoringEngine,
        leaderboardService: LeaderboardServiceProtocol = CloudKitLeaderboardService.shared
    ) {
        self.persistence = persistence
        self.blocking = blocking
        self.monitoring = monitoring
        self.leaderboardService = leaderboardService
        observeICloudKVChanges()
        // celebrations 변경을 self 의 objectWillChange 로 전파.
        celebrationsCancellable = celebrations.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
        // router · ticker (lazy) 도 같은 식으로 forwarding.
        _ = router
        routerCancellable = router.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
        _ = ticker
        tickerCancellable = ticker.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
        ticker.start()
    }

    private var routerCancellable: AnyCancellable?
    private var tickerCancellable: AnyCancellable?

    deinit {
        // ticker 는 main actor 에 묶여 있으나 Timer.invalidate 자체는 thread-safe.
        if let kvObserver {
            NotificationCenter.default.removeObserver(kvObserver)
        }
    }

    // 전역 1초 타이머 + onTick → ClockTicker 로 이동. cleanupStrictIfExpired 는 위에 있음.

    /// iCloud KV 가 다른 기기에서 바뀌었다는 알림을 받으면 로컬 캐시를 맞춰준다.
    /// split-brain 수렴 메커니즘: 두 기기가 동시에 앱을 처음 실행해 각자 UUID 를
    /// 만든 경우에도 KV 가 나중에 동기화되면 이 알림이 떠서 뒤늦게 합쳐진다.
    ///
    /// 이전 구현은 어떤 KV 키가 바뀌든 objectWillChange 를 쏴 전체 뷰 재렌더를
    /// 유발했다. 변경된 키 배열을 검사해 우리가 관심 있는 키가 섞여 있을 때만
    /// 브로드캐스트해 배터리·렌더 비용을 줄인다.
    private func observeICloudKVChanges() {
        let relevantKeys: Set<String> = [
            ICloudKeyValueStore.Keys.leaderboardUserID,
            ICloudKeyValueStore.Keys.nickname
        ]
        kvObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] note in
            guard let self else { return }
            let changedKeys = (note.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]) ?? []
            let changedSet = Set(changedKeys)
            // 관련 키가 전혀 없으면 무시. userInfo 미지원 OS 변화(방어) 시엔 안전하게 처리.
            if !changedKeys.isEmpty && changedSet.isDisjoint(with: relevantKeys) {
                return
            }
            // 닉네임·userID 모두 getter 내부에서 iCloud 우선으로 로컬을 재동기화한다.
            _ = self.persistence.leaderboardUserID
            _ = self.persistence.nickname
            self.objectWillChange.send()
        }
    }

    /// Preview / 시뮬레이터 / Coder-A 실구현 미완 상태에서 빌드를 유지하는 Mock 세트.
    /// Coder-A 가 `live()` 실구현을 별도 파일에 추가한다.
    static func preview() -> AppDependencies {
        AppDependencies(
            persistence: PreviewPersistenceStore(),
            blocking: PreviewBlockingEngine(),
            monitoring: PreviewMonitoringEngine()
        )
    }
}

// MARK: - Preview Mocks

final class PreviewPersistenceStore: PersistenceStore {
    var selection = FamilyActivitySelection()
    var schedule = Schedule.weekdayWorkHours
    var focusScoreToday = 42
    var hasCompletedOnboarding = false
    var isManualFocusActive = false
    var strictModeEndAt: Date? = nil
    var strictModeStartAt: Date? = nil
    var strictModeStartUptime: Double? = nil
    var strictModeDurationSeconds: Double? = nil
    var interceptQueue: [InterceptEvent] = []

    var focusEndCountToday: Int { 0 }
    func recordManualFocusEnd() {}

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

    // Preview score-rule stubs
    var manualFocusStartedAt: Date?
    func awardReturnPoint() -> Bool { false }
    func awardSessionCompletionIfEligible(now: Date) -> Bool { false }
    func awardDailyLoginIfNew() -> Bool { false }

    // Admin debug no-op
    func debugSetDailyFocusHistory(_ entries: [DailyFocus]) {}
    func clearTodayFocusData() {
        focusScoreToday = 0
        manualFocusStartedAt = nil
        interceptQueue = []
    }

    // Leaderboard (preview)
    var nickname: String? = nil
    let leaderboardUserID: String = "preview-user"
    var friendUserIDs: [String] = []
    var friendNicknameCache: [String: String] = [:]
    var focusGoalScore: Int = 80
    var useBiometricForPasscode: Bool = false
    var dailySummaryNotification: Bool = false
    var streakFreezeToken: Int = 0
    var streakFreezeLastWeek: String = ""
    var pinnedBadgeIDs: [String] = []

    func drainInterceptQueue() -> [InterceptEvent] {
        let q = interceptQueue
        interceptQueue.removeAll()
        return q
    }

    // Preview: 고정 10초 반환, unlock 누적은 하지 않음.
    func currentUnlockDelaySeconds() -> Int { 10 }
    func recordManualUnlock() {}
    func addFocusPoints(_ points: Int) {
        focusScoreToday = max(0, min(100, focusScoreToday + points))
    }

    func dailyFocusHistory(lastDays: Int) -> [DailyFocus] {
        // Preview 용 더미 데이터 — 최근 7일 요일별.
        let sample = [24, 42, 71, 55, 90, 33, focusScoreToday]
        let cal = Calendar.current
        let today = Date()
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return sample.enumerated().map { idx, score in
            let date = cal.date(byAdding: .day, value: idx - 6, to: today) ?? today
            return DailyFocus(date: f.string(from: date), score: score)
        }.suffix(lastDays).map { $0 }
    }
}

final class PreviewBlockingEngine: BlockingEngine {
    func applyWhitelist(for selection: FamilyActivitySelection) {}
    func clearShield() {}
    func temporarilyAllow(token: ApplicationToken, for duration: TimeInterval) {}
}

final class PreviewMonitoringEngine: MonitoringEngine {
    func startSchedule(_ schedule: Schedule, name: String) throws {}
    func stopMonitoring(name: String) {}
    func startTemporaryAllow(name: String, duration: TimeInterval) throws {}
}
