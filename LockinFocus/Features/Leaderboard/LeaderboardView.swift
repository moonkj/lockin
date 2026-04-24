import SwiftUI

/// CloudKit 기반 랭킹 — 일간/주간/월간 탭 + Top 3 메달 + 4~30위 리스트 + 내 순위.
struct LeaderboardView: View {
    @EnvironmentObject var deps: AppDependencies
    @Environment(\.dismiss) private var dismiss

    /// 서비스는 AppDependencies 에서 주입된 것을 사용한다 (테스트 mock 가능).
    private var service: LeaderboardServiceProtocol { deps.leaderboardService }

    @State private var period: LeaderboardPeriod
    @State private var entries: [LeaderboardEntry]
    @State private var isLoading: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?
    @State private var showNicknameSetup: Bool = false
    @State private var scope: Scope = .all
    @State private var showFriendsSheet: Bool = false
    /// CloudKit full fetch 캐시 — 1 회 fetch 로 3 period 모두 client-side 에서 커버.
    @State private var rawEntries: [LeaderboardEntry] = []
    @State private var rawEntriesFetchedAt: Date?
    private static let rankingCacheTTL: TimeInterval = 60  // 초. 사용자 체감 갱신률 vs. 배터리.

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

    /// iCloud KV 조회가 동기라서 매 프레임 수십 번 부르면 UI 가 느려진다 —
    /// 뷰 등장 시 한 번 캐시한 뒤 재사용.
    @State private var myUserID: String

    /// 기본 init — 런타임 사용 경로.
    init() {
        _period = State(initialValue: .daily)
        _entries = State(initialValue: [])
        _myUserID = State(initialValue: "")
    }

    /// 테스트 전용 init — 초기 entries/period/userID 주입해 medal/rankRow 렌더 분기 검증.
    init(
        initialPeriod: LeaderboardPeriod,
        initialEntries: [LeaderboardEntry],
        initialMyUserID: String = ""
    ) {
        _period = State(initialValue: initialPeriod)
        _entries = State(initialValue: initialEntries)
        _myUserID = State(initialValue: initialMyUserID)
    }
    private var myNickname: String? { deps.persistence.nickname }

    /// 현재 scope (전체/친구) 에 해당하는 엔트리만 필터링.
    /// 친구 scope 에서는 내 entry + 친구 entry 만 남기고 재정렬.
    private var visibleEntries: [LeaderboardEntry] {
        switch scope {
        case .all:
            return entries
        case .friends:
            let friendSet = Set(deps.persistence.friendUserIDs)
            let allowed = friendSet.union([myUserID])
            return entries
                .filter { allowed.contains($0.userID) }
                .sorted { $0.score(for: period) > $1.score(for: period) }
        }
    }

    private var myRank: Int? {
        visibleEntries.firstIndex { $0.userID == myUserID }.map { $0 + 1 }
    }

    private var myEntry: LeaderboardEntry? {
        visibleEntries.first { $0.userID == myUserID }
    }

    private var myPercentile: Int? {
        guard let rank = myRank, !visibleEntries.isEmpty else { return nil }
        let ratio = Double(rank) / Double(visibleEntries.count)
        return max(1, min(100, Int(ceil(ratio * 100))))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        scopePicker
                        periodPicker
                        topThreeSection
                        summaryStrip
                        rankingList
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .readingWidth()
                }

                if isLoading && entries.isEmpty {
                    ProgressView().scaleEffect(1.2)
                }
            }
            .navigationTitle(scope == .friends ? "친구 랭킹" : "전체 랭킹")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(AppColors.secondaryText)
                }
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 14) {
                        Button {
                            showFriendsSheet = true
                        } label: {
                            Image(systemName: "person.2")
                                .foregroundStyle(AppColors.primaryText)
                        }
                        .accessibilityLabel("친구 관리")

                        Button {
                            Task { await submitAndRefresh() }
                        } label: {
                            Image(systemName: "arrow.up.circle")
                                .foregroundStyle(AppColors.primaryText)
                        }
                        .disabled(isSubmitting)
                        .accessibilityLabel("내 점수 랭킹에 등록")
                    }
                }
            }
            .sheet(isPresented: $showNicknameSetup) {
                NicknameSetupView { _ in
                    Task { await submitAndRefresh() }
                }
                .environmentObject(deps)
            }
            .sheet(isPresented: $showFriendsSheet) {
                FriendsManagementView()
                    .environmentObject(deps)
            }
            .task {
                // 뷰 첫 등장 시 iCloud KV 에서 userID 를 한 번만 조회해 캐시.
                if myUserID.isEmpty {
                    myUserID = deps.persistence.leaderboardUserID
                }
                await load()
            }
            .onChange(of: period) { _ in
                Task { await load() }
            }
            .onReceive(deps.objectWillChange) { _ in
                // iCloud KV didChangeExternallyNotification 수신 시 AppDependencies 가
                // objectWillChange 를 쏜다 — 이때 다른 기기에서 userID 가 바뀌어
                // 들어왔다면 stale 캐시를 교체. 매 tick 에도 호출되지만 UserDefaults
                // 읽기 + 문자열 비교라 비용은 미미.
                // 테스트 inject 경로(`initialMyUserID`)는 deps 의 @Published 를
                // 건드리지 않아 여기에 도달하지 않으므로 주입 값이 보존된다.
                let fresh = deps.persistence.leaderboardUserID
                if !fresh.isEmpty && fresh != myUserID {
                    myUserID = fresh
                }
            }
        }
    }

    // MARK: - Sections

    /// 전체 / 친구 범위 전환 세그먼트.
    private var scopePicker: some View {
        HStack(spacing: 0) {
            ForEach(Scope.allCases) { s in
                let isSelected = scope == s
                Button {
                    Haptics.selection()
                    scope = s
                } label: {
                    Text(s.label)
                        .scaledFont(13, weight: isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? AppColors.primaryText : AppColors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(isSelected ? AppColors.surface : Color.clear)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppColors.divider.opacity(0.3))
        )
    }

    private var periodPicker: some View {
        HStack(spacing: 8) {
            ForEach(LeaderboardPeriod.allCases) { p in
                let isSelected = period == p
                Button {
                    period = p
                } label: {
                    Text(p.label)
                        .scaledFont(14, weight: isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? Color.white : AppColors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(isSelected ? AppColors.primaryText : AppColors.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(isSelected ? Color.clear : AppColors.divider, lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 4)
    }

    private var topThreeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(period.label) Top 3")
                .scaledFont(13, weight: .semibold)
                .foregroundStyle(AppColors.primaryText)

            HStack(alignment: .bottom, spacing: 20) {
                if visibleEntries.indices.contains(1) {
                    medalCell(rank: 2, entry: visibleEntries[1])
                } else {
                    placeholderMedal(rank: 2)
                }
                if visibleEntries.indices.contains(0) {
                    medalCell(rank: 1, entry: visibleEntries[0])
                } else {
                    placeholderMedal(rank: 1)
                }
                if visibleEntries.indices.contains(2) {
                    medalCell(rank: 3, entry: visibleEntries[2])
                } else {
                    placeholderMedal(rank: 3)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    private var summaryStrip: some View {
        HStack(spacing: 20) {
            summaryStat(label: "참여자", value: "\(visibleEntries.count)명")
            Divider().frame(height: 28)
            summaryStat(
                label: "내 등수",
                value: myRank.map { "\($0)등" } ?? "미등록"
            )
            Divider().frame(height: 28)
            summaryStat(
                label: "상위",
                value: myPercentile.map { "\($0)%" } ?? "—"
            )
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    private func summaryStat(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .scaledFont(15, weight: .semibold)
                .foregroundStyle(AppColors.primaryText)
            Text(label)
                .scaledFont(10)
                .foregroundStyle(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var rankingList: some View {
        VStack(spacing: 8) {
            if let errorMessage {
                Text(errorMessage)
                    .scaledFont(12)
                    .foregroundStyle(AppColors.error)
                    .padding(.vertical, 4)
            }

            if scope == .friends && deps.persistence.friendUserIDs.isEmpty {
                Text("아직 친구가 없어요.\n오른쪽 위 사람 아이콘에서 친구 초대 링크를 공유해보세요.")
                    .scaledFont(13)
                    .foregroundStyle(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 40)
            } else if visibleEntries.count <= 3 {
                Text("아직 등록된 기록이 많지 않아요.\n오른쪽 위 ↑ 버튼으로 내 점수를 등록해보세요.")
                    .scaledFont(13)
                    .foregroundStyle(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 40)
            } else {
                ForEach(Array(visibleEntries.prefix(30).enumerated()), id: \.element.id) { index, entry in
                    if index >= 3 {
                        rankRow(rank: index + 1, entry: entry)
                    }
                }
            }

            // 내 순위가 30위 밖이면 하단에 따로.
            if let rank = myRank, rank > 30, let me = myEntry {
                Divider().padding(.vertical, 6)
                Text("내 순위")
                    .scaledFont(12, weight: .semibold)
                    .foregroundStyle(AppColors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                rankRow(rank: rank, entry: me)
            }
        }
    }

    // MARK: - Components

    private func medalCell(rank: Int, entry: LeaderboardEntry) -> some View {
        let size: CGFloat = rank == 1 ? 64 : 54
        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(medalGradient(for: rank))
                    .frame(width: size, height: size)
                    .shadow(color: medalColor(for: rank).opacity(0.35), radius: 6, x: 0, y: 3)
                Image(systemName: "trophy.fill")
                    .scaledFont(rank == 1 ? 26 : 22, weight: .semibold)
                    .foregroundStyle(.white)
            }

            Text("\(rank)등")
                .scaledFont(11, weight: .semibold)
                .foregroundStyle(medalColor(for: rank))

            Text(entry.nickname)
                .scaledFont(12, weight: rank == 1 ? .semibold : .medium)
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("\(entry.score(for: period))점")
                .scaledFont(11, weight: .medium)
                .foregroundStyle(AppColors.secondaryText)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }

    private func placeholderMedal(rank: Int) -> some View {
        let size: CGFloat = rank == 1 ? 64 : 54
        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(AppColors.divider)
                    .frame(width: size, height: size)
                Image(systemName: "trophy.fill")
                    .scaledFont(rank == 1 ? 26 : 22, weight: .semibold)
                    .foregroundStyle(AppColors.secondaryText.opacity(0.5))
            }
            Text("\(rank)등")
                .scaledFont(11, weight: .semibold)
                .foregroundStyle(AppColors.secondaryText)
            Text("—")
                .scaledFont(12)
                .foregroundStyle(AppColors.secondaryText)
            Text(" ")
                .scaledFont(11)
        }
        .frame(maxWidth: .infinity)
    }

    private func rankRow(rank: Int, entry: LeaderboardEntry) -> some View {
        let isMe = entry.userID == myUserID
        let score = entry.score(for: period)
        let maxScore = Double(visibleEntries.first?.score(for: period) ?? 1)
        let ratio: Double = maxScore > 0 ? Double(score) / maxScore : 0
        // VoiceOver 용 통합 라벨 — 메달 색 · 등수 · 이름 · 점수를 한 번에 읽어준다.
        let medalPrefix: String = {
            switch rank {
            case 1: return "금메달 1등"
            case 2: return "은메달 2등"
            case 3: return "동메달 3등"
            default: return "\(rank)등"
            }
        }()
        let meSuffix = isMe ? " 나" : ""
        let a11yLabel = "\(medalPrefix), \(entry.nickname)\(meSuffix), \(score)점"

        return VStack(spacing: 6) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(medalColor(for: rank), lineWidth: 1.5)
                        .frame(width: 28, height: 28)
                    Text("\(rank)")
                        .scaledFont(13, weight: .semibold)
                        .foregroundStyle(medalColor(for: rank))
                }

                Text(entry.nickname)
                    .scaledFont(15, weight: isMe ? .semibold : .regular)
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(2)

                if isMe {
                    Text("나")
                        .scaledFont(10, weight: .semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(AppColors.primaryText))
                }

                Spacer()

                Text("\(score)점")
                    .scaledFont(14, weight: .semibold, design: .rounded)
                    .foregroundStyle(medalColor(for: rank))
                    .monospacedDigit()
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.divider)
                        .frame(height: 4)
                    Capsule()
                        .fill(medalColor(for: rank))
                        .frame(width: max(6, proxy.size.width * ratio), height: 4)
                }
            }
            .frame(height: 4)
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isMe ? AppColors.surface : Color.clear)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(a11yLabel)
    }

    // MARK: - Medal palette

    private func medalColor(for rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 0.95, green: 0.70, blue: 0.20) // gold
        case 2: return Color(red: 0.68, green: 0.70, blue: 0.74) // silver
        case 3: return Color(red: 0.80, green: 0.52, blue: 0.28) // bronze
        default: return Color(red: 0.93, green: 0.55, blue: 0.15) // orange tint for ranks 4+
        }
    }

    private func medalGradient(for rank: Int) -> LinearGradient {
        let base = medalColor(for: rank)
        return LinearGradient(
            colors: [base.opacity(0.9), base],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Actions

    @MainActor
    private func refreshFriendNicknameCache(from fetched: [LeaderboardEntry]) {
        let friendSet = Set(deps.persistence.friendUserIDs)
        guard !friendSet.isEmpty else { return }
        var cache = deps.persistence.friendNicknameCache
        var changed = false
        for entry in fetched where friendSet.contains(entry.userID) {
            if cache[entry.userID] != entry.nickname {
                cache[entry.userID] = entry.nickname
                changed = true
            }
        }
        if changed {
            deps.persistence.friendNicknameCache = cache
        }
    }

    /// TTL 창이 살아있고 raw 캐시가 비어있지 않으면 true.
    private var rawCacheFresh: Bool {
        guard !rawEntries.isEmpty, let at = rawEntriesFetchedAt else { return false }
        return Date().timeIntervalSince(at) < Self.rankingCacheTTL
    }

    /// rawEntries 를 현재 period 기준으로 filter + sort 해서 entries 에 반영.
    /// period 탭 전환만 된 경우 (CloudKit 재fetch 없이) 즉시 갱신.
    private func applyPeriodFilter() {
        let currentID = LeaderboardPeriodID.current(period)
        let filtered = rawEntries.filter { $0.periodID(for: period) == currentID }
        entries = filtered.sorted { $0.score(for: period) > $1.score(for: period) }
    }

    private func load(forceRefresh: Bool = false) async {
        // 캐시가 신선하면 client-side filter 만 재실행 — CloudKit 왕복 제거.
        if !forceRefresh && rawCacheFresh {
            applyPeriodFilter()
            return
        }

        isLoading = true
        errorMessage = nil
        // 조회도 로그인된 iCloud 계정이 필요하다 — 로그아웃 상태면 조용히 빈 리스트가
        // 뜨는 대신 명확한 에러 카피를 보여준다.
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
            applyPeriodFilter()
            // 친구 닉네임 캐시는 period 무관하게 전체에서 갱신 (raw 가 superset).
            refreshFriendNicknameCache(from: all)
            // 랭킹 로드 직후 순위 뱃지 판정 — 참가자 100명 이상이면 해당 구간·등수 뱃지 부여.
            let unlocked = BadgeEngine.onRankingFetched(
                entries: entries,
                userID: myUserID,
                persistence: deps.persistence
            )
            deps.celebrate(unlocked)
        } catch let error as CloudKitLeaderboardService.ServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    private func submitAndRefresh() async {
        // iCloud 를 먼저 체크 — 로그아웃 상태에서 nickname 시트를 먼저 띄우면
        // 닉네임 저장 뒤 submit 에서 또 iCloud 에러가 나는 2-step 혼란이 생긴다.
        guard await service.accountAvailable() else {
            errorMessage = "iCloud 에 로그인되어 있어야 랭킹에 참여할 수 있어요."
            return
        }
        guard let nickname = myNickname else {
            showNicknameSetup = true
            return
        }
        isSubmitting = true
        errorMessage = nil

        let dailyScore = deps.persistence.focusScoreToday
        let recent7 = deps.persistence.dailyFocusHistory(lastDays: 7)
        let weeklyTotal = recent7.reduce(0) { $0 + $1.score }
        let recent30 = deps.persistence.dailyFocusHistory(lastDays: 30)
        let monthlyTotal = recent30.reduce(0) { $0 + $1.score }

        do {
            _ = try await service.submit(
                userID: deps.persistence.leaderboardUserID,
                nickname: nickname,
                dailyScore: dailyScore,
                weeklyTotal: weeklyTotal,
                monthlyTotal: monthlyTotal
            )
            // 내 기록을 방금 저장했으니 캐시 무효화 후 재fetch.
            await load(forceRefresh: true)
        } catch let error as CloudKitLeaderboardService.ServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
