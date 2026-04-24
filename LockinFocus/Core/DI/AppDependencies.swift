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
    }

    /// deep link 진입점.
    func requestRoute(_ route: Route) { pendingRoute = route }

    /// 소비한 쪽이 호출. 다른 뷰의 race 를 방지하기 위한 명시적 API.
    func consumeRoute() { pendingRoute = nil }

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

    private var tickTimer: Timer?
    private var kvObserver: NSObjectProtocol?

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
        startGlobalTicker()
        observeICloudKVChanges()
    }

    deinit {
        tickTimer?.invalidate()
        if let kvObserver {
            NotificationCenter.default.removeObserver(kvObserver)
        }
    }

    /// 전역 타이머 — 엄격 모드 활성 중에만 1초 해상도로 돌고,
    /// 비활성 중에는 10초 해상도로 낮춰 배터리 부담을 최소화한다.
    /// publish 는 초 단위가 실제로 바뀌었을 때만 fire 해 SwiftUI 렌더 폭풍 방지.
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
        let strictActive = persistence.isStrictModeActive
        // 엄격 모드가 아니면 tick 을 매 10초에만 갱신 — 대부분 화면에서 재렌더 생략.
        let secondsSinceLastPublish = now.timeIntervalSince(tick)
        if strictActive || secondsSinceLastPublish >= 10 {
            tick = now
        }
        if let end = persistence.strictModeEndAt, end <= now {
            // 시계 조작 의심 — start 가 미래면 (사용자가 시간 되돌림) 아직 만료 안 된 것으로 간주.
            if let start = persistence.strictModeStartAt, now < start {
                return
            }
            // end 뿐 아니라 start 도 함께 정리 — 다음 엄격 모드 시작 시 오래된 start 가 남지 않도록.
            persistence.strictModeEndAt = nil
            persistence.strictModeStartAt = nil
            celebrate(BadgeEngine.onStrictSurvived(persistence: persistence))
        }
    }

    /// iCloud KV 가 다른 기기에서 바뀌었다는 알림을 받으면 로컬 캐시를 맞춰준다.
    /// split-brain 수렴 메커니즘: 두 기기가 동시에 앱을 처음 실행해 각자 UUID 를
    /// 만든 경우에도 KV 가 나중에 동기화되면 이 알림이 떠서 뒤늦게 합쳐진다.
    private func observeICloudKVChanges() {
        kvObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            // 닉네임·userID 모두 getter 내부에서 iCloud 우선으로 로컬을 재동기화한다.
            // 여기서는 objectWillChange 를 강제로 발행해 관찰 중인 뷰를 재렌더.
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
