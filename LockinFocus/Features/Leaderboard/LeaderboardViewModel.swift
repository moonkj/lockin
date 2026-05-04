import Foundation
import SwiftUI

/// LeaderboardView 의 비즈니스 로직을 뷰에서 분리한 ViewModel.
///
/// **책임 범위**:
/// - CloudKit fetch (`fetchAllRaw` + 60s TTL) + period / scope 별 client-side filter.
/// - 내 entry · 순위 · percentile 계산.
/// - 친구 닉네임 캐시 갱신 (fetched 결과에서 추출).
/// - iCloud KV userID 변경 시 캐시 교체.
///
/// 뷰는 @Published 상태만 관찰해서 렌더만 담당한다.
@MainActor
final class LeaderboardViewModel: ObservableObject {

    // MARK: - Enums

    enum Scope: String, CaseIterable, Identifiable {
        case all, friends
        var id: String { rawValue }
        var label: String {
            switch self {
            case .all: return "전체"
            case .friends: return "친구"
            }
        }
    }

    // MARK: - Dependencies

    /// VM 은 init 에서 실제 의존성을 받아 const 로 보유. container+child 패턴 덕분에
    /// SwiftUI `@StateObject` init-time 제약을 우회하는 stub+connect hack 이 필요 없다.
    let service: LeaderboardServiceProtocol
    let persistence: PersistenceStore
    var badgeAwardHandler: (([Badge]) -> Void)?
    private let clock: () -> Date

    // MARK: - Inputs

    @Published var period: LeaderboardPeriod = .daily {
        didSet {
            guard oldValue != period else { return }
            // period 탭 전환 — 캐시가 있으면 client-side 재필터만, 없으면 load.
            if rawCacheFresh {
                applyFilter()
            } else {
                Task { await load() }
            }
        }
    }
    @Published var scope: Scope = .all {
        didSet {
            guard oldValue != scope else { return }
            applyFilter()
        }
    }

    // MARK: - Outputs (view 가 관찰)

    /// scope + period 필터 적용된 표시용 리스트.
    /// - test 시 직접 대입 허용 (view-only setter restriction 제거) —
    ///   테스트가 특정 entries 상태에서 myRank/myPercentile 를 검증할 수 있어야 함.
    @Published var entries: [LeaderboardEntry] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isSubmitting: Bool = false
    @Published var errorMessage: String?

    /// 사용자 userID — iCloud KV 변경 시 갱신 가능하도록 @Published.
    @Published var myUserID: String

    // MARK: - Cache

    private var rawEntries: [LeaderboardEntry] = []
    private var rawEntriesFetchedAt: Date?
    private static let rankingCacheTTL: TimeInterval = 60

    private var rawCacheFresh: Bool {
        guard !rawEntries.isEmpty, let at = rawEntriesFetchedAt else { return false }
        return Date().timeIntervalSince(at) < Self.rankingCacheTTL
    }

    // MARK: - Init

    init(
        service: LeaderboardServiceProtocol,
        persistence: PersistenceStore,
        badgeAwardHandler: (([Badge]) -> Void)? = nil,
        clock: @escaping () -> Date = Date.init,
        initialPeriod: LeaderboardPeriod = .daily,
        initialEntries: [LeaderboardEntry] = [],
        initialMyUserID: String = ""
    ) {
        self.service = service
        self.persistence = persistence
        self.badgeAwardHandler = badgeAwardHandler
        self.clock = clock
        self.period = initialPeriod
        self.entries = initialEntries
        self.rawEntries = initialEntries
        if !initialEntries.isEmpty { self.rawEntriesFetchedAt = clock() }
        self.myUserID = initialMyUserID.isEmpty ? persistence.leaderboardUserID : initialMyUserID
    }

    // MARK: - Derived state

    var myNickname: String? { persistence.nickname }

    var myRank: Int? {
        entries.firstIndex { $0.userID == myUserID }.map { $0 + 1 }
    }

    var myEntry: LeaderboardEntry? {
        entries.first { $0.userID == myUserID }
    }

    var myPercentile: Int? {
        guard let rank = myRank, !entries.isEmpty else { return nil }
        let ratio = Double(rank) / Double(entries.count)
        return max(1, min(100, Int(ceil(ratio * 100))))
    }

    /// top-of-body `maxScore` 용 1회 lookup — rankRow 당 재계산 방지.
    var maxScoreInPeriod: Double {
        Double(entries.first?.score(for: period) ?? 1)
    }

    // MARK: - Actions

    /// 뷰 첫 등장 시 호출. iCloud KV 최신화 + cache stale 이면 fetch.
    func onAppear() async {
        refreshMyUserIDIfChanged()
        await load()
    }

    /// iCloud KV 변경 알림 (AppDependencies.objectWillChange) 수신 시 호출.
    func refreshMyUserIDIfChanged() {
        let fresh = persistence.leaderboardUserID
        if !fresh.isEmpty && fresh != myUserID {
            myUserID = fresh
            applyFilter()  // userID 바뀌면 myRank/myEntry 도 달라짐.
        }
    }

    /// 캐시 정책: forceRefresh=false 면 TTL 살아있을 때 CloudKit 왕복 skip.
    func load(forceRefresh: Bool = false) async {
        if !forceRefresh && rawCacheFresh {
            applyFilter()
            return
        }
        isLoading = true
        errorMessage = nil
        if !(await service.accountAvailable()) {
            errorMessage = "iCloud 에 로그인해주세요. 설정 → Apple ID → iCloud."
            entries = []
            rawEntries = []
            rawEntriesFetchedAt = nil
            isLoading = false
            return
        }
        do {
            let all = try await service.fetchAllRaw(limit: 500)
            rawEntries = all
            rawEntriesFetchedAt = Date()
            applyFilter()
            refreshFriendNicknameCache(from: all)
            let unlocked = BadgeEngine.onRankingFetched(
                entries: entries,
                userID: myUserID,
                persistence: persistence
            )
            if !unlocked.isEmpty { badgeAwardHandler?(unlocked) }
        } catch let error as CloudKitLeaderboardService.ServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// 지금 점수 랭킹 제출 + 재fetch (강제).
    func submitAndRefresh(
        nicknameSetupTrigger: (() -> Void)? = nil
    ) async {
        guard await service.accountAvailable() else {
            errorMessage = "iCloud 에 로그인되어 있어야 랭킹에 참여할 수 있어요."
            return
        }
        guard let nickname = myNickname else {
            nicknameSetupTrigger?()
            return
        }
        isSubmitting = true
        errorMessage = nil

        let now = clock()
        let dailyScore = persistence.focusScoreToday
        let recent7 = persistence.dailyFocusHistory(lastDays: 7)
        let weeklyTotal = recent7.reduce(0) { $0 + $1.score }
        let recent30 = persistence.dailyFocusHistory(lastDays: 30)
        let monthlyTotal = recent30.reduce(0) { $0 + $1.score }

        do {
            _ = try await service.submit(
                userID: myUserID,
                nickname: nickname,
                dailyScore: dailyScore,
                weeklyTotal: weeklyTotal,
                monthlyTotal: monthlyTotal,
                now: now
            )
            await load(forceRefresh: true)
        } catch let error as CloudKitLeaderboardService.ServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }

    // MARK: - Filter / cache

    /// rawEntries → entries 로 scope+period filter 적용.
    private func applyFilter() {
        let currentPeriodID = LeaderboardPeriodID.current(period)
        let inPeriod = rawEntries.filter { $0.periodID(for: period) == currentPeriodID }
        let scoped: [LeaderboardEntry]
        switch scope {
        case .all:
            scoped = inPeriod
        case .friends:
            let friendSet = Set(persistence.friendUserIDs)
            let allowed = friendSet.union([myUserID])
            scoped = inPeriod.filter { allowed.contains($0.userID) }
        }
        entries = scoped.sorted { $0.score(for: period) > $1.score(for: period) }
    }

    private func refreshFriendNicknameCache(from fetched: [LeaderboardEntry]) {
        let friendSet = Set(persistence.friendUserIDs)
        guard !friendSet.isEmpty else { return }
        var cache = persistence.friendNicknameCache
        var changed = false
        for entry in fetched where friendSet.contains(entry.userID) {
            if cache[entry.userID] != entry.nickname {
                cache[entry.userID] = entry.nickname
                changed = true
            }
        }
        if changed {
            persistence.friendNicknameCache = cache
        }
    }
}
