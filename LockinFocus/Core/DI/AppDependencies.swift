import Foundation
import FamilyControls
import ManagedSettings

@MainActor
final class AppDependencies: ObservableObject {
    let persistence: PersistenceStore
    let blocking: BlockingEngine
    let monitoring: MonitoringEngine
    /// 리더보드 서비스 — 테스트에서는 MockLeaderboardService 를 주입.
    /// 프로덕션은 CloudKitLeaderboardService.shared.
    let leaderboardService: LeaderboardServiceProtocol

    /// 위젯 탭 같은 외부 deep link 가 열렸을 때 갱신된다.
    /// 일회성 값 — `requestRoute(_:)` 로 쓰고 `consumeRoute()` 로 비운다.
    @Published private(set) var pendingRoute: Route?

    /// 네비게이션 타깃. 추후 파라미터가 필요하면 associated value 로 확장.
    enum Route: String, Equatable {
        case weeklyReport
        case quoteDetail
        case startFocus  // Siri/Shortcut 에서 "집중 시작" intent.
        case endFocus    // Siri/Shortcut 에서 "집중 종료" intent.
    }

    /// deep link 진입점.
    func requestRoute(_ route: Route) { pendingRoute = route }

    /// 소비한 쪽이 호출. 다른 뷰의 race 를 방지하기 위한 명시적 API.
    func consumeRoute() { pendingRoute = nil }

    /// 외부에서 친구 초대 링크가 들어왔을 때 임시 보관하는 payload.
    /// 자기 자신을 추가하는 건 무의미하므로 걸러낸다.
    @Published var pendingFriendInvite: FriendInviteLink.Payload?

    /// 연속 호출 (악성 링크 스팸 · universal link 리다이렉트 반복) 을 방어하기 위한
    /// 레이트 리미터.
    /// - 같은 UID 가 1초 이내 반복: 무시 (이전 동작)
    /// - 어떤 UID 든 200ms 이내 연속 호출: 무시 (다른 UID 폭주 공격 방어)
    private var lastInviteRequestAt: Date?
    private var lastInviteRequestUID: String?

    /// 친구 목록 상한. 끝없이 append 하는 DoS 방지 + iOS UserDefaults 어레이 성능 가드.
    static let maxFriendCount = 500

    func requestFriendInvite(_ payload: FriendInviteLink.Payload) {
        guard payload.userID != persistence.leaderboardUserID else { return }
        let now = Date()
        if let lastAt = lastInviteRequestAt {
            // 글로벌 throttle: 다른 UID 라도 200ms 이내 연속 호출은 무시.
            if now.timeIntervalSince(lastAt) < 0.2 { return }
            // 같은 UID 1초 이내 중복 무시.
            if let lastUID = lastInviteRequestUID,
               lastUID == payload.userID,
               now.timeIntervalSince(lastAt) < 1.0 {
                return
            }
        }
        lastInviteRequestAt = now
        lastInviteRequestUID = payload.userID
        pendingFriendInvite = payload
    }

    /// 표시 안전한 닉네임 — alert · 친구 목록 · 랭킹 행 등 외부 노출 시 항상 이 함수를 거친다.
    /// NicknameValidator 통과면 cleaned, 실패면 위치 기반 익명 라벨 ("친구 N").
    /// `position` 은 1-based; 알 수 없으면 nil 로 두면 그냥 "친구".
    static func safeDisplayName(for raw: String, position: Int? = nil) -> String {
        if case .success(let cleaned) = NicknameValidator.validate(raw) {
            return cleaned
        }
        if let position { return "친구 \(position)" }
        return "친구"
    }

    func consumeFriendInvite() { pendingFriendInvite = nil }

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

    /// 현재 payload 를 확정: 친구 목록에 추가하고 닉네임 캐시 갱신.
    /// 캐시 닉네임은 항상 `safeDisplayName(for:position:)` 을 거친 값만 저장.
    func acceptFriendInvite() {
        guard let p = pendingFriendInvite else { return }
        var ids = persistence.friendUserIDs
        if !ids.contains(p.userID) {
            // 상한 도달 시 가장 오래된 항목을 밀어낸다 — append 무한 증가 방지.
            if ids.count >= Self.maxFriendCount {
                ids.removeFirst(ids.count - Self.maxFriendCount + 1)
            }
            ids.append(p.userID)
            persistence.friendUserIDs = ids
        }
        var cache = persistence.friendNicknameCache
        let position = (ids.firstIndex(of: p.userID) ?? 0) + 1
        cache[p.userID] = Self.safeDisplayName(for: p.nickname, position: position)
        // 캐시도 친구 목록에 실제 있는 키만 유지.
        let allowed = Set(ids)
        cache = cache.filter { allowed.contains($0.key) }
        persistence.friendNicknameCache = cache
        pendingFriendInvite = nil
    }

    /// 현재 화면에 떠 있는 축하 모달. 없으면 nil.
    @Published private(set) var currentCelebratedBadge: Badge?

    /// 아직 안 보여준 뱃지 대기열. 동시에 여러 개 해제되면 하나씩 순차 표시.
    private var badgeQueue: [Badge] = []

    /// BadgeEngine 이 반환한 해제 뱃지를 축하 큐에 넣는다. 빈 배열은 무시.
    func celebrate(_ badges: [Badge]) {
        guard !badges.isEmpty else { return }
        if currentCelebratedBadge == nil {
            var rest = badges
            currentCelebratedBadge = rest.removeFirst()
            badgeQueue.append(contentsOf: rest)
        } else {
            badgeQueue.append(contentsOf: badges)
        }
    }

    /// 축하 모달 "확인" 에서 호출. 대기열이 남아 있으면 다음 뱃지로.
    func dismissCelebratedBadge() {
        if badgeQueue.isEmpty {
            currentCelebratedBadge = nil
        } else {
            currentCelebratedBadge = badgeQueue.removeFirst()
        }
    }

    /// 전역 1초 타이머에서 fire 하는 값. 시간 기반 상태(특히 엄격 모드 만료)를
    /// 관찰하는 뷰가 이 값을 읽으면 자동으로 매초 재렌더링된다.
    @Published private(set) var tick: Date = Date()

    /// 엄격 모드 활성 상태 캐시 — `persistence.isStrictModeActive` 는 매 호출마다
    /// UserDefaults 2 읽기 + Date 비교를 한다. 뷰 body 가 매 tick 이걸 여러 번 부르면
    /// syscall 폭주 — `@Published` 캐시에 두고 상태가 flip 한 때만 emission.
    @Published private(set) var strictActive: Bool = false

    private var tickTimer: Timer?
    private var kvObserver: NSObjectProtocol?

    /// 앱이 백그라운드로 갔을 때 Timer 를 정지해 wake-up 을 0으로. 포그라운드 복귀 시 재개.
    /// RootView 의 scenePhase onChange 에서 호출한다.
    func pauseTicker() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    func resumeTicker() {
        guard tickTimer == nil else { return }
        // 복귀 직후 strict 만료 체크가 늦지 않도록 한 번 즉시 실행.
        onTick()
        startGlobalTicker()
    }

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
        // strictActive 초기 상태 — onTick 가 돌기 전에도 뷰가 올바른 값을 읽도록.
        self.strictActive = persistence.isStrictModeActive
        startGlobalTicker()
        observeICloudKVChanges()
    }

    deinit {
        tickTimer?.invalidate()
        if let kvObserver {
            NotificationCenter.default.removeObserver(kvObserver)
        }
    }

    /// 전역 1초 타이머. 외부(설정·테스트·실기기 strict 시작) 에서 persistence 가 변경
    /// 됐을 때 즉각 감지해야 하므로 base interval 은 1초로 고정.
    /// 배터리 비용은 (a) `scenePhase .background` 시 즉시 invalidate (`pauseTicker`)
    /// 으로 차단, (b) `tick` publish 는 strict 비활성 시 10초마다만 (뷰 재렌더 폭주 방지).
    private func startGlobalTicker() {
        tickTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.onTick()
            }
        }
        tickTimer = timer
    }

    private func onTick() {
        let now = Date()
        let currentStrict = persistence.isStrictModeActive

        // 캐시된 strictActive 상태가 flip 했을 때만 @Published emission — 뷰 본문이
        // UserDefaults 를 매 렌더마다 읽지 않도록.
        if currentStrict != strictActive {
            strictActive = currentStrict
        }

        // strict 활성: 매초 publish (Live timer · countdown 라벨 정확도). 비활성: 10초 throttle.
        let secondsSinceLastPublish = now.timeIntervalSince(tick)
        if currentStrict || secondsSinceLastPublish >= 10 {
            tick = now
        }
        if let end = persistence.strictModeEndAt, end <= now {
            // 시계 조작 의심 — start 가 미래면 (사용자가 시간 되돌림) 아직 만료 안 된 것으로 간주.
            if let start = persistence.strictModeStartAt, now < start {
                return
            }
            // end 뿐 아니라 start 도 함께 정리 — 다음 엄격 모드 시작 시 오래된 start 가 남지 않도록.
            // uptime/duration 은 strictModeEndAt setter 가 자동 정리.
            persistence.strictModeEndAt = nil
            persistence.strictModeStartAt = nil
            // 엄격 모드 완주 — 긍정 햅틱.
            Haptics.success()
            celebrate(BadgeEngine.onStrictSurvived(persistence: persistence))
            // Live Activity + 예약된 완료 알림 모두 정리 (알림은 이미 발송됐을 수 있음).
            FocusActivityService.end()
            StrictCompletionScheduler.cancel()
        }
    }

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
