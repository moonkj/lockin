import FamilyControls
import Foundation

// MARK: - Sub-protocols (ISP 분해)
//
// 이전엔 PersistenceStore 한 protocol 에 30+ properties / 12+ functions 가 모여
// 새 라운드마다 mock 깨짐. 도메인별 sub-protocol 로 쪼개고 `PersistenceStore` 를
// composition typealias 로 재정의 — 외부 callsite (모두 `PersistenceStore` 타입으로
// 받음) 영향 0. 새 모듈/테스트는 필요한 sub-protocol 만 의존하면 mock 표면이 작아짐.

/// 차단 관련 — 허용 앱 selection + 스케줄 + 수동 집중 토글.
protocol BlockingStateStore: AnyObject {
    var selection: FamilyActivitySelection { get set }
    var schedule: Schedule { get set }
    var hasCompletedOnboarding: Bool { get set }
    var isManualFocusActive: Bool { get set }
    var manualFocusStartedAt: Date? { get set }
}

/// 엄격 모드 관련 — wallclock + uptime sentinel.
protocol StrictModeStore: AnyObject {
    var strictModeEndAt: Date? { get set }
    var strictModeStartAt: Date? { get set }
    var strictModeStartUptime: Double? { get set }
    var strictModeDurationSeconds: Double? { get set }
}

/// 점수 + 일별 기록 + 보상 규칙 (B).
protocol FocusScoreStore: AnyObject {
    var focusScoreToday: Int { get set }
    func addFocusPoints(_ points: Int)
    func dailyFocusHistory(lastDays: Int) -> [DailyFocus]

    /// 돌아가기 보상 (3분 쿨다운 + 하루 40점 한도).
    @discardableResult
    func awardReturnPoint() -> Bool

    /// 수동 집중 종료 시 세션 길이 기반 보너스(15분 이상 → +15점).
    @discardableResult
    func awardSessionCompletionIfEligible(now: Date) -> Bool

    /// 하루 첫 앱 실행 보상(+5).
    @discardableResult
    func awardDailyLoginIfNew() -> Bool

    /// 관리자 전용: 주간 리포트 원천 기록 덮어쓰기.
    func debugSetDailyFocusHistory(_ entries: [DailyFocus])
}

/// Intercept 큐 + 지연 해제 카운터 + "그래도 열기" 카운트.
protocol InterceptStore: AnyObject {
    var interceptQueue: [InterceptEvent] { get set }
    var focusEndCountToday: Int { get }

    func recordManualFocusEnd()
    func drainInterceptQueue() -> [InterceptEvent]
    func currentUnlockDelaySeconds() -> Int
    func recordManualUnlock()
}

/// 뱃지 + 누적 카운터.
protocol BadgeStore: AnyObject {
    var earnedBadgeIDs: Set<String> { get set }
    var totalReturnCount: Int { get set }
    var totalStrictSurvived: Int { get set }
    var totalFocusSeconds: Int { get set }
    var totalManualFocusStarts: Int { get set }

    /// 아직 없는 뱃지면 적재 후 true. 이미 있으면 false.
    func awardBadgeIfNew(_ id: String) -> Bool

    /// 대시보드 핀 고정 뱃지 (최대 3).
    var pinnedBadgeIDs: [String] { get set }
}

/// 리더보드 정체성 + 친구 목록 + 캐시.
protocol LeaderboardIdentityStore: AnyObject {
    var nickname: String? { get set }
    var leaderboardUserID: String { get }

    var friendUserIDs: [String] { get set }
    var friendNicknameCache: [String: String] { get set }
}

/// 사용자 토글·선호.
protocol UserSettingsStore: AnyObject {
    var focusGoalScore: Int { get set }
    var useBiometricForPasscode: Bool { get set }
    var dailySummaryNotification: Bool { get set }
    var streakFreezeToken: Int { get set }
    var streakFreezeLastWeek: String { get set }
}

// MARK: - Composed PersistenceStore

/// 앱 상태 저장 추상화. 실구현은 App Group UserDefaults 기반(UserDefaultsPersistenceStore),
/// 시뮬레이터/테스트는 InMemoryPersistenceStore.
///
/// **ISP 분해 (R7+)**: 도메인별 sub-protocol 들의 composition. 새 모듈은 필요한 부분만
/// 의존하면 mock 부담 줄어듦. 기존 callsite 는 `PersistenceStore` 타입을 그대로 사용.
typealias PersistenceStore = BlockingStateStore
    & StrictModeStore
    & FocusScoreStore
    & InterceptStore
    & BadgeStore
    & LeaderboardIdentityStore
    & UserSettingsStore

// MARK: - Strict mode helpers (sentinel logic)

extension StrictModeStore {
    /// 엄격 모드 활성 여부. wallclock + uptime sentinel + clock-rewind 방어.
    /// - 시계 되돌림 (now < start): 활성 유지
    /// - wallclock 만료 + uptime 미달 (시계 미래 조작): 활성 유지
    /// - wallclock 만료 + uptime 도달: 비활성
    /// - 재부팅 (uptimeNow < startUptime): 보수적으로 wallclock 신뢰
    var isStrictModeActive: Bool {
        guard let end = strictModeEndAt else { return false }
        let now = Date()
        if let start = strictModeStartAt, now < start {
            return true
        }
        if end > now { return true }
        if let startUptime = strictModeStartUptime,
           let duration = strictModeDurationSeconds {
            let uptimeNow = ProcessInfo.processInfo.systemUptime
            if uptimeNow >= startUptime {
                let uptimeElapsed = uptimeNow - startUptime
                if uptimeElapsed < duration {
                    return true
                }
            }
        }
        return false
    }

    /// 남은 엄격 모드 시간 (초). wallclock vs uptime 잔여 중 큰 값 반환.
    var strictModeRemainingSeconds: TimeInterval {
        guard let end = strictModeEndAt else { return 0 }
        let now = Date()
        if let start = strictModeStartAt, now < start {
            return max(0, end.timeIntervalSince(start))
        }
        let wallRemaining = max(0, end.timeIntervalSinceNow)
        if let startUptime = strictModeStartUptime,
           let duration = strictModeDurationSeconds {
            let uptimeNow = ProcessInfo.processInfo.systemUptime
            if uptimeNow >= startUptime {
                let uptimeRemaining = max(0, duration - (uptimeNow - startUptime))
                return max(wallRemaining, uptimeRemaining)
            }
        }
        return wallRemaining
    }
}
