import Foundation

/// 외부 진입점 (위젯 deep link · Siri App Intent · 친구 초대 URL) 의 pending state 관리.
///
/// 이전엔 AppDependencies 에 흩어져 있었으나 (pendingRoute / pendingFriendInvite /
/// throttle 상태) 라우팅은 dependency 와 무관해서 별도 ObservableObject 분리.
/// AppDependencies 는 forwarding 만 보유 (호환).
@MainActor
final class RouterStore: ObservableObject {

    // MARK: - Route

    /// 네비게이션 타깃. 추후 파라미터가 필요하면 associated value 로 확장.
    enum Route: String, Equatable {
        case weeklyReport
        case quoteDetail
        case startFocus
        case endFocus
        case showFocusScore
        /// Shield 의 secondary 버튼이 눌렸을 때 메인 앱이 받을 라우트. 메인 앱은
        /// 진입 즉시 InterceptView 시트를 띄워 10초 카운트다운 → "그래도 열기" 흐름을
        /// 제공한다.
        case intercept
    }

    /// 위젯 탭 같은 외부 deep link 가 열렸을 때 갱신된다. 일회성 값.
    @Published private(set) var pendingRoute: Route?

    func requestRoute(_ route: Route) { pendingRoute = route }
    func consumeRoute() { pendingRoute = nil }

    // MARK: - Friend Invite

    /// 외부에서 친구 초대 링크가 들어왔을 때 임시 보관하는 payload.
    @Published var pendingFriendInvite: FriendInviteLink.Payload?

    /// Throttle 상태 — DI container 가 아니라 router 의 책임.
    private var lastInviteRequestAt: Date?
    private var lastInviteRequestUID: String?

    /// 친구 추가 시 자기 자신 검출용 — 외부에서 주입 (init 시점엔 unknown).
    var myUserID: () -> String

    /// 친구 목록·캐시 mutate 위해 persistence 접근. DI 로 주입.
    private let persistence: any LeaderboardIdentityStore

    init(
        persistence: any LeaderboardIdentityStore,
        myUserID: @escaping () -> String
    ) {
        self.persistence = persistence
        self.myUserID = myUserID
    }

    func requestFriendInvite(_ payload: FriendInviteLink.Payload) {
        guard payload.userID != myUserID() else { return }
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

    func consumeFriendInvite() { pendingFriendInvite = nil }

    /// 친구 목록 상한.
    static let maxFriendCount = 500

    /// 현재 payload 를 확정: 친구 목록에 추가 + 닉네임 캐시 갱신 (sanitize 적용).
    func acceptFriendInvite() {
        guard let p = pendingFriendInvite else { return }
        var ids = persistence.friendUserIDs
        if !ids.contains(p.userID) {
            if ids.count >= Self.maxFriendCount {
                ids.removeFirst(ids.count - Self.maxFriendCount + 1)
            }
            ids.append(p.userID)
            persistence.friendUserIDs = ids
        }
        var cache = persistence.friendNicknameCache
        let position = (ids.firstIndex(of: p.userID) ?? 0) + 1
        cache[p.userID] = Self.safeDisplayName(for: p.nickname, position: position)
        let allowed = Set(ids)
        cache = cache.filter { allowed.contains($0.key) }
        persistence.friendNicknameCache = cache
        pendingFriendInvite = nil
    }

    /// 표시 안전한 닉네임 — alert · 친구 목록 · 랭킹 행 등 외부 노출 시 항상 이 함수를 거친다.
    /// NicknameValidator 통과면 cleaned, 실패면 위치 기반 익명 라벨 ("친구 N").
    static func safeDisplayName(for raw: String, position: Int? = nil) -> String {
        if case .success(let cleaned) = NicknameValidator.validate(raw) {
            return cleaned
        }
        if let position { return "친구 \(position)" }
        return "친구"
    }
}
